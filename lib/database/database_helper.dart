import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Pengelola koneksi dan skema database lokal SQLite Velora
class DatabaseHelper {
  static const String dbName = 'velora_local.db';
  static const int dbVersion = 2;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // Pengecekan defensif untuk kolom detak jantung jika versi sebelumnya terlewat
        await _ensureHeartRateColumns(db);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel Aktivitas Sesi
    await db.execute('''
      CREATE TABLE aktivitas (
        id TEXT PRIMARY KEY,
        jenis_olahraga TEXT NOT NULL,
        waktu_mulai INTEGER NOT NULL,
        waktu_selesai INTEGER NOT NULL,
        total_durasi_detik INTEGER NOT NULL,
        total_jarak_meter REAL NOT NULL,
        kecepatan_rata_rata REAL NOT NULL,
        kecepatan_maksimal REAL NOT NULL,
        pace_rata_rata REAL NOT NULL,
        elevasi_positif REAL DEFAULT 0.0,
        catatan TEXT,
        foto_path TEXT,
        avg_heart_rate REAL DEFAULT NULL,
        max_heart_rate INTEGER DEFAULT NULL
      )
    ''');

    // 2. Tabel Titik Koordinat GPS
    await db.execute('''
      CREATE TABLE titik_koordinat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aktivitas_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        elevasi REAL DEFAULT 0.0,
        kecepatan REAL DEFAULT 0.0,
        akurasi REAL DEFAULT 0.0,
        timestamp INTEGER NOT NULL,
        is_auto_paused INTEGER DEFAULT 0,
        detak_jantung INTEGER DEFAULT NULL,
        FOREIGN KEY (aktivitas_id) REFERENCES aktivitas (id) ON DELETE CASCADE
      )
    ''');

    // Indeks untuk query koordinat berdasarkan aktivitas_id yang cepat
    await db.execute('''
      CREATE INDEX idx_titik_aktivitas ON titik_koordinat (aktivitas_id)
    ''');

    // 3. Tabel Pengaturan & Profil Pengguna Lokal
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureHeartRateColumns(db);
    }
  }

  Future<void> _ensureHeartRateColumns(Database db) async {
    try {
      final coordColumns = await db.rawQuery('PRAGMA table_info(titik_koordinat)');
      final hasDetakJantung = coordColumns.any((col) => col['name'] == 'detak_jantung');
      if (!hasDetakJantung) {
        await db.execute('ALTER TABLE titik_koordinat ADD COLUMN detak_jantung INTEGER DEFAULT NULL');
      }

      final actColumns = await db.rawQuery('PRAGMA table_info(aktivitas)');
      final hasAvgHr = actColumns.any((col) => col['name'] == 'avg_heart_rate');
      if (!hasAvgHr) {
        await db.execute('ALTER TABLE aktivitas ADD COLUMN avg_heart_rate REAL DEFAULT NULL');
      }
      final hasMaxHr = actColumns.any((col) => col['name'] == 'max_heart_rate');
      if (!hasMaxHr) {
        await db.execute('ALTER TABLE aktivitas ADD COLUMN max_heart_rate INTEGER DEFAULT NULL');
      }
    } catch (e) {
      debugPrint('Database schema check: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
