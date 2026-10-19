import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Layanan untuk merender animasi flyover rute menjadi berkas video MP4
/// secara mandiri di perangkat (100% offline, hardware-accelerated MediaCodec).
class VideoExportService {
  static const _mediaChannel = MethodChannel('online.nurmancloud.velora/media_store');
  static const _shareChannel = MethodChannel('online.nurmancloud.velora/social_share');

  /// Memotong buffer piksel mentah ke dimensi target 9:16 (misal 1080x1920 untuk Reels/Story atau 2160x3840 untuk 4K)
  /// yang presisi sehingga tidak terkena kompresi/stretch blur di Instagram.
  static Uint8List cropToTargetDimensions(
    Uint8List src,
    int srcW,
    int srcH,
    int dstW,
    int dstH,
  ) {
    if (srcW == dstW && srcH == dstH) return src;
    final dst = Uint8List(dstW * dstH * 4);
    final srcStride = srcW * 4;
    final dstStride = dstW * 4;

    // Centering horizontal
    final maxOffsetX = (srcW - dstW).clamp(0, srcW);
    final startX = (maxOffsetX ~/ 2).clamp(0, srcW);

    // Centering vertikal: fokuskan sedikit ke area bawah (52%) tempat posisi penunjuk atlet berada
    final maxOffsetY = (srcH - dstH).clamp(0, srcH);
    final startY = (maxOffsetY * 0.52).toInt().clamp(0, maxOffsetY);

    for (int y = 0; y < dstH; y++) {
      if (startY + y >= srcH) break;
      final srcOffset = (startY + y) * srcStride + (startX * 4);
      final dstOffset = y * dstStride;
      dst.setRange(
        dstOffset,
        dstOffset + dstStride,
        src,
        srcOffset,
      );
    }
    return dst;
  }

  /// Kompatibilitas mundur untuk fungsi crop genap
  static Uint8List cropToEvenDimensions(
    Uint8List src,
    int srcW,
    int srcH,
    int dstW,
    int dstH,
  ) {
    return cropToTargetDimensions(src, srcW, srcH, dstW, dstH);
  }

  /// Menyimpan berkas video ke Galeri resmi ponsel (MediaStore Android -> folder Movies/Velora)
  static Future<bool> saveVideoToGallery(String filePath, {String title = 'velora_flyover'}) async {
    try {
      if (Platform.isAndroid) {
        final result = await _mediaChannel.invokeMethod<String>('saveVideoToGallery', {
          'filePath': filePath,
          'title': title,
        });
        debugPrint('VideoExportService: Berhasil simpan ke MediaStore: $result');
        return result != null;
      }
      return false;
    } catch (e) {
      debugPrint('VideoExportService: Gagal menyimpan ke galeri MediaStore: $e');
      return false;
    }
  }

  /// Merender frame dari widget RepaintBoundary menjadi berkas video MP4 rasio 9:16 super tajam
  static Future<String?> renderWidgetToVideo({
    required GlobalKey boundaryKey,
    required int totalFrames,
    required int fps,
    required Future<void> Function(int frameIndex, double progress) onStepFrame,
    required void Function(double progress, int currentFrame, int totalFrames) onProgress,
    bool Function()? isCancelled,
    int targetWidth = 1080,
    int bitrate = 20000000,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('VideoExportService: RepaintBoundary tidak ditemukan.');
        return null;
      }

      // 1. Tentukan direktori penyimpanan video
      final dir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${dir.path}/velora_videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${videosDir.path}/velora_flyover_$timestamp.mp4';

      // 2. Tentukan dimensi standar rasio 9:16 (Instagram Reels & Stories standard: 1080x1920 atau 2160x3840 4K)
      final int videoWidth = (targetWidth ~/ 2) * 2;
      final int videoHeight = (((videoWidth * 16) ~/ 9) ~/ 2) * 2;

      // Rasio piksel adaptif agar kanvas menghasilkan buffer piksel penuh setara videoWidth
      final boundaryWidth = boundary.size.width;
      final double effectivePixelRatio = (boundaryWidth > 0)
          ? (videoWidth / boundaryWidth)
          : 2.7;

      debugPrint(
        'VideoExportService: Memulai encode MP4 9:16 ($videoWidth x $videoHeight, $fps FPS, $totalFrames frames, ratio $effectivePixelRatio, bitrate $bitrate)',
      );

      // 3. Konfigurasi encoder video hardware H.264 dengan bitrate tinggi untuk ketajaman kristal
      await FlutterQuickVideoEncoder.setup(
        width: videoWidth,
        height: videoHeight,
        fps: fps,
        videoBitrate: bitrate,
        profileLevel: ProfileLevel.highAutoLevel,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: outputPath,
      );

      // 4. Loop render tiap frame rute
      for (int i = 0; i < totalFrames; i++) {
        if (isCancelled?.call() == true) {
          debugPrint('VideoExportService: Proses dibatalkan oleh pengguna.');
          try {
            await FlutterQuickVideoEncoder.finish();
            final partialFile = File(outputPath);
            if (await partialFile.exists()) {
              await partialFile.delete();
            }
          } catch (_) {}
          return null;
        }

        final progress = (i + 1) / totalFrames;

        // Gerakkan kamera dan titik rute ke posisi frame ke-i
        await onStepFrame(i, progress);

        // Ambil snapshot piksel Full HD dari RepaintBoundary
        final image = await boundary.toImage(pixelRatio: effectivePixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final imageW = image.width;
        final imageH = image.height;
        image.dispose();

        if (byteData == null) continue;

        // Potong ke rasio 9:16 presisi bebas stretch & blur
        final rawRgba = cropToTargetDimensions(
          byteData.buffer.asUint8List(),
          imageW,
          imageH,
          videoWidth,
          videoHeight,
        );

        // Tambahkan frame ke encoder video
        await FlutterQuickVideoEncoder.appendVideoFrame(rawRgba);

        // Beritahukan progres ke UI dialog
        onProgress(progress, i + 1, totalFrames);
      }

      // 5. Finalisasi berkas video
      await FlutterQuickVideoEncoder.finish();
      debugPrint('VideoExportService: Video berhasil ditulis ke $outputPath');

      // 6. Simpan otomatis ke Galeri resmi ponsel (MediaStore Android -> folder Movies/Velora)
      await saveVideoToGallery(outputPath, title: 'velora_flyover_$timestamp');

      // Salin juga ke folder publik Download & Movies ponsel sebagai fallback sekunder
      try {
        final downloadDir = Directory('/storage/emulated/0/Download/Velora');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        final publicFile = File('${downloadDir.path}/velora_flyover_$timestamp.mp4');
        await File(outputPath).copy(publicFile.path);
      } catch (e) {
        debugPrint('VideoExportService: Info copy ke Download: $e');
      }

      final file = File(outputPath);
      if (await file.exists() && await file.length() > 0) {
        return outputPath;
      }
      return null;
    } catch (e, stack) {
      debugPrint('VideoExportService error: $e\n$stack');
      try {
        await FlutterQuickVideoEncoder.finish();
      } catch (_) {}
      return null;
    }
  }

  /// Membagikan berkas video langsung ke Instagram Story / Reels
  static Future<bool> shareToInstagram(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final result = await _shareChannel.invokeMethod<bool>(
          'shareToInstagramStory',
          {'filePath': filePath},
        );
        return result ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('VideoExportService: Gagal share ke Instagram: $e');
      return false;
    }
  }

  /// Membagikan berkas video langsung ke WhatsApp
  static Future<bool> shareToWhatsApp(String filePath, {String? text}) async {
    try {
      if (Platform.isAndroid) {
        final result = await _shareChannel.invokeMethod<bool>(
          'shareToWhatsApp',
          {'filePath': filePath, 'text': text ?? 'Flyover Rute Latihan • Velora'},
        );
        return result ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('VideoExportService: Gagal share ke WhatsApp: $e');
      return false;
    }
  }

  /// Membagikan berkas video yang telah selesai diekspor ke aplikasi lain (WhatsApp, Reels, TikTok, dsb)
  static Future<ShareResult> shareVideo(String filePath, {String? text}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Berkas video tidak ditemukan pada: $filePath');
    }

    return await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'video/mp4')],
        text: text ?? 'Flyover Rute Latihan • Velora',
        subject: 'Flyover Rute Latihan • Velora',
      ),
    );
  }
}
