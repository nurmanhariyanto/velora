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
  static const _mediaChannel =
      MethodChannel('online.nurmancloud.velora/media_store');

  /// Mengambil snapshot widget RepaintBoundary menjadi citra PNG beresolusi tajam (Full HD 1080p+)
  static Future<Uint8List?> capturePng(GlobalKey repaintKey, {double? pixelRatio}) async {
    try {
      // Penundaan untuk memastikan widget tree selesai me-layout dan merender gambar map tile
      await Future.delayed(const Duration(milliseconds: 250));

      ui.Image? image;
      for (int i = 0; i < 5; i++) {
        try {
          final boundary =
              repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
          if (boundary != null && boundary.attached) {
            // Skala adaptif untuk menjamin output minimal 1080px (standar Instagram Story / WhatsApp Status)
            final double effectivePixelRatio;
            if (pixelRatio != null) {
              effectivePixelRatio = pixelRatio;
            } else {
              final boundaryWidth = boundary.size.width;
              if (boundaryWidth > 0) {
                // Target lebar 1080px (atau 1080x1920 untuk rasio 9:16)
                effectivePixelRatio = (1080.0 / boundaryWidth).clamp(3.0, 4.5);
              } else {
                effectivePixelRatio = 3.5;
              }
            }
            image = await boundary.toImage(pixelRatio: effectivePixelRatio);
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
          subject: subject ?? 'Velora Activity',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error sharing activity image: $e');
      return false;
    }
  }

  /// Menyimpan gambar kartu langsung ke Galeri resmi ponsel (Android MediaStore: Pictures/Velora)
  static Future<bool> saveImageToGallery({
    required GlobalKey repaintKey,
    String? title,
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
        final res = await _mediaChannel.invokeMethod<String>(
          'saveImageToGallery',
          {
            'filePath': file.path,
            'title': title ?? 'velora_share_$timestamp',
          },
        );
        return res != null;
      }
      return true;
    } catch (e) {
      debugPrint('Error saving image to gallery: $e');
      return false;
    }
  }
}
