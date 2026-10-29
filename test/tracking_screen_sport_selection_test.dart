import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/providers/achievement_provider.dart';
import 'package:velora/providers/history_provider.dart';
import 'package:velora/providers/tracking_provider.dart';
import 'package:velora/screens/tracking_screen.dart';

void main() {
  Widget buildTestScreen(TrackingProvider trackingProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrackingProvider>.value(value: trackingProvider),
        ChangeNotifierProvider<HistoryProvider>(create: (_) => HistoryProvider()),
        ChangeNotifierProvider<AchievementProvider>(create: (_) => AchievementProvider()),
      ],
      child: const MaterialApp(
        home: TrackingScreen(),
      ),
    );
  }

  group('TrackingScreen Sport Selection Modal & Dynamic Metrics Tests', () {
    testWidgets('Menekan MULAI LATIHAN memunculkan badge modal pemilihan 3 jenis olahraga',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final trackingProvider = TrackingProvider();

      await tester.pumpWidget(buildTestScreen(trackingProvider));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verifikasi tombol Mulai Latihan ada di layar awal
      final startButton = find.text('MULAI LATIHAN');
      expect(startButton, findsOneWidget);

      // 2. Ketuk tombol Mulai Latihan
      await tester.tap(startButton);
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 3. Verifikasi modal sheet muncul dengan opsi Lari, Sepeda, dan Mendaki
      expect(find.text('PILIH JENIS OLAHRAGA'), findsOneWidget);
      expect(find.text('Lari (Run)'), findsOneWidget);
      expect(find.text('Sepeda (Ride)'), findsOneWidget);
      expect(find.text('Mendaki (Hike / Trekking)'), findsOneWidget);

      // 4. Pilih opsi Mendaki
      final hikeOption = find.text('Mendaki (Hike / Trekking)');
      await tester.tap(hikeOption);
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 5. Verifikasi bahwa jenis olahraga berubah menjadi Mendaki (hike)
      expect(trackingProvider.sportsType, equals(SportsType.hike));
    });

    testWidgets('TrackingScreen menampilkan metrik dinamis mendaki (ALTITUDE mdpl, ELEV GAIN, PACE)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final trackingProvider = TrackingProvider();
      trackingProvider.setSportsType(SportsType.hike);

      await tester.pumpWidget(buildTestScreen(trackingProvider));
      await tester.pump(const Duration(milliseconds: 100));

      // Verifikasi metrik dinamis khusus Mendaki (Hike)
      expect(find.text('ALTITUDE'), findsOneWidget);
      expect(find.text('mdpl'), findsOneWidget);
      expect(find.text('ELEV GAIN'), findsOneWidget);
      expect(find.text('PACE'), findsOneWidget);
      expect(find.text('/km'), findsOneWidget);
    });

    testWidgets('TrackingScreen menampilkan metrik lari (AVG PACE, ELEVASI, SPEED)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final trackingProvider = TrackingProvider();
      trackingProvider.setSportsType(SportsType.run);

      await tester.pumpWidget(buildTestScreen(trackingProvider));
      await tester.pump(const Duration(milliseconds: 100));

      // Verifikasi metrik untuk Lari (Run)
      expect(find.text('AVG PACE'), findsOneWidget);
      expect(find.text('ELEVASI'), findsOneWidget);
      expect(find.text('SPEED'), findsOneWidget);
    });

    testWidgets('TrackingScreen menampilkan metrik sepeda (AVG SPEED, ELEVASI, SPEED)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final trackingProvider = TrackingProvider();
      trackingProvider.setSportsType(SportsType.ride);

      await tester.pumpWidget(buildTestScreen(trackingProvider));
      await tester.pump(const Duration(milliseconds: 100));

      // Verifikasi metrik untuk Sepeda (Ride)
      expect(find.text('AVG SPEED'), findsOneWidget);
      expect(find.text('ELEVASI'), findsOneWidget);
      expect(find.text('SPEED'), findsOneWidget);
    });
  });
}

