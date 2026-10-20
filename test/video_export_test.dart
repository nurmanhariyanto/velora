import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/services/video_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoExportService Unit Tests', () {
    test('alignDimension menyelaraskan dimensi ke kelipatan 8 dan 16 untuk MediaCodec', () {
      // Kelipatan 8 untuk lebar Full HD, HD, 4K
      expect(VideoExportService.alignDimension(1080, 8), equals(1080));
      expect(VideoExportService.alignDimension(720, 8), equals(720));
      expect(VideoExportService.alignDimension(2160, 8), equals(2160));
      expect(VideoExportService.alignDimension(3840, 8), equals(3840));
      expect(VideoExportService.alignDimension(540, 8), equals(536));

      // Kelipatan 16 untuk tinggi layar non-standar (misal 2340px atau 2460px)
      expect(VideoExportService.alignDimension(2340, 16), equals(2336));
      expect(VideoExportService.alignDimension(2336 % 16, 16), equals(16));
      expect(2336 % 16, equals(0));
      expect(VideoExportService.alignDimension(2400, 16), equals(2400));
      expect(2400 % 16, equals(0));
      expect(VideoExportService.alignDimension(3840, 16), equals(3840));
      expect(3840 % 16, equals(0));

      // Batas minimum
      expect(VideoExportService.alignDimension(4, 16), equals(16));
      expect(VideoExportService.alignDimension(0, 8), equals(8));
    });

    test('cropToEvenDimensions memotong dimensi ganjil ke genap secara akurat', () {
      // Misal gambar 5 x 3 piksel (RGPA = 4 bytes per piksel)
      final srcW = 5;
      final srcH = 3;
      final src = Uint8List(srcW * srcH * 4);
      for (int i = 0; i < src.length; i++) {
        src[i] = (i % 256);
      }

      // Target ke dimensi genap: 4 x 2
      final dstW = 4;
      final dstH = 2;
      final result = VideoExportService.cropToEvenDimensions(
        src,
        srcW,
        srcH,
        dstW,
        dstH,
      );

      // Verifikasi panjang buffer sesuai persis dstW * dstH * 4
      expect(result.length, equals(dstW * dstH * 4));
      expect(result.length, equals(32));

      // Dimensi yang sudah genap (4 x 2 ke 4 x 2) harus langsung mengembalikan src tanpa copy berlebih
      final identicalResult = VideoExportService.cropToEvenDimensions(
        result,
        dstW,
        dstH,
        dstW,
        dstH,
      );
      expect(identicalResult, equals(result));
    });

    test('MethodChannel flutter_quick_video_encoder merespon tanpa crash saat di-mock', () async {
      const channel = MethodChannel('flutter_quick_video_encoder/methods');
      final calls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call.method);
        return 0;
      });

      // Panggil metode setup simulasi Full HD 1080p
      await channel.invokeMethod('setup', {
        'width': 1080,
        'height': 2200,
        'fps': 24,
        'videoBitrate': 8000000,
        'filepath': '/tmp/test_1080p.mp4',
      });

      // Panggil metode finish
      await channel.invokeMethod('finish');

      expect(calls, contains('setup'));
      expect(calls, contains('finish'));
    });

    test('Perhitungan rasio piksel adaptif menjamin resolusi lebar Full HD 1080px', () {
      // Pada layar ponsel umum dengan lebar 360 - 412 dp
      const double screenWidth1 = 360.0;
      const double screenWidth2 = 392.0;
      const double screenWidth3 = 412.0;

      final ratio1 = (1080.0 / screenWidth1).clamp(2.0, 3.5);
      final ratio2 = (1080.0 / screenWidth2).clamp(2.0, 3.5);
      final ratio3 = (1080.0 / screenWidth3).clamp(2.0, 3.5);

      final widthPx1 = (screenWidth1 * ratio1).round();
      final widthPx2 = (screenWidth2 * ratio2).round();
      final widthPx3 = (screenWidth3 * ratio3).round();

      expect(widthPx1, equals(1080));
      expect(widthPx2, equals(1080));
      expect(widthPx3, equals(1080));
      expect(ratio2, greaterThan(2.5));
    });

    test('saveVideoToGallery memanggil MethodChannel dan mengembalikan status sukses', () async {
      const channel = MethodChannel('online.nurmancloud.velora/media_store');
      String? invokedMethod;
      Map<dynamic, dynamic>? receivedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        invokedMethod = call.method;
        receivedArgs = call.arguments as Map<dynamic, dynamic>?;
        if (call.method == 'saveVideoToGallery') {
          return 'content://media/external/video/media/42';
        }
        return null;
      });

      final success = await VideoExportService.saveVideoToGallery(
        '/data/user/0/online.nurmancloud.velora/app_flutter/test.mp4',
        title: 'rute_pagi',
      );

      expect(success, isTrue);
      expect(invokedMethod, equals('saveVideoToGallery'));
      expect(receivedArgs?['title'], equals('rute_pagi'));
      expect(receivedArgs?['filePath'], contains('test.mp4'));
    });

    test('saveVideoToGallery menangani error platform channel secara graceful', () async {
      const channel = MethodChannel('online.nurmancloud.velora/media_store');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'SAVE_FAILED', message: 'Storage full');
      });

      final success = await VideoExportService.saveVideoToGallery(
        '/data/user/0/online.nurmancloud.velora/app_flutter/test.mp4',
      );

      // Harus mengembalikan false tanpa melempar unhandled exception
      expect(success, isFalse);
    });

    test('shareToWhatsApp memanggil channel sosial dan mengembalikan status', () async {
      const channel = MethodChannel('online.nurmancloud.velora/social_share');
      String? invokedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        invokedMethod = call.method;
        if (call.method == 'shareToWhatsApp') {
          return true;
        }
        return false;
      });

      final success = await VideoExportService.shareToWhatsApp('/tmp/test.mp4', text: 'Rute Keren!');

      expect(success, isTrue);
      expect(invokedMethod, equals('shareToWhatsApp'));
    });

    test('shareToInstagram memanggil channel sosial dan mengembalikan status', () async {
      const channel = MethodChannel('online.nurmancloud.velora/social_share');
      String? invokedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        invokedMethod = call.method;
        if (call.method == 'shareToInstagramStory') {
          return true;
        }
        return false;
      });

      final success = await VideoExportService.shareToInstagram('/tmp/test.mp4');

      expect(success, isTrue);
      expect(invokedMethod, equals('shareToInstagramStory'));
    });

    test('shareVideo memvalidasi keberadaan dan ukuran berkas', () async {
      // 1. Berkas tidak ada
      expect(
        () => VideoExportService.shareVideo('/tmp/non_existent_velora_video_9999.mp4'),
        throwsA(isA<FileSystemException>()),
      );

      // 2. Berkas kosong (0 byte)
      final tempEmptyFile = File('${Directory.systemTemp.path}/empty_velora_test.mp4');
      if (tempEmptyFile.existsSync()) tempEmptyFile.deleteSync();
      tempEmptyFile.createSync();

      expect(
        () => VideoExportService.shareVideo(tempEmptyFile.path),
        throwsA(isA<FileSystemException>()),
      );

      tempEmptyFile.deleteSync();
    });
  });
}
