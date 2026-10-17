import 'package:flutter_test/flutter_test.dart';
import 'package:velora/services/auto_pause_detector.dart';

void main() {
  group('Mesin Logika Auto-Pause (Agent Analisis & QA)', () {
    late AutoPauseDetector detector;

    setUp(() {
      detector = AutoPauseDetector(
        pauseThresholdKmh: 2.0,
        resumeThresholdKmh: 2.5,
        confirmationWindowMs: 3000,
      );
    });

    test('Status awal adalah tidak auto-paused', () {
      expect(detector.isAutoPaused, isFalse);
    });

    test('Pengguna berlari 10 km/jam tetap tidak auto-paused', () {
      // 10 km/jam = 2.78 m/s
      final isPaused = detector.processPoint(
        speedMps: 2.78,
        timestampMs: 1000,
        distanceMovedMeters: 5.0,
      );
      expect(isPaused, isFalse);
      expect(detector.isAutoPaused, isFalse);
    });

    test('Pengguna berhenti (< 2 km/jam) selama kurang dari 3 detik BELUM auto-paused', () {
      // Detik 0: mulai berhenti (kecepatan 0.2 m/s = 0.72 km/h)
      detector.processPoint(
        speedMps: 0.2,
        timestampMs: 1000,
        distanceMovedMeters: 0.2,
      );
      expect(detector.isAutoPaused, isFalse);

      // Detik 2: masih berhenti, belum genap 3 detik
      final isPaused2 = detector.processPoint(
        speedMps: 0.1,
        timestampMs: 3000, // selisih 2000 ms
        distanceMovedMeters: 0.1,
      );
      expect(isPaused2, isFalse);
      expect(detector.isAutoPaused, isFalse);
    });

    test('Pengguna berhenti berturut-turut >= 3 detik MEMICU Auto-Pause', () {
      // Detik 0: berhenti
      detector.processPoint(
        speedMps: 0.1,
        timestampMs: 1000,
        distanceMovedMeters: 0.1,
      );

      // Detik 3.1: sudah melewati confirmationWindowMs (3000ms)
      final isPaused = detector.processPoint(
        speedMps: 0.1,
        timestampMs: 4100, // selisih 3100 ms
        distanceMovedMeters: 0.1,
      );

      expect(isPaused, isTrue);
      expect(detector.isAutoPaused, isTrue);
    });

    test('Setelah Auto-Pause aktif, bergerak kembali (>= 2.5 km/jam) me-RESUME pelacakan', () {
      // 1. Trigger auto pause
      detector.processPoint(
        speedMps: 0.0,
        timestampMs: 1000,
      );
      detector.processPoint(
        speedMps: 0.0,
        timestampMs: 4500,
      );
      expect(detector.isAutoPaused, isTrue);

      // 2. Pengguna mulai bergerak lagi: kecepatan 3.0 m/s (~10.8 km/jam)
      final isPausedNow = detector.processPoint(
        speedMps: 3.0,
        timestampMs: 5000,
        distanceMovedMeters: 6.0,
      );

      expect(isPausedNow, isFalse);
      expect(detector.isAutoPaused, isFalse);
    });

    test('Panggilan reset() mengembalikan detektor ke kondisi normal', () {
      detector.processPoint(speedMps: 0.0, timestampMs: 1000);
      detector.processPoint(speedMps: 0.0, timestampMs: 4500);
      expect(detector.isAutoPaused, isTrue);

      detector.reset();
      expect(detector.isAutoPaused, isFalse);
    });

    test('recordStationaryTick memicu auto-pause setelah melampaui confirmation window', () {
      // Detik 0: catat diam
      detector.recordStationaryTick(1000);
      expect(detector.isAutoPaused, isFalse);

      // Detik 2: masih diam
      detector.recordStationaryTick(3000);
      expect(detector.isAutoPaused, isFalse);

      // Detik 3.5: melewati 3000 ms
      final isPaused = detector.recordStationaryTick(4500);
      expect(isPaused, isTrue);
      expect(detector.isAutoPaused, isTrue);

      // Gerakan aktif mereset status
      detector.recordMovement();
      expect(detector.isAutoPaused, isFalse);
    });
  });
}
