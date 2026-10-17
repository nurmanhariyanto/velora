import 'package:intl/intl.dart';
import '../algorithms/pace_calculator.dart';
import 'sports_type.dart';

/// Rekor jarak terbaik (Best Effort) ala Strava untuk jarak standar/patokan
class BestEffort {
  final String id;
  final String label;
  final SportsType sportsType;
  final double targetDistanceMeters;
  final int? durationSeconds;
  final double? paceSecondsPerKm;
  final double? speedKmh;
  final DateTime? achievedDate;
  final String? activityId;

  const BestEffort({
    required this.id,
    required this.label,
    required this.sportsType,
    required this.targetDistanceMeters,
    this.durationSeconds,
    this.paceSecondsPerKm,
    this.speedKmh,
    this.achievedDate,
    this.activityId,
  });

  /// Apakah rekor milestone ini sudah berhasil dicapai
  bool get isAchieved => durationSeconds != null && durationSeconds! > 0;

  /// String format durasi pencapaian (cth: "19:42" atau "1:15:30")
  String get formattedDuration {
    if (!isAchieved) return '--:--';
    return PaceCalculator.formatDuration(durationSeconds!);
  }

  /// String format metrik performa (pace untuk lari, kecepatan untuk sepeda)
  String get formattedMetric {
    if (!isAchieved) {
      return sportsType == SportsType.run ? "--'--\"" : '--.- km/h';
    }
    if (sportsType == SportsType.run) {
      if (paceSecondsPerKm != null && paceSecondsPerKm! > 0) {
        return PaceCalculator.formatPace(paceSecondsPerKm!);
      }
      return "--'--\"";
    } else {
      if (speedKmh != null && speedKmh! > 0) {
        return '${speedKmh!.toStringAsFixed(1)} km/h';
      }
      return '--.- km/h';
    }
  }

  /// Format tanggal diraih
  String get formattedDate {
    if (!isAchieved || achievedDate == null) {
      return 'Belum tercapai';
    }
    return DateFormat('d MMM yyyy', 'id_ID').format(achievedDate!);
  }

  BestEffort copyWith({
    String? id,
    String? label,
    SportsType? sportsType,
    double? targetDistanceMeters,
    int? durationSeconds,
    double? paceSecondsPerKm,
    double? speedKmh,
    DateTime? achievedDate,
    String? activityId,
  }) {
    return BestEffort(
      id: id ?? this.id,
      label: label ?? this.label,
      sportsType: sportsType ?? this.sportsType,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      paceSecondsPerKm: paceSecondsPerKm ?? this.paceSecondsPerKm,
      speedKmh: speedKmh ?? this.speedKmh,
      achievedDate: achievedDate ?? this.achievedDate,
      activityId: activityId ?? this.activityId,
    );
  }
}
