import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Target destinasi pembagian kartu aktivitas
enum ShareDestination {
  whatsApp,
  instagramStory,
  system,
}

/// Layanan penangkapan render gambar RepaintBoundary dan pembagian ke media sosial
class SocialShareService {
  static const _shareChannel =
      MethodChannel('online.nurmancloud.velora/social_share');

  /// Mengambil snapshot widget RepaintBoundary menjadi citra PNG beresolusi tajam
  static Future<Uint8List?> capturePng(GlobalKey repaintKey, {double pixelRatio = 2.0}) async {
    try {
      // Penundaan singkat untuk memastikan widget tree selesai me-layout dan merender
      await Future.delayed(const Duration(milliseconds: 50));

      ui.Image? image;
      for (int i = 0; i < 5; i++) {
        try {
          final boundary =
              repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
          if (boundary != null && boundary.attached) {
            image = await boundary.toImage(pixelRatio: pixelRatio);
            break;
          }
        } catch (e) {
          debugPrint('SocialShareService: capturePng attempt $i caught: $e');
        }
        await Future.delayed(const Duration(milliseconds: 100));
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
    ShareDestination destination = ShareDestination.system,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final bytes = await capturePng(repaintKey);
      if (bytes == null) {
        debugPrint('capturePng returned null');
        return false;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = await saveBytesToTempFile(bytes, 'velora_share_$timestamp');
      if (file == null) {
        debugPrint('saveBytesToTempFile returned null');
        return false;
      }

      if (Platform.isAndroid) {
        if (destination == ShareDestination.whatsApp) {
          final res = await _shareChannel.invokeMethod<bool>(
            'shareToWhatsApp',
            {
              'filePath': file.path,
              'text': activityTitle,
            },
          );
          return res ?? false;
        } else if (destination == ShareDestination.instagramStory) {
          final res = await _shareChannel.invokeMethod<bool>(
            'shareToInstagramStory',
            {
              'filePath': file.path,
              'text': activityTitle,
            },
          );
          return res ?? false;
        }
      }

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
