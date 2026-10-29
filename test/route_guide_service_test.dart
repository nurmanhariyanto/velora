import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:velora/models/route_guide_info.dart';
import 'package:velora/services/route_guide_service.dart';

void main() {
  group('RouteGuideService (Perhitungan Jarak & Deteksi Keluar Jalur)', () {
    test('calculateDistanceToPolyline mengembalikan 0 atau mendekati 0 jika titik berada tepat di rute', () {
      final polyline = [
        const LatLng(-0.026000, 109.340000),
        const LatLng(-0.028000, 109.340000), // Garis lurus ke selatan
        const LatLng(-0.028000, 109.342000), // Belok ke timur
      ];

      // Titik uji di tengah segmen pertama
      final testPointOnRoute = const LatLng(-0.027000, 109.340000);
      final dist = RouteGuideService.calculateDistanceToPolyline(testPointOnRoute, polyline);

      expect(dist, lessThan(1.0)); // < 1 meter
    });

    test('calculateDistanceToPolyline menghitung jarak tegak lurus (perpendicular) secara akurat', () {
      final polyline = [
        const LatLng(0.000000, 109.000000),
        const LatLng(0.010000, 109.000000), // Garis utara-selatan di khatulistiwa (~1113.2 meter)
      ];

      // 1 derajat bujur di khatulistiwa ~111,320 meter
      // Geser 0.00045 derajat ke timur ~ 50.09 meter
      final userPoint = const LatLng(0.005000, 109.000450);
      final dist = RouteGuideService.calculateDistanceToPolyline(userPoint, polyline);

      expect(dist, closeTo(50.0, 1.5));
    });

    test('calculateDistanceToPolyline mengembalikan jarak ke ujung segmen jika proyeksi di luar segmen', () {
      final polyline = [
        const LatLng(-0.026000, 109.340000),
        const LatLng(-0.028000, 109.340000),
      ];

      // Titik berada jauh di sebelah utara titik awal (-0.025000)
      final userPointNorth = const LatLng(-0.025000, 109.340000);
      final dist = RouteGuideService.calculateDistanceToPolyline(userPointNorth, polyline);

      // Jarak 0.001 derajat latitude ~ 111.32 meter
      expect(dist, closeTo(111.3, 2.0));
    });

    test('calculateDistanceToPolyline menangani polylines kosong dan satu titik dengan aman', () {
      expect(
        RouteGuideService.calculateDistanceToPolyline(
          const LatLng(0, 0),
          [],
        ),
        equals(double.infinity),
      );

      final singlePoint = [const LatLng(0.000000, 109.000000)];
      final userPoint = const LatLng(0.000100, 109.000000); // ~11.13 meter
      final dist = RouteGuideService.calculateDistanceToPolyline(userPoint, singlePoint);

      expect(dist, closeTo(11.1, 1.0));
    });

    test('RouteGuideInfo.formattedDistance memformat meter dan kilometer dengan tepat', () {
      final shortRoute = RouteGuideInfo(
        name: 'Sprint 400m',
        points: const [LatLng(0, 0), LatLng(0.003, 0)],
        totalDistanceMeters: 400.0,
      );
      expect(shortRoute.formattedDistance, equals('400 m'));

      final longRoute = RouteGuideInfo(
        name: 'Half Marathon',
        points: const [LatLng(0, 0), LatLng(0.1, 0)],
        totalDistanceMeters: 21097.5,
      );
      expect(longRoute.formattedDistance, equals('21.10 km'));
    });
  });
}
