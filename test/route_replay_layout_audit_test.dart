import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/screens/route_replay_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'velora_athlete_name': 'Super Long Athlete Champion Name Velora Team International',
    });
  });

  final startTime = DateTime(2026, 10, 18, 7, 30, 0).millisecondsSinceEpoch;
  final dummyCoordinates = List.generate(30, (i) {
    return CoordinatePoint(
      id: i,
      activityId: 'replay-test-audit',
      latitude: -6.2088 + (i * 0.001),
      longitude: 106.8456 + (i * 0.0008),
      elevation: 50.0 + (i * 3.0),
      speed: 8.5, // 30.6 km/h
      timestamp: startTime + (i * 12 * 1000),
    );
  });

  final testSession = ActivitySession(
    id: 'session-audit',
    notes: 'Long Title Morning Ride Around The Mountain With Friends',
    sportsType: SportsType.ride,
    startTime: startTime,
    endTime: startTime + (360 * 1000),
    durationSeconds: 360,
    distanceMeters: 4500,
    elevationGain: 120.0,
    averageSpeedKmh: 30.6,
    maxSpeedKmh: 42.0,
    averagePaceSecondsPerKm: 118,
    coordinates: dummyCoordinates,
  );

  testWidgets('Audit layout on 360x640 (16:9) & 5-metric HUD', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RouteReplayScreen(session: testSession),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);

    // Verifikasi 5 metrik statistik HUD
    expect(find.text('JARAK'), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);
    expect(find.text('ELEVASI'), findsOneWidget);
    expect(find.text('GAIN'), findsOneWidget);
    expect(find.text('WAKTU'), findsOneWidget);
  });

  testWidgets('Audit layout on 360x800 (20:9)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RouteReplayScreen(session: testSession),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('GAIN'), findsOneWidget);
  });

  testWidgets('Audit layout on 390x844 (19.5:9 modern screen)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RouteReplayScreen(session: testSession),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('ELEVASI'), findsOneWidget);
    expect(find.text('GAIN'), findsOneWidget);
  });

  testWidgets('Audit layout on 320x568 (Narrow SE)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RouteReplayScreen(session: testSession),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('JARAK'), findsOneWidget);
  });

  testWidgets('Audit layout on 800x360 (Landscape 20:9)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RouteReplayScreen(session: testSession),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('GAIN'), findsOneWidget);
  });

  testWidgets('Audit layout with high text scale (1.3x)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.3),
            size: Size(360, 780),
          ),
          child: RouteReplayScreen(session: testSession),
        ),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Audit layout with extreme text scale (1.5x)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            size: Size(360, 800),
          ),
          child: RouteReplayScreen(session: testSession),
        ),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Audit Mode Rekam Layar Bersih (Watermark banner & 5 HUD metrics)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RouteReplayScreen(session: testSession),
      ),
    );
    await tester.pump();
    if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati & Langsung Putar'));
      await tester.pumpAndSettle();
    }

    // Buka Sheet Ekspor
    final videoBtn = find.byTooltip('Rekam & Bagikan Video');
    await tester.tap(videoBtn);
    await tester.pumpAndSettle();

    // Pilih Mode Rekam Layar Bersih
    final cleanRecordTile = find.text('Mulai Mode Rekam Layar Bersih');
    expect(cleanRecordTile, findsOneWidget);
    await tester.ensureVisible(cleanRecordTile);
    await tester.pumpAndSettle();
    await tester.tap(cleanRecordTile);
    await tester.pumpAndSettle();

    // Dialog konfirmasi rekam
    expect(find.text('MULAI PUTAR RUTE'), findsOneWidget);
    await tester.tap(find.text('MULAI PUTAR RUTE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Pastikan Watermark VELORA dan nama atlet muncul
    expect(find.text('VELORA'), findsOneWidget);
    expect(find.textContaining('Super Long Athlete Champion Name Velora Team International'), findsOneWidget);

    // Pastikan HUD bersih 5 metrik tampil tanpa overflow
    expect(find.text('JARAK'), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);
    expect(find.text('ELEVASI'), findsOneWidget);
    expect(find.text('GAIN'), findsOneWidget);
    expect(find.text('WAKTU'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
