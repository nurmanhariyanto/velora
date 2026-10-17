import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../algorithms/haversine.dart';

/// Layanan penanganan GPS perangkat dan filter noise
class LocationService {
  static const double maxAcceptableAccuracyMeters = 25.0;
  static const double minMovementThresholdMeters = 2.0;

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastValidPosition;

  Position? get lastValidPosition => _lastValidPosition;

  /// Memeriksa dan meminta izin lokasi Android/iOS
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Mengambil lokasi saat ini satu kali (untuk inisialisasi peta)
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Memulai stream lokasi GPS dengan filter noise & optimasi baterai
  Stream<Position> startLocationStream({
    int distanceFilterMeters = 3,
    int intervalDurationSeconds = 2,
  }) {
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilterMeters,
      forceLocationManager: false,
      intervalDuration: Duration(seconds: intervalDurationSeconds),
      foregroundNotificationConfig: null, // Ditangani flutter_foreground_task
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .where((position) => filterPosition(position));
  }

  /// Memfilter apakah titik posisi layak dicatat atau merupakan noise/drift GPS
  bool filterPosition(Position position) {
    // 1. Filter akurasi yang buruk
    if (position.accuracy > maxAcceptableAccuracyMeters) {
      return false;
    }

    // 2. Filter jitter saat diam
    if (_lastValidPosition != null) {
      final dist = Haversine.calculateDistance(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (dist < minMovementThresholdMeters && position.speed < 0.5) {
        return false;
      }
    }

    _lastValidPosition = position;
    return true;
  }

  void stop() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastValidPosition = null;
  }
}
