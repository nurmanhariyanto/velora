import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

/// TileProvider kustom Velora yang memprioritaskan pembacaan ubin peta
/// langsung dari penyimpanan disk lokal (100% offline, instan, bebas kotak hitam).
/// Jika ubin belum diunduh ke disk, otomatis mengambil via network dan menyimpannya.
class VeloraTileProvider extends TileProvider {
  final String cacheDir;
  final String providerType; // 'satellite' atau 'osm'
  final String userAgent;

  VeloraTileProvider({
    required this.cacheDir,
    this.providerType = 'satellite',
    this.userAgent = 'online.nurmancloud.velora',
    super.headers,
  });

  /// Mengembalikan path file ubin lokal pada disk
  static String getTileFilePath(String baseDir, String providerType, int z, int x, int y) {
    return '$baseDir/${providerType}_${z}_${x}_$y.tile';
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final path = getTileFilePath(
      cacheDir,
      providerType,
      coordinates.z,
      coordinates.x,
      coordinates.y,
    );
    final file = File(path);

    // 1. Prioritas Utama: Baca langsung dari disk jika file ubin sudah diunduh (100% offline, instan, bebas kotak hitam)
    if (file.existsSync() && file.lengthSync() > 100) {
      return FileImage(file);
    }

    // 2. Fallback: Ambil via network dan simpan otomatis ke disk untuk penggunaan berikutnya
    final url = getTileUrl(coordinates, options);
    _downloadTileInBackground(url, file);
    return NetworkImage(url, headers: {'User-Agent': userAgent});
  }

  void _downloadTileInBackground(String url, File file) {
    http.get(Uri.parse(url), headers: {'User-Agent': userAgent}).then((res) {
      if (res.statusCode == 200 && res.bodyBytes.length > 100) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsBytes(res.bodyBytes).catchError((_) => file);
      }
    }).catchError((_) {});
  }
}
