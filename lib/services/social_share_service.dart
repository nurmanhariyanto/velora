import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Layanan penangkapan render gambar RepaintBoundary dan pembagian ke media sosial
class SocialShareService {
  /// Mengambil snapshot widget RepaintBoundary menjadi citra PNG beresolusi tinggi
  static Future<Uint8List?> capturePng(GlobalKey repaintKey, {double pixelRatio = 3.0}) async {
    try {
      final boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan bytes PNG ke file lokal temporer
  static Future<File?> saveBytesToTempFile(Uint8List bytes, String filename) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, '$filename.png');
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Membagikan gambar hasil komposit ke WhatsApp / Instagram Story / sheet sistem
  static Future<void> shareActivityImage({
    required GlobalKey repaintKey,
    required String activityTitle,
    String? subject,
  }) async {
    final bytes = await capturePng(repaintKey);
    if (bytes == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = await saveBytesToTempFile(bytes, 'velora_share_$timestamp');
    if (file == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: activityTitle,
        subject: subject ?? 'Velora: Run & Ride Activity',
      ),
    );
  }
}
