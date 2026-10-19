import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/services/region_geocoding_service.dart';

void main() {
  group('RegionGeocodingService Tests', () {
    test('Mendeteksi offline nama Kota Pontianak dan Kab. Kubu Raya', () {
      // Koordinat pusat Kota Pontianak (-0.026330, 109.342504)
      final pontianak = RegionGeocodingService.lookupOfflineRegency(-0.026330, 109.342504);
      expect(pontianak, 'Kota Pontianak');

      // Koordinat Kab. Kubu Raya arah Bandara Supadio (-0.145, 109.405)
      final kubuRaya = RegionGeocodingService.lookupOfflineRegency(-0.145000, 109.405000);
      expect(kubuRaya, 'Kab. Kubu Raya');

      // Koordinat Kota Bandung (-6.917464, 107.619122)
      final bandung = RegionGeocodingService.lookupOfflineRegency(-6.917464, 107.619122);
      expect(bandung, 'Kota Bandung');
    });

    test('Mendeteksi peristiwa pergantian batas kabupaten saat melintasi batas daerah', () async {
      final startTime = DateTime(2026, 10, 19, 6, 0, 0).millisecondsSinceEpoch;

      // Lintasan gowes dari Alun-Alun Kapuas (Kota Pontianak) menuju Bandara Supadio (Kab. Kubu Raya)
      final coords = [
        CoordinatePoint(
          activityId: 'test-cross-1',
          latitude: -0.022000, // Pontianak
          longitude: 109.335000,
          timestamp: startTime,
        ),
        CoordinatePoint(
          activityId: 'test-cross-1',
          latitude: -0.035000, // Pontianak
          longitude: 109.348000,
          timestamp: startTime + 60000,
        ),
        CoordinatePoint(
          activityId: 'test-cross-1',
          latitude: -0.110000, // Masuk Kab. Kubu Raya!
          longitude: 109.390000,
          timestamp: startTime + 120000,
        ),
        CoordinatePoint(
          activityId: 'test-cross-1',
          latitude: -0.145000, // Tetap di Kab. Kubu Raya
          longitude: 109.405000,
          timestamp: startTime + 180000,
        ),
      ];

      final cumulativeDistances = [0.0, 1500.0, 9200.0, 14500.0];

      final borders = await RegionGeocodingService.detectRegencyBorders(
        coordinates: coords,
        cumulativeDistances: cumulativeDistances,
      );

      // Harus terdeteksi 1 kali peristiwa pergantian batas ke Kab. Kubu Raya
      expect(borders.length, 1);
      expect(borders.first.regencyName, 'Kab. Kubu Raya');
      expect(borders.first.distanceMeters, 9200.0);
    });
  });
}
