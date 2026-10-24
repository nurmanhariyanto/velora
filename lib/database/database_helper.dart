import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Pengelola koneksi dan skema database lokal SQLite Velora
class DatabaseHelper {
  static const String dbName = 'velora_local.db';
  static const int dbVersion = 1;

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
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
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
        foto_path TEXT
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

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
