import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_guide_info.dart';
import 'gpx_service.dart';

/// Layanan penghitungan panduan rute (Route Guide) & deteksi keluar jalur (Off-Course Detection)
/// Berjalan 100% lokal di perangkat tanpa koneksi server.
class RouteGuideService {
  static const MethodChannel _gpxChannel =
      MethodChannel('online.nurmancloud.velora/gpx_picker');

  /// Batas jarak dalam meter untuk memicu peringatan keluar jalur
  static const double defaultOffCourseThreshold = 50.0;

  /// Batas toleransi histeresis untuk menganggap pengguna sudah kembali ke rute (on-course)
  static const double defaultRecoveryThreshold = 30.0;

  /// Jumlah deteksi berturut-turut di luar batas sebelum memicu peringatan (anti-jitter)
  static const int requiredConsecutiveTriggers = 2;

  /// Menghitung jarak minimum terdekat (dalam meter) dari sebuah titik koordinat
  /// ke segmen garis terdekat pada polyline rute referensi.
  /// Menggunakan proyeksi ekuirektangular lokal berkecepatan tinggi (O(N) CPU-friendly).
  static double calculateDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) {
      // Hanya ada satu titik pada polyline
      return _haversineMeters(point, polyline.first);
    }

    // Faktor konversi derajat ke meter lokal
    const double latToMeters = 111320.0;
    final double radLat = point.latitude * (math.pi / 180.0);
    final double lonToMeters = 111320.0 * math.cos(radLat);

    double minDistanceSquared = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final pA = polyline[i];
      final pB = polyline[i + 1];

      // Koordinat relatif terhadap titik pengamatan (point)
      final ax = (pA.longitude - point.longitude) * lonToMeters;
      final ay = (pA.latitude - point.latitude) * latToMeters;
      final bx = (pB.longitude - point.longitude) * lonToMeters;
      final by = (pB.latitude - point.latitude) * latToMeters;

      final dx = bx - ax;
      final dy = by - ay;
      final segmentLengthSquared = dx * dx + dy * dy;

      double distSquared;

      if (segmentLengthSquared == 0.0) {
        // Titik A dan B identik
        distSquared = ax * ax + ay * ay;
      } else {
        // Proyeksi titik (0,0) ke segmen A->B:
        // Parameter t merepresentasikan proporsi titik proyeksi pada segmen [0, 1]
        final t = ((-ax * dx) + (-ay * dy)) / segmentLengthSquared;

        if (t <= 0.0) {
          distSquared = ax * ax + ay * ay;
        } else if (t >= 1.0) {
          distSquared = bx * bx + by * by;
        } else {
          final px = ax + t * dx;
          final py = ay + t * dy;
          distSquared = px * px + py * py;
        }
      }

      if (distSquared < minDistanceSquared) {
        minDistanceSquared = distSquared;
      }
    }

    return math.sqrt(minDistanceSquared);
  }

  /// Menghitung jarak Haversine sederhana antara dua titik
  static double _haversineMeters(LatLng a, LatLng b) {
    const double r = 6371000.0;
    final phi1 = a.latitude * (math.pi / 180.0);
    final phi2 = b.latitude * (math.pi / 180.0);
    final dPhi = (b.latitude - a.latitude) * (math.pi / 180.0);
    final dLambda = (b.longitude - a.longitude) * (math.pi / 180.0);

    final sPhi = math.sin(dPhi / 2.0);
    final sLam = math.sin(dLambda / 2.0);
    final sinTerm = sPhi * sPhi + math.cos(phi1) * math.cos(phi2) * sLam * sLam;
    final c = 2.0 * math.atan2(math.sqrt(sinTerm), math.sqrt(1.0 - sinTerm));
    return r * c;
  }

  /// Membuka file picker sistem operasi untuk memilih file .gpx lokal
  static Future<RouteGuideInfo?> pickAndLoadGpxFile() async {
    try {
      final res = await _gpxChannel.invokeMethod<Map<dynamic, dynamic>>('pickGpxFile');
      if (res == null) return null;

      final name = res['name'] as String? ?? 'Rute Panduan';
      final content = res['content'] as String? ?? '';

      return GpxService.parseGpx(content, defaultName: name);
    } catch (_) {
      return null;
    }
  }
}
