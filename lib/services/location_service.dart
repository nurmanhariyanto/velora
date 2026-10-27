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
    try {
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
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa status diagnosis layanan lokasi dan izin untuk memberikan pesan informatif
  Future<({bool serviceEnabled, bool permissionGranted, String? issueMessage})> checkDiagnostics() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          serviceEnabled: false,
          permissionGranted: false,
          issueMessage: 'Layanan GPS/lokasi perangkat belum aktif. Silakan aktifkan GPS di pengaturan HP Anda.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (
            serviceEnabled: true,
            permissionGranted: false,
            issueMessage: 'Izin akses lokasi ditolak. Velora membutuhkan izin lokasi untuk menampilkan posisi Anda.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (
          serviceEnabled: true,
          permissionGranted: false,
          issueMessage: 'Izin lokasi ditolak permanen. Buka Pengaturan Aplikasi di HP untuk mengizinkan akses lokasi.',
        );
      }

      return (
        serviceEnabled: true,
        permissionGranted: true,
        issueMessage: null,
      );
    } catch (e) {
      return (
        serviceEnabled: false,
        permissionGranted: false,
        issueMessage: 'Gagal memeriksa status lokasi: $e',
      );
    }
  }

  /// Mengambil lokasi terakhir yang disimpan sistem Android/iOS secara instan
  Future<Position?> getLastKnownPosition() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Mengambil lokasi saat ini satu kali (untuk inisialisasi peta atau tombol pusatkan)
  Future<Position?> getCurrentPosition({Duration timeLimit = const Duration(seconds: 10)}) async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
    } catch (_) {
      return await getLastKnownPosition();
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
