import 'dart:typed_data';
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

      // Panggil metode setup simulasi
      await channel.invokeMethod('setup', {
        'width': 720,
        'height': 1280,
        'fps': 24,
        'videoBitrate': 3500000,
        'filepath': '/tmp/test.mp4',
      });

      // Panggil metode finish
      await channel.invokeMethod('finish');

      expect(calls, contains('setup'));
      expect(calls, contains('finish'));
    });
  });
}
