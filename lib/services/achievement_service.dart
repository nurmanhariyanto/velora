import 'package:flutter/material.dart';
import '../algorithms/haversine.dart';
import '../algorithms/pace_calculator.dart';
import '../database/activity_repository.dart';
import '../models/activity_session.dart';
import '../models/best_effort.dart';
import '../models/lifetime_stats.dart';
import '../models/sports_type.dart';
import '../models/trophy_badge.dart';

/// Layanan kalkulasi statistik seumur hidup, rekor jarak (Best Efforts), dan evaluasi lencana (Trophy Case)
class AchievementService {
  final ActivityRepository _repository;

  AchievementService({ActivityRepository? repository})
      : _repository = repository ?? ActivityRepository();

  /// Menghitung akumulasi LifetimeStats untuk [sportsType] dari daftar aktivitas
  static LifetimeStats calculateLifetimeStats(
    SportsType sportsType,
    List<ActivitySession> activities,
  ) {
    final filtered = activities.where((a) => a.sportsType == sportsType).toList();
    if (filtered.isEmpty) {
      return LifetimeStats.empty(sportsType);
    }

    double totalDist = 0.0;
    int totalDur = 0;
    double maxClimb = 0.0;
    double maxDist = 0.0;
    double maxSpeed = 0.0;
    double maxAvgSpeed = 0.0;
    double minPace = double.infinity;

    for (final session in filtered) {
      totalDist += session.distanceMeters;
      totalDur += session.durationSeconds;
      if (session.elevationGain > maxClimb) {
        maxClimb = session.elevationGain;
      }
      if (session.distanceMeters > maxDist) {
        maxDist = session.distanceMeters;
      }
      if (session.maxSpeedKmh > maxSpeed) {
        maxSpeed = session.maxSpeedKmh;
      }
      if (session.averageSpeedKmh > maxAvgSpeed) {
        maxAvgSpeed = session.averageSpeedKmh;
      }
      if (session.averagePaceSecondsPerKm > 0 &&
          session.averagePaceSecondsPerKm < minPace) {
        minPace = session.averagePaceSecondsPerKm;
      }
    }

    return LifetimeStats(
      sportsType: sportsType,
      totalDistanceMeters: totalDist,
      totalDurationSeconds: totalDur,
      totalWorkouts: filtered.length,
      biggestClimbMeters: maxClimb,
      longestDistanceMeters: maxDist,
      maxSpeedKmh: maxSpeed,
      bestAverageSpeedKmh: maxAvgSpeed,
      bestPaceSecondsPerKm: minPace.isFinite ? minPace : 0.0,
    );
  }

  /// Memuat LifetimeStats langsung dari SQLite melalui repository
  Future<LifetimeStats> getLifetimeStats(SportsType sportsType) async {
    return await _repository.getLifetimeStats(sportsType);
  }

  /// Ekstraksi rekor jarak patokan (Best Efforts)
  static List<BestEffort> extractBestEfforts(
    SportsType sportsType,
    List<ActivitySession> activities,
  ) {
    final sportActivities =
        activities.where((a) => a.sportsType == sportsType).toList();

    // Definisi target milestone
    final List<({String id, String label, double targetMeters})> milestones;
    if (sportsType == SportsType.run) {
      milestones = const [
        (id: 'run_1k', label: '1 km', targetMeters: 1000.0),
        (id: 'run_5k', label: '5 km', targetMeters: 5000.0),
        (id: 'run_10k', label: '10 km', targetMeters: 10000.0),
        (id: 'run_half_marathon', label: '21.1 km Half-Marathon', targetMeters: 21097.5),
        (id: 'run_marathon', label: '42.2 km Marathon', targetMeters: 42195.0),
      ];
    } else if (sportsType == SportsType.hike) {
      milestones = const [
        (id: 'hike_1k', label: '1 km Trail', targetMeters: 1000.0),
        (id: 'hike_3k', label: '3 km Trek', targetMeters: 3000.0),
        (id: 'hike_5k', label: '5 km Mountain Trek', targetMeters: 5000.0),
        (id: 'hike_10k', label: '10 km Summit Expedition', targetMeters: 10000.0),
        (id: 'hike_15k', label: '15 km Ultra Trail', targetMeters: 15000.0),
      ];
    } else {
      milestones = const [
        (id: 'ride_1k', label: '1 km Sprint', targetMeters: 1000.0),
        (id: 'ride_5k', label: '5 km TT', targetMeters: 5000.0),
        (id: 'ride_10k', label: '10 km TT', targetMeters: 10000.0),
        (id: 'ride_20k', label: '20 km', targetMeters: 20000.0),
        (id: 'ride_40k', label: '40 km Time Trial', targetMeters: 40000.0),
        (id: 'ride_100k', label: '100 km Gran Fondo', targetMeters: 100000.0),
      ];
    }

    final List<BestEffort> records = [];

    for (final milestone in milestones) {
      int bestDuration = double.maxFinite.toInt();
      ActivitySession? bestActivity;

      for (final session in sportActivities) {
        if (session.distanceMeters < milestone.targetMeters) continue;

        int? effortSeconds;

        // Jika memiliki titik koordinat rute GPS, gunakan sliding window
        if (session.coordinates.length >= 2) {
          effortSeconds = _findFastestSegmentDuration(
            session.coordinates,
            milestone.targetMeters,
          );
        }

        // Fallback: hitung dari kecepatan / durasi rata-rata sesi jika koordinat tidak tersedia
        if (effortSeconds == null || effortSeconds <= 0) {
          if (sportsType == SportsType.run &&
              session.averagePaceSecondsPerKm > 0) {
            effortSeconds = (session.averagePaceSecondsPerKm *
                    (milestone.targetMeters / 1000.0))
                .round();
          } else {
            effortSeconds = (session.durationSeconds *
                    (milestone.targetMeters / session.distanceMeters))
                .round();
          }
        }

        if (effortSeconds > 0 && effortSeconds < bestDuration) {
          bestDuration = effortSeconds;
          bestActivity = session;
        }
      }

      if (bestActivity != null && bestDuration < double.maxFinite.toInt()) {
        final pace = PaceCalculator.calculatePaceSecondsPerKm(
          milestone.targetMeters,
          bestDuration,
        );
        final speed = PaceCalculator.calculateSpeedKmh(
          milestone.targetMeters,
          bestDuration,
        );

        records.add(
          BestEffort(
            id: milestone.id,
            label: milestone.label,
            sportsType: sportsType,
            targetDistanceMeters: milestone.targetMeters,
            durationSeconds: bestDuration,
            paceSecondsPerKm: pace,
            speedKmh: speed,
            achievedDate:
                DateTime.fromMillisecondsSinceEpoch(bestActivity.startTime),
            activityId: bestActivity.id,
          ),
        );
      } else {
        records.add(
          BestEffort(
            id: milestone.id,
            label: milestone.label,
            sportsType: sportsType,
            targetDistanceMeters: milestone.targetMeters,
          ),
        );
      }
    }

    return records;
  }

  /// Menghitung durasi tercepat untuk segmen rute tertentu menggunakan sliding window
  static int? _findFastestSegmentDuration(
    List<dynamic> coords,
    double targetMeters,
  ) {
    if (coords.length < 2) return null;

    final cumDist = List<double>.filled(coords.length, 0.0);
    for (int i = 1; i < coords.length; i++) {
      final p1 = coords[i - 1];
      final p2 = coords[i];
      cumDist[i] = cumDist[i - 1] +
          Haversine.calculateDistance(
            p1.latitude as double,
            p1.longitude as double,
            p2.latitude as double,
            p2.longitude as double,
          );
    }

    if (cumDist.last < targetMeters) return null;

    int minDuration = double.maxFinite.toInt();
    int j = 0;

    for (int i = 0; i < coords.length; i++) {
      while (j < coords.length && (cumDist[j] - cumDist[i]) < targetMeters) {
        j++;
      }
      if (j < coords.length) {
        final segDist = cumDist[j] - cumDist[i];
        final timeMs =
            (coords[j].timestamp as int) - (coords[i].timestamp as int);
        if (timeMs > 0 && segDist >= targetMeters) {
          final adjustedDuration =
              (timeMs / 1000.0) * (targetMeters / segDist);
          final durSec = adjustedDuration.round();
          if (durSec > 0 && durSec < minDuration) {
            minDuration = durSec;
          }
        }
      }
    }

    return minDuration < double.maxFinite.toInt() ? minDuration : null;
  }

  /// Mengevaluasi seluruh lencana prestasi (Trophy Case Badges)
  static List<TrophyBadge> evaluateBadges(List<ActivitySession> allActivities) {
    final rides = allActivities.where((a) => a.sportsType == SportsType.ride).toList();
    final runs = allActivities.where((a) => a.sportsType == SportsType.run).toList();

    // 1. Gran Fondo (Bersepeda >= 100 km)
    final granFondoAct = rides.where((a) => a.distanceMeters >= 100000).toList();
    final maxRideDistKm = rides.isEmpty
        ? 0.0
        : rides.map((a) => a.distanceKm).reduce((a, b) => a > b ? a : b);

    // 2. Half Fondo (Bersepeda >= 50 km)
    final halfFondoAct = rides.where((a) => a.distanceMeters >= 50000).toList();

    // 3. Century Rider (Bersepeda >= 160.9 km)
    final centuryRideAct = rides.where((a) => a.distanceMeters >= 160934).toList();

    // 4. Speed Demon (Kecepatan rata-rata >= 30 km/h, jarak >= 5 km)
    final speedDemonAct = rides
        .where((a) => a.distanceMeters >= 5000 && a.averageSpeedKmh >= 30.0)
        .toList();
    final maxSpeedDemon = rides
        .where((a) => a.distanceMeters >= 5000)
        .fold(0.0, (prev, a) => a.averageSpeedKmh > prev ? a.averageSpeedKmh : prev);

    // 5. 5K Finisher (Lari >= 5 km)
    final run5kAct = runs.where((a) => a.distanceMeters >= 5000).toList();
    final maxRunDistKm = runs.isEmpty
        ? 0.0
        : runs.map((a) => a.distanceKm).reduce((a, b) => a > b ? a : b);

    // 6. 10K Finisher (Lari >= 10 km)
    final run10kAct = runs.where((a) => a.distanceMeters >= 10000).toList();

    // 7. Half Marathoner (Lari >= 21.1 km)
    final runHalfMarathonAct =
        runs.where((a) => a.distanceMeters >= 21097.5).toList();

    // 8. Climbing Legend (Elevasi >= 1000 m)
    final climbLegendAct =
        allActivities.where((a) => a.elevationGain >= 1000.0).toList();
    final maxElevation = allActivities.isEmpty
        ? 0.0
        : allActivities.map((a) => a.elevationGain).reduce((a, b) => a > b ? a : b);

    // 9. King of the Hill (Elevasi >= 500 m)
    final climberAct =
        allActivities.where((a) => a.elevationGain >= 500.0).toList();

    // 10. Early Bird (Mulai 04:00 - 06:30)
    final earlyBirdAct = allActivities.where((a) {
      final dt = DateTime.fromMillisecondsSinceEpoch(a.startTime);
      final m = dt.hour * 60 + dt.minute;
      return m >= 240 && m <= 390;
    }).toList();

    // 11. Night Owl (Mulai 20:00 - 03:59)
    final nightOwlAct = allActivities.where((a) {
      final dt = DateTime.fromMillisecondsSinceEpoch(a.startTime);
      final m = dt.hour * 60 + dt.minute;
      return m >= 1200 || m < 240;
    }).toList();

    // 12. Consistent Athlete (Total >= 5 latihan)
    final totalWorkouts = allActivities.length;

    // 13. Centurion Distance Club (Total akumulasi jarak >= 100 km)
    final totalDistAllKm = allActivities.fold(0.0, (prev, a) => prev + a.distanceKm);

    DateTime? getFirstDate(List<ActivitySession> list) {
      if (list.isEmpty) return null;
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return DateTime.fromMillisecondsSinceEpoch(list.first.startTime);
    }

    return [
      TrophyBadge(
        id: 'gran_fondo',
        title: 'Gran Fondo',
        description: 'Selesaikan perjalanan bersepeda sejauh 100 km dalam satu sesi.',
        icon: Icons.pedal_bike_rounded,
        sportsType: SportsType.ride,
        isUnlocked: granFondoAct.isNotEmpty,
        unlockedDate: getFirstDate(granFondoAct),
        currentProgress: maxRideDistKm,
        targetValue: 100.0,
        unit: 'km',
      ),
      TrophyBadge(
        id: 'half_fondo',
        title: 'Half Fondo',
        description: 'Selesaikan perjalanan bersepeda sejauh 50 km dalam satu sesi.',
        icon: Icons.directions_bike_rounded,
        sportsType: SportsType.ride,
        isUnlocked: halfFondoAct.isNotEmpty,
        unlockedDate: getFirstDate(halfFondoAct),
        currentProgress: maxRideDistKm,
        targetValue: 50.0,
        unit: 'km',
      ),
      TrophyBadge(
        id: 'century_rider',
        title: 'Century Rider',
        description: 'Taklukkan 100 mil (160,9 km) bersepeda dalam satu sesi legendaris.',
        icon: Icons.military_tech_rounded,
        sportsType: SportsType.ride,
        isUnlocked: centuryRideAct.isNotEmpty,
        unlockedDate: getFirstDate(centuryRideAct),
        currentProgress: maxRideDistKm,
        targetValue: 160.9,
        unit: 'km',
      ),
      TrophyBadge(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Catat kecepatan rata-rata di atas 30 km/jam pada sesi minimal 5 km.',
        icon: Icons.speed_rounded,
        sportsType: SportsType.ride,
        isUnlocked: speedDemonAct.isNotEmpty,
        unlockedDate: getFirstDate(speedDemonAct),
        currentProgress: maxSpeedDemon,
        targetValue: 30.0,
        unit: 'km/h',
      ),
      TrophyBadge(
        id: '5k_finisher',
        title: '5K Finisher',
        description: 'Selesaikan lari sejauh minimal 5 km dalam satu sesi latihan.',
        icon: Icons.directions_run_rounded,
        sportsType: SportsType.run,
        isUnlocked: run5kAct.isNotEmpty,
        unlockedDate: getFirstDate(run5kAct),
        currentProgress: maxRunDistKm,
        targetValue: 5.0,
        unit: 'km',
      ),
      TrophyBadge(
        id: '10k_finisher',
        title: '10K Finisher',
        description: 'Tuntaskan lari sejauh minimal 10 km dalam satu sesi latihan.',
        icon: Icons.timer_rounded,
        sportsType: SportsType.run,
        isUnlocked: run10kAct.isNotEmpty,
        unlockedDate: getFirstDate(run10kAct),
        currentProgress: maxRunDistKm,
        targetValue: 10.0,
        unit: 'km',
      ),
      TrophyBadge(
        id: 'half_marathoner',
        title: 'Half Marathoner',
        description: 'Lari menembus jarak Half-Marathon 21,1 km dalam satu sesi epik.',
        icon: Icons.workspace_premium_rounded,
        sportsType: SportsType.run,
        isUnlocked: runHalfMarathonAct.isNotEmpty,
        unlockedDate: getFirstDate(runHalfMarathonAct),
        currentProgress: maxRunDistKm,
        targetValue: 21.1,
        unit: 'km',
      ),
      TrophyBadge(
        id: 'climbing_legend',
        title: 'Climbing Legend',
        description: 'Daki elevasi total minimal 1.000 meter dalam satu sesi aktivitas.',
        icon: Icons.terrain_rounded,
        isUnlocked: climbLegendAct.isNotEmpty,
        unlockedDate: getFirstDate(climbLegendAct),
        currentProgress: maxElevation,
        targetValue: 1000.0,
        unit: 'm',
      ),
      TrophyBadge(
        id: 'climber',
        title: 'King of the Hill',
        description: 'Taklukkan tanjakan dengan elevasi minimal 500 meter dalam satu sesi.',
        icon: Icons.filter_hdr_rounded,
        isUnlocked: climberAct.isNotEmpty,
        unlockedDate: getFirstDate(climberAct),
        currentProgress: maxElevation,
        targetValue: 500.0,
        unit: 'm',
      ),
      TrophyBadge(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Mulai sesi olahraga di waktu subuh atau pagi (04:00 - 06:30).',
        icon: Icons.wb_sunny_rounded,
        isUnlocked: earlyBirdAct.isNotEmpty,
        unlockedDate: getFirstDate(earlyBirdAct),
        currentProgress: earlyBirdAct.isNotEmpty ? 1.0 : 0.0,
        targetValue: 1.0,
        unit: 'sesi',
      ),
      TrophyBadge(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Taklukkan kegelapan malam dengan berolahraga antara 20:00 - 03:59.',
        icon: Icons.nights_stay_rounded,
        isUnlocked: nightOwlAct.isNotEmpty,
        unlockedDate: getFirstDate(nightOwlAct),
        currentProgress: nightOwlAct.isNotEmpty ? 1.0 : 0.0,
        targetValue: 1.0,
        unit: 'sesi',
      ),
      TrophyBadge(
        id: 'consistency_streak',
        title: 'Consistent Athlete',
        description: 'Selesaikan minimal 5 sesi latihan untuk membangun kebiasaan prima.',
        icon: Icons.local_fire_department_rounded,
        isUnlocked: totalWorkouts >= 5,
        unlockedDate: totalWorkouts >= 5
            ? DateTime.fromMillisecondsSinceEpoch(allActivities[4].startTime)
            : null,
        currentProgress: totalWorkouts.toDouble(),
        targetValue: 5.0,
        unit: 'sesi',
      ),
      TrophyBadge(
        id: 'centurion_distance',
        title: '100K Century Club',
        description: 'Kumpulkan akumulasi jarak total 100 km di seluruh riwayat olahragamu.',
        icon: Icons.stars_rounded,
        isUnlocked: totalDistAllKm >= 100.0,
        unlockedDate: totalDistAllKm >= 100.0
            ? DateTime.fromMillisecondsSinceEpoch(allActivities.last.startTime)
            : null,
        currentProgress: totalDistAllKm,
        targetValue: 100.0,
        unit: 'km',
      ),
    ];
  }
}
