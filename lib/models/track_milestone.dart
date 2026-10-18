import '../algorithms/pace_calculator.dart';
import 'sports_type.dart';

/// Jenis penanda milestone di sepanjang rute track
enum TrackMilestoneType {
  start,          // Titik Awal (Start Pin 🟢)
  finish,         // Titik Selesai (Finish Pin 🏁)
  kmSplit,        // Penanda Kilometer (KM 1, KM 2, dst 📍)
  maxSpeed,       // Titik Kecepatan Puncak (⚡)
  peakElevation,  // Titik Ketinggian Maksimum (🏔️)
  bestEffort,     // Segmen Tercepat (🏆)
}

/// Model data untuk penanda titik penting di atas garis lintasan rute GPS
class TrackMilestone {
  final TrackMilestoneType type;
  final int kmNumber;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double elevation;
  final double speedKmh;
  final int? splitDurationSeconds;
  final double? splitPaceSecondsPerKm;
  final double? splitSpeedKmh;
  final double? splitElevationGain;
  final bool isFastestKm;
  final String title;
  final String description;

  const TrackMilestone({
    required this.type,
    this.kmNumber = 0,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.elevation,
    required this.speedKmh,
    this.splitDurationSeconds,
    this.splitPaceSecondsPerKm,
    this.splitSpeedKmh,
    this.splitElevationGain,
    this.isFastestKm = false,
    required this.title,
    required this.description,
  });

  /// Format durasi split per kilometer (cth: "4:35")
  String get formattedSplitDuration {
    if (splitDurationSeconds == null || splitDurationSeconds! <= 0) return '--:--';
    return PaceCalculator.formatDuration(splitDurationSeconds!);
  }

  /// Format kecepatan atau pace split sesuai jenis olahraga
  String formattedMetric(SportsType sportsType) {
    if (sportsType == SportsType.run) {
      if (splitPaceSecondsPerKm != null && splitPaceSecondsPerKm! > 0) {
        return PaceCalculator.formatPace(splitPaceSecondsPerKm!);
      }
      return "--'--\"";
    } else {
      if (splitSpeedKmh != null && splitSpeedKmh! > 0) {
        return '${splitSpeedKmh!.toStringAsFixed(1)} km/h';
      }
      return '--.- km/h';
    }
  }

  /// Label ringkas untuk ditampilkan di dalam pin peta
  String get pinLabel {
    switch (type) {
      case TrackMilestoneType.start:
        return 'S';
      case TrackMilestoneType.finish:
        return 'F';
      case TrackMilestoneType.kmSplit:
        return '$kmNumber';
      case TrackMilestoneType.maxSpeed:
        return '⚡';
      case TrackMilestoneType.peakElevation:
        return '▲';
      case TrackMilestoneType.bestEffort:
        return '★';
    }
  }
}
