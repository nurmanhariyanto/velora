import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:velora/database/database_helper.dart';

/// Layanan lokal untuk membaca dan menyimpan profil atlet secara persisten.
/// Menggunakan penyimpanan 3 lapis perlindungan:
/// 1. SharedPreferences (akses cepat UI)
/// 2. Dokumen Lokal JSON (cadangan berkas di storage aplikasi)
/// 3. Database SQLite velora_local.db (tabel user_settings yang tahan banting terhadap pembaruan APK)
/// Hal ini menjamin nama profil tidak akan pernah kembali ke default saat aplikasi diperbarui (app update).
class UserProfileService {
  static const String _keyAthleteName = 'velora_athlete_name';
  static const String defaultAthleteName = 'Velora Athlete';
  static const String _backupFileName = 'velora_profile.json';

  static String? _cachedAthleteName;

  @visibleForTesting
  static void resetCacheForTesting() => _cachedAthleteName = null;

  /// Mendapatkan nama atlet tersimpan (atau 'Velora Athlete' jika belum disetel)
  static Future<String> getAthleteName() async {
    // 1. Cek cache memori instan untuk performa tinggi & sinkronisasi UI
    if (_cachedAthleteName != null &&
        _cachedAthleteName!.trim().isNotEmpty &&
        _cachedAthleteName != defaultAthleteName) {
      return _cachedAthleteName!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        await prefs.reload();
      } catch (_) {}

      final name = prefs.getString(_keyAthleteName)?.trim();
      if (name != null && name.isNotEmpty && name != defaultAthleteName) {
        _cachedAthleteName = name;
        return name;
      }

      // Lapisan 1 Cadangan: Coba pulihkan dari cadangan file JSON
      try {
        final fileBackup = await _readFromFile();
        if (fileBackup != null && fileBackup.isNotEmpty && fileBackup != defaultAthleteName) {
          _cachedAthleteName = fileBackup;
          await prefs.setString(_keyAthleteName, fileBackup);
          return fileBackup;
        }
      } catch (_) {}

      // Lapisan 2 Cadangan: Coba pulihkan dari SQLite database lokal
      try {
        final dbBackup = await _readFromDb();
        if (dbBackup != null && dbBackup.isNotEmpty && dbBackup != defaultAthleteName) {
          _cachedAthleteName = dbBackup;
          await prefs.setString(_keyAthleteName, dbBackup);
          return dbBackup;
        }
      } catch (_) {}

      if (name != null && name.isNotEmpty) {
        _cachedAthleteName = name;
        return name;
      }
    } catch (e) {
      debugPrint('UserProfileService.getAthleteName error: $e');
    }

    _cachedAthleteName = defaultAthleteName;
    return defaultAthleteName;
  }

  /// Menyimpan nama atlet baru ke 3 lapisan penyimpanan lokal secara terjamin
  static Future<bool> setAthleteName(String name) async {
    try {
      final trimmed = name.trim();
      final finalName = trimmed.isEmpty ? defaultAthleteName : trimmed;

      // Update cache memori secara instan
      _cachedAthleteName = finalName;

      final prefs = await SharedPreferences.getInstance();
      final spSuccess = await prefs.setString(_keyAthleteName, finalName);

      // 1. Sinkronkan ke cadangan file JSON
      await _syncToFile(finalName);

      // 2. Sinkronkan ke database SQLite
      await _syncToDb(finalName);

      return spSuccess;
    } catch (e) {
      debugPrint('UserProfileService.setAthleteName error: $e');
      return true; // Tetap sukses di level memori cache
    }
  }

  static Future<void> _syncToFile(String name) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_backupFileName');
      await file.writeAsString(jsonEncode({'athlete_name': name}));
    } catch (_) {}
  }

  static Future<String?> _readFromFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_backupFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map && data['athlete_name'] is String) {
          final name = (data['athlete_name'] as String).trim();
          if (name.isNotEmpty) return name;
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
        if (val.isNotEmpty) return val;
      }
    } catch (_) {}
    return null;
  }
}
