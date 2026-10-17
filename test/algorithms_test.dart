import 'package:flutter_test/flutter_test.dart';
import 'package:velora/algorithms/douglas_peucker.dart';
import 'package:velora/algorithms/haversine.dart';
import 'package:velora/algorithms/pace_calculator.dart';
import 'package:velora/models/coordinate_point.dart';

void main() {
  group('Algoritma Haversine', () {
    test('Jarak antara titik yang sama harus 0.0 meter', () {
      final distance = Haversine.calculateDistance(
        -0.026330,
        109.342504,
        -0.026330,
        109.342504,
      );
      expect(distance, equals(0.0));
    });

    test('Kalkulasi jarak dua koordinat riil di Pontianak (akurasi toleransi 1%)', () {
      // Titik A: Jl. Danau Sentarum (-0.026330, 109.342504)
      // Titik B: Bundaran Digulis (-0.057390, 109.344490) (~ 3.45 km)
      final distance = Haversine.calculateDistance(
        -0.026330,
        109.342504,
        -0.057390,
        109.344490,
      );

      expect(distance, greaterThan(3400.0));
      expect(distance, lessThan(3550.0));
    });

    test('Bearing arah utara ke selatan mendekati 180 derajat', () {
      final bearing = Haversine.calculateBearing(0.0, 109.0, -1.0, 109.0);
      expect(bearing, closeTo(180.0, 1.0));
    });
  });

  group('Algoritma Douglas-Peucker (Route Simplification)', () {
    test('Menyederhanakan garis lurus 5 titik berurutan menjadi 2 titik ujung', () {
      final points = [
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: 1000,
        ),
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.001,
          longitude: 0.001,
          timestamp: 2000,
        ),
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.002,
          longitude: 0.002,
          timestamp: 3000,
        ),
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.003,
          longitude: 0.003,
          timestamp: 4000,
        ),
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.004,
          longitude: 0.004,
          timestamp: 5000,
        ),
      ];

      final simplified = DouglasPeucker.simplify(points, epsilon: 0.0001);
      expect(simplified.length, equals(2));
      expect(simplified.first.latitude, equals(0.0));
      expect(simplified.last.latitude, equals(0.004));
    });

    test('Mempertahankan titik belokan tajam', () {
      final points = [
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: 1000,
        ),
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.005,
          longitude: 0.010, // Belokan tajam
          timestamp: 2000,
        ),
        const CoordinatePoint(
          activityId: 'test',
          latitude: 0.0,
          longitude: 0.020,
          timestamp: 3000,
        ),
      ];

      final simplified = DouglasPeucker.simplify(points, epsilon: 0.0001);
      expect(simplified.length, equals(3));
    });
  });

  group('PaceCalculator & Metrics', () {
    test('Kalkulasi pace lari 5 km dalam 25 menit (300 detik/km = 5\'00" /km)', () {
      final paceSec = PaceCalculator.calculatePaceSecondsPerKm(5000.0, 1500);
      expect(paceSec, equals(300.0));
      expect(PaceCalculator.formatPace(paceSec), equals("5'00\""));
    });

    test('Kalkulasi kecepatan sepeda 20 km dalam 40 menit (30 km/jam)', () {
      final speed = PaceCalculator.calculateSpeedKmh(20000.0, 2400);
      expect(speed, closeTo(30.0, 0.01));
    });

    test('Format durasi jam, menit, detik', () {
      expect(PaceCalculator.formatDuration(45), equals('00:45'));
      expect(PaceCalculator.formatDuration(3665), equals('01:01:05'));
    });

    test('Format jarak kilometer dan meter', () {
      expect(PaceCalculator.formatDistance(850.0), equals('850 m'));
      expect(PaceCalculator.formatDistance(5240.0), equals('5.24 km'));
    });
  });
}
