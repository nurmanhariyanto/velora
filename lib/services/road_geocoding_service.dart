import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/coordinate_point.dart';
import '../algorithms/haversine.dart';

/// Model penanda peristiwa saat rute atlet berpindah ke jalan/ruas baru
class RoadTransitionEvent {
  final String roadName; // cth: "Jl. Jend. Sudirman", "Jl. Ahmad Yani"
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final int pointIndex;

  const RoadTransitionEvent({
    required this.roadName,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.pointIndex,
  });

  @override
  String toString() =>
      'RoadTransitionEvent(road: $roadName, dist: ${distanceMeters.toStringAsFixed(1)}m, pt: $pointIndex)';
}

/// Layanan deteksi dan reverse-geocoding nama jalan di sepanjang rute latihan GPS.
/// Mendukung lookup offline instan (jalur latihan populer di berbagai kota)
/// serta reverse geocoding online OpenStreetMap Nominatim (zoom level 18) dengan in-memory cache.
class RoadGeocodingService {
  static const String userAgent = 'online.nurmancloud.velora';

  // Cache lokal in-memory untuk koordinat yang sudah di-resolve
  static final Map<String, String> _cache = <String, String>{};

  /// Mencari nama jalan berdasarkan koordinat GPS
  static Future<String?> getRoadName(
    double lat,
    double lon, {
    http.Client? client,
  }) async {
    // Kunci cache berbasis presisi ~100 meter (3 digit desimal)
    final cacheKey = '${(lat * 1000).round() / 1000},${(lon * 1000).round() / 1000}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Coba pencocokan offline cepat terlebih dahulu (0 ms, 100% offline)
    final offlineRoad = lookupOfflineRoad(lat, lon);
    if (offlineRoad != null && offlineRoad.isNotEmpty) {
      final formatted = formatRoadName(offlineRoad);
      _cache[cacheKey] = formatted;
      return formatted;
    }

    // 2. Jika offline tidak cocok, lakukan reverse geocoding via OSM Nominatim (zoom=18)
    try {
      final onlineRoad = await reverseGeocodeRoadOnline(lat, lon, client: client);
      if (onlineRoad != null && onlineRoad.isNotEmpty) {
        final formatted = formatRoadName(onlineRoad);
        _cache[cacheKey] = formatted;
        return formatted;
      }
    } catch (e) {
      debugPrint('RoadGeocodingService: Info lookup online ($lat, $lon): $e');
    }

    return null;
  }

  /// Format nama jalan agar ringkas, konsisten, dan mudah dibaca pada badge layar
  static String formatRoadName(String raw) {
    var name = raw.trim();
    if (name.startsWith('Jalan ')) {
      name = 'Jl. ${name.substring(6)}';
    } else if (name.startsWith('Gang ')) {
      name = 'Gg. ${name.substring(5)}';
    } else if (name.startsWith('Lorong ')) {
      name = 'Lr. ${name.substring(7)}';
    } else if (name.startsWith('Boulevard ')) {
      name = 'Blvd. ${name.substring(10)}';
    }
    return name;
  }

  /// Deteksi titik perpindahan nama jalan di sepanjang lintasan rute GPS
  static Future<List<RoadTransitionEvent>> detectRoadTransitions({
    required List<CoordinatePoint> coordinates,
    required List<double> cumulativeDistances,
    http.Client? client,
  }) async {
    if (coordinates.length < 2) return const [];

    final transitions = <RoadTransitionEvent>[];
    String? currentRoad;

    // 1. Kumpulkan indeks titik rute yang relevan untuk diperiksa:
    // - Titik awal rute (KM 0)
    // - Titik dengan belokan signifikan (perubahan bearing > 28 derajat)
    // - Titik reguler setiap interval jarak (~250-400 meter)
    final sampleIndices = <int>{0};

    double lastSampleDist = 0.0;
    for (int i = 1; i < coordinates.length - 1; i++) {
      final prev = coordinates[i - 1];
      final curr = coordinates[i];
      final next = coordinates[i + 1];

      final dist = i < cumulativeDistances.length ? cumulativeDistances[i] : 0.0;

      // Cek perubahan sudut belokan (turn angle)
      final bearing1 = Haversine.calculateBearing(prev.latitude, prev.longitude, curr.latitude, curr.longitude);
      final bearing2 = Haversine.calculateBearing(curr.latitude, curr.longitude, next.latitude, next.longitude);
      var angleDiff = (bearing2 - bearing1).abs();
      if (angleDiff > 180) angleDiff = 360 - angleDiff;

      final isSharpTurn = angleDiff >= 28.0;
      final isDistanceInterval = (dist - lastSampleDist) >= 300.0;

      if (isSharpTurn || isDistanceInterval) {
        sampleIndices.add(i);
        lastSampleDist = dist;
      }

      // Batasi maksimal 45 titik sampel untuk menjaga performa optimal
      if (sampleIndices.length >= 45) break;
    }
    sampleIndices.add(coordinates.length - 1);

    final sortedIndices = sampleIndices.toList()..sort();

    // 2. Query nama jalan untuk setiap titik sampel
    for (final idx in sortedIndices) {
      final pt = coordinates[idx];
      final road = await getRoadName(pt.latitude, pt.longitude, client: client);
      if (road == null || road.isEmpty) continue;

      if (currentRoad == null) {
        currentRoad = road;
        final dist = idx < cumulativeDistances.length ? cumulativeDistances[idx] : 0.0;
        transitions.add(
          RoadTransitionEvent(
            roadName: road,
            latitude: pt.latitude,
            longitude: pt.longitude,
            distanceMeters: dist,
            pointIndex: idx,
          ),
        );
      } else if (road.toLowerCase() != currentRoad.toLowerCase()) {
        final dist = idx < cumulativeDistances.length ? cumulativeDistances[idx] : 0.0;
        transitions.add(
          RoadTransitionEvent(
            roadName: road,
            latitude: pt.latitude,
            longitude: pt.longitude,
            distanceMeters: dist,
            pointIndex: idx,
          ),
        );
        currentRoad = road;
      }
    }

    return transitions;
  }

  /// Pencarian offline cepat berdasarkan batas koordinat jalan-jalan populer
  static String? lookupOfflineRoad(double lat, double lon) {
    // -------------------------------------------------------------------------
    // 1. KOTA PONTIANAK & SEKITARNYA
    // -------------------------------------------------------------------------
    // Jl. Jenderal Ahmad Yani (Ayani 1): koridor utama pusat olahraga (Simpang Pajak ke Bundaran Untan)
    if (lat >= -0.065 && lat <= -0.039 && lon >= 109.340 && lon <= 109.355) {
      return 'Jl. Jend. Ahmad Yani';
    }

    // Jl. Gajah Mada: koridor kuliner & rute lari tengah kota
    if (lat >= -0.038 && lat <= -0.025 && lon >= 109.330 && lon <= 109.345) {
      return 'Jl. Gajah Mada';
    }

    // Jl. Tanjungpura: koridor tepian Sungai Kapuas
    if (lat >= -0.035 && lat <= -0.020 && lon >= 109.325 && lon <= 109.350) {
      return 'Jl. Tanjungpura';
    }

    // Jl. Veteran: penghubung Ayani & Gajah Mada
    if (lat >= -0.045 && lat <= -0.030 && lon >= 109.342 && lon <= 109.352) {
      return 'Jl. Veteran';
    }

    // Kawasan Olahraga Untan / Jl. Daya Nasional
    if (lat >= -0.065 && lat <= -0.050 && lon >= 109.340 && lon <= 109.355) {
      return 'Jl. Daya Nasional';
    }

    // Jl. Perdana / Sepakat: rute perumahan favorit pelari
    if (lat >= -0.075 && lat <= -0.055 && lon >= 109.325 && lon <= 109.342) {
      return 'Jl. Perdana';
    }

    // Jl. Arteri Supadio (Ayani 2): koridor gowes bandara
    if (lat >= -0.140 && lat <= -0.065 && lon >= 109.350 && lon <= 109.410) {
      return 'Jl. Arteri Supadio';
    }

    // Jl. Khatulistiwa (Siantan / Tugu Khatulistiwa)
    if (lat >= -0.015 && lat <= 0.020 && lon >= 109.310 && lon <= 109.340) {
      return 'Jl. Khatulistiwa';
    }

    // -------------------------------------------------------------------------
    // 2. DKI JAKARTA
    // -------------------------------------------------------------------------
    // Jl. Jenderal Sudirman (Blok M - Bundaran HI)
    if (lat >= -6.240 && lat <= -6.195 && lon >= 106.815 && lon <= 106.828) {
      return 'Jl. Jend. Sudirman';
    }

    // Jl. M.H. Thamrin (Bundaran HI - Monas)
    if (lat >= -6.195 && lat <= -6.175 && lon >= 106.820 && lon <= 106.828) {
      return 'Jl. M.H. Thamrin';
    }

    // Kawasan Gelora Bung Karno & Jl. Asia Afrika
    if (lat >= -6.225 && lat <= -6.210 && lon >= 106.795 && lon <= 106.810) {
      return 'Jl. Asia Afrika';
    }

    // Jl. Gatot Subroto
    if (lat >= -6.245 && lat <= -6.230 && lon >= 106.800 && lon <= 106.850) {
      return 'Jl. Gatot Subroto';
    }

    // Jl. H.R. Rasuna Said (Kuningan)
    if (lat >= -6.240 && lat <= -6.205 && lon >= 106.828 && lon <= 106.836) {
      return 'Jl. H.R. Rasuna Said';
    }

    // Monumen Nasional / Medan Merdeka
    if (lat >= -6.180 && lat <= -6.170 && lon >= 106.820 && lon <= 106.835) {
      return 'Jl. Medan Merdeka';
    }

    // -------------------------------------------------------------------------
    // 3. KOTA BANDUNG
    // -------------------------------------------------------------------------
    // Jl. Ir. H. Djuanda (Dago)
    if (lat >= -6.905 && lat <= -6.865 && lon >= 107.608 && lon <= 107.618) {
      return 'Jl. Ir. H. Djuanda';
    }

    // Jl. Diponegoro (Gedung Sate / Gasibu)
    if (lat >= -6.905 && lat <= -6.898 && lon >= 107.615 && lon <= 107.625) {
      return 'Jl. Diponegoro';
    }

    // Jl. Asia Afrika Bandung
    if (lat >= -6.924 && lat <= -6.918 && lon >= 107.600 && lon <= 107.615) {
      return 'Jl. Asia Afrika';
    }

    // -------------------------------------------------------------------------
    // 4. KOTA SURABAYA
    // -------------------------------------------------------------------------
    // Jl. Raya Darmo
    if (lat >= -7.295 && lat <= -7.275 && lon >= 106.735 && lon <= 106.745) {
      return 'Jl. Raya Darmo';
    }

    // Jl. Tunjungan
    if (lat >= -7.265 && lat <= -7.255 && lon >= 106.735 && lon <= 106.742) {
      return 'Jl. Tunjungan';
    }

    // -------------------------------------------------------------------------
    // 5. BALI (DENPASAR & BADUNG)
    // -------------------------------------------------------------------------
    // Jl. Sunset Road Kuta
    if (lat >= -8.720 && lat <= -8.680 && lon >= 115.170 && lon <= 115.195) {
      return 'Jl. Sunset Road';
    }

    // Jl. Bypass Ngurah Rai Sanur
    if (lat >= -8.710 && lat <= -8.660 && lon >= 115.240 && lon <= 115.265) {
      return 'Jl. Bypass Ngurah Rai';
    }

    return null;
  }

  /// Reverse geocoding online menggunakan OpenStreetMap Nominatim level jalan (zoom=18)
  static Future<String?> reverseGeocodeRoadOnline(
    double lat,
    double lon, {
    http.Client? client,
  }) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
    );

    final httpClient = client ?? http.Client();
    final response = await httpClient
        .get(uri, headers: const {'User-Agent': userAgent})
        .timeout(const Duration(milliseconds: 2500));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address != null) {
        final road = address['road'] as String?;
        final pedestrian = address['pedestrian'] as String?;
        final cycleway = address['cycleway'] as String?;
        final footway = address['footway'] as String?;
        final path = address['path'] as String?;
        final residential = address['residential'] as String?;

        final candidate = road ?? pedestrian ?? cycleway ?? footway ?? path ?? residential;
        if (candidate != null && candidate.isNotEmpty) {
          return candidate;
        }
      }

      // Fallback ke field name jika spesifik
      final name = data['name'] as String?;
      if (name != null && name.isNotEmpty && name.length > 2) {
        return name;
      }
    }
    return null;
  }

  /// Menghapus seluruh cache (untuk pengujian atau pembersihan memori)
  @visibleForTesting
  static void clearCache() {
    _cache.clear();
  }
}
