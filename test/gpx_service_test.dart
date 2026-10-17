import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/services/gpx_service.dart';

void main() {
  group('Layanan Ekspor GPX (GpxService)', () {
    test('Format GPX 1.1 XML menghasilkan struktur track yang valid', () {
      final session = ActivitySession(
        id: 'velora_test_gpx',
        sportsType: SportsType.run,
        startTime: 1700000000000,
        endTime: 1700001800000,
        durationSeconds: 1800,
        distanceMeters: 5000.0,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.5,
        averagePaceSecondsPerKm: 360.0,
        elevationGain: 35.0,
        coordinates: const [
          CoordinatePoint(
            activityId: 'velora_test_gpx',
            latitude: -0.026330,
            longitude: 109.342504,
            elevation: 12.0,
            speed: 2.8,
            timestamp: 1700000000000,
          ),
          CoordinatePoint(
            activityId: 'velora_test_gpx',
            latitude: -0.028000,
            longitude: 109.345000,
            elevation: 15.0,
            speed: 3.1,
            timestamp: 1700000010000,
          ),
        ],
      );

      final gpxString = GpxService.generateGpx(session);

      expect(gpxString, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpxString, contains('<gpx version="1.1"'));
      expect(gpxString, contains('<trk>'));
      expect(gpxString, contains('<trkseg>'));
      expect(gpxString, contains('lat="-0.02633" lon="109.342504"'));
      expect(gpxString, contains('<ele>12.0</ele>'));
      expect(gpxString, contains('<speed>2.80</speed>'));
      expect(gpxString, contains('</trkseg>'));
      expect(gpxString, contains('</trk>'));
      expect(gpxString, contains('</gpx>'));
    });
  });
}
