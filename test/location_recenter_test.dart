import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/providers/tracking_provider.dart';
import 'package:velora/widgets/live_map_view.dart';

void main() {
  group('Location & Recenter Functionality Tests', () {
    testWidgets('LiveMapView merender peta dan mengeksekusi onRecenter saat tombol pusatkan ditekan', (WidgetTester tester) async {
      bool recenterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: LiveMapView(
                coordinates: const [],
                currentLocation: const LatLng(-0.026330, 109.342504),
                sportsType: SportsType.run,
                onRecenter: () {
                  recenterCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Cari tombol Pusatkan Lokasi via tooltip
      final recenterBtn = find.byTooltip('Pusatkan Lokasi');
      expect(recenterBtn, findsOneWidget);

      // Tekan tombol pusatkan
      await tester.tap(recenterBtn);
      await tester.pump();

      expect(recenterCalled, isTrue);
    });

    testWidgets('LiveMapView tetap aman dieksekusi saat currentLocation bernilai null', (WidgetTester tester) async {
      bool recenterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: LiveMapView(
                coordinates: const [],
                currentLocation: null,
                sportsType: SportsType.run,
                onRecenter: () {
                  recenterCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final recenterBtn = find.byTooltip('Pusatkan Lokasi');
      expect(recenterBtn, findsOneWidget);

      await tester.tap(recenterBtn);
      await tester.pump();

      // onRecenter tetap terpanggil untuk memicu pencarian GPS di parent screen
      expect(recenterCalled, isTrue);
    });

    test('TrackingProvider lifecycle idle location listener dapat dijalankan dan dihentikan dengan aman', () {
      final provider = TrackingProvider();

      expect(provider.currentPosition, isNull);

      // Start listener tidak melempar exception di unit test environment
      expect(() => provider.startIdleLocationListener(), returnsNormally);
      expect(() => provider.stopIdleLocationListener(), returnsNormally);

      provider.dispose();
    });
  });
}
