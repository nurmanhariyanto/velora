import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coordinate_point.dart';

/// Model penanda peristiwa saat rute melintasi batas kabupaten/kota baru
class RegencyBorderEvent {
  final String regencyName; // cth: "Kab. Kubu Raya", "Kota Pontianak"
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final int pointIndex;

  const RegencyBorderEvent({
    required this.regencyName,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.pointIndex,
  });

  @override
  String toString() =>
      'RegencyBorderEvent(regency: $regencyName, dist: ${distanceMeters.toStringAsFixed(1)}m, pt: $pointIndex)';
}

/// Layanan deteksi batas wilayah kabupaten/kota di sepanjang rute latihan GPS.
/// Mendukung lookup offline instan (Kalimantan Barat & kota-kota utama Indonesia)
/// serta reverse geocoding online Nominatim OpenStreetMap dengan in-memory cache.
class RegionGeocodingService {
  static const String userAgent = 'online.nurmancloud.velora';

  // Cache lokal in-memory untuk koordinat yang sudah di-resolve
  static final Map<String, String> _cache = <String, String>{};

  /// Mencari nama kabupaten/kota berdasarkan koordinat GPS
  static Future<String?> getRegencyName(double lat, double lon) async {
    final cacheKey = '${(lat * 100).round() / 100},${(lon * 100).round() / 100}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Coba pencocokan offline terlebih dahulu (instan 0 ms, 100% offline)
    final offlineName = lookupOfflineRegency(lat, lon);
    if (offlineName != null) {
      _cache[cacheKey] = offlineName;
      return offlineName;
    }

    // 2. Jika offline tidak cocok, coba reverse geocode via OSM Nominatim (timeout singkat 2 detik)
    try {
      final onlineName = await reverseGeocodeOnline(lat, lon);
      if (onlineName != null && onlineName.isNotEmpty) {
        _cache[cacheKey] = onlineName;
        return onlineName;
      }
    } catch (_) {
      // Abaikan jika tidak ada koneksi internet
    }

    return null;
  }

  /// Deteksi pergantian kabupaten/kota di sepanjang rute koordinat GPS
  static Future<List<RegencyBorderEvent>> detectRegencyBorders({
    required List<CoordinatePoint> coordinates,
    required List<double> cumulativeDistances,
  }) async {
    if (coordinates.length < 2) return const [];

    final borders = <RegencyBorderEvent>[];
    String? currentRegency;

    // Sampling titik rute (setiap ~300-500m atau titik signifikan)
    final sampleStep = coordinates.length > 200 ? (coordinates.length / 80).ceil() : 1;

    for (int i = 0; i < coordinates.length; i += sampleStep) {
      final pt = coordinates[i];
      final regency = await getRegencyName(pt.latitude, pt.longitude);
      if (regency == null || regency.isEmpty) continue;

      if (currentRegency == null) {
        currentRegency = regency;
      } else if (regency != currentRegency) {
        // Terjadi perpindahan kabupaten/kota!
        final dist = i < cumulativeDistances.length ? cumulativeDistances[i] : 0.0;
        borders.add(
          RegencyBorderEvent(
            regencyName: regency,
            latitude: pt.latitude,
            longitude: pt.longitude,
            distanceMeters: dist,
            pointIndex: i,
          ),
        );
        currentRegency = regency;
      }
    }

    // Periksa juga titik akhir rute jika belum terperiksa
    if (coordinates.isNotEmpty) {
      final lastIdx = coordinates.length - 1;
      final lastPt = coordinates[lastIdx];
      final lastRegency = await getRegencyName(lastPt.latitude, lastPt.longitude);
      if (lastRegency != null &&
          lastRegency.isNotEmpty &&
          currentRegency != null &&
          lastRegency != currentRegency) {
        final dist = lastIdx < cumulativeDistances.length ? cumulativeDistances[lastIdx] : 0.0;
        borders.add(
          RegencyBorderEvent(
            regencyName: lastRegency,
            latitude: lastPt.latitude,
            longitude: lastPt.longitude,
            distanceMeters: dist,
            pointIndex: lastIdx,
          ),
        );
      }
    }

    return borders;
  }

  /// Pencarian offline cepat berdasarkan batas geografis kabupaten/kota
  static String? lookupOfflineRegency(double lat, double lon) {
    // -------------------------------------------------------------------------
    // 1. Wilayah Kalimantan Barat
    // -------------------------------------------------------------------------
    // Kota Pontianak: wilayah inti kota khatulistiwa
    if (lat >= -0.080 && lat <= 0.015 && lon >= 109.280 && lon <= 109.375) {
      return 'Kota Pontianak';
    }

    // Kabupaten Kubu Raya: mengelilingi Kota Pontianak ke selatan, timur, dan pesisir
    if (lat >= -0.750 && lat <= 0.200 && lon >= 109.050 && lon <= 109.950) {
      return 'Kab. Kubu Raya';
    }

    // Kabupaten Mempawah (Mempawah Hilir, Anjongan, Toho, Siantan Utara)
    if (lat >= 0.100 && lat <= 0.650 && lon >= 108.850 && lon <= 109.350) {
      return 'Kab. Mempawah';
    }

    // Kota Singkawang
    if (lat >= 0.750 && lat <= 1.050 && lon >= 108.900 && lon <= 109.150) {
      return 'Kota Singkawang';
    }

    // Kabupaten Sambas
    if (lat >= 1.000 && lat <= 2.100 && lon >= 108.950 && lon <= 110.100) {
      return 'Kab. Sambas';
    }

    // Kabupaten Landak (Ngabang, Mandor, dll)
    if (lat >= 0.150 && lat <= 0.950 && lon >= 109.400 && lon <= 110.350) {
      return 'Kab. Landak';
    }

    // Kabupaten Sanggau
    if (lat >= -0.350 && lat <= 0.750 && lon >= 110.000 && lon <= 110.850) {
      return 'Kab. Sanggau';
    }

    // Kabupaten Sekadau
    if (lat >= -0.300 && lat <= 0.300 && lon >= 110.750 && lon <= 111.350) {
      return 'Kab. Sekadau';
    }

    // Kabupaten Sintang
    if (lat >= -0.850 && lat <= 1.050 && lon >= 111.100 && lon <= 112.500) {
      return 'Kab. Sintang';
    }

    // Kabupaten Kapuas Hulu (Putussibau, Danau Sentarum)
    if (lat >= 0.250 && lat <= 1.500 && lon >= 111.850 && lon <= 113.850) {
      return 'Kab. Kapuas Hulu';
    }

    // Kabupaten Ketapang
    if (lat >= -2.900 && lat <= -0.900 && lon >= 109.800 && lon <= 111.450) {
      return 'Kab. Ketapang';
    }

    // Kabupaten Kayong Utara (Sukadana)
    if (lat >= -1.600 && lat <= -0.950 && lon >= 109.700 && lon <= 110.500) {
      return 'Kab. Kayong Utara';
    }

    // Kabupaten Melawi (Nanga Pinoh)
    if (lat >= -1.200 && lat <= -0.150 && lon >= 111.200 && lon <= 112.300) {
      return 'Kab. Melawi';
    }

    // Kabupaten Bengkayang
    if (lat >= 0.550 && lat <= 1.300 && lon >= 109.100 && lon <= 110.150) {
      return 'Kab. Bengkayang';
    }

    // -------------------------------------------------------------------------
    // 2. Wilayah Jabodetabek & Jawa Barat
    // -------------------------------------------------------------------------
    if (lat >= -6.370 && lat <= -6.080 && lon >= 106.680 && lon <= 106.980) {
      if (lat >= -6.210 && lat <= -6.150 && lon >= 106.810 && lon <= 106.870) return 'Jakarta Pusat';
      if (lat >= -6.370 && lat <= -6.200 && lon >= 106.750 && lon <= 106.860) return 'Jakarta Selatan';
      if (lat >= -6.210 && lat <= -6.110 && lon >= 106.680 && lon <= 106.820) return 'Jakarta Barat';
      if (lat >= -6.370 && lat <= -6.170 && lon >= 106.850 && lon <= 106.970) return 'Jakarta Timur';
      return 'DKI Jakarta';
    }

    if (lat >= -6.650 && lat <= -6.530 && lon >= 106.750 && lon <= 106.850) return 'Kota Bogor';
    if (lat >= -6.750 && lat <= -6.350 && lon >= 106.500 && lon <= 107.150) return 'Kab. Bogor';
    if (lat >= -6.450 && lat <= -6.330 && lon >= 106.730 && lon <= 106.900) return 'Kota Depok';
    if (lat >= -6.350 && lat <= -6.180 && lon >= 106.930 && lon <= 107.050) return 'Kota Bekasi';
    if (lat >= -6.400 && lat <= -6.000 && lon >= 107.000 && lon <= 107.300) return 'Kab. Bekasi';
    if (lat >= -6.250 && lat <= -6.120 && lon >= 106.580 && lon <= 106.730) return 'Kota Tangerang';
    if (lat >= -6.360 && lat <= -6.250 && lon >= 106.660 && lon <= 106.760) return 'Tangerang Selatan';
    if (lat >= -6.350 && lat <= -6.000 && lon >= 106.350 && lon <= 106.650) return 'Kab. Tangerang';
    if (lat >= -6.970 && lat <= -6.840 && lon >= 107.540 && lon <= 107.730) return 'Kota Bandung';
    if (lat >= -7.050 && lat <= -6.670 && lon >= 107.150 && lon <= 107.650) return 'Kab. Bandung Barat';
    if (lat >= -7.300 && lat <= -6.900 && lon >= 107.300 && lon <= 107.850) return 'Kab. Bandung';

    // -------------------------------------------------------------------------
    // 3. Wilayah Jawa Tengah & DIY
    // -------------------------------------------------------------------------
    if (lat >= -7.100 && lat <= -6.930 && lon >= 110.280 && lon <= 110.500) return 'Kota Semarang';
    if (lat >= -7.830 && lat <= -7.770 && lon >= 110.350 && lon <= 110.410) return 'Kota Yogyakarta';
    if (lat >= -7.800 && lat <= -7.550 && lon >= 110.250 && lon <= 110.550) return 'Kab. Sleman';
    if (lat >= -8.020 && lat <= -7.800 && lon >= 110.200 && lon <= 110.500) return 'Kab. Bantul';

    // -------------------------------------------------------------------------
    // 4. Wilayah Jawa Timur & Bali
    // -------------------------------------------------------------------------
    if (lat >= -7.360 && lat <= -7.180 && lon >= 112.600 && lon <= 112.820) return 'Kota Surabaya';
    if (lat >= -7.580 && lat <= -7.340 && lon >= 112.500 && lon <= 112.850) return 'Kab. Sidoarjo';
    if (lat >= -7.350 && lat <= -6.850 && lon >= 112.450 && lon <= 112.750) return 'Kab. Gresik';
    if (lat >= -8.730 && lat <= -8.580 && lon >= 115.170 && lon <= 115.280) return 'Kota Denpasar';
    if (lat >= -8.850 && lat <= -8.250 && lon >= 115.080 && lon <= 115.300) return 'Kab. Badung';

    return null;
  }

  /// Reverse geocoding online menggunakan OpenStreetMap Nominatim
  static Future<String?> reverseGeocodeOnline(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
    );

    final response = await http
        .get(uri, headers: const {'User-Agent': userAgent})
        .timeout(const Duration(milliseconds: 2500));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address != null) {
        final county = address['county'] as String?;
        final city = address['city'] as String?;
        final town = address['town'] as String?;
        final stateDistrict = address['state_district'] as String?;

        String? rawName = county ?? city ?? town ?? stateDistrict;
        if (rawName != null) {
          // Bersihkan awalan nama resmi ke format ringkas (cth: "Kabupaten " -> "Kab. ")
          rawName = rawName.replaceAll('Kabupaten ', 'Kab. ');
          return rawName;
        }
      }
    }
    return null;
  }
}
