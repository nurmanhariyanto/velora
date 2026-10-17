/// Detektor Auto-Pause pintar berdasarkan ambang batas kecepatan dan waktu
class AutoPauseDetector {
  /// Ambang batas kecepatan dalam km/jam (di bawah nilai ini dihitung berhenti)
  final double pauseThresholdKmh;

  /// Ambang batas kecepatan untuk melanjutkan kembali (resume)
  final double resumeThresholdKmh;

  /// Waktu konfirmasi berhenti berturut-turut sebelum trigger pause (milidetik)
  final int confirmationWindowMs;

  int? _stoppedSinceTimestamp;
  bool _isCurrentlyAutoPaused = false;

  AutoPauseDetector({
    this.pauseThresholdKmh = 2.0,
    this.resumeThresholdKmh = 2.5,
    this.confirmationWindowMs = 3000, // 3 detik
  });

  bool get isAutoPaused => _isCurrentlyAutoPaused;

  /// Memproses titik koordinat baru dengan kecepatan (m/s) dan timestamp (ms)
  /// Mengembalikan status auto-pause saat ini
  bool processPoint({
    required double speedMps,
    required int timestampMs,
    double distanceMovedMeters = 0.0,
  }) {
    final speedKmh = speedMps * 3.6;

    if (_isCurrentlyAutoPaused) {
      // Periksa apakah pengguna mulai bergerak kembali
      if (speedKmh >= resumeThresholdKmh || distanceMovedMeters >= 5.0) {
        _isCurrentlyAutoPaused = false;
        _stoppedSinceTimestamp = null;
      }
    } else {
      // Sedang berjalan normal: periksa apakah melambat di bawah ambang batas
      if (speedKmh < pauseThresholdKmh) {
        _stoppedSinceTimestamp ??= timestampMs;
        final elapsedStopped = timestampMs - _stoppedSinceTimestamp!;
        if (elapsedStopped >= confirmationWindowMs) {
          _isCurrentlyAutoPaused = true;
        }
      } else {
        // Kecepatan di atas ambang batas: reset timer henti
        _stoppedSinceTimestamp = null;
      }
    }

    return _isCurrentlyAutoPaused;
  }

  /// Reset status detektor saat sesi baru dimulai
  void reset() {
    _stoppedSinceTimestamp = null;
    _isCurrentlyAutoPaused = false;
  }
}
