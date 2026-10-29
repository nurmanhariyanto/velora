import 'package:latlong2/latlong.dart';
import '../models/activity_session.dart';

/// Model data untuk rute referensi panduan lintasan (Route Breadcrumbs)
class RouteGuideInfo {
  /// Nama rute (nama file GPX atau judul sesi aktivitas)
  final String name;

  /// Daftar titik koordinat lintasan panduan
  final List<LatLng> points;

  /// Total jarak rute referensi dalam meter
  final double totalDistanceMeters;

  /// Total elevasi naik rute referensi dalam meter (jika tersedia)
  final double? elevationGain;

  /// Waktu pembuatan rute (jika tersedia)
  final DateTime? createdAt;

  /// ID aktivitas jika rute dimuat dari riwayat lokal
  final String? sourceActivityId;

  const RouteGuideInfo({
    required this.name,
    required this.points,
    required this.totalDistanceMeters,
    this.elevationGain,
    this.createdAt,
    this.sourceActivityId,
  });

  /// Membuat RouteGuideInfo dari ActivitySession riwayat lokal
  factory RouteGuideInfo.fromSession(ActivitySession session) {
    final points = session.coordinates
        .map((coord) => LatLng(coord.latitude, coord.longitude))
        .toList();

    return RouteGuideInfo(
      name: session.displayTitle,
      points: points,
      totalDistanceMeters: session.distanceMeters,
      elevationGain: session.elevationGain > 0 ? session.elevationGain : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(session.startTime),
      sourceActivityId: session.id,
    );
  }

  /// Titik awal rute
  LatLng? get startPoint => points.isNotEmpty ? points.first : null;

  /// Titik akhir rute
  LatLng? get endPoint => points.isNotEmpty ? points.last : null;

  /// Format jarak dalam kilometer untuk UI (misal: "12.45 km")
  String get formattedDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.toStringAsFixed(0)} m';
    }
    return '${(totalDistanceMeters / 1000).toStringAsFixed(2)} km';
  }
}
