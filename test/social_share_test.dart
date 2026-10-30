import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/services/social_share_service.dart';
import 'package:velora/screens/share_preview_screen.dart';
import 'package:velora/widgets/mini_route_painter.dart';
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

    // Mock media channel for saveImageToGallery
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('velora/media_channel'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveImageToGallery') {
          return 'content://media/external/images/media/999';
        }
        return null;
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
    test('Formatters formatCleanPace dan formatCleanDuration menangani edge cases dengan aman', () {
      // Test formatCleanPace
      expect(SocialShareCard.formatCleanPace(313.0), '5:13 /km');
      expect(SocialShareCard.formatCleanPace(59.8), '1:00 /km'); // Rounding safely to 1:00 instead of 0:60
      expect(SocialShareCard.formatCleanPace(0), '--:-- /km');
      expect(SocialShareCard.formatCleanPace(-10), '--:-- /km');
      expect(SocialShareCard.formatCleanPace(3601), '--:-- /km');
      expect(SocialShareCard.formatCleanPace(double.nan), '--:-- /km');

      // Test formatCleanDuration
      expect(SocialShareCard.formatCleanDuration(3267), '54m 27s');
      expect(SocialShareCard.formatCleanDuration(3600), '1h 0m 0s');
      expect(SocialShareCard.formatCleanDuration(4335), '1h 12m 15s');
      expect(SocialShareCard.formatCleanDuration(0), '0m 0s');
      expect(SocialShareCard.formatCleanDuration(-5), '0m 0s');
    });
    testWidgets('Merender SocialShareCard gaya Clean Minimalis (Strava Style) dan menguji capturePng',
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
                  style: ShareCardStyle.clean,
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
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('25.40 km'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('25.4 km/h'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('1h 0m 0s'), findsOneWidget);
      expect(find.text('VELORA'), findsOneWidget);

      // Uji penangkapan PNG dari RepaintBoundary
      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });

      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);

      // Verifikasi Magic Header PNG: 0x89 0x50 0x4E 0x47
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
      expect(pngBytes[3], 0x47);
    });

    testWidgets('Merender SocialShareCard gaya Clean untuk aktivitas Lari (Run - Strava Style)',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      final runSession = ActivitySession(
        id: 'test-run-101',
        startTime: DateTime(2026, 10, 17, 6, 0).millisecondsSinceEpoch,
        endTime: DateTime(2026, 10, 17, 6, 54, 27).millisecondsSinceEpoch,
        sportsType: SportsType.run,
        distanceMeters: 10440.0,
        durationSeconds: 3267, // 54m 27s
        elevationGain: 45.0,
        maxSpeedKmh: 14.5,
        averageSpeedKmh: 11.5,
        averagePaceSecondsPerKm: 313.0, // 5:13 /km
        coordinates: [
          CoordinatePoint(activityId: 'test-run-101', latitude: -0.0263, longitude: 109.3425, timestamp: 1000),
          CoordinatePoint(activityId: 'test-run-101', latitude: -0.0270, longitude: 109.3435, timestamp: 2000),
          CoordinatePoint(activityId: 'test-run-101', latitude: -0.0280, longitude: 109.3450, timestamp: 3000),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: SocialShareCard(
                  session: runSession,
                  style: ShareCardStyle.clean,
                  repaintKey: repaintKey,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(repaintKey), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('10.44 km'), findsOneWidget);
      expect(find.text('Pace'), findsOneWidget);
      expect(find.text('5:13 /km'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('54m 27s'), findsOneWidget);
      expect(find.text('VELORA'), findsOneWidget);
    });

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

    group('Formula formatCleanPace & formatCleanDuration Unit Tests', () {
      test('formatCleanPace mengonversi pace normal dengan benar', () {
        expect(SocialShareCard.formatCleanPace(313.0), equals('5:13 /km'));
        expect(SocialShareCard.formatCleanPace(300.0), equals('5:00 /km'));
        expect(SocialShareCard.formatCleanPace(359.0), equals('5:59 /km'));
      });

      test('formatCleanPace menangani pembulatan detik ke 60 (mencegah format waktu anomali 5:60 /km)', () {
        // Kasus 359.8 detik (5 menit 59.8 detik) harus dibulatkan ke 6:00 /km, bukan 5:60 /km
        expect(SocialShareCard.formatCleanPace(359.8), equals('6:00 /km'));
        // Kasus 59.9 detik harus menjadi 1:00 /km, bukan 0:60 /km
        expect(SocialShareCard.formatCleanPace(59.9), equals('1:00 /km'));
        // Kasus 3599.6 detik harus dibulatkan ke 60:00 /km, bukan 59:60 /km
        expect(SocialShareCard.formatCleanPace(3599.6), equals('60:00 /km'));
      });

      test('formatCleanPace menangani batas ekstrem, NaN, Infinity, dan angka negatif tanpa crash', () {
        expect(SocialShareCard.formatCleanPace(double.nan), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(double.infinity), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(-double.infinity), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(0.0), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(0.2), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(-10.0), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(3600.5), equals('--:-- /km'));
        expect(SocialShareCard.formatCleanPace(5000.0), equals('--:-- /km'));
      });

      test('formatCleanDuration memformat durasi waktu bersih dengan benar', () {
        expect(SocialShareCard.formatCleanDuration(0), equals('0m 0s'));
        expect(SocialShareCard.formatCleanDuration(-15), equals('0m 0s'));
        expect(SocialShareCard.formatCleanDuration(45), equals('0m 45s'));
        expect(SocialShareCard.formatCleanDuration(3267), equals('54m 27s'));
        expect(SocialShareCard.formatCleanDuration(3600), equals('1h 0m 0s'));
        expect(SocialShareCard.formatCleanDuration(7325), equals('2h 2m 5s'));
      });

      test('ActivitySession.formattedPace menangani NaN dan pembulatan detik 60 secara aman', () {
        final sessionEdge = ActivitySession(
          id: 'edge-pace',
          startTime: 1000,
          endTime: 2000,
          sportsType: SportsType.run,
          distanceMeters: 5000,
          durationSeconds: 1800,
          elevationGain: 0,
          maxSpeedKmh: 12.0,
          averageSpeedKmh: 10.0,
          averagePaceSecondsPerKm: 359.8,
        );
        expect(sessionEdge.formattedPace, equals("6'00\""));

        final sessionNaN = ActivitySession(
          id: 'nan-pace',
          startTime: 1000,
          endTime: 2000,
          sportsType: SportsType.run,
          distanceMeters: 5000,
          durationSeconds: 1800,
          elevationGain: 0,
          maxSpeedKmh: 12.0,
          averageSpeedKmh: 10.0,
          averagePaceSecondsPerKm: double.nan,
        );
        expect(sessionNaN.formattedPace, equals("--'--\""));
      });
    });

    group('MiniRoutePainter Unit & Canvas Scaling Tests', () {
      test('MiniRoutePainter merender kanvas dengan aman ketika titik koordinat < 2', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 200);

        // Kasus 0 titik
        final painterEmpty = MiniRoutePainter(coordinates: const []);
        expect(() => painterEmpty.paint(canvas, size), returnsNormally);

        // Kasus 1 titik
        final painterSingle = MiniRoutePainter(
          coordinates: [
            CoordinatePoint(activityId: 't1', latitude: -0.02, longitude: 109.34, timestamp: 1000),
          ],
        );
        expect(() => painterSingle.paint(canvas, size), returnsNormally);
      });

      test('MiniRoutePainter menangani rute lurus horizontal (East-West) tanpa distorsi skala', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 200);

        final horizontalPoints = [
          CoordinatePoint(activityId: 't2', latitude: -0.0263, longitude: 109.3000, timestamp: 1000),
          CoordinatePoint(activityId: 't2', latitude: -0.0263, longitude: 109.3500, timestamp: 2000),
        ];

        final painter = MiniRoutePainter(coordinates: horizontalPoints);
        expect(() => painter.paint(canvas, size), returnsNormally);
      });

      test('MiniRoutePainter menangani rute lurus vertikal (North-South) tanpa distorsi skala', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 200);

        final verticalPoints = [
          CoordinatePoint(activityId: 't3', latitude: -0.0200, longitude: 109.3425, timestamp: 1000),
          CoordinatePoint(activityId: 't3', latitude: -0.0800, longitude: 109.3425, timestamp: 2000),
        ];

        final painter = MiniRoutePainter(coordinates: verticalPoints);
        expect(() => painter.paint(canvas, size), returnsNormally);
      });

      test('MiniRoutePainter mengabaikan koordinat NaN dan Infinity secara aman', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 200);

        final mixedPoints = [
          CoordinatePoint(activityId: 't4', latitude: double.nan, longitude: 109.3425, timestamp: 1000),
          CoordinatePoint(activityId: 't4', latitude: -0.0200, longitude: 109.3425, timestamp: 2000),
          CoordinatePoint(activityId: 't4', latitude: -0.0250, longitude: double.infinity, timestamp: 3000),
          CoordinatePoint(activityId: 't4', latitude: -0.0300, longitude: 109.3500, timestamp: 4000),
        ];

        final painter = MiniRoutePainter(coordinates: mixedPoints);
        expect(() => painter.paint(canvas, size), returnsNormally);
      });

      test('MiniRoutePainter shouldRepaint mengecek kesetaraan atribut dengan benar', () {
        final pointsA = [
          CoordinatePoint(activityId: 't5', latitude: -0.02, longitude: 109.34, timestamp: 1000),
          CoordinatePoint(activityId: 't5', latitude: -0.03, longitude: 109.35, timestamp: 2000),
        ];
        final pointsB = [
          CoordinatePoint(activityId: 't5', latitude: -0.04, longitude: 109.36, timestamp: 3000),
          CoordinatePoint(activityId: 't5', latitude: -0.05, longitude: 109.37, timestamp: 4000),
        ];

        final p1 = MiniRoutePainter(coordinates: pointsA, routeColor: Colors.orange, strokeWidth: 3.5, showMarkers: true);
        final pSame = MiniRoutePainter(coordinates: pointsA, routeColor: Colors.orange, strokeWidth: 3.5, showMarkers: true);
        final pDiffColor = MiniRoutePainter(coordinates: pointsA, routeColor: Colors.blue, strokeWidth: 3.5, showMarkers: true);
        final pDiffStroke = MiniRoutePainter(coordinates: pointsA, routeColor: Colors.orange, strokeWidth: 5.0, showMarkers: true);
        final pDiffMarkers = MiniRoutePainter(coordinates: pointsA, routeColor: Colors.orange, strokeWidth: 3.5, showMarkers: false);
        final pDiffCoords = MiniRoutePainter(coordinates: pointsB, routeColor: Colors.orange, strokeWidth: 3.5, showMarkers: true);

        expect(p1.shouldRepaint(pSame), isFalse);
        expect(p1.shouldRepaint(pDiffColor), isTrue);
        expect(p1.shouldRepaint(pDiffStroke), isTrue);
        expect(p1.shouldRepaint(pDiffMarkers), isTrue);
        expect(p1.shouldRepaint(pDiffCoords), isTrue);
      });
    });

    group('SocialShareCard Extended Scenarios Widget Tests', () {
      testWidgets('SocialShareCard gaya Clean menangani sesi tanpa GPS (0 titik koordinat) secara anggun',
          (WidgetTester tester) async {
        final repaintKey = GlobalKey();

        final indoorSession = ActivitySession(
          id: 'test-indoor-1',
          startTime: DateTime(2026, 10, 17, 7, 0).millisecondsSinceEpoch,
          endTime: DateTime(2026, 10, 17, 7, 30).millisecondsSinceEpoch,
          sportsType: SportsType.run,
          distanceMeters: 5000.0,
          durationSeconds: 1800,
          elevationGain: 0.0,
          maxSpeedKmh: 10.0,
          averageSpeedKmh: 10.0,
          averagePaceSecondsPerKm: 360.0,
          coordinates: const [], // Tanpa koordinat GPS
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: SocialShareCard(
                    session: indoorSession,
                    style: ShareCardStyle.clean,
                    repaintKey: repaintKey,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(repaintKey), findsOneWidget);
        expect(find.text('Distance'), findsOneWidget);
        expect(find.text('5.00 km'), findsOneWidget);
        expect(find.text('Pace'), findsOneWidget);
        expect(find.text('6:00 /km'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);
        expect(find.text('30m 0s'), findsOneWidget);
        expect(find.text('VELORA'), findsOneWidget);
      });

      testWidgets('SocialShareCard gaya Foto (ShareCardStyle.photo) merender konten teks clean dengan shadow',
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
                    style: ShareCardStyle.photo,
                    backgroundPhotoPath: null, // Fallback ke hitam pekat jika foto tidak ada
                    repaintKey: repaintKey,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(repaintKey), findsOneWidget);
        expect(find.text('Distance'), findsOneWidget);
        expect(find.text('25.40 km'), findsOneWidget);
        expect(find.text('Speed'), findsOneWidget);
        expect(find.text('25.4 km/h'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);
        expect(find.text('1h 0m 0s'), findsOneWidget);
        expect(find.text('VELORA'), findsOneWidget);
      });

      testWidgets('SocialShareCard gaya Transparan (ShareCardStyle.transparent) merender teks clean dan rute hero berlatar transparan',
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
                    style: ShareCardStyle.transparent,
                    repaintKey: repaintKey,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(repaintKey), findsOneWidget);
        expect(find.text('Distance'), findsOneWidget);
        expect(find.text('25.40 km'), findsOneWidget);
        expect(find.text('Speed'), findsOneWidget);
        expect(find.text('25.4 km/h'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);
        expect(find.text('1h 0m 0s'), findsOneWidget);
        expect(find.text('VELORA'), findsOneWidget);

        // Verifikasi MiniRoutePainter menggunakan paddingFraction 0.05 dan hasShadow true
        final customPaintFinder = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MiniRoutePainter,
        );
        expect(customPaintFinder, findsOneWidget);
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        final painter = customPaint.painter as MiniRoutePainter;
        expect(painter.paddingFraction, 0.05);
        expect(painter.hasShadow, isTrue);
        expect(painter.strokeWidth, 4.8);

        // Uji penangkapan PNG transparan
        final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
          return await SocialShareService.capturePng(repaintKey);
        });

        expect(pngBytes, isNotNull);
        expect(pngBytes!.isNotEmpty, isTrue);
        expect(pngBytes[0], 0x89);
        expect(pngBytes[1], 0x50);
        expect(pngBytes[2], 0x4E);
        expect(pngBytes[3], 0x47);
      });

      test('MiniRoutePainter shouldRepaint mendeteksi perubahan paddingFraction dan hasShadow', () {
        final p1 = MiniRoutePainter(
          coordinates: dummySession.coordinates,
          paddingFraction: 0.15,
          hasShadow: false,
        );
        final p2 = MiniRoutePainter(
          coordinates: dummySession.coordinates,
          paddingFraction: 0.05,
          hasShadow: false,
        );
        final p3 = MiniRoutePainter(
          coordinates: dummySession.coordinates,
          paddingFraction: 0.05,
          hasShadow: true,
        );

        expect(p2.shouldRepaint(p1), isTrue);
        expect(p3.shouldRepaint(p2), isTrue);
        expect(p3.shouldRepaint(p3), isFalse);
      });

      testWidgets('SharePreviewScreen mendukung pemilihan gaya Transparan dan tombol SIMPAN STIKER PNG KE GALERI',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SharePreviewScreen(
              session: dummySession,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Default style adalah Clean
        expect(find.text('Clean'), findsOneWidget);
        expect(find.text('Transparan'), findsOneWidget);
        expect(find.text('Format Clean Minimalis (Strava Style)'), findsOneWidget);

        // Ketuk tab gaya Transparan
        await tester.tap(find.text('Transparan'));
        await tester.pumpAndSettle();

        // Banner info stiker transparan dan tombol Simpan Stiker PNG ke Galeri muncul
        expect(find.text('Stiker PNG Transparan (Bisa Ditempel di IG)'), findsOneWidget);
        expect(find.text('SIMPAN STIKER PNG KE GALERI'), findsOneWidget);

        // Checkerboard transparency painter aktif
        expect(
          find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TransparencyGridPainter),
          findsOneWidget,
        );
      });

      testWidgets('SocialShareService.saveImageToGallery berhasil mengeksekusi platform channel',
          (WidgetTester tester) async {
        final repaintKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: repaintKey,
                  child: Container(
                    width: 200,
                    height: 200,
                    color: Colors.transparent,
                    child: const Text('Test Sticker'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final bool success = await tester.runAsync<bool>(() async {
          return await SocialShareService.saveImageToGallery(
            repaintKey: repaintKey,
            title: 'test_sticker',
          );
        }) ?? false;

        expect(success, isTrue);
      });
    });
  });
}
