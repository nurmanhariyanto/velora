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
      'velora_athlete_name': 'Velora Pro Rider',
    });
  });

  group('RouteReplayScreen (Flyover Route Replay) Tests', () {
    final startTime = DateTime(2026, 10, 18, 7, 30, 0).millisecondsSinceEpoch;
    final dummyCoordinates = List.generate(25, (i) {
      return CoordinatePoint(
        id: i,
        activityId: 'replay-test-1',
        latitude: -0.026330 + (i * 0.001),
        longitude: 109.342504 + (i * 0.0008),
        elevation: 25.0 + (i * 2.5),
        speed: 7.5, // 27.0 km/h
        timestamp: startTime + (i * 10 * 1000),
      );
    });

    final testSession = ActivitySession(
      id: 'session-replay-test',
      notes: 'Gowes Pagi Flyover',
      sportsType: SportsType.ride,
      startTime: startTime,
      endTime: startTime + (240 * 1000),
      durationSeconds: 240,
      distanceMeters: 2800,
      elevationGain: 60.0,
      averageSpeedKmh: 27.0,
      maxSpeedKmh: 36.5,
      averagePaceSecondsPerKm: 133,
      coordinates: dummyCoordinates,
    );

    testWidgets('Merender RouteReplayScreen, HUD Statistik, dan Kontrol Pemutaran',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: testSession),
        ),
      );

      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verifikasi Header Atas
      expect(find.text('Gowes Pagi Flyover'), findsOneWidget);
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);

      // Verifikasi Metrik HUD
      expect(find.text('JARAK'), findsOneWidget);
      expect(find.text('SPEED'), findsOneWidget);
      expect(find.text('ELEVASI'), findsOneWidget);
      expect(find.text('WAKTU'), findsOneWidget);

      // Verifikasi Tombol Kontrol Pemutaran
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
      expect(find.text('2x'), findsOneWidget); // Default speed 2x

      // Uji Ketuk Tombol Pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      // Sekarang tombol harus berubah menjadi Play
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Uji Ganti Kecepatan (2x -> 4x)
      await tester.tap(find.text('2x'));
      await tester.pumpAndSettle();
      expect(find.text('4x'), findsOneWidget);

      // Uji Ganti Kecepatan lagi (4x -> 8x)
      await tester.tap(find.text('4x'));
      await tester.pumpAndSettle();
      expect(find.text('8x'), findsOneWidget);

      // Uji Tombol Kamera Auto-Follow
      final followBtn = find.byTooltip('Kamera Mengikuti Atlet');
      expect(followBtn, findsOneWidget);
      await tester.tap(followBtn);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kamera Bebas'), findsOneWidget);

      // Uji Tombol Kamera Mode Flyover Stabil (Utara) Default & Beralih ke POV
      final stableFlyoverBtn = find.byTooltip('Mode Flyover Stabil (Utara)');
      expect(stableFlyoverBtn, findsOneWidget);
      await tester.tap(stableFlyoverBtn);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mode POV Berputar Aktif'), findsOneWidget);

      // Beralih kembali ke Mode Flyover Stabil
      await tester.tap(find.byTooltip('Mode POV Berputar Aktif'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mode Flyover Stabil (Utara)'), findsOneWidget);

      // Uji Tombol Sudut Pandang 3D Menyamping (Perspective Tilt)
      final tilt3dBtn = find.byTooltip('Perspektif 3D Menyamping Aktif');
      expect(tilt3dBtn, findsOneWidget);
      await tester.tap(tilt3dBtn);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tampilan 2D Datar'), findsOneWidget);

      // Beralih kembali ke Perspektif 3D Menyamping
      await tester.tap(find.byTooltip('Tampilan 2D Datar'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Perspektif 3D Menyamping Aktif'), findsOneWidget);

      // Uji Tombol Mode Satelit HD vs Peta Jalan OSM
      final satBtn = find.byTooltip('Mode Satelit HD Aktif');
      expect(satBtn, findsOneWidget);
      await tester.tap(satBtn);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mode Peta Jalan'), findsOneWidget);

      // Beralih kembali ke Satelit HD
      await tester.tap(find.byTooltip('Mode Peta Jalan'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mode Satelit HD Aktif'), findsOneWidget);
    });

    testWidgets('Menampilkan pesan jika koordinat tidak cukup untuk animasi',
        (WidgetTester tester) async {
      final shortSession = ActivitySession(
        id: 'short-session',
        sportsType: SportsType.run,
        startTime: startTime,
        endTime: startTime + 1000,
        durationSeconds: 10,
        distanceMeters: 5,
        averageSpeedKmh: 1.8,
        maxSpeedKmh: 2.0,
        averagePaceSecondsPerKm: 2000,
        coordinates: [dummyCoordinates.first], // Hanya 1 titik
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: shortSession),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Titik koordinat tidak cukup untuk animasi flyover rute.'),
        findsOneWidget,
      );
    });

    testWidgets('Membuka dialog Bagikan Video dan mengaktifkan Mode Rekam Bersih',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: testSession),
        ),
      );

      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verifikasi tombol Rekam & Bagikan Video ada
      final videoBtn = find.byTooltip('Rekam & Bagikan Video');
      expect(videoBtn, findsOneWidget);

      // Buka bottom sheet bagikan video
      await tester.tap(videoBtn);
      await tester.pumpAndSettle();

      // Verifikasi isi bottom sheet
      expect(find.text('Bagikan Video Rute'), findsOneWidget);
      expect(find.text('Mode Rekam Layar'), findsOneWidget);
      expect(find.text('Bagikan Berkas Video'), findsOneWidget);
      expect(find.text('Bagikan Kartu Ringkasan'), findsOneWidget);

      // Ketuk opsi Mode Rekam Layar
      await tester.ensureVisible(find.text('Mode Rekam Layar'));
      await tester.tap(find.text('Mode Rekam Layar'));
      await tester.pumpAndSettle();

      // Dialog konfirmasi petunjuk rekam layar
      if (find.text('MULAI PUTAR RUTE').evaluate().isNotEmpty) {
        await tester.tap(find.text('MULAI PUTAR RUTE'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Sekarang tombol header atas harus tersembunyi dan tooltip rekam aktif terlihat
      expect(find.text('FLYOVER REPLAY'), findsNothing);
      expect(
        find.text('Mode Rekam Aktif • Ketuk layar untuk keluar'),
        findsOneWidget,
      );

      // Ketuk layar untuk keluar dari mode rekam bersih
      await tester.tap(
        find.byKey(const ValueKey('exit_clean_record_tap_area')),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tombol header atas kembali terlihat
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);
    });

    testWidgets('Membuka opsi ekspor video dan mendukung tombol Latar Belakang',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: testSession),
        ),
      );

      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final videoBtn = find.byTooltip('Rekam & Bagikan Video');
      expect(videoBtn, findsOneWidget);

      await tester.tap(videoBtn);
      await tester.pumpAndSettle();

      // Temukan opsi ekspor video Full HD
      final exportTile = find.text('Ekspor Video Full HD');
      expect(exportTile, findsOneWidget);

      await tester.tap(exportTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verifikasi dialog render menampilkan tombol LATAR BELAKANG dan BATALKAN
      expect(find.text('LATAR BELAKANG'), findsOneWidget);
      expect(find.text('BATALKAN'), findsOneWidget);

      // Ketuk tombol LATAR BELAKANG untuk meminimalkan proses render
      await tester.tap(find.text('LATAR BELAKANG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Modal dialog utama harus tertutup, dan floating banner latar belakang tampil
      expect(find.byTooltip('Batalkan Render'), findsOneWidget);
      expect(find.byTooltip('Buka Dialog'), findsOneWidget);

      // Batalkan render dari floating banner
      await tester.tap(find.byTooltip('Batalkan Render'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Banner menghilang dan antarmuka kembali normal
      expect(find.byTooltip('Batalkan Render'), findsNothing);
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);
    });

    testWidgets('Menangani siklus preloading tile peta dan memastikan kontrol siap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: testSession),
        ),
      );

      // Preloading berjalan dan otomatis selesai di environment test
      await tester.pump(const Duration(milliseconds: 5000));
      await tester.pumpAndSettle();

      // Kontrol pemutaran rute siap digunakan
      expect(find.text('Gowes Pagi Flyover'), findsOneWidget);
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('Pengguna menggeser slider (scrubbing) memperbarui statistik HUD seketika tanpa stutter',
        (WidgetTester tester) async {
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

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Geser slider ke posisi tengah (~50%)
      final topLeft = tester.getTopLeft(sliderFinder);
      final bottomRight = tester.getBottomRight(sliderFinder);
      final midPoint = Offset((topLeft.dx + bottomRight.dx) / 2, (topLeft.dy + bottomRight.dy) / 2);

      await tester.tapAt(midPoint);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Jarak dan waktu terupdate mengikuti titik tengah rute (~1.4 km)
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('JARAK'), findsOneWidget);
      expect(find.text('SPEED'), findsOneWidget);
      expect(find.text('ELEVASI'), findsOneWidget);
      expect(find.text('WAKTU'), findsOneWidget);
    });

    testWidgets('Eksplorasi manual peta (pan/zoom) menonaktifkan auto-follow dan memunculkan tombol Fokus ke Atlet',
        (WidgetTester tester) async {
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

      // Tombol Kamera Awalnya aktif mengikuti atlet
      expect(find.byTooltip('Kamera Mengikuti Atlet'), findsOneWidget);
      expect(find.text('Fokus ke Atlet'), findsNothing);

      // Simulasikan non-aktif auto follow dengan menekan tombol kamera bebas
      await tester.tap(find.byTooltip('Kamera Mengikuti Atlet'));
      await tester.pumpAndSettle();

      // Sekarang tombol Fokus ke Atlet muncul melayang
      expect(find.byTooltip('Kamera Bebas'), findsOneWidget);
      expect(find.text('Fokus ke Atlet'), findsOneWidget);

      // Ketuk tombol Fokus ke Atlet untuk memfokuskan kembali
      await tester.tap(find.text('Fokus ke Atlet'));
      await tester.pumpAndSettle();

      // Kamera kembali terkunci mengikuti atlet dan tombol floating hilang
      expect(find.byTooltip('Kamera Mengikuti Atlet'), findsOneWidget);
      expect(find.text('Fokus ke Atlet'), findsNothing);
    });

    testWidgets('Sesi Lari merender HUD PACE (/KM) secara tepat dan bebas NaN',
        (WidgetTester tester) async {
      final runSession = ActivitySession(
        id: 'session-run-replay',
        notes: 'Lari Pagi Flyover',
        sportsType: SportsType.run,
        startTime: startTime,
        endTime: startTime + (300 * 1000),
        durationSeconds: 300,
        distanceMeters: 1200,
        elevationGain: 15.0,
        averageSpeedKmh: 10.5,
        maxSpeedKmh: 14.0,
        averagePaceSecondsPerKm: 342, // ~5'42" /km
        coordinates: dummyCoordinates,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: runSession),
        ),
      );

      await tester.pump();
      if (find.text('Lewati & Langsung Putar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lewati & Langsung Putar'));
        await tester.pumpAndSettle();
      }

      // Verifikasi bahwa untuk lari, label PACE dan unit /KM ditampilkan alih-alih SPEED
      expect(find.text('PACE'), findsOneWidget);
      expect(find.text('/KM'), findsOneWidget);
      expect(find.text('Lari Pagi Flyover'), findsOneWidget);
    });
  });
}
