import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:velora/database/database_helper.dart';
import 'package:velora/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SQLite FFI untuk lingkungan pengujian unit lokal
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempTestDir;
  late Directory supportDir;
  late Directory docDir;
  late Directory extDir;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('velora_profile_test_');
    supportDir = Directory('${tempTestDir.path}/support')..createSync(recursive: true);
    docDir = Directory('${tempTestDir.path}/documents')..createSync(recursive: true);
    extDir = Directory('${tempTestDir.path}/external')..createSync(recursive: true);

    // Mock path_provider platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationSupportDirectory':
            return supportDir.path;
          case 'getApplicationDocumentsDirectory':
            return docDir.path;
          case 'getTemporaryDirectory':
            return tempTestDir.path;
          case 'getExternalStorageDirectory':
            return extDir.path;
          default:
            return tempTestDir.path;
        }
      },
    );

    SharedPreferences.setMockInitialValues({});
    UserProfileService.resetCacheForTesting();
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('DELETE FROM user_settings');
    } catch (_) {}
    await DatabaseHelper.instance.close();

    // Pastikan seluruh berkas tes terisolasi bersih
    for (final dir in [supportDir, docDir, extDir]) {
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    }
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('online.nurmancloud.velora/native_profile'),
      null,
    );

    try {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    } catch (_) {}
    await DatabaseHelper.instance.close();
  });

  group('Simulasi Migrasi Profil APK Lama ke APK Baru (Hepta-Layer Persistence)', () {
    test('Skenario 1: Profil disimpan di APK versi lama v1.0.3.6 (Hanya SharedPreferences)', () async {
      // Simulasikan state data yang ditinggalkan oleh APK versi v1.0.3.6
      SharedPreferences.setMockInitialValues({
        'velora_athlete_name': 'Pak Budi Gowes',
      });
      UserProfileService.resetCacheForTesting();

      // Jalankan inisialisasi aplikasi pada APK versi baru
      await UserProfileService.init();

      // Verifikasi nama atlet tidak kembali default, melainkan sukses terbaca
      expect(UserProfileService.currentAthleteName, equals('Pak Budi Gowes'));
      final loadedName = await UserProfileService.getAthleteName();
      expect(loadedName, equals('Pak Budi Gowes'));
    });

    test('Skenario 2: SharedPreferences terhapus/korup saat update, pulihkan dari berkas JSON APK v1.0.4.4 - v1.0.9', () async {
      // SharedPreferences kosong (misal terhapus saat pembaruan paket sistem atau bug R8)
      SharedPreferences.setMockInitialValues({});
      UserProfileService.resetCacheForTesting();

      // Simulasikan file cadangan yang ditinggalkan oleh APK v1.0.4.4 - v1.0.9 di Application Documents
      final backupFile = File('${docDir.path}/velora_profile.json');
      await backupFile.writeAsString(jsonEncode({
        'athlete_name': 'Rina UltraRunner',
        'updated_at': 1700000000000,
      }));

      // Inisialisasi APK baru
      final restoredName = await UserProfileService.getAthleteName();

      // Pastikan nama berhasil dipulihkan secara utuh
      expect(restoredName, equals('Rina UltraRunner'));
      expect(UserProfileService.currentAthleteName, equals('Rina UltraRunner'));

      // Verifikasi mekanisme Self-Healing: SharedPreferences otomatis terisi kembali
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('velora_athlete_name'), equals('Rina UltraRunner'));
    });

    test('Skenario 3: SharedPreferences & File dokumen kosong, pulihkan dari SQLite Database user_settings', () async {
      SharedPreferences.setMockInitialValues({});
      UserProfileService.resetCacheForTesting();

      // Simulasikan database SQLite lokal dengan tabel user_settings berisi nama atlet
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.insert(
        'user_settings',
        {'key': 'velora_athlete_name', 'value': 'Hendra Climber'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Jalankan pemulihan pada APK baru
      final restoredName = await UserProfileService.getAthleteName();
      expect(restoredName, equals('Hendra Climber'));
      expect(UserProfileService.currentAthleteName, equals('Hendra Climber'));

      // Verifikasi Self-Healing menyinkronkan kembali ke SharedPreferences & Dokumen
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('velora_athlete_name'), equals('Hendra Climber'));
    });

    test('Skenario 4: Perubahan nama profil di APK baru tersimpan permanen dan tahan banting', () async {
      UserProfileService.resetCacheForTesting();

      // Simpan nama baru melalui UserProfileService.setAthleteName
      final saved = await UserProfileService.setAthleteName('Captain Pelotonia');
      expect(saved, isTrue);
      expect(UserProfileService.currentAthleteName, equals('Captain Pelotonia'));

      // Simulasikan restart aplikasi (hapus cache RAM)
      UserProfileService.resetCacheForTesting();

      // Baca kembali saat aplikasi baru terbuka
      final loaded = await UserProfileService.getAthleteName();
      expect(loaded, equals('Captain Pelotonia'));
      expect(UserProfileService.currentAthleteName, equals('Captain Pelotonia'));
    });

    test('Skenario 5: Pemasangan baru murni (Fresh Install) tetap mengembalikan default "Velora Athlete"', () async {
      SharedPreferences.setMockInitialValues({});
      UserProfileService.resetCacheForTesting();

      final db = await DatabaseHelper.instance.database;
      await db.execute("DELETE FROM user_settings WHERE key = 'velora_athlete_name'");

      final defaultName = await UserProfileService.getAthleteName();
      expect(defaultName, equals('Velora Athlete'));
      expect(UserProfileService.currentAthleteName, equals('Velora Athlete'));
    });
  });
}
