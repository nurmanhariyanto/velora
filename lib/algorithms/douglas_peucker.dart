import 'dart:math' as math;
import '../models/coordinate_point.dart';

/// Algoritma Ramer-Douglas-Peucker untuk penyederhanaan rute koordinat GPS
/// Mencegah rendering overhead dan memory lag pada track panjang
class DouglasPeucker {
  /// Menyederhanakan deretan CoordinatePoint dengan toleransi epsilon
  /// Default epsilon: 0.00003 derajat (~ 3.3 meter)
  static List<CoordinatePoint> simplify(
    List<CoordinatePoint> points, {
    double epsilon = 0.00003,
  }) {
    if (points.length <= 2) return points;

    return _simplifyRecursive(points, 0, points.length - 1, epsilon);
  }

  static List<CoordinatePoint> _simplifyRecursive(
    List<CoordinatePoint> points,
    int firstIndex,
    int lastIndex,
    double epsilon,
  ) {
    double maxDistance = 0.0;
    int indexFarthest = 0;

    final first = points[firstIndex];
    final last = points[lastIndex];

    for (int i = firstIndex + 1; i < lastIndex; i++) {
      final point = points[i];
      final distance = _perpendicularDistance(
        point.latitude,
        point.longitude,
        first.latitude,
        first.longitude,
        last.latitude,
        last.longitude,
      );

      if (distance > maxDistance) {
        maxDistance = distance;
        indexFarthest = i;
      }
    }

    if (maxDistance > epsilon) {
      final leftSegment = _simplifyRecursive(
        points,
        firstIndex,
        indexFarthest,
        epsilon,
      );
      final rightSegment = _simplifyRecursive(
        points,
        indexFarthest,
        lastIndex,
        epsilon,
      );

      // Gabungkan segmen kiri dan kanan (hilangkan duplikasi titik tengah)
      return [
        ...leftSegment.sublist(0, leftSegment.length - 1),
        ...rightSegment,
      ];
    } else {
      return [points[firstIndex], points[lastIndex]];
    }
  }

  /// Menghitung jarak tegak lurus suatu titik ke garis lurus (p1 - p2) dalam derajat bidang datar
  static double _perpendicularDistance(
    double lat,
    double lon,
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double dx = lon2 - lon1;
    final double dy = lat2 - lat1;

    final double lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) {
      final dLat = lat - lat1;
      final dLon = lon - lon1;
      return math.sqrt(dLat * dLat + dLon * dLon);
    }

    // Jarak titik ke garis: |dy*lon - dx*lat + p2.lon*p1.lat - p2.lat*p1.lon| / sqrt(lengthSq)
    final double numerator = (dy * lon - dx * lat + lon2 * lat1 - lat2 * lon1).abs();
    return numerator / math.sqrt(lengthSq);
  }
}
