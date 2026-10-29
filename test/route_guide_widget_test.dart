import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/route_guide_info.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/providers/history_provider.dart';
import 'package:velora/providers/tracking_provider.dart';
import 'package:velora/widgets/live_map_view.dart';
import 'package:velora/widgets/off_course_banner.dart';
import 'package:velora/widgets/route_guide_sheet.dart';

void main() {
  group('OffCourseBanner Widget Tests', () {
    testWidgets('Merender banner peringatan keluar jalur dengan jarak meter & kilometer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OffCourseBanner(
              isOffCourse: true,
              distanceMeters: 65.0,
            ),
          ),
        ),
      );

      expect(find.text('PERINGATAN: KELUAR DARI JALUR'), findsOneWidget);
      expect(find.text('Anda berjarak 65 m dari lintasan rute.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Uji format kilometer jika jarak >= 1000m
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OffCourseBanner(
              isOffCourse: true,
              distanceMeters: 1450.0,
            ),
          ),
        ),
      );

      expect(find.text('Anda berjarak 1.45 km dari lintasan rute.'), findsOneWidget);

      // Saat isOffCourse == false, banner menyusut menjadi SizedBox.shrink()
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OffCourseBanner(
              isOffCourse: false,
              distanceMeters: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('PERINGATAN: KELUAR DARI JALUR'), findsNothing);
    });
  });

  group('RouteGuideSheet & LiveMapView Integration Tests', () {
    testWidgets('RouteGuideSheet menampilkan opsi muat file GPX dan riwayat saat rute kosong', (tester) async {
      final tracking = TrackingProvider();
      final history = HistoryProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TrackingProvider>.value(value: tracking),
            ChangeNotifierProvider<HistoryProvider>.value(value: history),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RouteGuideSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Panduan Rute GPX & Peringatan'), findsOneWidget);
      expect(find.text('Pilih File GPX dari Perangkat'), findsOneWidget);
      expect(find.text('Pilih dari Riwayat Latihan'), findsOneWidget);
    });

    testWidgets('RouteGuideSheet menampilkan kartu rute aktif, switch toggle, dan tombol hapus', (tester) async {
      final tracking = TrackingProvider();
      final history = HistoryProvider();

      final guide = RouteGuideInfo(
        name: 'Rute Danau Sebedang',
        points: const [
          LatLng(-0.026330, 109.342504),
          LatLng(-0.027000, 109.343000),
        ],
        totalDistanceMeters: 5200.0,
      );

      tracking.setRouteGuide(guide);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TrackingProvider>.value(value: tracking),
            ChangeNotifierProvider<HistoryProvider>.value(value: history),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RouteGuideSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Rute Danau Sebedang'), findsOneWidget);
      expect(find.text('5.20 km • 2 titik koordinat'), findsOneWidget);
      expect(find.text('Panduan Rute & Peringatan Jalur'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Ganti Rute'), findsOneWidget);
      expect(find.text('Hapus Rute'), findsOneWidget);

      // Uji menekan tombol Hapus Rute
      await tester.tap(find.text('Hapus Rute'));
      await tester.pump();

      expect(tracking.routeGuide, isNull);
      expect(tracking.isRouteGuideEnabled, isFalse);
    });

    testWidgets('LiveMapView merender garis panduan referensi (referenceRoute) dan tombol aksi panduan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool guidePressed = false;

      final referencePoints = [
        const LatLng(-0.026330, 109.342504),
        const LatLng(-0.027000, 109.343000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveMapView(
              coordinates: const [
                CoordinatePoint(
                  activityId: 'act1',
                  latitude: -0.026330,
                  longitude: 109.342504,
                  elevation: 10,
                  speed: 2.5,
                  timestamp: 1000,
                ),
              ],
              currentLocation: const LatLng(-0.026330, 109.342504),
              referenceRoute: referencePoints,
              onRouteGuidePressed: () {
                guidePressed = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verifikasi tombol panduan rute muncul pada floating action buttons
      final guideBtn = find.byIcon(Icons.alt_route_rounded);
      expect(guideBtn, findsOneWidget);

      await tester.tap(guideBtn);
      await tester.pump();

      expect(guidePressed, isTrue);
    });

    testWidgets('RouteGuideInfo.fromSession mengonversi sesi aktivitas riwayat ke RouteGuideInfo dengan akurat', (tester) async {
      const session = ActivitySession(
        id: 'act_test_hike',
        sportsType: SportsType.hike,
        startTime: 1700000000000,
        endTime: 1700003600000,
        durationSeconds: 3600,
        distanceMeters: 4500.0,
        averageSpeedKmh: 4.5,
        maxSpeedKmh: 6.0,
        averagePaceSecondsPerKm: 800.0,
        elevationGain: 280.0,
        notes: 'Daki Gunung Palung',
        coordinates: [
          CoordinatePoint(
            activityId: 'act_test_hike',
            latitude: -1.2,
            longitude: 110.1,
            elevation: 100,
            speed: 1.2,
            timestamp: 1700000000000,
          ),
          CoordinatePoint(
            activityId: 'act_test_hike',
            latitude: -1.21,
            longitude: 110.11,
            elevation: 380,
            speed: 1.0,
            timestamp: 1700003600000,
          ),
        ],
      );

      final guide = RouteGuideInfo.fromSession(session);

      expect(guide.name, equals('Daki Gunung Palung'));
      expect(guide.totalDistanceMeters, equals(4500.0));
      expect(guide.elevationGain, equals(280.0));
      expect(guide.points.length, equals(2));
      expect(guide.points.first.latitude, equals(-1.2));
      expect(guide.points.last.latitude, equals(-1.21));
      expect(guide.startPoint, isNotNull);
      expect(guide.endPoint, isNotNull);
    });
  });
}
