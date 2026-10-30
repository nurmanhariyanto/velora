import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/services/gpx_service.dart';
import 'package:velora/services/heart_rate_service.dart';

void main() {
  group('HeartRateService Tests', () {
    test('calculateZones computes accurate BPM boundaries based on Max HR', () {
      const maxHr = 190;
      final zones = HeartRateService.calculateZones(maxHr);

      expect(zones.length, 5);
      expect(zones[0].zone, HeartRateZoneType.zone1);
      expect(zones[0].label, 'Z1');
      expect(zones[0].minBpm, 95); // 50%
      expect(zones[0].maxBpm, 113); // 60% - 1

      expect(zones[1].zone, HeartRateZoneType.zone2);
      expect(zones[1].label, 'Z2');
      expect(zones[1].minBpm, 114); // 60%
      expect(zones[1].maxBpm, 132); // 70% - 1

      expect(zones[2].zone, HeartRateZoneType.zone3);
      expect(zones[2].label, 'Z3');
      expect(zones[2].minBpm, 133); // 70%
      expect(zones[2].maxBpm, 151); // 80% - 1

      expect(zones[3].zone, HeartRateZoneType.zone4);
      expect(zones[3].label, 'Z4');
      expect(zones[3].minBpm, 152); // 80%
      expect(zones[3].maxBpm, 170); // 90% - 1

      expect(zones[4].zone, HeartRateZoneType.zone5);
      expect(zones[4].label, 'Z5');
      expect(zones[4].minBpm, 171); // 90%
      expect(zones[4].maxBpm, 190); // 100%
    });

    test('getZoneForBpm correctly categorizes various BPM values', () {
      const maxHr = 190;
      expect(HeartRateService.getZoneForBpm(100, maxHr).zone, HeartRateZoneType.zone1);
      expect(HeartRateService.getZoneForBpm(125, maxHr).zone, HeartRateZoneType.zone2);
      expect(HeartRateService.getZoneForBpm(145, maxHr).zone, HeartRateZoneType.zone3);
      expect(HeartRateService.getZoneForBpm(165, maxHr).zone, HeartRateZoneType.zone4);
      expect(HeartRateService.getZoneForBpm(185, maxHr).zone, HeartRateZoneType.zone5);
    });

    test('parseHeartRateBytes parses standard Bluetooth GATT 0x2A37 payloads', () {
      // 8-bit format: flag bit 0 is 0, byte 1 is 142 bpm
      final bytes8Bit = [0x00, 142];
      expect(HeartRateService.parseHeartRateBytes(bytes8Bit), 142);

      // 16-bit format: flag bit 0 is 1, bytes 1-2 are 160 bpm (0x00A0)
      final bytes16Bit = [0x01, 0xA0, 0x00];
      expect(HeartRateService.parseHeartRateBytes(bytes16Bit), 160);

      // Empty / invalid
      expect(HeartRateService.parseHeartRateBytes([]), 0);
      expect(HeartRateService.parseHeartRateBytes([0x00]), 0);
    });

    test('calculateDistribution determines time and dominant zone accurately', () {
      const maxHr = 190;
      final t0 = 1000000;
      final points = [
        CoordinatePoint(
          activityId: 'test_1',
          latitude: -6.2,
          longitude: 106.8,
          timestamp: t0,
          heartRate: 125, // Z2 (114-132)
        ),
        CoordinatePoint(
          activityId: 'test_1',
          latitude: -6.2001,
          longitude: 106.8001,
          timestamp: t0 + 10000, // +10s in Z2
          heartRate: 128, // Z2
        ),
        CoordinatePoint(
          activityId: 'test_1',
          latitude: -6.2002,
          longitude: 106.8002,
          timestamp: t0 + 20000, // +10s in Z2
          heartRate: 160, // Z4 (152-170)
        ),
        CoordinatePoint(
          activityId: 'test_1',
          latitude: -6.2003,
          longitude: 106.8003,
          timestamp: t0 + 25000, // +5s in Z4
          heartRate: 162,
        ),
      ];

      final dist = HeartRateService.calculateDistribution(points, maxHr);
      expect(dist.totalSecondsWithHr, 25);
      expect(dist.secondsPerZone[HeartRateZoneType.zone2], 20);
      expect(dist.secondsPerZone[HeartRateZoneType.zone4], 5);
      expect(dist.dominantZone, HeartRateZoneType.zone2);
      expect(dist.percentPerZone[HeartRateZoneType.zone2], 80.0);
      expect(dist.percentPerZone[HeartRateZoneType.zone4], 20.0);
    });
  });

  group('GPX Service Heart Rate Extensions Tests', () {
    test('generateGpx outputs Garmin TrackPointExtension schema and hr tags', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final session = ActivitySession(
        id: 'test_session_gpx_hr',
        sportsType: SportsType.ride,
        startTime: now,
        endTime: now + 60000,
        durationSeconds: 60,
        distanceMeters: 500,
        averageSpeedKmh: 30.0,
        maxSpeedKmh: 35.0,
        averagePaceSecondsPerKm: 120.0,
        coordinates: [
          CoordinatePoint(
            activityId: 'test_session_gpx_hr',
            latitude: -6.2088,
            longitude: 106.8456,
            elevation: 25.0,
            speed: 8.0,
            timestamp: now,
            heartRate: 135,
          ),
          CoordinatePoint(
            activityId: 'test_session_gpx_hr',
            latitude: -6.2090,
            longitude: 106.8460,
            elevation: 26.0,
            speed: 8.5,
            timestamp: now + 30000,
            heartRate: 152,
          ),
        ],
        averageHeartRate: 143,
        maxHeartRate: 152,
      );

      final gpxString = GpxService.generateGpx(session);

      // Verify Garmin TrackPointExtension schema is included
      expect(gpxString.contains('xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"'), isTrue);

      // Verify `<gpxtpx:TrackPointExtension>` and `<gpxtpx:hr>` tags are generated
      expect(gpxString.contains('<gpxtpx:hr>135</gpxtpx:hr>'), isTrue);
      expect(gpxString.contains('<gpxtpx:hr>152</gpxtpx:hr>'), isTrue);
    });

    test('parseGpxToActivitySession parses smartwatch GPX files with heart rate tags', () {
      const smartwatchGpx = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Haylou Fun Watch" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
  <metadata>
    <name>Morning Solo Ride</name>
    <time>2026-10-30T06:00:00Z</time>
  </metadata>
  <trk>
    <name>Morning Solo Ride</name>
    <type>RIDE</type>
    <trkseg>
      <trkpt lat="-6.20000" lon="106.80000">
        <ele>15.0</ele>
        <time>2026-10-30T06:00:00Z</time>
        <extensions>
          <gpxtpx:TrackPointExtension>
            <gpxtpx:hr>128</gpxtpx:hr>
          </gpxtpx:TrackPointExtension>
        </extensions>
      </trkpt>
      <trkpt lat="-6.20100" lon="106.80100">
        <ele>18.0</ele>
        <time>2026-10-30T06:01:00Z</time>
        <extensions>
          <gpxtpx:TrackPointExtension>
            <gpxtpx:hr>142</gpxtpx:hr>
          </gpxtpx:TrackPointExtension>
        </extensions>
      </trkpt>
      <trkpt lat="-6.20200" lon="106.80200">
        <ele>22.0</ele>
        <time>2026-10-30T06:02:00Z</time>
        <extensions>
          <gpxtpx:TrackPointExtension>
            <gpxtpx:hr>166</gpxtpx:hr>
          </gpxtpx:TrackPointExtension>
        </extensions>
      </trkpt>
    </trkseg>
  </trk>
</gpx>''';

      final session = GpxService.parseGpxToActivitySession(smartwatchGpx);

      expect(session, isNotNull);
      expect(session!.sportsType, SportsType.ride);
      expect(session.displayTitle, 'Morning Solo Ride');
      expect(session.coordinates.length, 3);
      expect(session.hasHeartRateData, isTrue);

      // Check extracted HR values
      expect(session.coordinates[0].heartRate, 128);
      expect(session.coordinates[1].heartRate, 142);
      expect(session.coordinates[2].heartRate, 166);

      // Check average & max HR calculation
      expect(session.averageHeartRate, (128 + 142 + 166) ~/ 3); // 145 bpm
      expect(session.maxHeartRate, 166); // 166 bpm
      expect(session.elevationGain, 7.0); // 15 -> 18 (+3) -> 22 (+4) = 7m
      expect(session.durationSeconds, 120); // 06:00 to 06:02 = 120s
      expect(session.distanceMeters, greaterThan(100.0));
    });
  });
}
