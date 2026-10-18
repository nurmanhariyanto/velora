import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/screens/activity_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ActivityDetailScreen Unified Share Action Tests', () {
    final startTime = DateTime(2026, 10, 18, 6, 0, 0).millisecondsSinceEpoch;
    final dummyCoords = List.generate(15, (i) {
      return CoordinatePoint(
        id: i,
        activityId: 'act-detail-test',
        latitude: -0.026330 + (i * 0.001),
        longitude: 109.342504 + (i * 0.001),
        elevation: 20.0 + (i * 1.5),
        speed: 8.0,
        timestamp: startTime + (i * 15 * 1000),
      );
    });

    final testSession = ActivitySession(
      id: 'act-detail-test',
      notes: 'Gowes Keliling Kota',
      sportsType: SportsType.ride,
      startTime: startTime,
      endTime: startTime + (300 * 1000),
      durationSeconds: 300,
      distanceMeters: 3500,
      elevationGain: 45.0,
      averageSpeedKmh: 28.0,
      maxSpeedKmh: 35.0,
      averagePaceSecondsPerKm: 128,
      coordinates: dummyCoords,
    );

    testWidgets('Tombol Bagikan membuka modal pilihan format (Poster HD & Video Flyover MP4)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailScreen(session: testSession),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi judul dan rincian utama ada di layar
      expect(find.text('Gowes Keliling Kota'), findsWidgets);
      expect(find.text('PUTAR RUTE'), findsOneWidget);
      expect(find.text('BAGIKAN'), findsOneWidget);

      // Verifikasi AppBar hanya memiliki 1 tombol ikon bagikan
      final appbarShareBtn = find.byTooltip('Bagikan Aktivitas');
      expect(appbarShareBtn, findsOneWidget);

      // Ketuk tombol BAGIKAN di bagian bawah
      await tester.tap(find.text('BAGIKAN'));
      await tester.pumpAndSettle();

      // Verifikasi bottom sheet modal muncul dengan opsi yang jelas
      expect(find.text('Bagikan Aktivitas'), findsOneWidget);
      expect(find.text('Pilih format konten yang ingin Anda bagikan ke media sosial'), findsOneWidget);
      expect(find.text('Poster Ringkasan Latihan (HD)'), findsOneWidget);
      expect(find.text('Video Flyover Rute (MP4 Sinematik)'), findsOneWidget);
      expect(find.text('Ekspor Berkas GPS (GPX)'), findsOneWidget);

      // Verifikasi label badge format
      expect(find.text('FOTO & PETA'), findsOneWidget);
      expect(find.text('VIDEO MP4'), findsOneWidget);
      expect(find.text('FILE GPX'), findsOneWidget);
    });

    testWidgets('Tombol Bagikan di AppBar juga membuka modal pilihan format yang sama',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailScreen(session: testSession),
        ),
      );

      await tester.pumpAndSettle();

      final appbarShareBtn = find.byTooltip('Bagikan Aktivitas');
      await tester.tap(appbarShareBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bagikan Aktivitas'), findsOneWidget);
      expect(find.text('Poster Ringkasan Latihan (HD)'), findsOneWidget);
      expect(find.text('Video Flyover Rute (MP4 Sinematik)'), findsOneWidget);
    });
  });
}
