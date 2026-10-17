import 'package:sqflite/sqflite.dart';
import '../models/activity_session.dart';
import '../models/coordinate_point.dart';
import '../models/lifetime_stats.dart';
import '../models/sports_type.dart';
import 'database_helper.dart';

/// Repository untuk membaca dan memanipulasi data riwayat latihan lokal
class ActivityRepository {
  final DatabaseHelper _dbHelper;

  ActivityRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Menyimpan sesi aktivitas dan titik koordinatnya secara transaksional
  Future<void> insertActivity(ActivitySession session) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Simpan header sesi
      await txn.insert(
        'aktivitas',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Simpan titik koordinat via batch agar efisien
      if (session.coordinates.isNotEmpty) {
        final batch = txn.batch();
        for (final point in session.coordinates) {
          batch.insert(
            'titik_koordinat',
            point.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  /// Mengambil semua sesi aktivitas (tanpa koordinat penuh demi performa cepat pada daftar)
  Future<List<ActivitySession>> getAllActivities() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aktivitas',
      orderBy: 'waktu_mulai DESC',
    );

    return maps.map((map) => ActivitySession.fromMap(map)).toList();
  }

  /// Mengambil rincian sesi beserta seluruh titik koordinatnya
  Future<ActivitySession?> getActivityById(String id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> sessionMaps = await db.query(
      'aktivitas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (sessionMaps.isEmpty) return null;

    final List<Map<String, dynamic>> coordMaps = await db.query(
      'titik_koordinat',
      where: 'aktivitas_id = ?',
      whereArgs: [id],
      orderBy: 'timestamp ASC',
    );

    final coordinates =
        coordMaps.map((map) => CoordinatePoint.fromMap(map)).toList();

    return ActivitySession.fromMap(sessionMaps.first, coordinates: coordinates);
  }

  /// Menghapus sesi aktivitas beserta seluruh koordinatnya (CASCADE)
  Future<int> deleteActivity(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'aktivitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Memperbarui catatan atau foto latar aktivitas
  Future<int> updateActivityNotes(String id, String? notes, {String? photoPath}) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> values = {'catatan': notes};
    if (photoPath != null) {
      values['foto_path'] = photoPath;
    }

    return await db.update(
      'aktivitas',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menghitung akumulasi statistik keseluruhan
  Future<({double totalDistanceMeters, int totalDurationSeconds, int totalWorkouts})>
      getAggregatedStats() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(total_jarak_meter) as total_dist,
        SUM(total_durasi_detik) as total_dur,
        COUNT(id) as total_count
      FROM aktivitas
    ''');

    if (result.isEmpty) {
      return (totalDistanceMeters: 0.0, totalDurationSeconds: 0, totalWorkouts: 0);
    }

    final row = result.first;
    final totalDist = (row['total_dist'] as num?)?.toDouble() ?? 0.0;
    final totalDur = (row['total_dur'] as num?)?.toInt() ?? 0;
    final totalCount = (row['total_count'] as num?)?.toInt() ?? 0;

    return (
      totalDistanceMeters: totalDist,
      totalDurationSeconds: totalDur,
      totalWorkouts: totalCount,
    );
  }

  /// Menghitung akumulasi statistik seumur hidup untuk jenis olahraga tertentu
  Future<LifetimeStats> getLifetimeStats(SportsType sportsType) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(id) as total_count,
        SUM(total_jarak_meter) as total_dist,
        SUM(total_durasi_detik) as total_dur,
        MAX(elevasi_positif) as max_climb,
        MAX(total_jarak_meter) as max_dist,
        MAX(kecepatan_maksimal) as max_speed,
        MAX(kecepatan_rata_rata) as max_avg_speed,
        MIN(CASE WHEN pace_rata_rata > 0 THEN pace_rata_rata ELSE NULL END) as min_pace
      FROM aktivitas
      WHERE jenis_olahraga = ?
    ''', [sportsType.name]);

    if (result.isEmpty) {
      return LifetimeStats.empty(sportsType);
    }

    final row = result.first;
    final totalCount = (row['total_count'] as num?)?.toInt() ?? 0;
    if (totalCount == 0) {
      return LifetimeStats.empty(sportsType);
    }

    final totalDist = (row['total_dist'] as num?)?.toDouble() ?? 0.0;
    final totalDur = (row['total_dur'] as num?)?.toInt() ?? 0;
    final maxClimb = (row['max_climb'] as num?)?.toDouble() ?? 0.0;
    final maxDist = (row['max_dist'] as num?)?.toDouble() ?? 0.0;
    final maxSpeed = (row['max_speed'] as num?)?.toDouble() ?? 0.0;
    final maxAvgSpeed = (row['max_avg_speed'] as num?)?.toDouble() ?? 0.0;
    final minPace = (row['min_pace'] as num?)?.toDouble() ?? 0.0;

    return LifetimeStats(
      sportsType: sportsType,
      totalDistanceMeters: totalDist,
      totalDurationSeconds: totalDur,
      totalWorkouts: totalCount,
      biggestClimbMeters: maxClimb,
      longestDistanceMeters: maxDist,
      maxSpeedKmh: maxSpeed,
      bestAverageSpeedKmh: maxAvgSpeed,
      bestPaceSecondsPerKm: minPace,
    );
  }

  /// Mengambil semua sesi aktivitas berdasarkan jenis olahraga
  Future<List<ActivitySession>> getActivitiesBySport(SportsType sportsType) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aktivitas',
      where: 'jenis_olahraga = ?',
      whereArgs: [sportsType.name],
      orderBy: 'waktu_mulai DESC',
    );

    return maps.map((map) => ActivitySession.fromMap(map)).toList();
  }
}
