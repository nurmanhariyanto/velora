import 'dart:math' as math;

/// Algoritma kalkulasi jarak menggunakan Formula Haversine
class Haversine {
  // Radius rata-rata bumi dalam meter
  static const double earthRadiusMeters = 6371000.0;

  /// Menghitung jarak lengkung bumi antara dua koordinat (lat1, lon1) dan (lat2, lon2)
  /// Mengembalikan jarak dalam satuan meter
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0;
    }

    final phi1 = lat1 * (math.pi / 180.0);
    final phi2 = lat2 * (math.pi / 180.0);
    final deltaPhi = (lat2 - lat1) * (math.pi / 180.0);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(deltaPhi / 2.0) * math.sin(deltaPhi / 2.0) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2.0) *
            math.sin(deltaLambda / 2.0);

    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));

    return earthRadiusMeters * c;
  }

  /// Menghitung total jarak dari urutan titik koordinat
  static double calculateTotalDistance(
    List<({double lat, double lon})> points,
  ) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += calculateDistance(
        points[i].lat,
        points[i].lon,
        points[i + 1].lat,
        points[i + 1].lon,
      );
    }
    return total;
  }

  /// Menghitung arah mata angin / bearing dari titik 1 ke titik 2 dalam derajat (0-360)
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = lat1 * (math.pi / 180.0);
    final phi2 = lat2 * (math.pi / 180.0);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180.0);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final theta = math.atan2(y, x);
    final bearing = (theta * (180.0 / math.pi) + 360.0) % 360.0;
    return bearing;
  }
}
