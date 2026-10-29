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

    test('Mem-parsing file GPX valid menghasilkan RouteGuideInfo yang tepat', () {
      const sampleGpx = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Velora Run &amp; Ride">
  <metadata>
    <name>Rute Lintasan Danau Sebedang</name>
    <time>2026-10-29T08:00:00Z</time>
  </metadata>
  <trk>
    <name>Track Danau</name>
    <trkseg>
      <trkpt lat="-0.026330" lon="109.342504">
        <ele>12.0</ele>
        <time>2026-10-29T08:00:00Z</time>
      </trkpt>
      <trkpt lat="-0.027000" lon="109.343000">
        <ele>15.0</ele>
        <time>2026-10-29T08:01:00Z</time>
      </trkpt>
      <trkpt lat="-0.028000" lon="109.344000">
        <ele>18.0</ele>
        <time>2026-10-29T08:02:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
</gpx>''';

      final guide = GpxService.parseGpx(sampleGpx);

      expect(guide, isNotNull);
      expect(guide!.name, equals('Rute Lintasan Danau Sebedang'));
      expect(guide.points.length, equals(3));
      expect(guide.points.first.latitude, equals(-0.026330));
      expect(guide.points.first.longitude, equals(109.342504));
      expect(guide.points.last.latitude, equals(-0.028000));
      expect(guide.totalDistanceMeters, greaterThan(100));
      expect(guide.elevationGain, equals(6.0));
      expect(guide.createdAt, isNotNull);
    });

    test('Mem-parsing GPX berbasis route (<rtept>) atau waypoint (<wpt>)', () {
      const rteGpx = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <rte>
    <name>Rute Sepeda Pesisir</name>
    <rtept lat="-0.01" lon="109.31"><ele>5.0</ele></rtept>
    <rtept lat="-0.02" lon="109.32"><ele>8.0</ele></rtept>
  </rte>
</gpx>''';

      final guide = GpxService.parseGpx(rteGpx);
      expect(guide, isNotNull);
      expect(guide!.name, equals('Rute Sepeda Pesisir'));
      expect(guide.points.length, equals(2));
      expect(guide.elevationGain, equals(3.0));
    });

    test('Mem-parsing string GPX kosong atau rusak mengembalikan null secara aman', () {
      expect(GpxService.parseGpx(''), isNull);
      expect(GpxService.parseGpx('   '), isNull);
      expect(GpxService.parseGpx('<invalid>xml</invalid>'), isNull);
      expect(GpxService.parseGpx('<gpx><trk></trk></gpx>'), isNull);
    });
  });
}
