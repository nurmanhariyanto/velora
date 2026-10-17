import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/services/achievement_service.dart';

void main() {
  group('Strava Time-of-Day Activity Naming (Deteksi Waktu Cerdas)', () {
    DateTime makeTime(int hour, int minute) {
      return DateTime(2026, 10, 17, hour, minute);
    }

    test('04:00 - 10:59 menghasilkan Pagi', () {
      final t1 = makeTime(4, 0).millisecondsSinceEpoch;
      final t2 = makeTime(8, 30).millisecondsSinceEpoch;
      final t3 = makeTime(10, 59).millisecondsSinceEpoch;

      final s1 = ActivitySession(
        id: '1',
        sportsType: SportsType.ride,
        startTime: t1,
        endTime: t1 + 3600000,
        durationSeconds: 3600,
        distanceMeters: 25000,
        averageSpeedKmh: 25.0,
        maxSpeedKmh: 35.0,
        averagePaceSecondsPerKm: 144,
      );

      final s2 = ActivitySession(
        id: '2',
        sportsType: SportsType.run,
        startTime: t2,
        endTime: t2 + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        averagePaceSecondsPerKm: 360,
      );

      final s3 = ActivitySession(
        id: '3',
        sportsType: SportsType.ride,
        startTime: t3,
        endTime: t3 + 3600000,
        durationSeconds: 3600,
        distanceMeters: 20000,
        averageSpeedKmh: 20.0,
        maxSpeedKmh: 30.0,
        averagePaceSecondsPerKm: 180,
      );

      expect(s1.defaultTitle, equals('Bersepeda Pagi'));
      expect(s2.defaultTitle, equals('Lari Pagi'));
      expect(s3.defaultTitle, equals('Bersepeda Pagi'));
    });

    test('11:00 - 14:59 menghasilkan Siang Hari', () {
      final t1 = makeTime(11, 0).millisecondsSinceEpoch;
      final t2 = makeTime(14, 59).millisecondsSinceEpoch;

      final s1 = ActivitySession(
        id: '1',
        sportsType: SportsType.ride,
        startTime: t1,
        endTime: t1 + 3600000,
        durationSeconds: 3600,
        distanceMeters: 20000,
        averageSpeedKmh: 20.0,
        maxSpeedKmh: 28.0,
        averagePaceSecondsPerKm: 180,
      );

      final s2 = ActivitySession(
        id: '2',
        sportsType: SportsType.run,
        startTime: t2,
        endTime: t2 + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        averagePaceSecondsPerKm: 360,
      );

      expect(s1.defaultTitle, equals('Bersepeda Siang Hari'));
      expect(s2.defaultTitle, equals('Lari Siang Hari'));
    });

    test('15:00 - 18:29 menghasilkan Sore Hari', () {
      final t1 = makeTime(15, 0).millisecondsSinceEpoch;
      final t2 = makeTime(18, 29).millisecondsSinceEpoch;

      final s1 = ActivitySession(
        id: '1',
        sportsType: SportsType.ride,
        startTime: t1,
        endTime: t1 + 3600000,
        durationSeconds: 3600,
        distanceMeters: 25000,
        averageSpeedKmh: 25.0,
        maxSpeedKmh: 32.0,
        averagePaceSecondsPerKm: 144,
      );

      final s2 = ActivitySession(
        id: '2',
        sportsType: SportsType.run,
        startTime: t2,
        endTime: t2 + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 13.0,
        averagePaceSecondsPerKm: 360,
      );

      expect(s1.defaultTitle, equals('Bersepeda Sore Hari'));
      expect(s2.defaultTitle, equals('Lari Sore Hari'));
    });

    test('18:30 - 23:59 menghasilkan Malam Hari', () {
      final t1 = makeTime(18, 30).millisecondsSinceEpoch;
      final t2 = makeTime(23, 59).millisecondsSinceEpoch;

      final s1 = ActivitySession(
        id: '1',
        sportsType: SportsType.ride,
        startTime: t1,
        endTime: t1 + 3600000,
        durationSeconds: 3600,
        distanceMeters: 20000,
        averageSpeedKmh: 20.0,
        maxSpeedKmh: 28.0,
        averagePaceSecondsPerKm: 180,
      );

      final s2 = ActivitySession(
        id: '2',
        sportsType: SportsType.run,
        startTime: t2,
        endTime: t2 + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        averagePaceSecondsPerKm: 360,
      );

      expect(s1.defaultTitle, equals('Bersepeda Malam Hari'));
      expect(s2.defaultTitle, equals('Lari Malam Hari'));
    });

    test('00:00 - 03:59 menghasilkan Subuh', () {
      final t1 = makeTime(0, 0).millisecondsSinceEpoch;
      final t2 = makeTime(3, 59).millisecondsSinceEpoch;

      final s1 = ActivitySession(
        id: '1',
        sportsType: SportsType.ride,
        startTime: t1,
        endTime: t1 + 3600000,
        durationSeconds: 3600,
        distanceMeters: 20000,
        averageSpeedKmh: 20.0,
        maxSpeedKmh: 28.0,
        averagePaceSecondsPerKm: 180,
      );

      final s2 = ActivitySession(
        id: '2',
        sportsType: SportsType.run,
        startTime: t2,
        endTime: t2 + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        averagePaceSecondsPerKm: 360,
      );

      expect(s1.defaultTitle, equals('Bersepeda Subuh'));
      expect(s2.defaultTitle, equals('Lari Subuh'));
    });

    test('displayTitle menggunakan catatan khusus jika diisi', () {
      final t = makeTime(6, 0).millisecondsSinceEpoch;
      final sessionWithNote = ActivitySession(
        id: 'custom_1',
        sportsType: SportsType.ride,
        startTime: t,
        endTime: t + 3600000,
        durationSeconds: 3600,
        distanceMeters: 30000,
        averageSpeedKmh: 30.0,
        maxSpeedKmh: 40.0,
        averagePaceSecondsPerKm: 120,
        notes: 'Interval Training Khatulistiwa',
      );

      final sessionEmptyNote = ActivitySession(
        id: 'custom_2',
        sportsType: SportsType.run,
        startTime: t,
        endTime: t + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        averagePaceSecondsPerKm: 360,
        notes: '   ',
      );

      expect(sessionWithNote.displayTitle, equals('Interval Training Khatulistiwa'));
      expect(sessionEmptyNote.displayTitle, equals('Lari Pagi'));
    });
  });

  group('Kalkulasi All-Time Lifetime Stats', () {
    test('calculateLifetimeStats mengagregasikan metrik sepeda dan lari dengan tepat', () {
      final activities = [
        ActivitySession(
          id: 'ride_1',
          sportsType: SportsType.ride,
          startTime: 1697500000000,
          endTime: 1697503600000,
          durationSeconds: 3600,
          distanceMeters: 30000.0, // 30 km
          averageSpeedKmh: 30.0,
          maxSpeedKmh: 45.0,
          averagePaceSecondsPerKm: 120.0,
          elevationGain: 250.0,
        ),
        ActivitySession(
          id: 'ride_2',
          sportsType: SportsType.ride,
          startTime: 1697586400000,
          endTime: 1697593600000,
          durationSeconds: 7200,
          distanceMeters: 60000.0, // 60 km
          averageSpeedKmh: 30.0,
          maxSpeedKmh: 52.0,
          averagePaceSecondsPerKm: 120.0,
          elevationGain: 400.0,
        ),
        ActivitySession(
          id: 'run_1',
          sportsType: SportsType.run,
          startTime: 1697672800000,
          endTime: 1697674600000,
          durationSeconds: 1800,
          distanceMeters: 5000.0, // 5 km
          averageSpeedKmh: 10.0,
          maxSpeedKmh: 14.0,
          averagePaceSecondsPerKm: 360.0, // 6'00"
          elevationGain: 50.0,
        ),
        ActivitySession(
          id: 'run_2',
          sportsType: SportsType.run,
          startTime: 1697759200000,
          endTime: 1697762200000,
          durationSeconds: 3000,
          distanceMeters: 10000.0, // 10 km
          averageSpeedKmh: 12.0,
          maxSpeedKmh: 15.5,
          averagePaceSecondsPerKm: 300.0, // 5'00"
          elevationGain: 80.0,
        ),
      ];

      final rideStats = AchievementService.calculateLifetimeStats(
        SportsType.ride,
        activities,
      );

      expect(rideStats.totalWorkouts, equals(2));
      expect(rideStats.totalDistanceMeters, equals(90000.0));
      expect(rideStats.totalDistanceKm, equals(90.0));
      expect(rideStats.totalDurationSeconds, equals(10800));
      expect(rideStats.totalHours, equals(3.0));
      expect(rideStats.longestDistanceMeters, equals(60000.0));
      expect(rideStats.biggestClimbMeters, equals(400.0));
      expect(rideStats.maxSpeedKmh, equals(52.0));
      expect(rideStats.bestAverageSpeedKmh, equals(30.0));

      final runStats = AchievementService.calculateLifetimeStats(
        SportsType.run,
        activities,
      );

      expect(runStats.totalWorkouts, equals(2));
      expect(runStats.totalDistanceKm, equals(15.0));
      expect(runStats.totalDurationSeconds, equals(4800));
      expect(runStats.longestDistanceKm, equals(10.0));
      expect(runStats.biggestClimbMeters, equals(80.0));
      expect(runStats.maxSpeedKmh, equals(15.5));
      expect(runStats.bestAverageSpeedKmh, equals(12.0));
      expect(runStats.bestPaceSecondsPerKm, equals(300.0));
      expect(runStats.formattedBestPace, equals("5'00\""));
    });

    test('calculateLifetimeStats menghasilkan objek empty saat daftar kosong', () {
      final emptyRide = AchievementService.calculateLifetimeStats(
        SportsType.ride,
        [],
      );
      expect(emptyRide.totalWorkouts, equals(0));
      expect(emptyRide.totalDistanceKm, equals(0.0));
      expect(emptyRide.totalHours, equals(0.0));
      expect(emptyRide.longestDistanceKm, equals(0.0));
      expect(emptyRide.biggestClimbMeters, equals(0.0));
      expect(emptyRide.maxSpeedKmh, equals(0.0));
    });
  });

  group('Ekstraksi Rekor Jarak (Best Efforts)', () {
    test('extractBestEfforts mengekstrak rekor lari dan menghitung pace dengan tepat', () {
      final activities = [
        ActivitySession(
          id: 'run_fast_5k',
          sportsType: SportsType.run,
          startTime: 1697500000000,
          endTime: 1697501500000,
          durationSeconds: 1500, // 25 menit untuk 5k -> pace 5'00"
          distanceMeters: 5000.0,
          averageSpeedKmh: 12.0,
          maxSpeedKmh: 14.0,
          averagePaceSecondsPerKm: 300.0,
        ),
      ];

      final efforts = AchievementService.extractBestEfforts(
        SportsType.run,
        activities,
      );

      final effort1k = efforts.firstWhere((e) => e.id == 'run_1k');
      final effort5k = efforts.firstWhere((e) => e.id == 'run_5k');
      final effort10k = efforts.firstWhere((e) => e.id == 'run_10k');

      expect(effort1k.isAchieved, isTrue);
      expect(effort1k.durationSeconds, equals(300)); // 300 detik untuk 1k
      expect(effort1k.formattedDuration, equals('05:00'));

      expect(effort5k.isAchieved, isTrue);
      expect(effort5k.durationSeconds, equals(1500));
      expect(effort5k.formattedDuration, equals('25:00'));
      expect(effort5k.formattedMetric, equals("5'00\""));

      expect(effort10k.isAchieved, isFalse);
      expect(effort10k.durationSeconds, isNull);
      expect(effort10k.formattedDuration, equals('--:--'));
      expect(effort10k.formattedDate, equals('Belum tercapai'));
    });

    test('extractBestEfforts menggunakan sliding window koordinat GPS jika ada', () {
      // Buat 3 titik koordinat dengan jarak ~1110 meter (0.01 deg lat ~ 1.11 km)
      final coords = [
        const CoordinatePoint(
          id: 1,
          activityId: 'gps_session',
          latitude: 0.0,
          longitude: 109.0,
          timestamp: 1697500000000,
        ),
        const CoordinatePoint(
          id: 2,
          activityId: 'gps_session',
          latitude: 0.005,
          longitude: 109.0,
          timestamp: 1697500120000, // +120s (~555m)
        ),
        const CoordinatePoint(
          id: 3,
          activityId: 'gps_session',
          latitude: 0.010,
          longitude: 109.0,
          timestamp: 1697500240000, // +240s total (~1110m)
        ),
      ];

      final session = ActivitySession(
        id: 'gps_session',
        sportsType: SportsType.run,
        startTime: 1697500000000,
        endTime: 1697500300000,
        durationSeconds: 300,
        distanceMeters: 1200.0,
        averageSpeedKmh: 14.4,
        maxSpeedKmh: 16.0,
        averagePaceSecondsPerKm: 250.0,
        coordinates: coords,
      );

      final efforts = AchievementService.extractBestEfforts(
        SportsType.run,
        [session],
      );

      final effort1k = efforts.firstWhere((e) => e.id == 'run_1k');
      expect(effort1k.isAchieved, isTrue);
      expect(effort1k.durationSeconds, isNotNull);
      expect(effort1k.durationSeconds!, greaterThan(0));
    });
  });

  group('Evaluasi Lencana Digital (Trophy Case Badges)', () {
    test('Gran Fondo, Half Fondo, dan Century Rider terbuka sesuai jarak ride', () {
      final act100k = ActivitySession(
        id: 'act_100k',
        sportsType: SportsType.ride,
        startTime: 1697500000000,
        endTime: 1697514400000,
        durationSeconds: 14400,
        distanceMeters: 105000.0, // 105 km
        averageSpeedKmh: 26.25,
        maxSpeedKmh: 45.0,
        averagePaceSecondsPerKm: 137.0,
      );

      final badges = AchievementService.evaluateBadges([act100k]);

      final granFondo = badges.firstWhere((b) => b.id == 'gran_fondo');
      final halfFondo = badges.firstWhere((b) => b.id == 'half_fondo');
      final century = badges.firstWhere((b) => b.id == 'century_rider');

      expect(granFondo.isUnlocked, isTrue);
      expect(granFondo.progressFraction, equals(1.0));
      expect(halfFondo.isUnlocked, isTrue);
      expect(century.isUnlocked, isFalse);
      expect(century.currentProgress, equals(105.0));
      expect(century.progressFraction, closeTo(105.0 / 160.9, 0.01));
    });

    test('Speed Demon terbuka saat kecepatan rata-rata >= 30 km/h dengan jarak >= 5km', () {
      final fastRide = ActivitySession(
        id: 'speed_demon_act',
        sportsType: SportsType.ride,
        startTime: 1697500000000,
        endTime: 1697501000000,
        durationSeconds: 1000,
        distanceMeters: 9000.0,
        averageSpeedKmh: 32.4, // > 30 km/h
        maxSpeedKmh: 48.0,
        averagePaceSecondsPerKm: 111.0,
      );

      final badges = AchievementService.evaluateBadges([fastRide]);
      final speedDemon = badges.firstWhere((b) => b.id == 'speed_demon');

      expect(speedDemon.isUnlocked, isTrue);
      expect(speedDemon.currentProgress, equals(32.4));
    });

    test('5K, 10K, dan Half Marathoner terbuka saat lari memenuhi patokan jarak', () {
      final run22k = ActivitySession(
        id: 'run_22k',
        sportsType: SportsType.run,
        startTime: 1697500000000,
        endTime: 1697507200000,
        durationSeconds: 7200,
        distanceMeters: 22000.0, // 22 km
        averageSpeedKmh: 11.0,
        maxSpeedKmh: 14.0,
        averagePaceSecondsPerKm: 327.0,
      );

      final badges = AchievementService.evaluateBadges([run22k]);

      final b5k = badges.firstWhere((b) => b.id == '5k_finisher');
      final b10k = badges.firstWhere((b) => b.id == '10k_finisher');
      final bHm = badges.firstWhere((b) => b.id == 'half_marathoner');

      expect(b5k.isUnlocked, isTrue);
      expect(b10k.isUnlocked, isTrue);
      expect(bHm.isUnlocked, isTrue);
    });

    test('Climbing Legend dan Climber terbuka sesuai total elevasi', () {
      final climbAct = ActivitySession(
        id: 'climb_1200m',
        sportsType: SportsType.ride,
        startTime: 1697500000000,
        endTime: 1697507200000,
        durationSeconds: 7200,
        distanceMeters: 45000.0,
        averageSpeedKmh: 22.5,
        maxSpeedKmh: 40.0,
        averagePaceSecondsPerKm: 160.0,
        elevationGain: 1250.0, // > 1000m
      );

      final badges = AchievementService.evaluateBadges([climbAct]);

      final legend = badges.firstWhere((b) => b.id == 'climbing_legend');
      final climber = badges.firstWhere((b) => b.id == 'climber');

      expect(legend.isUnlocked, isTrue);
      expect(climber.isUnlocked, isTrue);
    });

    test('Early Bird dan Night Owl terbuka sesuai waktu mulai sesi', () {
      final earlyTime = DateTime(2026, 10, 17, 5, 30).millisecondsSinceEpoch;
      final nightTime = DateTime(2026, 10, 17, 21, 15).millisecondsSinceEpoch;

      final earlyAct = ActivitySession(
        id: 'early_act',
        sportsType: SportsType.run,
        startTime: earlyTime,
        endTime: earlyTime + 1800000,
        durationSeconds: 1800,
        distanceMeters: 5000.0,
        averageSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        averagePaceSecondsPerKm: 360.0,
      );

      final nightAct = ActivitySession(
        id: 'night_act',
        sportsType: SportsType.ride,
        startTime: nightTime,
        endTime: nightTime + 3600000,
        durationSeconds: 3600,
        distanceMeters: 25000.0,
        averageSpeedKmh: 25.0,
        maxSpeedKmh: 35.0,
        averagePaceSecondsPerKm: 144.0,
      );

      final badgesEarly = AchievementService.evaluateBadges([earlyAct]);
      expect(badgesEarly.firstWhere((b) => b.id == 'early_bird').isUnlocked, isTrue);
      expect(badgesEarly.firstWhere((b) => b.id == 'night_owl').isUnlocked, isFalse);

      final badgesNight = AchievementService.evaluateBadges([nightAct]);
      expect(badgesNight.firstWhere((b) => b.id == 'night_owl').isUnlocked, isTrue);
    });

    test('Consistent Athlete terbuka saat ada 5 sesi latihan', () {
      final fiveSessions = List.generate(
        5,
        (i) => ActivitySession(
          id: 'sess_$i',
          sportsType: SportsType.run,
          startTime: 1697500000000 + (i * 86400000),
          endTime: 1697501800000 + (i * 86400000),
          durationSeconds: 1800,
          distanceMeters: 5000.0,
          averageSpeedKmh: 10.0,
          maxSpeedKmh: 12.0,
          averagePaceSecondsPerKm: 360.0,
        ),
      );

      final badges = AchievementService.evaluateBadges(fiveSessions);
      final streak = badges.firstWhere((b) => b.id == 'consistency_streak');

      expect(streak.isUnlocked, isTrue);
      expect(streak.currentProgress, equals(5.0));
    });
  });
}
