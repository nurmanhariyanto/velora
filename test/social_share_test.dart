import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/services/social_share_service.dart';
import 'package:velora/widgets/social_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);

    // Mock path_provider method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  final dummySession = ActivitySession(
    id: 'test-session-999',
    startTime: DateTime(2026, 10, 17, 8, 30).millisecondsSinceEpoch,
    endTime: DateTime(2026, 10, 17, 9, 30).millisecondsSinceEpoch,
    sportsType: SportsType.ride,
    distanceMeters: 25400.0,
    durationSeconds: 3600,
    elevationGain: 185.0,
    maxSpeedKmh: 38.5,
    averageSpeedKmh: 25.4,
    averagePaceSecondsPerKm: 142.0,
    coordinates: [
      CoordinatePoint(activityId: 'test-session-999', latitude: -0.0263, longitude: 109.3425, timestamp: 1000),
      CoordinatePoint(activityId: 'test-session-999', latitude: -0.0270, longitude: 109.3435, timestamp: 2000),
      CoordinatePoint(activityId: 'test-session-999', latitude: -0.0280, longitude: 109.3450, timestamp: 3000),
      CoordinatePoint(activityId: 'test-session-999', latitude: -0.0290, longitude: 109.3470, timestamp: 4000),
    ],
  );

  group('SocialShareCard & SocialShareService Testing', () {
    testWidgets('Merender SocialShareCard dan menguji SocialShareService.capturePng',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: SocialShareCard(
                  session: dummySession,
                  style: ShareCardStyle.minimal,
                  repaintKey: repaintKey,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan widget terpasang dengan benar di pohon widget
      expect(find.byKey(repaintKey), findsOneWidget);
      expect(find.text('25.40'), findsOneWidget);
      expect(find.text('KM'), findsOneWidget);
      expect(find.text('Bersepeda Pagi'), findsOneWidget);

      // Uji penangkapan PNG dari RepaintBoundary
      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });

      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);

      // Verifikasi Magic Header PNG: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50); // P
      expect(pngBytes[2], 0x4E); // N
      expect(pngBytes[3], 0x47); // G
    });

    testWidgets('Merender SocialShareCard gaya Peta OSM dan menguji capturePng',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: SocialShareCard(
                  session: dummySession,
                  style: ShareCardStyle.map,
                  repaintKey: repaintKey,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(repaintKey), findsOneWidget);

      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });

      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
    });

    test('SocialShareService.saveBytesToTempFile berhasil menulis berkas PNG', () async {
      final fakePngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x01
      ]);

      final file = await SocialShareService.saveBytesToTempFile(
        fakePngBytes,
        'test_share_${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(file, isNotNull);
      expect(await file!.exists(), isTrue);
      expect(await file.readAsBytes(), equals(fakePngBytes));

      // Bersihkan file tes
      await file.delete();
    });
  });
}
