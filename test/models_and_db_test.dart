import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';

void main() {
  group('Serialisasi Model Data (SQLite & Domain)', () {
    test('CoordinatePoint toMap dan fromMap menghasilkan data yang identik', () {
      const original = CoordinatePoint(
        id: 1,
        activityId: 'session_123',
        latitude: -0.026330,
        longitude: 109.342504,
        elevation: 12.5,
        speed: 3.2,
        accuracy: 4.0,
        timestamp: 1697520000000,
        isAutoPaused: true,
      );

      final map = original.toMap();
      final reconstructed = CoordinatePoint.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.activityId, equals(original.activityId));
      expect(reconstructed.latitude, closeTo(original.latitude, 0.000001));
      expect(reconstructed.longitude, closeTo(original.longitude, 0.000001));
      expect(reconstructed.elevation, equals(original.elevation));
      expect(reconstructed.speed, equals(original.speed));
      expect(reconstructed.speedKmh, closeTo(3.2 * 3.6, 0.01));
      expect(reconstructed.isAutoPaused, isTrue);
    });

    test('ActivitySession toMap dan fromMap memetakan metrik dengan tepat', () {
      final session = ActivitySession(
        id: 'velora_test_1',
        sportsType: SportsType.run,
        startTime: 1697520000000,
        endTime: 1697521800000,
        durationSeconds: 1800,
        distanceMeters: 5000.0,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 14.2,
        averagePaceSecondsPerKm: 360.0,
        elevationGain: 45.0,
        notes: 'Latihan pagi yang menyegarkan',
      );

      final map = session.toMap();
      final parsed = ActivitySession.fromMap(map);

      expect(parsed.id, equals('velora_test_1'));
      expect(parsed.sportsType, equals(SportsType.run));
      expect(parsed.distanceKm, equals(5.0));
      expect(parsed.formattedDuration, equals('30:00'));
      expect(parsed.formattedPace, equals("6'00\""));
      expect(parsed.notes, equals('Latihan pagi yang menyegarkan'));
    });

    test('SportsType parsing dan label metrik', () {
      expect(SportsType.fromString('run'), equals(SportsType.run));
      expect(SportsType.fromString('ride'), equals(SportsType.ride));
      expect(SportsType.fromString('UNKNOWN'), equals(SportsType.run));

      expect(SportsType.run.primaryMetricLabel, equals('AVG PACE'));
      expect(SportsType.ride.primaryMetricLabel, equals('AVG SPEED'));
    });
  });
}
