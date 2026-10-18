import '../algorithms/pace_calculator.dart';
import 'sports_type.dart';

/// Statistik akumulasi seumur hidup (All-Time Lifetime Stats) per jenis olahraga
class LifetimeStats {
  final SportsType sportsType;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final int totalWorkouts;
  final double biggestClimbMeters;
  final double longestDistanceMeters;
  final double maxSpeedKmh;
  final double bestAverageSpeedKmh;
  final double bestPaceSecondsPerKm;

  const LifetimeStats({
    required this.sportsType,
    this.totalDistanceMeters = 0.0,
    this.totalDurationSeconds = 0,
    this.totalWorkouts = 0,
    this.biggestClimbMeters = 0.0,
    this.longestDistanceMeters = 0.0,
    this.maxSpeedKmh = 0.0,
    this.bestAverageSpeedKmh = 0.0,
    this.bestPaceSecondsPerKm = 0.0,
  });

  factory LifetimeStats.empty(SportsType sportsType) {
    return LifetimeStats(sportsType: sportsType);
  }

  /// Total jarak dalam kilometer
  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  /// Jarak terpanjang dalam satu sesi (km)
  double get longestDistanceKm => longestDistanceMeters / 1000.0;

  /// Total jam olahraga
  double get totalHours => totalDurationSeconds / 3600.0;

  /// Format total waktu
  String get formattedTotalDuration {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours j $minutes m';
    }
    return '$minutes m';
  }

  /// Format total jarak
  String get formattedTotalDistance {
    return '${totalDistanceKm.toStringAsFixed(1)} km';
  }

  /// Format jarak terpanjang
  String get formattedLongestDistance {
    if (longestDistanceMeters <= 0) return '0.0 km';
    return '${longestDistanceKm.toStringAsFixed(2)} km';
  }

  /// Format elevasi terbesar
  String get formattedBiggestClimb {
    return '+${biggestClimbMeters.toStringAsFixed(0)} m';
  }

  /// Format kecepatan maksimal puncak
  String get formattedMaxSpeed {
    return '${maxSpeedKmh.toStringAsFixed(1)} km/h';
  }

  /// Format rata-rata kecepatan terbaik
  String get formattedBestAverageSpeed {
    return '${bestAverageSpeedKmh.toStringAsFixed(1)} km/h';
  }

  /// Format pace lari terbaik
  String get formattedBestPace {
    return PaceCalculator.formatPace(bestPaceSecondsPerKm);
  }
}
