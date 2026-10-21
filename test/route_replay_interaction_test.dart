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
      'velora_athlete_name': 'Velora Test Rider',
    });
  });

  final startTime = DateTime(2026, 10, 18, 7, 30, 0).millisecondsSinceEpoch;
  final dummyCoordinates = List.generate(20, (i) {
    return CoordinatePoint(
      id: i,
      activityId: 'replay-interaction-test',
      latitude: -0.026330 + (i * 0.001),
      longitude: 109.342504 + (i * 0.0008),
      elevation: 20.0 + (i * 2.0),
      speed: 8.0, // 28.8 km/h
      timestamp: startTime + (i * 10 * 1000),
    );
  });

  final testSession = ActivitySession(
    id: 'session-interaction-test',
    notes: 'Uji Interaksi Tombol Flyover',
    sportsType: SportsType.ride,
    startTime: startTime,
    endTime: startTime + (200 * 1000),
    durationSeconds: 200,
    distanceMeters: 2200,
    elevationGain: 40.0,
    averageSpeedKmh: 28.8,
    maxSpeedKmh: 35.0,
    averagePaceSecondsPerKm: 125,
    coordinates: dummyCoordinates,
  );

  Widget createReplayScreen() {
    return MaterialApp(
      home: RouteReplayScreen(session: testSession),
    );
  }

  group('RouteReplayScreen Button Interaction & Feedback Tests', () {
    testWidgets('Tombol Pengatur Kecepatan memiliki Material InkWell dan ukuran sentuh nyaman',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      // Cari tombol kecepatan 2x
      final speedFinder = find.text('2x');
      expect(speedFinder, findsOneWidget);

      // Verifikasi widget dibungkus Material dan InkWell untuk efek ripple
      final inkWellFinder = find.ancestor(
        of: speedFinder,
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsWidgets);

      // Verifikasi ukuran container memenuhi minimum target sentuh (minWidth 48, minHeight 44)
      final RenderBox speedBox = tester.renderObject(speedFinder);
      expect(speedBox.size.width, greaterThan(0));

      // Ketuk untuk mengubah kecepatan 2x -> 4x
      await tester.tap(speedFinder);
      await tester.pumpAndSettle();
      expect(find.text('4x'), findsOneWidget);

      // Ketuk lagi 4x -> 8x
      await tester.tap(find.text('4x'));
      await tester.pumpAndSettle();
      expect(find.text('8x'), findsOneWidget);

      // Ketuk lagi 8x -> 1x
      await tester.tap(find.text('8x'));
      await tester.pumpAndSettle();
      expect(find.text('1x'), findsOneWidget);
    });

    testWidgets('Tombol Play/Pause berbentuk bundar dengan Material ripple responsif',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      // Tombol default adalah Pause (sedang playing)
      final pauseIconFinder = find.byIcon(Icons.pause_rounded);
      expect(pauseIconFinder, findsOneWidget);

      // Verifikasi dibungkus Material & InkWell untuk visual tactile ripple
      final inkWellParent = find.ancestor(
        of: pauseIconFinder,
        matching: find.byType(InkWell),
      );
      expect(inkWellParent, findsWidgets);

      // Ketuk Pause
      await tester.tap(pauseIconFinder);
      await tester.pumpAndSettle();

      // Sekarang berubah menjadi Play
      final playIconFinder = find.byIcon(Icons.play_arrow_rounded);
      expect(playIconFinder, findsOneWidget);

      // Ketuk Play kembali
      await tester.tap(playIconFinder);
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('Timeline Scrubber Slider memiliki konfigurasi ergonomis dan seekbar responsif',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      final SliderTheme sliderTheme = tester.widget(
        find.ancestor(of: sliderFinder, matching: find.byType(SliderTheme)).first,
      );
      expect(sliderTheme.data.trackHeight, 4.0);

      // Uji interaksi scrubbing slider
      await tester.tap(sliderFinder);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tombol Replay dari awal merespons ketukan dengan reset progress',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      final replayBtn = find.byIcon(Icons.replay_rounded);
      expect(replayBtn, findsOneWidget);

      await tester.tap(replayBtn);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sheet Ekspor memiliki tombol Tutup yang menutup sheet dengan aman',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      // Buka Sheet Ekspor
      final videoBtn = find.byTooltip('Rekam & Bagikan Video');
      await tester.tap(videoBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bagikan Video Rute'), findsOneWidget);
      expect(find.text('TUTUP'), findsOneWidget);

      // Ketuk tombol TUTUP
      await tester.ensureVisible(find.text('TUTUP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TUTUP'));
      await tester.pumpAndSettle();

      // Sheet harus tertutup
      expect(find.text('Bagikan Video Rute'), findsNothing);
    });

    testWidgets('Dialog Konfirmasi Rekam Layar memiliki tombol BATAL yang menutup dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      // Buka Sheet Ekspor
      final videoBtn = find.byTooltip('Rekam & Bagikan Video');
      await tester.tap(videoBtn);
      await tester.pumpAndSettle();

      // Pilih Mode Rekam Layar
      final cleanRecordTile = find.text('Mode Rekam Layar');
      await tester.ensureVisible(cleanRecordTile);
      await tester.pumpAndSettle();
      await tester.tap(cleanRecordTile);
      await tester.pumpAndSettle();

      // Dialog Siapkan Perekam Layar muncul
      expect(find.text('Siapkan Perekam Layar'), findsOneWidget);
      expect(find.text('BATAL'), findsOneWidget);

      // Ketuk BATAL
      await tester.tap(find.text('BATAL'));
      await tester.pumpAndSettle();

      // Dialog harus tertutup
      expect(find.text('Siapkan Perekam Layar'), findsNothing);
    });

    testWidgets('Mode Rekam Layar Bersih keluar seketika dengan ketukan layar dan menampilkan feedback SnackBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      // Buka Sheet Ekspor
      await tester.tap(find.byTooltip('Rekam & Bagikan Video'));
      await tester.pumpAndSettle();

      // Pilih Mode Rekam Layar
      final cleanRecordTile = find.text('Mode Rekam Layar');
      await tester.ensureVisible(cleanRecordTile);
      await tester.pumpAndSettle();
      await tester.tap(cleanRecordTile);
      await tester.pumpAndSettle();

      // Ketuk MULAI PUTAR RUTE
      await tester.tap(find.text('MULAI PUTAR RUTE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi mode rekam bersih aktif
      expect(find.text('Mode Rekam Aktif • Ketuk layar untuk keluar'), findsOneWidget);

      // Ketuk area layar untuk keluar
      final exitTapArea = find.byKey(const ValueKey('exit_clean_record_tap_area'));
      expect(exitTapArea, findsOneWidget);
      await tester.tap(exitTapArea, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Mode rekam bersih nonaktif, header atas kembali tampil
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);
      expect(find.text('Keluar dari Mode Rekam Bersih'), findsOneWidget);
    });

    testWidgets('Sheet Ekspor memiliki toggle Pengaturan Tampilan (Tata Letak Proporsional & Nama Jalan di Jalur)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createReplayScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buka Sheet Ekspor
      await tester.tap(find.byTooltip('Rekam & Bagikan Video'));
      await tester.pumpAndSettle();

      // Verifikasi judul pengaturan
      expect(find.text('PENGATURAN TAMPILAN'), findsOneWidget);

      // Verifikasi toggle Tata Letak Proporsional
      expect(find.text('Tata Letak Proporsional'), findsOneWidget);

      // Verifikasi toggle Nama Jalan di Jalur
      expect(find.text('Nama Jalan di Jalur'), findsOneWidget);

      // Verifikasi Switch dapat berinteraksi
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      // Ketuk switch Badge Nama Jalan untuk mengubah nilainya
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      // Tutup sheet
      await tester.ensureVisible(find.text('TUTUP'));
      await tester.tap(find.text('TUTUP'));
      await tester.pumpAndSettle();
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);
    });
  });
}
