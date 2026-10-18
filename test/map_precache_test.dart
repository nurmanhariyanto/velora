import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/services/map_precache_service.dart';

void main() {
  group('MapPrecacheService Unit Tests', () {
    test('latLonToTile mengonversi koordinat Monas dengan benar pada zoom 16', () {
      final tile = MapPrecacheService.latLonToTile(-6.1754, 106.8272, 16);
      expect(tile.z, equals(16));
      expect(tile.x, equals(52215));
      expect(tile.y, equals(33894));
    });

    test('latLonToTile membatasi rentang nilai tile agar tidak overflow', () {
      final northPole = MapPrecacheService.latLonToTile(89.0, 180.0, 16);
      expect(northPole.x, inInclusiveRange(0, 65535));
      expect(northPole.y, inInclusiveRange(0, 65535));

      final southPole = MapPrecacheService.latLonToTile(-89.0, -180.0, 16);
      expect(southPole.x, inInclusiveRange(0, 65535));
      expect(southPole.y, inInclusiveRange(0, 65535));
    });

    test('calculateRouteTiles menghasilkan daftar tile unik di sepanjang lintasan', () {
      final points = [
        const CoordinatePoint(
          activityId: 'test-1',
          latitude: -6.1754,
          longitude: 106.8272,
          timestamp: 1000,
        ),
        const CoordinatePoint(
          activityId: 'test-1',
          latitude: -6.1760,
          longitude: 106.8280,
          timestamp: 2000,
        ),
        const CoordinatePoint(
          activityId: 'test-1',
          latitude: -6.1770,
          longitude: 106.8290,
          timestamp: 3000,
        ),
      ];

      final tiles = MapPrecacheService.calculateRouteTiles(
        points,
        zoom: 16,
        includeNeighbors: true,
        maxTiles: 20,
      );

      expect(tiles, isNotEmpty);
      expect(tiles.length, lessThanOrEqualTo(20));
      expect(tiles.first.z, equals(16));
    });

    test('calculateRouteTiles mengembalikan himpunan kosong jika titik kosong', () {
      final tiles = MapPrecacheService.calculateRouteTiles([], zoom: 16);
      expect(tiles, isEmpty);
    });
  });
}
