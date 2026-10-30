import 'coordinate_point.dart';
import 'sports_type.dart';

/// Sesi aktivitas olahraga yang tersimpan di SQLite lokal
class ActivitySession {
  final String id;
  final SportsType sportsType;
  final int startTime; // epoch ms
  final int endTime; // epoch ms
  final int durationSeconds; // durasi aktif (bersih)
  final double distanceMeters;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double averagePaceSecondsPerKm;
  final double elevationGain;
  final String? notes;
  final String? photoPath;
  final List<CoordinatePoint> coordinates;
  final int? averageHeartRate; // Rata-rata detak jantung dalam BPM
  final int? maxHeartRate; // Detak jantung maksimal dalam BPM

  const ActivitySession({
    required this.id,
    required this.sportsType,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.averagePaceSecondsPerKm,
    this.elevationGain = 0.0,
    this.notes,
    this.photoPath,
    this.coordinates = const [],
    this.averageHeartRate,
    this.maxHeartRate,
  });

  /// Jarak dalam kilometer
  double get distanceKm => distanceMeters / 1000.0;

  /// String format durasi HH:mm:ss atau mm:ss
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// String format pace lari (cth: 5'12")
  String get formattedPace {
    if (averagePaceSecondsPerKm.isNaN ||
        averagePaceSecondsPerKm.isInfinite ||
        averagePaceSecondsPerKm <= 0 ||
        averagePaceSecondsPerKm > 3600) {
      return "--'--\"";
    }
    final int totalSecs = averagePaceSecondsPerKm.round();
    if (totalSecs <= 0 || totalSecs > 3600) {
      return "--'--\"";
    }
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return "$mins'${secs.toString().padLeft(2, '0')}\"";
  }

  /// String format kecepatan (cth: 24.5 km/h)
  String get formattedSpeed {
    return '${averageSpeedKmh.toStringAsFixed(1)} km/h';
  }

  /// Apakah aktivitas ini memiliki rekaman detak jantung
  bool get hasHeartRateData =>
      (averageHeartRate != null && averageHeartRate! > 0) ||
      coordinates.any((c) => c.heartRate != null && c.heartRate! > 0);

  /// String format rata-rata detak jantung (cth: 148 bpm)
  String get formattedHeartRate =>
      averageHeartRate != null ? '$averageHeartRate bpm' : '-- bpm';

  /// String format detak jantung puncak/maksimal (cth: 175 bpm)
  String get formattedMaxHeartRate =>
      maxHeartRate != null ? '$maxHeartRate bpm' : '-- bpm';

  /// Judul default aktivitas otomatis berdasarkan waktu mulai sesi
  String get defaultTitle {
    final date = DateTime.fromMillisecondsSinceEpoch(startTime);
    final minuteOfDay = date.hour * 60 + date.minute;
    final String timeOfDayName;

    if (minuteOfDay >= 240 && minuteOfDay <= 659) {
      // 04:00 - 10:59
      timeOfDayName = 'Pagi';
    } else if (minuteOfDay >= 660 && minuteOfDay <= 899) {
      // 11:00 - 14:59
      timeOfDayName = 'Siang Hari';
    } else if (minuteOfDay >= 900 && minuteOfDay <= 1109) {
      // 15:00 - 18:29
      timeOfDayName = 'Sore Hari';
    } else if (minuteOfDay >= 1110 && minuteOfDay <= 1439) {
      // 18:30 - 23:59
      timeOfDayName = 'Malam Hari';
    } else {
      // 00:00 - 03:59
      timeOfDayName = 'Subuh';
    }

    final prefix = sportsType == SportsType.ride
        ? 'Bersepeda'
        : (sportsType == SportsType.hike ? 'Mendaki' : 'Lari');
    return '$prefix $timeOfDayName';
  }

  /// Judul tampilan aktivitas: menggunakan catatan khusus jika diisi, atau defaultTitle
  String get displayTitle {
    if (notes != null && notes!.trim().isNotEmpty) {
      return notes!.trim();
    }
    return defaultTitle;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis_olahraga': sportsType.name,
      'waktu_mulai': startTime,
      'waktu_selesai': endTime,
      'total_durasi_detik': durationSeconds,
      'total_jarak_meter': distanceMeters,
      'kecepatan_rata_rata': averageSpeedKmh,
      'kecepatan_maksimal': maxSpeedKmh,
      'pace_rata_rata': averagePaceSecondsPerKm,
      'elevasi_positif': elevationGain,
      'catatan': notes,
      'foto_path': photoPath,
      'avg_heart_rate': averageHeartRate,
      'max_heart_rate': maxHeartRate,
    };
  }

  factory ActivitySession.fromMap(
    Map<String, dynamic> map, {
    List<CoordinatePoint> coordinates = const [],
  }) {
    return ActivitySession(
      id: map['id'] as String,
      sportsType: SportsType.fromString(map['jenis_olahraga'] as String),
      startTime: map['waktu_mulai'] as int,
      endTime: map['waktu_selesai'] as int,
      durationSeconds: map['total_durasi_detik'] as int,
      distanceMeters: (map['total_jarak_meter'] as num).toDouble(),
      averageSpeedKmh: (map['kecepatan_rata_rata'] as num).toDouble(),
      maxSpeedKmh: (map['kecepatan_maksimal'] as num).toDouble(),
      averagePaceSecondsPerKm: (map['pace_rata_rata'] as num).toDouble(),
      elevationGain: (map['elevasi_positif'] as num?)?.toDouble() ?? 0.0,
      notes: map['catatan'] as String?,
      photoPath: map['foto_path'] as String?,
      coordinates: coordinates,
      averageHeartRate: (map['avg_heart_rate'] as num?)?.round(),
      maxHeartRate: (map['max_heart_rate'] as num?)?.round(),
    );
  }

  ActivitySession copyWith({
    String? id,
    SportsType? sportsType,
    int? startTime,
    int? endTime,
    int? durationSeconds,
    double? distanceMeters,
    double? averageSpeedKmh,
    double? maxSpeedKmh,
    double? averagePaceSecondsPerKm,
    double? elevationGain,
    String? notes,
    String? photoPath,
    List<CoordinatePoint>? coordinates,
    int? averageHeartRate,
    int? maxHeartRate,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      sportsType: sportsType ?? this.sportsType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      averagePaceSecondsPerKm:
          averagePaceSecondsPerKm ?? this.averagePaceSecondsPerKm,
      elevationGain: elevationGain ?? this.elevationGain,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      coordinates: coordinates ?? this.coordinates,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
    );
  }
}
