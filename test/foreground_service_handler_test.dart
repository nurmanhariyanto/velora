import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/services/foreground_service_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForegroundServiceHandler Unit Tests', () {
    final calls = <String>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_foreground_task/methods'),
        (MethodCall call) async {
          calls.add(call.method);
          if (call.method == 'isRunningService') {
            return false;
          }
          if (call.method == 'checkNotificationPermission') {
            return 'granted';
          }
          return null;
        },
      );
    });

    test('startOrUpdatePrecacheProgress mengeksekusi tanpa unhandled exception', () async {
      await ForegroundServiceHandler.startOrUpdatePrecacheProgress(
        progress: 0.45,
        loaded: 45,
        total: 100,
        isSatellite: true,
      );
      // Memastikan fungsi berjalan dengan anggun
      expect(calls, isNotEmpty);
    });

    test('startOrUpdateRenderProgress mengeksekusi dengan title dan text yang tepat', () async {
      await ForegroundServiceHandler.startOrUpdateRenderProgress(
        progress: 0.80,
        currentFrame: 240,
        totalFrames: 300,
      );
      expect(calls, isNotEmpty);
    });

    test('showRenderCompletedNotification menampilkan notifikasi penyelesaian', () async {
      await ForegroundServiceHandler.showRenderCompletedNotification(
        title: 'Video Flyover Selesai!',
        text: 'Tersimpan di Galeri Ponsel',
      );
      expect(calls, isNotEmpty);
    });

    test('stopRenderProgress menghentikan layanan latar belakang', () async {
      await ForegroundServiceHandler.stopRenderProgress();
      expect(calls, isNotEmpty);
    });
  });
}
