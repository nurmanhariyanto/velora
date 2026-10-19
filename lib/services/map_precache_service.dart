import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../models/coordinate_point.dart';

/// Representasi koordinat tile (x, y) pada level zoom z
class TileCoord {
  final int x;
  final int y;
  final int z;

  const TileCoord(this.x, this.y, this.z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoord &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'TileCoord(z: $z, x: $x, y: $y)';
}

/// Layanan pre-caching dan pre-buffering potongan gambar peta (OSM Tiles)
/// untuk menjamin pemutaran animasi flyover rute berjalan mulus 60 FPS
/// bahkan di perangkat berspesifikasi rendah / HP lemot.
class MapPrecacheService {
  static const String userAgent = 'online.nurmancloud.velora';

  /// Mengonversi latitude, longitude, dan level zoom ke koordinat tile (x, y) OSM
  static TileCoord latLonToTile(double lat, double lon, int zoom) {
    final n = math.pow(2.0, zoom);
    final x = ((lon + 180.0) / 360.0 * n).floor().clamp(0, (n - 1).toInt());
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n)
        .floor()
        .clamp(0, (n - 1).toInt());
    return TileCoord(x, y, zoom);
  }

  /// Menghitung seluruh tile unik di sepanjang lintasan titik koordinat rute
  static Set<TileCoord> calculateRouteTiles(
    List<CoordinatePoint> coordinates, {
    int zoom = 16,
    bool includeNeighbors = true,
    int maxTiles = 60,
  }) {
    if (coordinates.isEmpty) return {};

    final tiles = <TileCoord>{};
    final maxCoord = (math.pow(2.0, zoom) - 1).toInt();

    // Sampling titik rute secara adaptif
    final step = coordinates.length > 300 ? (coordinates.length / 150).ceil() : 1;

    for (int i = 0; i < coordinates.length; i += step) {
      final pt = coordinates[i];
      final base = latLonToTile(pt.latitude, pt.longitude, zoom);
      tiles.add(base);

      if (includeNeighbors) {
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            final nx = (base.x + dx).clamp(0, maxCoord);
            final ny = (base.y + dy).clamp(0, maxCoord);
            tiles.add(TileCoord(nx, ny, zoom));
            if (tiles.length >= maxTiles) break;
          }
          if (tiles.length >= maxTiles) break;
        }
      }

      if (tiles.length >= maxTiles) break;
    }

    return tiles;
  }

  /// Memanaskan (pre-cache & decode) seluruh tile ke dalam in-memory cache Flutter
  /// sehingga saat animasi rute diputar, gambar tile langsung tersedia tanpa latensi.
  static Future<void> precacheRouteTiles({
    required List<CoordinatePoint> coordinates,
    BuildContext? context,
    int zoom = 16,
    int maxTiles = 60,
    String urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    void Function(double progress, int loaded, int total)? onProgress,
    Duration timeout = const Duration(milliseconds: 3500),
  }) async {
    final tiles = calculateRouteTiles(
      coordinates,
      zoom: zoom,
      includeNeighbors: true,
      maxTiles: maxTiles,
    );

    if (tiles.isEmpty) {
      onProgress?.call(1.0, 0, 0);
      return;
    }

    final total = tiles.length;
    int loaded = 0;

    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        onProgress?.call(1.0, total, total);
        completer.complete();
      }
    });

    final futures = <Future<void>>[];
    const headers = {'User-Agent': userAgent};

    final config = context != null
        ? createLocalImageConfiguration(context)
        : ImageConfiguration.empty;

    for (final tile in tiles) {
      final url = urlTemplate
          .replaceAll('{z}', '${tile.z}')
          .replaceAll('{x}', '${tile.x}')
          .replaceAll('{y}', '${tile.y}');
      final imageProvider = NetworkImage(url, headers: headers);

      final tileCompleter = Completer<void>();
      final stream = imageProvider.resolve(config);
      late ImageStreamListener listener;

      listener = ImageStreamListener(
        (ImageInfo? image, bool sync) {
          if (!tileCompleter.isCompleted) {
            tileCompleter.complete();
          }
          try {
            stream.removeListener(listener);
          } catch (_) {}
          loaded++;
          onProgress?.call(loaded / total, loaded, total);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!tileCompleter.isCompleted) {
            tileCompleter.complete();
          }
          try {
            stream.removeListener(listener);
          } catch (_) {}
          loaded++;
          onProgress?.call(loaded / total, loaded, total);
        },
      );

      stream.addListener(listener);
      futures.add(tileCompleter.future);
    }

    Future.wait(futures).then((_) {
      timer.cancel();
      if (!completer.isCompleted) {
        onProgress?.call(1.0, total, total);
        completer.complete();
      }
    });

    return completer.future;
  }
}
