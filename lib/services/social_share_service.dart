import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Layanan penangkapan render gambar RepaintBoundary dan pembagian ke media sosial
class SocialShareService {
  /// Mengambil snapshot widget RepaintBoundary menjadi citra PNG beresolusi tajam
  static Future<Uint8List?> capturePng(GlobalKey repaintKey, {double pixelRatio = 2.0}) async {
    try {
      // Tunggu hingga rendering frame selesai sepenuhnya
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary? boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.attached) {
        debugPrint('RepaintBoundary render object is not ready or unattached, waiting...');
        await Future.delayed(const Duration(milliseconds: 100));
        await WidgetsBinding.instance.endOfFrame;
        boundary =
            repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null || !boundary.attached) {
          debugPrint('RepaintBoundary still null or unattached');
          return null;
        }
      }

      int attempts = 0;
      while ((boundary?.debugNeedsPaint ?? false) && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        await WidgetsBinding.instance.endOfFrame;
        boundary =
            repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null || !boundary.attached) return null;
        attempts++;
      }

      ui.Image? image;
      for (int i = 0; i < 3; i++) {
        try {
          final current =
              repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
          if (current == null || !current.attached) return null;

          if (current.debugNeedsPaint) {
            await Future.delayed(const Duration(milliseconds: 50));
            await WidgetsBinding.instance.endOfFrame;
            continue;
          }
          image = await current.toImage(pixelRatio: pixelRatio);
          break;
        } catch (e) {
          debugPrint('SocialShareService: capturePng attempt $i caught: $e');
          await Future.delayed(const Duration(milliseconds: 100));
          await WidgetsBinding.instance.endOfFrame;
        }
      }

      if (image == null) {
        debugPrint('SocialShareService: Failed to obtain image from RepaintBoundary');
        return null;
      }

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing PNG: $e');
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
    } catch (e) {
      debugPrint('Error saving share file: $e');
      return null;
    }
  }

  /// Membagikan gambar hasil komposit ke WhatsApp / Instagram Story / sheet sistem
  static Future<bool> shareActivityImage({
    required GlobalKey repaintKey,
    required String activityTitle,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final bytes = await capturePng(repaintKey);
      if (bytes == null) return false;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = await saveBytesToTempFile(bytes, 'velora_share_$timestamp');
      if (file == null) return false;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: activityTitle,
          subject: subject ?? 'Velora: Run & Ride Activity',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error sharing activity image: $e');
      return false;
    }
  }
}
