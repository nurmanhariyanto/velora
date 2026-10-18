import 'dart:io';
import 'dart:typed_data';
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
      expect(find.text('MAX SPEED'), findsOneWidget);
      expect(find.text('38.5 km/h'), findsOneWidget);

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

    test('SocialShareCard.darkMatrix tidak memotong warna OSM ke hitam pekat (zero clamping)', () {
      final m = SocialShareCard.darkMatrix;
      expect(m.length, 20);

      List<int> transform(int r, int g, int b) {
        double rOut = m[0] * r + m[1] * g + m[2] * b + m[4];
        double gOut = m[5] * r + m[6] * g + m[7] * b + m[9];
        double bOut = m[10] * r + m[11] * g + m[12] * b + m[14];
        return [
          rOut.clamp(0, 255).round(),
          gOut.clamp(0, 255).round(),
          bOut.clamp(0, 255).round(),
        ];
      }

      // 1. Daratan OSM (#F2EFE9)
      final land = transform(242, 239, 233);
      expect(land[0], greaterThan(0), reason: 'Daratan R tidak boleh 0');
      expect(land[1], greaterThan(0), reason: 'Daratan G tidak boleh 0');
      expect(land[2], greaterThan(0), reason: 'Daratan B tidak boleh 0');

      // 2. Jalan Putih OSM (#FFFFFF)
      final road = transform(255, 255, 255);
      expect(road[0], greaterThan(0), reason: 'Jalan R tidak boleh 0');
      expect(road[1], greaterThan(0), reason: 'Jalan G tidak boleh 0');
      expect(road[2], greaterThan(0), reason: 'Jalan B tidak boleh 0');

      // 3. Kontras Jalan vs Daratan: Jalan harus lebih terang dari daratan
      final roadLum = 0.2126 * road[0] + 0.7152 * road[1] + 0.0722 * road[2];
      final landLum = 0.2126 * land[0] + 0.7152 * land[1] + 0.0722 * land[2];
      expect(roadLum, greaterThan(landLum), reason: 'Jalan harus lebih terang daripada daratan');

      // 4. Air OSM (#AAD3DF): Komponen biru harus dominan
      final water = transform(170, 211, 223);
      expect(water[2], greaterThan(water[0]), reason: 'Air harus memiliki rona biru (B > R)');

      // 5. Taman Hijau OSM (#CDEBB0): Harus menghasilkan warna hijau tua yang tampak
      final park = transform(205, 235, 176);
      expect(park[1], greaterThan(park[0]), reason: 'Taman harus memiliki rona hijau (G > R)');
    });

    testWidgets('Merender SocialShareCard tema Peta Terang (mapDarkTheme=false) dan menguji capturePng',
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
                  mapDarkTheme: false,
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

    testWidgets('capturePng menghasilkan resolusi tajam Full HD (>= 1080px width)',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 568,
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

      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });

      expect(pngBytes, isNotNull);
      // Header PNG: byte 16..19 adalah lebar citra (uint32 big-endian)
      final byteData = ByteData.sublistView(pngBytes!);
      final width = byteData.getUint32(16, Endian.big);
      final height = byteData.getUint32(20, Endian.big);

      expect(width, greaterThanOrEqualTo(1080), reason: 'Lebar gambar harus minimal 1080px Full HD');
      expect(height, greaterThanOrEqualTo(1900), reason: 'Tinggi gambar harus minimal 1900px Full HD');
    });

    testWidgets('Merender nama atlet kustom pada SocialShareCard',
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
                  athleteName: 'John Doe',
                  style: ShareCardStyle.minimal,
                  repaintKey: repaintKey,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('John Doe'), findsOneWidget);
      expect(find.text('MAX SPEED'), findsOneWidget);
      expect(find.text('38.5 km/h'), findsOneWidget);
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
