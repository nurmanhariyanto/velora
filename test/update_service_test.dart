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
      expect(AppUpdateInfo.isNewerVersion('1.0.3.2', '1.0.3.3'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.3.1', '1.0.4'), isTrue);
    });
  });
}
