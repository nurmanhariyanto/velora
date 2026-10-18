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
      expect(find.text('Bagikan Video Flyover Rute'), findsOneWidget);
      expect(find.text('Mulai Mode Rekam Layar Bersih'), findsOneWidget);
      expect(find.text('Bagikan Berkas Video dari Galeri'), findsOneWidget);
      expect(find.text('Bagikan Kartu Ringkasan (Foto & Peta HD)'), findsOneWidget);

      // Ketuk opsi Mode Rekam Layar Bersih
      await tester.tap(find.text('Mulai Mode Rekam Layar Bersih'));
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

    testWidgets('Menangani siklus preloading tile peta dan memastikan kontrol siap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteReplayScreen(session: testSession),
        ),
      );

      // Preloading berjalan dan otomatis selesai di environment test
      await tester.pumpAndSettle();

      // Kontrol pemutaran rute siap digunakan
      expect(find.text('Gowes Pagi Flyover'), findsOneWidget);
      expect(find.text('FLYOVER REPLAY'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });
  });
}
