import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velora/models/coordinate_point.dart';
import 'package:velora/services/road_geocoding_service.dart';

void main() {
  setUp(() {
    RoadGeocodingService.clearCache();
  });

  group('RoadGeocodingService Tests', () {
    test('formatRoadName memformat awalan jalan secara rapi', () {
      expect(RoadGeocodingService.formatRoadName('Jalan Jend. Sudirman'), 'Jl. Jend. Sudirman');
      expect(RoadGeocodingService.formatRoadName('Gang Melati'), 'Gg. Melati');
      expect(RoadGeocodingService.formatRoadName('Lorong H. Syukur'), 'Lr. H. Syukur');
      expect(RoadGeocodingService.formatRoadName('Boulevard Barat'), 'Blvd. Barat');
      expect(RoadGeocodingService.formatRoadName('Jl. Ahmad Yani'), 'Jl. Ahmad Yani');
    });

    test('lookupOfflineRoad mengenali jalan populer Pontianak secara offline', () {
      // Koordinat Jl. Ahmad Yani Pontianak (-0.050, 109.345)
      final road1 = RoadGeocodingService.lookupOfflineRoad(-0.050, 109.345);
      expect(road1, isNotNull);
      expect(road1, contains('Ahmad Yani'));

      // Koordinat Untan (-0.058, 109.348)
      final roadUntan = RoadGeocodingService.lookupOfflineRoad(-0.058, 109.348);
      expect(roadUntan, isNotNull);

      // Koordinat Jl. Gajah Mada (-0.035, 109.338)
      final roadGajahMada = RoadGeocodingService.lookupOfflineRoad(-0.035, 109.338);
      expect(roadGajahMada, 'Jl. Gajah Mada');
    });

    test('lookupOfflineRoad mengenali jalan populer Jakarta & Bandung secara offline', () {
      // Sudirman Jakarta (-6.215, 106.822)
      final roadJkt = RoadGeocodingService.lookupOfflineRoad(-6.215, 106.822);
      expect(roadJkt, 'Jl. Jend. Sudirman');

      // Thamrin Jakarta (-6.185, 106.824)
      final roadThamrin = RoadGeocodingService.lookupOfflineRoad(-6.185, 106.824);
      expect(roadThamrin, 'Jl. M.H. Thamrin');

      // Dago Bandung (-6.890, 107.612)
      final roadBdg = RoadGeocodingService.lookupOfflineRoad(-6.890, 107.612);
      expect(roadBdg, 'Jl. Ir. H. Djuanda');
    });

    test('getRoadName menggunakan in-memory cache untuk koordinat yang sama', () async {
      // Pertama kali
      final r1 = await RoadGeocodingService.getRoadName(-6.215, 106.822);
      expect(r1, 'Jl. Jend. Sudirman');

      // Kedua kali harus dari cache
      final r2 = await RoadGeocodingService.getRoadName(-6.215, 106.822);
      expect(r2, 'Jl. Jend. Sudirman');
    });

    test('reverseGeocodeRoadOnline mengekstrak road dari response Nominatim JSON', () async {
      final mockClient = MockClient((request) async {
        final mockJson = jsonEncode({
          'address': {
            'road': 'Jalan Diponegoro',
            'suburb': 'Citarum',
            'city': 'Bandung',
          }
        });
        return http.Response(mockJson, 200);
      });

      final result = await RoadGeocodingService.reverseGeocodeRoadOnline(-6.901, 107.618, client: mockClient);
      expect(result, 'Jalan Diponegoro');
    });

    test('detectRoadTransitions mendeteksi transisi antar jalan di sepanjang rute', () async {
      final coords = [
        const CoordinatePoint(activityId: 'a1', latitude: -6.215, longitude: 106.822, elevation: 12, timestamp: 0),
        const CoordinatePoint(activityId: 'a1', latitude: -6.214, longitude: 106.822, elevation: 12, timestamp: 10),
        const CoordinatePoint(activityId: 'a1', latitude: -6.185, longitude: 106.824, elevation: 14, timestamp: 60), // Thamrin
      ];
      final distances = [0.0, 500.0, 3500.0];

      final transitions = await RoadGeocodingService.detectRoadTransitions(
        coordinates: coords,
        cumulativeDistances: distances,
      );

      expect(transitions.isNotEmpty, isTrue);
      expect(transitions.first.roadName, contains('Sudirman'));
    });

    test('detectRoadTransitions mendeduplikasi nama jalan sehingga nama yang sama hanya muncul tepat 1 kali', () async {
      final coords = [
        const CoordinatePoint(activityId: 'a1', latitude: -6.215, longitude: 106.822, elevation: 12, timestamp: 0), // Sudirman
        const CoordinatePoint(activityId: 'a1', latitude: -6.185, longitude: 106.824, elevation: 14, timestamp: 60), // Thamrin
        const CoordinatePoint(activityId: 'a1', latitude: -6.216, longitude: 106.821, elevation: 12, timestamp: 120), // Sudirman lagi (kembali)
      ];
      final distances = [0.0, 2500.0, 5000.0];

      final transitions = await RoadGeocodingService.detectRoadTransitions(
        coordinates: coords,
        cumulativeDistances: distances,
      );

      // Sudirman hanya boleh muncul 1 kali, Thamrin 1 kali
      final sudirmanCount = transitions.where((t) => t.roadName.contains('Sudirman')).length;
      expect(sudirmanCount, 1);
      final thamrinCount = transitions.where((t) => t.roadName.contains('Thamrin')).length;
      expect(thamrinCount, 1);
    });

    test('lookupOfflineRoad mengenali koridor rute Pontianak tambahan secara akurat', () {
      expect(RoadGeocodingService.lookupOfflineRoad(-0.038, 109.320), 'Jl. Uray Bawadi');
      expect(RoadGeocodingService.lookupOfflineRoad(-0.044, 109.323), 'Jl. Sutan Syahrir');
      expect(RoadGeocodingService.lookupOfflineRoad(-0.053, 109.318), 'Jl. Kesehatan');
      expect(RoadGeocodingService.lookupOfflineRoad(-0.064, 109.313), 'Jl. Harapan Jaya');
      expect(RoadGeocodingService.lookupOfflineRoad(-0.048, 109.305), 'Jl. Ampera');
      expect(RoadGeocodingService.lookupOfflineRoad(-0.056, 109.314), 'Jl. Prof. M. Yamin');
      expect(RoadGeocodingService.lookupOfflineRoad(-0.040, 109.312), 'Jl. Dr. Wahidin S.');
    });

    test('detectRoadTransitions memicu onProgressUpdate seketika pada frame awal (0 ms)', () async {
      final coords = [
        const CoordinatePoint(activityId: 'a1', latitude: -0.038, longitude: 109.320, elevation: 5, timestamp: 0),
        const CoordinatePoint(activityId: 'a1', latitude: -0.053, longitude: 109.318, elevation: 12, timestamp: 60),
      ];
      final distances = [0.0, 1800.0];

      List<RoadTransitionEvent>? firstUpdate;
      final transitions = await RoadGeocodingService.detectRoadTransitions(
        coordinates: coords,
        cumulativeDistances: distances,
        onProgressUpdate: (updated) {
          firstUpdate ??= updated;
        },
      );

      expect(firstUpdate, isNotNull);
      expect(firstUpdate!.isNotEmpty, isTrue);
      expect(transitions.isNotEmpty, isTrue);
      expect(transitions.any((t) => t.roadName.contains('Uray Bawadi') || t.roadName.contains('Kesehatan')), isTrue);
    });

    test('precacheRoadTransitions memanaskan data nama jalan ke dalam memori', () async {
      final coords = [
        const CoordinatePoint(activityId: 'a1', latitude: -0.038, longitude: 109.320, elevation: 5, timestamp: 0),
        const CoordinatePoint(activityId: 'a1', latitude: -0.053, longitude: 109.318, elevation: 12, timestamp: 60),
      ];

      await RoadGeocodingService.precacheRoadTransitions(coords);
      final cachedRoad = await RoadGeocodingService.getRoadName(-0.038, 109.320);
      expect(cachedRoad, 'Jl. Uray Bawadi');
    });
  });
}
