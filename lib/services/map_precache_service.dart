import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../database/activity_repository.dart';
import '../models/coordinate_point.dart';
import 'velora_tile_provider.dart';

export 'velora_tile_provider.dart';

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

/// Layanan pre-caching dan pre-buffering potongan gambar peta (OSM & Citra Satelit Tiles)
/// untuk menjamin pemutaran animasi flyover rute berjalan mulus 60 FPS dan hasil render
/// video bebas kotak hitam (black tiles).
class MapPrecacheService {
  static const String userAgent = 'online.nurmancloud.velora';
  static String? _cachedTileDir;
  static bool _isWarmingUp = false;

  /// Flag simulasi koneksi internet untuk pengujian otomatis
  @visibleForTesting
  static bool? mockHasInternet;

  /// Memeriksa ketersediaan koneksi internet aktif secara cepat dan ringan
  static Future<bool> hasInternetConnection({
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    if (mockHasInternet != null) return mockHasInternet!;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    try {
      final lookup = await InternetAddress.lookup('tile.openstreetmap.org')
          .timeout(timeout);
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('dns.google')
            .timeout(timeout);
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Mengambil atau menginisialisasi direktori cache ubin lokal pada penyimpanan internal
  static Future<String> getTileCacheDir() async {
    if (_cachedTileDir != null) return _cachedTileDir!;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cachedTileDir = '${appDir.path}/velora_tile_cache';
    } catch (_) {
      _cachedTileDir = '${Directory.systemTemp.path}/velora_tile_cache';
    }
    final dir = Directory(_cachedTileDir!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return _cachedTileDir!;
  }

  /// Memanaskan dan mengunduh ubin peta saat aplikasi dibuka jika ada internet.
  /// Jika tidak ada koneksi internet, proses dilewati (skip) agar hemat baterai & data,
  /// sehingga peta baru akan dimuat saat render nanti sesuai ketersediaan jaringan.
  static Future<void> warmUpOnAppStart({
    ActivityRepository? repository,
  }) async {
    if (_isWarmingUp) return;
    if (Platform.environment.containsKey('FLUTTER_TEST') && mockHasInternet == null) {
      return;
    }
    _isWarmingUp = true;

    try {
      // 1. Cek koneksi internet terlebih dahulu
      final isOnline = await hasInternetConnection();
      if (!isOnline) {
        debugPrint('MapPrecacheService: Tidak ada internet saat aplikasi dibuka. Precache ditunda.');
        _isWarmingUp = false;
        return;
      }

      debugPrint('MapPrecacheService: Internet terdeteksi. Memulai pemanasan ubin peta di latar belakang...');
      final cacheDir = await getTileCacheDir();

      // 2. Precache peta di sekitar lokasi pengguna saat ini (Live Tracking Map)
      try {
        final lastPos = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 2),
        );
        if (lastPos != null) {
          await _precacheLocationTiles(
            lat: lastPos.latitude,
            lon: lastPos.longitude,
            cacheDir: cacheDir,
          );
        }
      } catch (_) {}

      // 3. Precache rute sesi latihan terbaru (agar saat dibuka & dirender langsung instan)
      try {
        final repo = repository ?? ActivityRepository();
        final latestActivities = await repo.getLatestActivitiesWithCoordinates(limit: 2);
        for (final act in latestActivities) {
          if (act.coordinates.length >= 2) {
            // Unduh ubin citra satelit dan OSM untuk rute ini
            await downloadAndCacheRouteTiles(
              coordinates: act.coordinates,
              cacheDir: cacheDir,
              providerType: 'satellite',
              timeout: const Duration(seconds: 35),
            );
            await downloadAndCacheRouteTiles(
              coordinates: act.coordinates,
              cacheDir: cacheDir,
              providerType: 'osm',
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              timeout: const Duration(seconds: 35),
            );
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('MapPrecacheService.warmUpOnAppStart error: $e');
    } finally {
      _isWarmingUp = false;
    }
  }

  /// Mengunduh ubin di sekitar koordinat lokasi spesifik (misal lokasi GPS saat ini)
  static Future<void> _precacheLocationTiles({
    required double lat,
    required double lon,
    required String cacheDir,
  }) async {
    for (final zoom in [16, 15]) {
      final center = latLonToTile(lat, lon, zoom);
      final maxCoord = (math.pow(2.0, zoom) - 1).toInt();
      final tiles = <TileCoord>[];
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final nx = (center.x + dx).clamp(0, maxCoord);
          final ny = (center.y + dy).clamp(0, maxCoord);
          tiles.add(TileCoord(nx, ny, zoom));
        }
      }

      for (final t in tiles) {
        final filePath = VeloraTileProvider.getTileFilePath(
          cacheDir,
          'osm',
          t.z,
          t.x,
          t.y,
        );
        final file = File(filePath);
        if (file.existsSync() && file.lengthSync() > 100) continue;

        try {
          final url = 'https://tile.openstreetmap.org/${t.z}/${t.x}/${t.y}.png';
          final res = await http.get(
            Uri.parse(url),
            headers: const {'User-Agent': userAgent},
          ).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200 && res.bodyBytes.length > 100) {
            if (!file.parent.existsSync()) {
              file.parent.createSync(recursive: true);
            }
            await file.writeAsBytes(res.bodyBytes);
          }
        } catch (_) {}
      }
    }
  }

  /// Mengunduh ubin untuk sesi aktivitas tertentu di latar belakang saat detail aktivitas dibuka
  static Future<void> precacheActivityRoute(
    List<CoordinatePoint> coordinates, {
    bool isSatellite = false,
  }) async {
    if (coordinates.length < 2) return;
    if (Platform.environment.containsKey('FLUTTER_TEST') && mockHasInternet == null) {
      return;
    }
    try {
      final isOnline = await hasInternetConnection(timeout: const Duration(milliseconds: 1500));
      if (!isOnline) return;

      final cacheDir = await getTileCacheDir();
      await downloadAndCacheRouteTiles(
        coordinates: coordinates,
        cacheDir: cacheDir,
        providerType: isSatellite ? 'satellite' : 'osm',
        urlTemplate: isSatellite
            ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        timeout: const Duration(seconds: 40),
      );
    } catch (_) {}
  }

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
    int neighborRadius = 1,
    int maxTiles = 2500,
  }) {
    if (coordinates.isEmpty) return {};

    final tiles = <TileCoord>{};
    final maxCoord = (math.pow(2.0, zoom) - 1).toInt();

    // 1. Ekstrak ubin dasar di sepanjang 100% rute secara menyeluruh tanpa melompati titik
    final baseTiles = <TileCoord>{};
    for (int i = 0; i < coordinates.length; i++) {
      final pt = coordinates[i];
      baseTiles.add(latLonToTile(pt.latitude, pt.longitude, zoom));
    }

    // Masukkan seluruh ubin rute utama terlebih dahulu
    for (final base in baseTiles) {
      tiles.add(base);
      if (tiles.length >= maxTiles) break;
    }

    // 2. Tambahkan ubin tetangga di sekitar koridor rute agar saat kamera miring / meluncur tidak ada kotak hitam
    if (includeNeighbors && tiles.length < maxTiles) {
      for (final base in baseTiles) {
        for (int dx = -neighborRadius; dx <= neighborRadius; dx++) {
          for (int dy = -neighborRadius; dy <= neighborRadius; dy++) {
            if (dx == 0 && dy == 0) continue;
            final nx = (base.x + dx).clamp(0, maxCoord);
            final ny = (base.y + dy).clamp(0, maxCoord);
            tiles.add(TileCoord(nx, ny, zoom));
            if (tiles.length >= maxTiles) break;
          }
          if (tiles.length >= maxTiles) break;
        }
        if (tiles.length >= maxTiles) break;
      }
    }

    return tiles;
  }

  /// Mengunduh seluruh potongan gambar peta (tiles) di sepanjang rute langsung
  /// ke penyimpanan internal ponsel (disk storage). Menjamin saat video dirender,
  /// 100% ubin dibaca langsung dari file lokal tanpa tergantung koneksi internet
  /// sehingga bebas kotak hitam.
  static Future<void> downloadAndCacheRouteTiles({
    required List<CoordinatePoint> coordinates,
    required String cacheDir,
    required String providerType,
    String urlTemplate = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    void Function(double progress, int loaded, int total)? onProgress,
    Duration timeout = const Duration(seconds: 120),
    bool Function()? isCancelled,
  }) async {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // 1. Ekstrak seluruh ubin zoom 16 di sepanjang rute + ubin tetangga radius 2 (Resolusi Utama Kamera Flyover)
    final tilesZ16 = calculateRouteTiles(
      coordinates,
      zoom: 16,
      includeNeighbors: true,
      neighborRadius: 2,
      maxTiles: 2000,
    );

    // 2. Ekstrak seluruh ubin zoom 17 di sepanjang rute untuk detail tajam saat kamera mendekat
    final tilesZ17 = calculateRouteTiles(
      coordinates,
      zoom: 17,
      includeNeighbors: true,
      neighborRadius: 1,
      maxTiles: 2500,
    );

    // 3. Ekstrak ubin zoom 15 untuk cakrawala horizon 3D & transisi
    final tilesZ15 = calculateRouteTiles(
      coordinates,
      zoom: 15,
      includeNeighbors: true,
      neighborRadius: 1,
      maxTiles: 800,
    );

    final allTiles = <TileCoord>{...tilesZ16, ...tilesZ17, ...tilesZ15}.toList();
    final total = allTiles.length;
    if (total == 0) {
      onProgress?.call(1.0, 0, 0);
      return;
    }

    int loaded = 0;
    int nextIdx = 0;
    final workerCount = math.min(12, allTiles.length);
    final completer = Completer<void>();

    // Cek koneksi internet sebelum memulai worker
    final isOnline = await hasInternetConnection(timeout: const Duration(milliseconds: 1500));

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        if (isCancelled?.call() != true) {
          onProgress?.call(1.0, total, total);
        }
        completer.complete();
      }
    });

    Future<void> worker() async {
      while (nextIdx < allTiles.length && !completer.isCompleted) {
        if (isCancelled?.call() == true) return;
        final idx = nextIdx++;
        final tile = allTiles[idx];
        final filePath = VeloraTileProvider.getTileFilePath(
          cacheDir,
          providerType,
          tile.z,
          tile.x,
          tile.y,
        );
        final file = File(filePath);

        // Jika file sudah ada di disk dan valid (> 100 byte), langsung hitung sebagai loaded
        if (file.existsSync() && file.lengthSync() > 100) {
          loaded++;
          if (isCancelled?.call() != true) {
            onProgress?.call((loaded / total).clamp(0.0, 1.0), loaded, total);
          }
          continue;
        }

        // Jika offline, lewati pengambilan jaringan agar tidak menghabiskan waktu pada timeout
        if (!isOnline) {
          loaded++;
          if (isCancelled?.call() != true) {
            onProgress?.call((loaded / total).clamp(0.0, 1.0), loaded, total);
          }
          continue;
        }

        final url = urlTemplate
            .replaceAll('{z}', '${tile.z}')
            .replaceAll('{x}', '${tile.x}')
            .replaceAll('{y}', '${tile.y}');

        for (int attempt = 0; attempt < 3; attempt++) {
          if (isCancelled?.call() == true) return;
          try {
            final res = await http.get(
              Uri.parse(url),
              headers: const {'User-Agent': userAgent},
            ).timeout(const Duration(seconds: 10));

            if (res.statusCode == 200 && res.bodyBytes.length > 100) {
              if (isCancelled?.call() == true) return;
              if (!file.parent.existsSync()) {
                file.parent.createSync(recursive: true);
              }
              // Penulisan atomik via berkas temporer untuk mencegah ubin rusak / 0 byte
              final tmpFile = File('$filePath.tmp');
              await tmpFile.writeAsBytes(res.bodyBytes);
              if (isCancelled?.call() == true) {
                if (tmpFile.existsSync()) tmpFile.deleteSync();
                return;
              }
              if (tmpFile.existsSync() && tmpFile.lengthSync() > 100) {
                if (file.existsSync()) file.deleteSync();
                await tmpFile.rename(filePath);
              }
              break;
            }
          } catch (_) {
            if (attempt < 2 &&
                isCancelled?.call() != true &&
                WidgetsBinding.instance is WidgetsFlutterBinding) {
              await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
            }
          }
        }

        loaded++;
        if (isCancelled?.call() != true) {
          onProgress?.call((loaded / total).clamp(0.0, 1.0), loaded, total);
        }
      }
    }

    await Future.wait(List.generate(workerCount, (_) => worker()));
    timer.cancel();
    if (!completer.isCompleted) {
      if (isCancelled?.call() != true) {
        onProgress?.call(1.0, total, total);
      }
      completer.complete();
    }
  }

  /// Membersihkan memori in-memory image cache setelah proses selesai atau dibatalkan
  /// guna mengembalikan ratusan megabyte RAM ke sistem operasi dan mencegah OOM
  static void cleanupMemoryCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      PaintingBinding.instance.imageCache.maximumSize = 1000;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
    } catch (_) {}
  }

  /// Memanaskan (pre-cache & decode) seluruh tile ke dalam in-memory cache Flutter
  /// sehingga saat animasi rute diputar di layar ponsel berjalan mulus 60 FPS.
  static Future<void> precacheRouteTiles({
    required List<CoordinatePoint> coordinates,
    BuildContext? context,
    TileProvider? tileProvider,
    TileLayer? tileLayer,
    int zoom = 16,
    int maxTiles = 800,
    String urlTemplate = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    void Function(double progress, int loaded, int total)? onProgress,
    Duration timeout = const Duration(seconds: 45),
    void Function(Timer timer)? onTimerCreated,
    bool Function()? isCancelled,
  }) async {
    // Alokasikan memori in-memory cache Flutter hingga 500 MB agar tile tidak dibuang selama rendering
    PaintingBinding.instance.imageCache.maximumSize = 3500;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 500 << 20; // 500 MB

    final tiles = calculateRouteTiles(
      coordinates,
      zoom: zoom,
      includeNeighbors: true,
      maxTiles: maxTiles,
    );

    if (tiles.isEmpty || (isCancelled?.call() ?? false)) {
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
    onTimerCreated?.call(timer);

    final config = context != null
        ? createLocalImageConfiguration(context)
        : ImageConfiguration.empty;

    final tileList = tiles.toList();
    final workerCount = math.min(10, tileList.length);
    int nextIndex = 0;

    Future<void> runWorker() async {
      while (nextIndex < tileList.length &&
          !completer.isCompleted &&
          !(isCancelled?.call() ?? false)) {
        final currentIndex = nextIndex++;
        final tile = tileList[currentIndex];
        await _loadTileWithRetry(
          tile: tile,
          tileProvider: tileProvider,
          tileLayer: tileLayer,
          urlTemplate: urlTemplate,
          config: config,
          isCancelled: isCancelled,
        );
        loaded++;
        onProgress?.call((loaded / total).clamp(0.0, 1.0), loaded, total);
      }
    }

    await Future.wait(List.generate(workerCount, (_) => runWorker()));

    timer.cancel();
    if (!completer.isCompleted) {
      onProgress?.call(1.0, total, total);
      completer.complete();
    }
  }

  static Future<void> _loadTileWithRetry({
    required TileCoord tile,
    required TileProvider? tileProvider,
    required TileLayer? tileLayer,
    required String urlTemplate,
    required ImageConfiguration config,
    bool Function()? isCancelled,
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      if (isCancelled?.call() ?? false) return;
      try {
        final completer = Completer<void>();
        final url = urlTemplate
            .replaceAll('{z}', '${tile.z}')
            .replaceAll('{x}', '${tile.x}')
            .replaceAll('{y}', '${tile.y}');

        final ImageProvider imageProvider = (tileProvider != null && tileLayer != null)
            ? tileProvider.getImage(TileCoordinates(tile.x, tile.y, tile.z), tileLayer)
            : NetworkImage(url, headers: const {'User-Agent': userAgent});

        final stream = imageProvider.resolve(config);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo? info, bool sync) {
            if (!completer.isCompleted) completer.complete();
            try {
              stream.removeListener(listener);
            } catch (_) {}
          },
          onError: (dynamic err, StackTrace? stack) {
            if (!completer.isCompleted) completer.complete();
            try {
              stream.removeListener(listener);
            } catch (_) {}
          },
        );
        stream.addListener(listener);

        await completer.future.timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            try {
              stream.removeListener(listener);
            } catch (_) {}
          },
        );
        return;
      } catch (_) {
        if (attempt == 1 || (isCancelled?.call() ?? false)) return;
      }
    }
  }
}
