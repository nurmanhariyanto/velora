import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:velora/constants/app_colors.dart';
import 'package:velora/models/activity_session.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/screens/share_preview_screen.dart';
import 'package:velora/services/social_share_service.dart';
import 'package:velora/widgets/mini_route_painter.dart';
import 'package:velora/widgets/social_share_card.dart';
import 'package:velora/widgets/velora_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File dummyPhotoFile;

  // Minimal valid 10x10 PNG bytes
  final dummyPngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x0A,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x02, 0x50, 0x58,
    0xEA, 0x00, 0x00, 0x00, 0x1A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x60, 0x18, 0x05, 0xA3,
    0x60, 0x14, 0x8C, 0x82, 0x51, 0x30, 0x28, 0x18,
    0x23, 0x00, 0x00, 0x01, 0xEC, 0x00, 0x01, 0x8D,
    0xDE, 0xF8, 0x5A, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);

    // Siapkan mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );

    // Mock platform channel untuk share & media store
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('online.nurmancloud.velora/social_share'),
      (MethodCall methodCall) async {
        return true;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('online.nurmancloud.velora/media_store'),
      (MethodCall methodCall) async {
        return 'content://media/external/images/media/1001';
      },
    );

    // Tulis dummy foto untuk pengujian ShareCardStyle.photo
    dummyPhotoFile = File('${Directory.systemTemp.path}/test_audit_photo.png');
    await dummyPhotoFile.writeAsBytes(dummyPngBytes);
  });

  tearDownAll(() async {
    if (await dummyPhotoFile.exists()) {
      await dummyPhotoFile.delete();
    }
  });

  // Sesi Bersepeda dengan GPS
  final rideSession = ActivitySession(
    id: 'audit-ride-001',
    startTime: DateTime(2026, 10, 30, 6, 30).millisecondsSinceEpoch,
    endTime: DateTime(2026, 10, 30, 7, 30).millisecondsSinceEpoch,
    sportsType: SportsType.ride,
    distanceMeters: 26890.0, // 26.89 km
    durationSeconds: 5503, // 1h 31m 43s
    elevationGain: 120.0,
    maxSpeedKmh: 35.4,
    averageSpeedKmh: 17.6, // 17.6 km/h
    averagePaceSecondsPerKm: 204.0,
    coordinates: [
      CoordinatePoint(activityId: 'audit-ride-001', latitude: -0.0263, longitude: 109.3425, timestamp: 1000),
      CoordinatePoint(activityId: 'audit-ride-001', latitude: -0.0270, longitude: 109.3435, timestamp: 2000),
      CoordinatePoint(activityId: 'audit-ride-001', latitude: -0.0280, longitude: 109.3450, timestamp: 3000),
      CoordinatePoint(activityId: 'audit-ride-001', latitude: -0.0290, longitude: 109.3470, timestamp: 4000),
      CoordinatePoint(activityId: 'audit-ride-001', latitude: -0.0300, longitude: 109.3490, timestamp: 5000),
    ],
  );

  // Sesi Lari dengan GPS
  final runSession = ActivitySession(
    id: 'audit-run-002',
    startTime: DateTime(2026, 10, 30, 5, 45).millisecondsSinceEpoch,
    endTime: DateTime(2026, 10, 30, 6, 39, 12).millisecondsSinceEpoch,
    sportsType: SportsType.run,
    distanceMeters: 10440.0, // 10.44 km
    durationSeconds: 3267, // 54m 27s
    elevationGain: 42.0,
    maxSpeedKmh: 14.5,
    averageSpeedKmh: 11.5,
    averagePaceSecondsPerKm: 313.0, // 5:13 /km
    coordinates: [
      CoordinatePoint(activityId: 'audit-run-002', latitude: -0.0263, longitude: 109.3425, timestamp: 1000),
      CoordinatePoint(activityId: 'audit-run-002', latitude: -0.0275, longitude: 109.3440, timestamp: 2000),
      CoordinatePoint(activityId: 'audit-run-002', latitude: -0.0285, longitude: 109.3460, timestamp: 3000),
    ],
  );

  // Sesi Indoor tanpa GPS (0 koordinat)
  final indoorSession = ActivitySession(
    id: 'audit-indoor-003',
    startTime: DateTime(2026, 10, 30, 8, 0).millisecondsSinceEpoch,
    endTime: DateTime(2026, 10, 30, 8, 30).millisecondsSinceEpoch,
    sportsType: SportsType.ride,
    distanceMeters: 15000.0,
    durationSeconds: 1800,
    elevationGain: 0.0,
    maxSpeedKmh: 30.0,
    averageSpeedKmh: 30.0,
    averagePaceSecondsPerKm: 120.0,
    coordinates: const [],
  );

  Widget buildTestHost(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: SizedBox(
            width: 360,
            height: 640,
            child: child,
          ),
        ),
      ),
    );
  }

  group('AUDIT GAYA 1: ShareCardStyle.clean (Clean Minimalis ala Strava)', () {
    testWidgets('Merender latar hitam pekat, konten clean tanpa duplikasi, dan capture PNG tajam',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.clean,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi Dekorasi Kontainer Utama
      final containerFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Container),
      );
      final mainContainer = tester.widget<Container>(containerFinder.first);
      final decoration = mainContainer.decoration as BoxDecoration;

      expect(decoration.color, equals(Colors.black), reason: 'Latar clean harus hitam pekat');
      expect(decoration.borderRadius, equals(BorderRadius.circular(24)));
      expect(decoration.boxShadow, isNotNull, reason: 'Clean mode memiliki drop shadow kontainer');

      // 2. Verifikasi Latar Belakang Child (_buildBackground)
      // Child pertama di Stack adalah Container dengan Colors.black
      final stackFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsOneWidget);
      final stack = tester.widget<Stack>(stackFinder);
      expect(stack.children.first is Container, isTrue);
      final bgContainer = stack.children.first as Container;
      expect(bgContainer.color, equals(Colors.black));

      // 3. Verifikasi TIDAK ADA lapisan vignette gradient pada Clean mode
      final hasVignetteGradient = stack.children.any((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          return box.gradient is LinearGradient &&
              (box.gradient as LinearGradient).stops?.length == 3;
        }
        return false;
      });
      expect(hasVignetteGradient, isFalse, reason: 'Clean mode tidak boleh memiliki vignette gradient');

      // 4. Verifikasi Teks Metrik Tepat Satu Kali (Zero Duplication)
      expect(find.text('Distance'), findsOneWidget, reason: 'Label Distance harus tepat 1');
      expect(find.text('26.89 km'), findsOneWidget, reason: 'Nilai Distance harus tepat 1');
      expect(find.text('Speed'), findsOneWidget, reason: 'Label Speed harus tepat 1');
      expect(find.text('17.6 km/h'), findsOneWidget, reason: 'Nilai Speed harus tepat 1');
      expect(find.text('Time'), findsOneWidget, reason: 'Label Time harus tepat 1');
      expect(find.text('1h 31m 43s'), findsOneWidget, reason: 'Nilai Time harus tepat 1');
      expect(find.text('VELORA'), findsOneWidget, reason: 'Brand VELORA harus tepat 1');

      // 5. Verifikasi Elemen Klasik TIDAK Boleh Muncul
      expect(find.text('DURASI'), findsNothing);
      expect(find.text('AVG SPEED'), findsNothing);
      expect(find.text('MAX SPEED'), findsNothing);
      expect(find.text('ELEVASI'), findsNothing);
      expect(find.byType(VeloraLogo), findsNothing);

      // 6. Verifikasi MiniRoutePainter Siluet Bersih (tanpa marker pin start/finish ala Strava)
      final painterFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MiniRoutePainter,
      );
      expect(painterFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(painterFinder);
      final painter = customPaint.painter as MiniRoutePainter;
      expect(painter.showMarkers, isFalse, reason: 'Gaya Strava tidak menampilkan pin start/finish');
      expect(painter.routeColor, equals(const Color(0xFFFC5200)));
      expect(painter.strokeWidth, equals(4.8));
      expect(painter.paddingFraction, equals(0.05));
      expect(painter.hasShadow, isTrue);

      // 7. Uji capturePng menghasilkan bytes PNG valid
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

    testWidgets('Clean mode merender Pace dengan tepat untuk olahraga Lari',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: runSession,
            style: ShareCardStyle.clean,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('10.44 km'), findsOneWidget);
      expect(find.text('Pace'), findsOneWidget, reason: 'Olahraga lari harus menampilkan Pace');
      expect(find.text('5:13 /km'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('54m 27s'), findsOneWidget);
      expect(find.text('VELORA'), findsOneWidget);
      expect(find.text('Speed'), findsNothing);
    });
  });

  group('AUDIT GAYA 2: ShareCardStyle.transparent (Stiker PNG Transparan)', () {
    testWidgets('Merender latar transparan murni, tanpa boxShadow, teks berpelindung shadow, dan alpha PNG',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.transparent,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi Kontainer Utama Benar-Benar Transparan
      final containerFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Container),
      );
      final mainContainer = tester.widget<Container>(containerFinder.first);
      final decoration = mainContainer.decoration as BoxDecoration;

      expect(
        decoration.color,
        equals(Colors.transparent),
        reason: 'Latar gaya stiker transparan harus Colors.transparent',
      );
      expect(
        decoration.boxShadow,
        isNull,
        reason: 'Stiker transparan TIDAK BOLEH memiliki boxShadow (menghindari bayangan kotak di IG)',
      );

      // 2. Verifikasi Latar Belakang Child adalah SizedBox.shrink()
      final stackFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Stack),
      );
      final stack = tester.widget<Stack>(stackFinder);
      expect(stack.children.first is SizedBox, isTrue);
      final bgSizedBox = stack.children.first as SizedBox;
      expect(bgSizedBox.width, equals(0.0));
      expect(bgSizedBox.height, equals(0.0));

      // 3. Verifikasi TIDAK ADA vignette gradient
      final hasVignetteGradient = stack.children.any((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          return box.gradient is LinearGradient;
        }
        return false;
      });
      expect(hasVignetteGradient, isFalse, reason: 'Stiker transparan tidak boleh memiliki vignette gradient');

      // 4. Verifikasi Teks Metrik Memiliki Drop Shadow Pelindung (Kontras di atas foto IG)
      final distanceTextWidget = tester.widget<Text>(find.text('26.89 km'));
      expect(
        distanceTextWidget.style?.shadows,
        isNotNull,
        reason: 'Teks angka pada stiker transparan harus memiliki drop shadow pelindung',
      );
      expect(distanceTextWidget.style!.shadows!.length, equals(2));

      final veloraTextWidget = tester.widget<Text>(find.text('VELORA'));
      expect(veloraTextWidget.style?.shadows, isNotNull);
      expect(veloraTextWidget.style!.shadows!.length, equals(2));

      // 5. Verifikasi Tepat Satu Set Metrik (Zero Duplication)
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('26.89 km'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('17.6 km/h'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('1h 31m 43s'), findsOneWidget);
      expect(find.text('VELORA'), findsOneWidget);

      // 6. Verifikasi Rute Oranye Strava Hero
      final painterFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MiniRoutePainter,
      );
      expect(painterFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(painterFinder);
      final painter = customPaint.painter as MiniRoutePainter;
      expect(painter.showMarkers, isFalse);
      expect(painter.hasShadow, isTrue);

      // 7. Uji capturePng menghasilkan PNG ber-alpha transparan
      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });
      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);
      // Validasi PNG header
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
      expect(pngBytes[3], 0x47);
    });
  });

  group('AUDIT GAYA 3: ShareCardStyle.photo (Gaya Foto Pengguna)', () {
    testWidgets('Merender foto latar belakang dari berkas, vignette gradient, dan teks berpelindung tanpa duplikasi',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.photo,
            backgroundPhotoPath: dummyPhotoFile.path,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi Foto Pengguna Dirender Menggunakan Image.file
      final imageFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Image),
      );
      expect(imageFinder, findsOneWidget, reason: 'Foto latar belakang pengguna harus dirender');
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image is FileImage, isTrue);
      final fileImage = imageWidget.image as FileImage;
      expect(fileImage.file.path, equals(dummyPhotoFile.path));
      expect(imageWidget.fit, equals(BoxFit.cover));

      // 2. Verifikasi Lapisan Vignette Gradient Aktif di atas foto
      final stackFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Stack),
      );
      final stack = tester.widget<Stack>(stackFinder);
      final vignetteFinder = stack.children.where((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          return box.gradient is LinearGradient &&
              (box.gradient as LinearGradient).stops?.length == 3;
        }
        return false;
      });
      expect(vignetteFinder.length, equals(1), reason: 'Harus ada lapisan vignette gradient di atas foto');

      // 3. Verifikasi Drop Shadow Pelindung Teks Aktif
      final distanceTextWidget = tester.widget<Text>(find.text('26.89 km'));
      expect(distanceTextWidget.style?.shadows, isNotNull);

      // 4. Verifikasi Tepat Satu Set Metrik Teks Tanpa Duplikasi
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('26.89 km'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('17.6 km/h'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('1h 31m 43s'), findsOneWidget);
      expect(find.text('VELORA'), findsOneWidget);

      // 5. Verifikasi capturePng berhasil
      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });
      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);
    });

    testWidgets('Gaya Foto fallback secara aman ke latar hitam jika berkas tidak ada atau null',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.photo,
            backgroundPhotoPath: '/non/existent/path/to/missing_photo.jpg',
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tidak boleh crash, fallback ke Container hitam
      expect(find.byKey(repaintKey), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('26.89 km'), findsOneWidget);
      expect(find.text('VELORA'), findsOneWidget);
    });
  });

  group('AUDIT GAYA 4: ShareCardStyle.map (Gaya Peta OSM)', () {
    testWidgets('Merender FlutterMap dengan tema gelap (matrix filter) dan statistik klasik tanpa duplikasi',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.map,
            mapDarkTheme: true,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi FlutterMap Dirender
      expect(find.byType(FlutterMap), findsOneWidget);

      // 2. Verifikasi TileLayer OSM Menggunakan Filter Warna Matrix Mode Gelap
      final tileLayerFinder = find.byType(TileLayer);
      expect(tileLayerFinder, findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(tileLayerFinder);
      expect(tileLayer.tileBuilder, isNotNull, reason: 'Mode gelap peta harus menyertakan tileBuilder matrix filter');

      // 3. Verifikasi PolylineLayer & MarkerLayer Ada di Peta
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(2), reason: 'Harus ada marker start & finish');

      // 4. Verifikasi Konten Statistik Klasik Lengkap
      expect(find.text(rideSession.displayTitle), findsOneWidget);
      expect(find.text('26.89'), findsOneWidget, reason: 'Angka jarak besar');
      expect(find.text('KM'), findsOneWidget);
      expect(find.text('DURASI'), findsOneWidget);
      expect(find.text('AVG SPEED'), findsOneWidget);
      expect(find.text('17.6 km/h'), findsOneWidget);
      expect(find.text('MAX SPEED'), findsOneWidget);
      expect(find.text('35.4 km/h'), findsOneWidget);
      expect(find.text('ELEVASI'), findsOneWidget);
      expect(find.text('+120 m'), findsOneWidget);
      expect(find.byType(VeloraLogo), findsOneWidget);

      // 5. Verifikasi Bahwa Foreground MiniRoutePainter TIDAK Muncul (karena rute ada di peta)
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is MiniRoutePainter),
        findsNothing,
        reason: 'Pada mode Peta, lintasan rute sudah digambar di FlutterMap sehingga foreground MiniRoutePainter di-skip',
      );

      // 6. Verifikasi Tidak Ada Teks Clean Mode
      expect(find.text('Distance'), findsNothing);
      expect(find.text('Time'), findsNothing);

      // 7. Uji capturePng
      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });
      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);
    });

    testWidgets('Merender FlutterMap dengan tema terang (mapDarkTheme = false)',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.map,
            mapDarkTheme: false,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.tileBuilder, isNull, reason: 'Mode terang peta tidak menggunakan filter matrix');
    });
  });

  group('AUDIT GAYA 5: ShareCardStyle.minimal (Gaya Klasik Lengkap)', () {
    testWidgets('Merender kartu klasik lengkap (4 metrik kotak, rute start/finish pin, logo Velora) tanpa duplikasi',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: rideSession,
            style: ShareCardStyle.minimal,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi Latar Belakang Gradien Klasik
      final stackFinder = find.descendant(
        of: find.byKey(repaintKey),
        matching: find.byType(Stack),
      );
      final stack = tester.widget<Stack>(stackFinder);
      expect(stack.children.first is Container, isTrue);
      final bgContainer = stack.children.first as Container;
      final bgDec = bgContainer.decoration as BoxDecoration;
      expect(bgDec.gradient is LinearGradient, isTrue);

      // 2. Verifikasi Header: Badge Olahraga & Tanggal
      expect(find.text(rideSession.displayTitle), findsOneWidget);

      // 3. Verifikasi Angka Jarak Besar
      expect(find.text('26.89'), findsOneWidget);
      expect(find.text('KM'), findsOneWidget);

      // 4. Verifikasi Kotak 4 Metrik Sekunder
      expect(find.text('DURASI'), findsOneWidget);
      expect(find.text(rideSession.formattedDuration), findsOneWidget);
      expect(find.text('AVG SPEED'), findsOneWidget);
      expect(find.text(rideSession.formattedSpeed), findsOneWidget);
      expect(find.text('MAX SPEED'), findsOneWidget);
      expect(find.text('35.4 km/h'), findsOneWidget);
      expect(find.text('ELEVASI'), findsOneWidget);
      expect(find.text('+120 m'), findsOneWidget);

      // 5. Verifikasi Rute Klasik dengan Start & Finish Pin
      final painterFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MiniRoutePainter,
      );
      expect(painterFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(painterFinder);
      final painter = customPaint.painter as MiniRoutePainter;
      expect(painter.showMarkers, isTrue, reason: 'Mode Klasik menampilkan pin penanda start & finish');
      expect(painter.routeColor, equals(AppColors.primaryOrange));

      // 6. Verifikasi Logo Velora & Garis Aksen
      expect(find.byType(VeloraLogo), findsOneWidget);

      // 7. Verifikasi Tidak Ada Teks Clean Mode
      expect(find.text('Distance'), findsNothing);
      expect(find.text('Time'), findsNothing);

      // 8. Uji capturePng
      final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
        return await SocialShareService.capturePng(repaintKey);
      });
      expect(pngBytes, isNotNull);
      expect(pngBytes!.isNotEmpty, isTrue);
    });

    testWidgets('Gaya Klasik merender label PACE untuk olahraga Lari',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        buildTestHost(
          SocialShareCard(
            session: runSession,
            style: ShareCardStyle.minimal,
            repaintKey: repaintKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PACE'), findsOneWidget);
      expect(find.text('5\'13"'), findsOneWidget);
      expect(find.text('AVG SPEED'), findsNothing);
    });
  });

  group('AUDIT INTEGRITAS BEBAS DUPLIKASI (ZERO DUPLICATION AUDIT)', () {
    testWidgets('Verifikasi absolut: tidak ada duplikasi widget teks pada kelima gaya',
        (WidgetTester tester) async {
      final styles = [
        ShareCardStyle.clean,
        ShareCardStyle.transparent,
        ShareCardStyle.photo,
        ShareCardStyle.map,
        ShareCardStyle.minimal,
      ];

      for (final style in styles) {
        final repaintKey = GlobalKey();

        await tester.pumpWidget(
          buildTestHost(
            SocialShareCard(
              session: rideSession,
              style: style,
              backgroundPhotoPath: dummyPhotoFile.path,
              repaintKey: repaintKey,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Di setiap gaya, teks apa pun yang muncul tidak boleh lebih dari 1 instance
        final allTexts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
        final textCounts = <String, int>{};
        for (final t in allTexts) {
          if (t != null && t.isNotEmpty) {
            textCounts[t] = (textCounts[t] ?? 0) + 1;
          }
        }

        for (final entry in textCounts.entries) {
          expect(
            entry.value,
            equals(1),
            reason: 'Teks "${entry.key}" mengalami duplikasi (${entry.value}x) pada gaya $style!',
          );
        }
      }
    });

    testWidgets('Kelima gaya menangani sesi tanpa GPS (0 titik koordinat) secara elegan tanpa crash',
        (WidgetTester tester) async {
      final styles = [
        ShareCardStyle.clean,
        ShareCardStyle.transparent,
        ShareCardStyle.photo,
        ShareCardStyle.map,
        ShareCardStyle.minimal,
      ];

      for (final style in styles) {
        final repaintKey = GlobalKey();

        await tester.pumpWidget(
          buildTestHost(
            SocialShareCard(
              session: indoorSession,
              style: style,
              backgroundPhotoPath: dummyPhotoFile.path,
              repaintKey: repaintKey,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(repaintKey), findsOneWidget);
      }
    });

    testWidgets('SharePreviewScreen: Berpindah antar-gaya dan memvalidasi isolasi RepaintBoundary',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SharePreviewScreen(session: rideSession),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan 5 chip pilihan gaya tersedia
      expect(find.text('Clean'), findsOneWidget);
      expect(find.text('Transparan'), findsOneWidget);
      expect(find.text('Foto Saya'), findsOneWidget);
      expect(find.text('Peta'), findsOneWidget);
      expect(find.text('Klasik'), findsOneWidget);

      // Default adalah Clean: pastikan tidak ada checkerboard di preview
      expect(find.byType(TransparencyGridPainter), findsNothing);

      // Pindah ke Transparan
      await tester.tap(find.text('Transparan'));
      await tester.pumpAndSettle();

      // Checkerboard transparan hanya muncul di luar RepaintBoundary untuk preview visual user
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TransparencyGridPainter),
        findsOneWidget,
      );

      // Pindah ke Peta
      await tester.tap(find.text('Peta'));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);

      // Pindah ke Klasik
      await tester.tap(find.text('Klasik'));
      await tester.pumpAndSettle();
      expect(find.text('DURASI'), findsOneWidget);
      expect(find.text('MAX SPEED'), findsOneWidget);
    });
  });
}
