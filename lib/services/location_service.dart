import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Layanan penanganan GPS perangkat dan filter noise
class LocationService {
  static const double maxAcceptableAccuracyMeters = 35.0;

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

  /// Memulai stream lokasi GPS berkala tanpa membuang event diam demi fungsi Auto-Pause
  Stream<Position> startLocationStream({
    int distanceFilterMeters = 0,
    int intervalDurationSeconds = 1,
  }) {
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilterMeters,
      forceLocationManager: false,
      intervalDuration: Duration(seconds: intervalDurationSeconds),
      foregroundNotificationConfig: null,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .where((position) => filterPosition(position));
  }

  /// Memfilter hanya titik GPS dengan akurasi sinyal yang sangat buruk (> 35 meter)
  bool filterPosition(Position position) {
    if (position.accuracy > maxAcceptableAccuracyMeters) {
      return false;
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
