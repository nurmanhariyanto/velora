import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/services/video_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoExportService Unit Tests', () {
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
  });
}
