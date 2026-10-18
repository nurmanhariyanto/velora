import '../algorithms/haversine.dart';
import '../models/coordinate_point.dart';
import '../models/sports_type.dart';
import '../models/track_milestone.dart';

/// Layar layanan untuk menganalisis lintasan rute GPS dan menghasilkan
/// penanda milestone (KM Splits, Puncak Elevasi, Kecepatan Tertinggi, dan Segmen Rekor)
class TrackAnalysisService {
  /// Menganalisis seluruh koordinat untuk menghasilkan daftar penanda lintasan
  static List<TrackMilestone> analyzeTrack(
    List<CoordinatePoint> coordinates,
    SportsType sportsType,
  ) {
    if (coordinates.length < 2) return const [];

    final milestones = <TrackMilestone>[];
    final kmSplits = <TrackMilestone>[];

    // 1. Titik Awal (Start Pin)
    final startPt = coordinates.first;
    milestones.add(
      TrackMilestone(
        type: TrackMilestoneType.start,
        latitude: startPt.latitude,
        longitude: startPt.longitude,
        distanceMeters: 0,
        elevation: startPt.elevation,
        speedKmh: startPt.speedKmh,
        title: 'Titik Awal (Start)',
        description: 'Mulai aktivitas',
      ),
    );

    double cumulativeDistance = 0.0;
    int previousKm = 0;
    int prevKmIndex = 0;

    CoordinatePoint maxSpeedPt = coordinates.first;
    double maxSpeedDist = 0.0;

    CoordinatePoint peakElevationPt = coordinates.first;
    double peakElevationDist = 0.0;

    for (int i = 1; i < coordinates.length; i++) {
      final prev = coordinates[i - 1];
      final curr = coordinates[i];

      final dist = Haversine.calculateDistance(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
      cumulativeDistance += dist;

      // Pantau Kecepatan Maksimum (abaikan glitch > 150 km/h)
      if (curr.speedKmh > maxSpeedPt.speedKmh && curr.speedKmh < 150.0) {
        maxSpeedPt = curr;
        maxSpeedDist = cumulativeDistance;
      }

      // Pantau Ketinggian Tertinggi
      if (curr.elevation > peakElevationPt.elevation) {
        peakElevationPt = curr;
        peakElevationDist = cumulativeDistance;
      }

      // Deteksi Pergantian Kilometer (1 km, 2 km, 3 km, dst)
      final currentKm = (cumulativeDistance / 1000.0).floor();
      if (currentKm > previousKm) {
        final splitDurationMs = curr.timestamp - coordinates[prevKmIndex].timestamp;
        final splitSec = (splitDurationMs / 1000).clamp(1, 86400).toInt();

        // Hitung jarak split aktual
        final splitDistanceMeters = cumulativeDistance - (previousKm * 1000.0);
        final splitSpeedKmh = splitSec > 0
            ? (splitDistanceMeters / 1000.0) / (splitSec / 3600.0)
            : 0.0;
        final splitPaceSec = splitDistanceMeters > 0
            ? splitSec / (splitDistanceMeters / 1000.0)
            : 0.0;

        // Hitung akumulasi elevasi selama 1 km ini
        double elevGain = 0.0;
        for (int k = prevKmIndex + 1; k <= i; k++) {
          final diff = coordinates[k].elevation - coordinates[k - 1].elevation;
          if (diff > 0) elevGain += diff;
        }

        final kmMilestone = TrackMilestone(
          type: TrackMilestoneType.kmSplit,
          kmNumber: currentKm,
          latitude: curr.latitude,
          longitude: curr.longitude,
          distanceMeters: cumulativeDistance,
          elevation: curr.elevation,
          speedKmh: curr.speedKmh,
          splitDurationSeconds: splitSec,
          splitSpeedKmh: splitSpeedKmh,
          splitPaceSecondsPerKm: splitPaceSec,
          splitElevationGain: elevGain,
          title: 'Kilometer $currentKm',
          description: sportsType == SportsType.run
              ? 'Pace ${kmMilestonePaceStr(splitPaceSec)} • +${elevGain.toStringAsFixed(0)}m'
              : '${splitSpeedKmh.toStringAsFixed(1)} km/h • +${elevGain.toStringAsFixed(0)}m',
        );

        kmSplits.add(kmMilestone);
        previousKm = currentKm;
        prevKmIndex = i;
      }
    }

    // 2. Tandai Kilometer Tercepat (Fastest KM)
    if (kmSplits.isNotEmpty) {
      TrackMilestone fastestKm = kmSplits.first;
      for (final split in kmSplits) {
        if (split.splitDurationSeconds != null &&
            fastestKm.splitDurationSeconds != null &&
            split.splitDurationSeconds! < fastestKm.splitDurationSeconds!) {
          fastestKm = split;
        }
      }

      for (final split in kmSplits) {
        if (split.kmNumber == fastestKm.kmNumber && kmSplits.length > 1) {
          milestones.add(
            TrackMilestone(
              type: TrackMilestoneType.kmSplit,
              kmNumber: split.kmNumber,
              latitude: split.latitude,
              longitude: split.longitude,
              distanceMeters: split.distanceMeters,
              elevation: split.elevation,
              speedKmh: split.speedKmh,
              splitDurationSeconds: split.splitDurationSeconds,
              splitSpeedKmh: split.splitSpeedKmh,
              splitPaceSecondsPerKm: split.splitPaceSecondsPerKm,
              splitElevationGain: split.splitElevationGain,
              isFastestKm: true,
              title: 'KM ${split.kmNumber} (Tercepat!)',
              description: split.description,
            ),
          );
        } else {
          milestones.add(split);
        }
      }
    }

    // 3. Titik Kecepatan Puncak (⚡ Max Speed)
    if (maxSpeedPt.speedKmh > 5.0 &&
        (maxSpeedPt.latitude != startPt.latitude ||
            maxSpeedPt.longitude != startPt.longitude)) {
      milestones.add(
        TrackMilestone(
          type: TrackMilestoneType.maxSpeed,
          latitude: maxSpeedPt.latitude,
          longitude: maxSpeedPt.longitude,
          distanceMeters: maxSpeedDist,
          elevation: maxSpeedPt.elevation,
          speedKmh: maxSpeedPt.speedKmh,
          title: 'Kecepatan Puncak',
          description: '${maxSpeedPt.speedKmh.toStringAsFixed(1)} km/h',
        ),
      );
    }

    // 4. Titik Puncak Ketinggian (▲ Titik Tertinggi)
    if (peakElevationPt.elevation > 0 &&
        (peakElevationPt.latitude != startPt.latitude ||
            peakElevationPt.longitude != startPt.longitude)) {
      milestones.add(
        TrackMilestone(
          type: TrackMilestoneType.peakElevation,
          latitude: peakElevationPt.latitude,
          longitude: peakElevationPt.longitude,
          distanceMeters: peakElevationDist,
          elevation: peakElevationPt.elevation,
          speedKmh: peakElevationPt.speedKmh,
          title: 'Titik Tertinggi',
          description: '${peakElevationPt.elevation.toStringAsFixed(0)} mdpl',
        ),
      );
    }

    // 5. Titik Akhir (Finish Pin 🏁)
    final finishPt = coordinates.last;
    milestones.add(
      TrackMilestone(
        type: TrackMilestoneType.finish,
        latitude: finishPt.latitude,
        longitude: finishPt.longitude,
        distanceMeters: cumulativeDistance,
        elevation: finishPt.elevation,
        speedKmh: finishPt.speedKmh,
        title: 'Garis Akhir (Finish)',
        description:
            'Total jarak ${(cumulativeDistance / 1000.0).toStringAsFixed(2)} km',
      ),
    );

    return milestones;
  }

  /// Menemukan potongan lintasan (segmen) tercepat untuk jarak tertentu (default: 1.000 meter / 1 km)
  /// Mengembalikan sublist koordinat yang mewakili segmen tersebut agar dapat disorot di peta
  static List<CoordinatePoint>? findFastestSegment(
    List<CoordinatePoint> coordinates, {
    double targetDistanceMeters = 1000.0,
  }) {
    if (coordinates.length < 5) return null;

    int bestStartIndex = -1;
    int bestEndIndex = -1;
    int minDurationMs = 0x7fffffffffffffff;

    double windowDistance = 0.0;
    int windowEnd = 0;

    for (int start = 0; start < coordinates.length - 1; start++) {
      if (start > 0) {
        final removed = Haversine.calculateDistance(
          coordinates[start - 1].latitude,
          coordinates[start - 1].longitude,
          coordinates[start].latitude,
          coordinates[start].longitude,
        );
        windowDistance -= removed;
      }

      while (windowDistance < targetDistanceMeters &&
          windowEnd < coordinates.length - 1) {
        windowEnd++;
        final added = Haversine.calculateDistance(
          coordinates[windowEnd - 1].latitude,
          coordinates[windowEnd - 1].longitude,
          coordinates[windowEnd].latitude,
          coordinates[windowEnd].longitude,
        );
        windowDistance += added;
      }

      if (windowDistance >= targetDistanceMeters) {
        final durationMs =
            coordinates[windowEnd].timestamp - coordinates[start].timestamp;
        if (durationMs > 0 && durationMs < minDurationMs) {
          minDurationMs = durationMs;
          bestStartIndex = start;
          bestEndIndex = windowEnd;
        }
      }
    }

    if (bestStartIndex != -1 && bestEndIndex > bestStartIndex) {
      return coordinates.sublist(bestStartIndex, bestEndIndex + 1);
    }

    return null;
  }

  static String kmMilestonePaceStr(double paceSec) {
    if (paceSec <= 0) return "--'--\"";
    final m = paceSec ~/ 60;
    final s = (paceSec % 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
}
