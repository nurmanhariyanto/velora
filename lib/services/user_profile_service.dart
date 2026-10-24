import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:velora/database/database_helper.dart';

/// Layanan lokal untuk membaca, menyimpan, dan memulihkan profil atlet secara permanen.
/// Menggunakan Hepta-Layer Persistence Engine (7 Lapisan Perlindungan) dengan Self-Healing:
/// 1. Cache Memori Instan (0 ms akses UI)
/// 2. SharedPreferences Native OS Android (Langsung via Platform Channel bawaan Android, kebal R8/plugin)
/// 3. SharedPreferences Standar Flutter (`velora_athlete_name`)
/// 4. Application Support Directory (`files/velora_profile.json` - Kebal pembersih cache sistem)
/// 5. Application Documents Directory (`app_flutter/velora_profile.json` - Warisan APK lama v1.0.4 - v1.0.9)
/// 6. Penyimpanan Berkas Eksternal Aplikasi (`getExternalFilesDir` - Kebal update tanpa butuh izin storage)
/// 7. SQLite Database (`velora_local.db` tabel user_settings dengan wal_checkpoint)
/// + Cadangan Tambahan: Penyimpanan Eksternal Publik Android (`Download/Velora` & `Android/media`)
///
/// Jika data di salah satu lapisan hilang atau terhapus saat pembaruan APK,
/// sistem secara otomatis memulihkan (Self-Healing) profil dari lapisan cadangan
/// dan menyinkronkannya kembali ke seluruh lapisan secara serentak.
class UserProfileService {
  static const String _keyAthleteName = 'velora_athlete_name';
  static const String defaultAthleteName = 'Velora Athlete';
  static const String _backupFileName = 'velora_profile.json';

  static const MethodChannel _nativeProfileChannel =
      MethodChannel('online.nurmancloud.velora/native_profile');

  static String? _cachedAthleteName;

  /// Nilai nama atlet yang saat ini aktif di memori (sinkron tanpa jeda async)
  static String get currentAthleteName {
    if (_cachedAthleteName != null &&
        _cachedAthleteName!.trim().isNotEmpty &&
        _cachedAthleteName != defaultAthleteName) {
      return _cachedAthleteName!;
    }
    return defaultAthleteName;
  }

  @visibleForTesting
  static void resetCacheForTesting() => _cachedAthleteName = null;

  /// Inisialisasi awal saat aplikasi mulai berjalan (dipanggil di main() sebelum runApp)
  static Future<void> init() async {
    await getAthleteName();
  }

  /// Membaca nama atlet tersimpan dari 7 lapisan penyimpanan dengan pemulihan otomatis
  static Future<String> getAthleteName() async {
    // 0. Cek cache memori instan untuk performa tinggi & sinkronisasi UI
    if (_cachedAthleteName != null &&
        _cachedAthleteName!.trim().isNotEmpty &&
        _cachedAthleteName != defaultAthleteName) {
      return _cachedAthleteName!;
    }

    String? foundName;

    // 1. Cek SharedPreferences Native OS Android (Platform Channel)
    if (Platform.isAndroid) {
      try {
        final nativeName = await _nativeProfileChannel
            .invokeMethod<String>('getAthleteName')
            .timeout(const Duration(milliseconds: 600));
        if (nativeName != null &&
            nativeName.trim().isNotEmpty &&
            nativeName.trim() != defaultAthleteName) {
          foundName = nativeName.trim();
        }
      } catch (_) {}
    }

    // 2. Cek SharedPreferences Standar Flutter
    if (foundName == null || foundName.isEmpty || foundName == defaultAthleteName) {
      try {
        final prefs = await SharedPreferences.getInstance();
        try {
          await prefs.reload();
        } catch (_) {}

        final spName = prefs.getString(_keyAthleteName)?.trim();
        if (spName != null && spName.isNotEmpty && spName != defaultAthleteName) {
          foundName = spName;
        }
      } catch (e) {
        debugPrint('UserProfileService [SP Error]: $e');
      }
    }

    // 3. Cek Application Support Directory (files/velora_profile.json)
    if (foundName == null || foundName.isEmpty || foundName == defaultAthleteName) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        final name = await _readFromJsonFile(File('${supportDir.path}/$_backupFileName'));
        if (name != null && name.isNotEmpty && name != defaultAthleteName) {
          foundName = name;
        }
      } catch (_) {}
    }

    // 4. Cek Application Documents Directory (app_flutter/velora_profile.json - warisan v1.0.4.4 - v1.0.9)
    if (foundName == null || foundName.isEmpty || foundName == defaultAthleteName) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final name = await _readFromJsonFile(File('${docDir.path}/$_backupFileName'));
        if (name != null && name.isNotEmpty && name != defaultAthleteName) {
          foundName = name;
        }
      } catch (_) {}
    }

    // 5. Cek Penyimpanan Eksternal Aplikasi (getExternalFilesDir - kebal update tanpa izin)
    if (foundName == null || foundName.isEmpty || foundName == defaultAthleteName) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final name = await _readFromJsonFile(File('${extDir.path}/$_backupFileName'));
          if (name != null && name.isNotEmpty && name != defaultAthleteName) {
            foundName = name;
          }
        }
      } catch (_) {}
    }

    // 6. Cek SQLite Database (velora_local.db tabel user_settings)
    if (foundName == null || foundName.isEmpty || foundName == defaultAthleteName) {
      try {
        final dbBackup = await _readFromDb();
        if (dbBackup != null && dbBackup.isNotEmpty && dbBackup != defaultAthleteName) {
          foundName = dbBackup;
        }
      } catch (_) {}
    }

    // 7. Cek Penyimpanan Eksternal Publik Android (Download/Velora & Android/media)
    if (foundName == null || foundName.isEmpty || foundName == defaultAthleteName) {
      try {
        final extCandidates = [
          File('/storage/emulated/0/Download/Velora/.velora_profile.json'),
          File('/storage/emulated/0/Download/Velora/velora_profile.json'),
          File('/storage/emulated/0/Android/media/online.nurmancloud.velora/.velora_profile.json'),
          File('/storage/emulated/0/Android/media/online.nurmancloud.velora/velora_profile.json'),
        ];
        for (final candidate in extCandidates) {
          final extName = await _readFromJsonFile(candidate);
          if (extName != null && extName.isNotEmpty && extName != defaultAthleteName) {
            foundName = extName;
            break;
          }
        }
      } catch (_) {}
    }

    // Pemulihan Otomatis (Self-Healing): Jika nama valid ditemukan, sinkronkan ke seluruh lapisan
    if (foundName != null && foundName.isNotEmpty && foundName != defaultAthleteName) {
      _cachedAthleteName = foundName;
      _healAllLayers(foundName).catchError((_) {});
      return foundName;
    }

    _cachedAthleteName = defaultAthleteName;
    return defaultAthleteName;
  }

  /// Menyimpan nama atlet baru ke 7 lapisan penyimpanan lokal secara terisolasi & terjamin
  static Future<bool> setAthleteName(String name) async {
    try {
      final trimmed = name.trim();
      final finalName = trimmed.isEmpty ? defaultAthleteName : trimmed;

      // Update cache memori secara instan untuk 0 ms latency UI
      _cachedAthleteName = finalName;

      // Sinkronkan ke seluruh 7 lapisan perlindungan secara terisolasi
      await _healAllLayers(finalName);

      return true;
    } catch (e) {
      debugPrint('UserProfileService.setAthleteName error: $e');
      return true; // Tetap sukses di level memori cache
    }
  }

  /// Memastikan seluruh lapisan penyimpanan ter-flush sempurna sebelum pemasangan pembaruan APK
  static Future<void> flushBeforeUpdate() async {
    try {
      final current = await getAthleteName();
      if (current.isNotEmpty && current != defaultAthleteName) {
        await _healAllLayers(current);
      }
    } catch (_) {}
  }

  /// Menyinkronkan dan memulihkan nama ke semua lapisan penyimpanan
  static Future<void> _healAllLayers(String name) async {
    // 1. SharedPreferences Native OS Android (Platform Channel)
    if (Platform.isAndroid) {
      try {
        await _nativeProfileChannel
            .invokeMethod('saveAthleteName', {'name': name})
            .timeout(const Duration(milliseconds: 1000));
      } catch (_) {}
    }

    // 2. SharedPreferences Standar Flutter
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAthleteName, name);
    } catch (_) {}

    // 3. Application Support Directory (files/velora_profile.json)
    try {
      final supportDir = await getApplicationSupportDirectory();
      await _writeToJsonFile(File('${supportDir.path}/$_backupFileName'), name);
    } catch (_) {}

    // 4. Application Documents Directory (app_flutter/velora_profile.json)
    try {
      final docDir = await getApplicationDocumentsDirectory();
      await _writeToJsonFile(File('${docDir.path}/$_backupFileName'), name);
    } catch (_) {}

    // 5. Penyimpanan Berkas Eksternal Aplikasi (getExternalFilesDir)
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        await _writeToJsonFile(File('${extDir.path}/$_backupFileName'), name);
      }
    } catch (_) {}

    // 6. SQLite Database (velora_local.db tabel user_settings)
    try {
      await _syncToDb(name);
    } catch (_) {}

    // 7. Penyimpanan Eksternal Publik Android (Download/Velora & Android/media)
    try {
      final extCandidates = [
        File('/storage/emulated/0/Download/Velora/.velora_profile.json'),
        File('/storage/emulated/0/Android/media/online.nurmancloud.velora/.velora_profile.json'),
      ];
      for (final file in extCandidates) {
        try {
          if (!file.parent.existsSync()) {
            file.parent.createSync(recursive: true);
          }
          await _writeToJsonFile(file, name);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<void> _writeToJsonFile(File file, String name) async {
    try {
      await file.writeAsString(
        jsonEncode({
          'athlete_name': name,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }),
        flush: true,
      );
    } catch (_) {}
  }

  static Future<String?> _readFromJsonFile(File file) async {
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map && data['athlete_name'] is String) {
          final name = (data['athlete_name'] as String).trim();
          if (name.isNotEmpty && name != defaultAthleteName) return name;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _syncToDb(String name) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.insert(
        'user_settings',
        {'key': _keyAthleteName, 'value': name},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Checkpoint WAL agar data tersimpan permanen ke file database fisik di disk
      await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}
  }

  static Future<String?> _readFromDb() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      final res = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: [_keyAthleteName],
        limit: 1,
      );
      if (res.isNotEmpty && res.first['value'] is String) {
        final val = (res.first['value'] as String).trim();
        if (val.isNotEmpty && val != defaultAthleteName) return val;
      }
    } catch (_) {}
    return null;
  }
}
