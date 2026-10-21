import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/services/wakelock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WakelockService Unit Tests', () {
    const channel = MethodChannel('online.nurmancloud.velora/wakelock');
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        if (call.method == 'keepScreenOn') {
          return true;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('WakelockService.enable mengaktifkan proteksi layar aktif via Platform Channel', () async {
      final success = await WakelockService.enable();

      expect(success, isTrue);
      expect(WakelockService.isEnabled, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('keepScreenOn'));
      expect(methodCalls.first.arguments['enable'], isTrue);
    });

    test('WakelockService.disable melepas proteksi layar aktif via Platform Channel', () async {
      final success = await WakelockService.disable();

      expect(success, isTrue);
      expect(WakelockService.isEnabled, isFalse);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('keepScreenOn'));
      expect(methodCalls.first.arguments['enable'], isFalse);
    });

    test('WakelockService menangani kegagalan platform channel secara aman tanpa unhandled exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'ERROR', message: 'Wakelock failed');
      });

      final success = await WakelockService.enable();
      expect(success, isFalse);
    });
  });
}
