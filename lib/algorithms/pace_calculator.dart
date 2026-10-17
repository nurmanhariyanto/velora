/// Utilitas perhitungan dan pemformatan metrik olahraga (Pace, Kecepatan, Jarak, Waktu)
class PaceCalculator {
  /// Menghitung pace (detik per kilometer) dari jarak (meter) dan durasi (detik)
  static double calculatePaceSecondsPerKm(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 5.0 || durationSeconds <= 0) {
      return 0.0;
    }
    final distanceKm = distanceMeters / 1000.0;
    return durationSeconds / distanceKm;
  }

  /// Menghitung kecepatan rata-rata (km/jam) dari jarak (meter) dan durasi (detik)
  static double calculateSpeedKmh(double distanceMeters, int durationSeconds) {
    if (durationSeconds <= 0 || distanceMeters <= 0) {
      return 0.0;
    }
    final distanceKm = distanceMeters / 1000.0;
    final hours = durationSeconds / 3600.0;
    return distanceKm / hours;
  }

  /// Menghitung pace instan dari kecepatan instan dalam m/s
  static double instantPaceFromSpeed(double speedMps) {
    if (speedMps <= 0.2) return 0.0; // Terlalu lambat / diam
    final speedKmh = speedMps * 3.6;
    return (3600.0 / speedKmh);
  }

  /// Format pace ke bentuk: 5'24" /km
  static String formatPace(double paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0 || paceSecondsPerKm > 3600) {
      return "--'--\"";
    }
    final mins = paceSecondsPerKm ~/ 60;
    final secs = (paceSecondsPerKm % 60).round();
    return "$mins'${secs.toString().padLeft(2, '0')}\"";
  }

  /// Format durasi ke bentuk HH:mm:ss atau mm:ss
  static String formatDuration(int durationSeconds) {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Format jarak dalam kilometer (cth: "4.82 km" atau "850 m")
  static String formatDistance(double distanceMeters, {bool includeUnit = true}) {
    if (distanceMeters < 1000) {
      final m = distanceMeters.toStringAsFixed(0);
      return includeUnit ? '$m m' : (distanceMeters / 1000.0).toStringAsFixed(2);
    }
    final km = (distanceMeters / 1000.0).toStringAsFixed(2);
    return includeUnit ? '$km km' : km;
  }
}
