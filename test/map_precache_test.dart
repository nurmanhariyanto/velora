import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/services/map_precache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('cleanupMemoryCache mengosongkan cache gambar dan menyetel batas memori aman', () {
      PaintingBinding.instance.imageCache.maximumSize = 3500;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 500 << 20;

      MapPrecacheService.cleanupMemoryCache();

      expect(PaintingBinding.instance.imageCache.maximumSize, equals(1000));
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes, equals(100 << 20));
    });

    test('downloadAndCacheRouteTiles berhenti seketika saat isCancelled bernilai true', () async {
      final points = [
        const CoordinatePoint(
          activityId: 'test-cancel',
          latitude: -6.1754,
          longitude: 106.8272,
          timestamp: 1000,
        ),
      ];

      final tempDir = Directory.systemTemp.createTempSync('velora_tile_test_cancel');
      bool wasCancelled = true;
      double lastProgress = 0.0;

      await MapPrecacheService.downloadAndCacheRouteTiles(
        coordinates: points,
        cacheDir: tempDir.path,
        providerType: 'osm',
        isCancelled: () => wasCancelled,
        onProgress: (p, loaded, total) {
          lastProgress = p;
        },
      );

      // Karena langsung dibatalkan sebelum unduhan dimulai, progress tidak boleh mencapai 1.0 dari loop
      expect(lastProgress, lessThan(1.0));

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getTileCacheDir mengembalikan path direktori cache yang valid', () async {
      final cacheDir = await MapPrecacheService.getTileCacheDir();
      expect(cacheDir, isNotEmpty);
      expect(Directory(cacheDir).existsSync(), isTrue);
    });

    test('hasInternetConnection mengeksekusi pemeriksaan jaringan dengan aman', () async {
      final online = await MapPrecacheService.hasInternetConnection(
        timeout: const Duration(milliseconds: 1000),
      );
      // Nilai boolean bergantung pada koneksi host uji coba, harus berupa bool
      expect(online, isA<bool>());
    });

    test('precacheActivityRoute menangani koordinat kosong atau < 2 secara instan', () async {
      await expectLater(
        MapPrecacheService.precacheActivityRoute([]),
        completes,
      );
      await expectLater(
        MapPrecacheService.precacheActivityRoute([
          const CoordinatePoint(
            activityId: 'p1',
            latitude: -6.2,
            longitude: 106.8,
            timestamp: 100,
          ),
        ]),
        completes,
      );
    });

    test('warmUpOnAppStart dieksekusi dengan aman tanpa unhandled exception', () async {
      await expectLater(
        MapPrecacheService.warmUpOnAppStart(),
        completes,
      );
    });
  });
}
