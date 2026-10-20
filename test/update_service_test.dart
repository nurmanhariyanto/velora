import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/app_update_info.dart';

void main() {
  group('Logika Perbandingan Versi Auto-Update (SemVer)', () {
    test('Versi lebih tinggi harus menghasilkan hasUpdate = true', () {
      expect(AppUpdateInfo.isNewerVersion('1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.0', '1.1.0'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.0', '2.0.0'), isTrue);
    });

    test('Awalan tag "v" atau "V" tidak mempengaruhi perbandingan', () {
      expect(AppUpdateInfo.isNewerVersion('1.0.0', 'v1.0.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('v1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('v1.0.0', 'v1.0.1'), isTrue);
    });

    test('Versi yang sama atau lebih rendah harus menghasilkan false', () {
      expect(AppUpdateInfo.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.1.0', '1.0.5'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('2.0.0', '1.9.9'), isFalse);
    });

    test('Penanganan format build number (+1)', () {
      expect(AppUpdateInfo.isNewerVersion('1.0.0+1', '1.0.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.0+1', '1.0.0'), isFalse);
    });

    test('Pembaruan minor 4-digit versi (cth: v1.0.3.1)', () {
      expect(AppUpdateInfo.isNewerVersion('1.0.3', '1.0.3.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('v1.0.3', 'v1.0.3.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.3.1', '1.0.3'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.3.1', '1.0.3.1'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.3.1', '1.0.3.2'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.3.1', '1.0.4'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.4', '1.0.4.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('v1.0.4', 'v1.0.4.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.4.1', '1.0.4.1'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.4.1', '1.0.4'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.4.6', '1.0.4.7'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.4.7', '1.0.4.8'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.4.8', '1.0.4.9'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.4', '1.0.4.9'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.4.9', '1.0.5.0'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.0', '1.0.5.0'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.0', '1.0.5.1'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.1', '1.0.5.1'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.1', '1.0.5.2'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.2', '1.0.5.2'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.2', '1.0.5.3'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.3', '1.0.5.3'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.3', '1.0.5.4'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.4', '1.0.5.4'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.4', '1.0.5.5'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.5', '1.0.5.5'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.5', '1.0.5.6'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.6', '1.0.5.6'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.6', '1.0.5.7'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.5.7', '1.0.5.7'), isFalse);
    });
  });
}
