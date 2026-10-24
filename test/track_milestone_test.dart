import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/models/track_milestone.dart';
import 'package:velora/services/track_analysis_service.dart';
import 'package:velora/widgets/live_map_view.dart';
import 'package:velora/widgets/track_milestone_pin.dart';

void main() {
  group('TrackAnalysisService & Track Milestones Tests (Penanda Lintasan)', () {
    List<CoordinatePoint> generateTestPoints({
      required int count,
      required double distancePerStepMeters,
      required int durationPerStepSeconds,
      double initialElevation = 100.0,
      double peakElevation = 250.0,
      int peakIndex = 15,
      double normalSpeed = 6.0, // m/s (~21.6 km/h)
      double maxSpeed = 11.0, // m/s (~39.6 km/h)
      int maxSpeedIndex = 8,
    }) {
      final points = <CoordinatePoint>[];
      final baseTime = DateTime(2026, 10, 18, 8, 0, 0).millisecondsSinceEpoch;

      // Rasio perpindahan koordinat garis lurus (~111.000 meter per derajat latitude)
      final latStep = distancePerStepMeters / 111000.0;

      for (int i = 0; i < count; i++) {
        final elev = (i == peakIndex) ? peakElevation : initialElevation + (i * 2.0);
        final spd = (i == maxSpeedIndex) ? maxSpeed : normalSpeed;
        final time = baseTime + (i * durationPerStepSeconds * 1000);

        points.add(
          CoordinatePoint(
            id: i,
            activityId: 'test-act-1',
            latitude: -0.026330 + (i * latStep),
            longitude: 109.342504,
            elevation: elev,
            speed: spd,
            timestamp: time,
          ),
        );
      }
      return points;
    }

    test('Mengekstrak Start, Finish, KM Splits, Puncak Elevasi, dan Max Speed', () {
      // 30 titik dengan jarak per langkah 100 meter = total ~2.900 meter (~2.9 km)
      final points = generateTestPoints(
        count: 30,
        distancePerStepMeters: 100.0,
        durationPerStepSeconds: 15,
        peakElevation: 320.0,
        peakIndex: 12,
        maxSpeed: 10.5, // 37.8 km/h
        maxSpeedIndex: 7,
      );

      final milestones = TrackAnalysisService.analyzeTrack(points, SportsType.ride);

      expect(milestones, isNotEmpty);

      // Verifikasi Titik Awal (Start)
      final start = milestones.firstWhere((m) => m.type == TrackMilestoneType.start);
      expect(start.distanceMeters, equals(0.0));
      expect(start.pinLabel, equals('S'));

      // Verifikasi Titik Akhir (Finish)
      final finish = milestones.firstWhere((m) => m.type == TrackMilestoneType.finish);
      expect(finish.distanceMeters, greaterThan(2500.0));
      expect(finish.pinLabel, equals('F'));

      // Verifikasi KM Splits (KM 1 dan KM 2)
      final kmSplits = milestones.where((m) => m.type == TrackMilestoneType.kmSplit).toList();
      expect(kmSplits.length, greaterThanOrEqualTo(2));
      expect(kmSplits[0].kmNumber, equals(1));
      expect(kmSplits[1].kmNumber, equals(2));

      // Verifikasi Max Speed Milestone
      final maxSpeedMilestone = milestones.firstWhere((m) => m.type == TrackMilestoneType.maxSpeed);
      expect(maxSpeedMilestone.speedKmh, closeTo(37.8, 0.5));
      expect(maxSpeedMilestone.pinLabel, equals('⚡'));

      // Verifikasi Titik Tertinggi (Peak Elevation)
      final peakMilestone = milestones.firstWhere((m) => m.type == TrackMilestoneType.peakElevation);
      expect(peakMilestone.elevation, equals(320.0));
      expect(peakMilestone.pinLabel, equals('▲'));
    });

    test('Rute turunan (downhill) atau start tidak pernah ditandai sebagai puncak', () {
      final points = <CoordinatePoint>[];
      final baseTime = DateTime(2026, 10, 18, 8, 0, 0).millisecondsSinceEpoch;
      const latStep = 100.0 / 111000.0;

      // Rute menuruni bukit: mulai di 600m dan terus turun ke 400m
      for (int i = 0; i < 20; i++) {
        points.add(
          CoordinatePoint(
            activityId: 'downhill-test',
            latitude: -0.026330 + (i * latStep),
            longitude: 109.342504,
            elevation: 600.0 - (i * 10.0),
            speed: 5.0,
            timestamp: baseTime + (i * 15 * 1000),
          ),
        );
      }

      final milestones = TrackAnalysisService.analyzeTrack(points, SportsType.ride);
      final peakMilestones = milestones.where((m) => m.type == TrackMilestoneType.peakElevation).toList();

      expect(peakMilestones, isEmpty, reason: 'Start atau rute murni turunan tidak boleh diberi penanda puncak');
    });

    test('Rute datar tanpa tanjakan bermakna tidak menghasilkan puncak palsu', () {
      final points = <CoordinatePoint>[];
      final baseTime = DateTime(2026, 10, 18, 8, 0, 0).millisecondsSinceEpoch;
      const latStep = 100.0 / 111000.0;

      // Elevasi datar dengan fluktuasi GPS wajar (+/- 1.5m)
      for (int i = 0; i < 20; i++) {
        points.add(
          CoordinatePoint(
            activityId: 'flat-test',
            latitude: -0.026330 + (i * latStep),
            longitude: 109.342504,
            elevation: 25.0 + ((i % 3) * 1.0),
            speed: 5.0,
            timestamp: baseTime + (i * 15 * 1000),
          ),
        );
      }

      final milestones = TrackAnalysisService.analyzeTrack(points, SportsType.run);
      final peakMilestones = milestones.where((m) => m.type == TrackMilestoneType.peakElevation).toList();

      expect(peakMilestones, isEmpty, reason: 'Rute datar tidak boleh diberi penanda puncak');
    });

    test('Menentukan Kilometer Tercepat (isFastestKm)', () {
      // Buat lintasan di mana KM 2 jauh lebih cepat dari KM 1
      final points = <CoordinatePoint>[];
      final baseTime = DateTime(2026, 10, 18, 8, 0, 0).millisecondsSinceEpoch;
      const latStep = 100.0 / 111000.0;

      // KM 1: 10 langkah @ 100m = 1000m, butuh waktu 300 detik (5 menit)
      for (int i = 0; i < 11; i++) {
        points.add(
          CoordinatePoint(
            activityId: 'act-speed-test',
            latitude: -0.026330 + (i * latStep),
            longitude: 109.342504,
            elevation: 50.0,
            speed: 3.33,
            timestamp: baseTime + (i * 30 * 1000),
          ),
        );
      }

      // KM 2: 10 langkah berikutnya @ 100m = 1000m, butuh waktu hanya 150 detik (2.5 menit)
      final km1EndTime = baseTime + (10 * 30 * 1000);
      for (int i = 1; i <= 10; i++) {
        points.add(
          CoordinatePoint(
            activityId: 'act-speed-test',
            latitude: -0.026330 + ((10 + i) * latStep),
            longitude: 109.342504,
            elevation: 50.0,
            speed: 6.66,
            timestamp: km1EndTime + (i * 15 * 1000),
          ),
        );
      }

      final milestones = TrackAnalysisService.analyzeTrack(points, SportsType.run);
      final kmSplits = milestones.where((m) => m.type == TrackMilestoneType.kmSplit).toList();

      expect(kmSplits.length, equals(2));
      expect(kmSplits[0].kmNumber, equals(1));
      expect(kmSplits[0].isFastestKm, isFalse);

      expect(kmSplits[1].kmNumber, equals(2));
      expect(kmSplits[1].isFastestKm, isTrue, reason: 'KM 2 harus ditandai sebagai kilometer tercepat');
    });

    test('findFastestSegment menemukan sublist koordinat segmen tercepat ~1000m', () {
      final points = <CoordinatePoint>[];
      final baseTime = DateTime(2026, 10, 18, 8, 0, 0).millisecondsSinceEpoch;
      const latStep = 100.0 / 111000.0;

      for (int i = 0; i < 25; i++) {
        // Pada indeks 10 s/d 20 kecepatan tinggi (durasi pendek)
        final stepDuration = (i >= 10 && i < 20) ? 10 : 30;
        points.add(
          CoordinatePoint(
            activityId: 'act-fastest-segment',
            latitude: -0.026330 + (i * latStep),
            longitude: 109.342504,
            timestamp: baseTime + (i * stepDuration * 1000),
          ),
        );
      }

      final fastestSegment = TrackAnalysisService.findFastestSegment(points, targetDistanceMeters: 1000.0);
      expect(fastestSegment, isNotNull);
      expect(fastestSegment!.length, greaterThanOrEqualTo(10));
    });

    testWidgets('LiveMapView merender TrackMilestonePin dan interaksi sentuh penanda lintasan', (WidgetTester tester) async {
      final points = generateTestPoints(
        count: 22,
        distancePerStepMeters: 100.0,
        durationPerStepSeconds: 15,
      );

      TrackMilestone? tappedMilestone;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: LiveMapView(
                coordinates: points,
                showTrackMilestones: true,
                sportsType: SportsType.ride,
                onMilestoneTapped: (m) => tappedMilestone = m,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan widget TrackMilestonePin terpasang
      expect(find.byType(TrackMilestonePin), findsWidgets);

      // Cari salah satu pin dan ketuk
      final firstPin = find.byType(TrackMilestonePin).first;
      await tester.tap(firstPin);
      await tester.pumpAndSettle();

      expect(tappedMilestone, isNotNull);
    });
  });
}
