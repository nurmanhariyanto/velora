import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../algorithms/douglas_peucker.dart';
import '../algorithms/haversine.dart';
import '../algorithms/pace_calculator.dart';
import '../database/activity_repository.dart';
import '../models/activity_session.dart';
import '../models/coordinate_point.dart';
import '../models/sports_type.dart';
import '../models/tracking_status.dart';
import '../services/auto_pause_detector.dart';
import '../services/foreground_service_handler.dart';
import '../services/location_service.dart';

/// Provider utama pengelola siklus pelacakan, perhitungan real-time, dan GPS stream
class TrackingProvider extends ChangeNotifier {
  final LocationService _locationService;
  final ActivityRepository _activityRepository;
  final AutoPauseDetector _autoPauseDetector;

  TrackingProvider({
    LocationService? locationService,
    ActivityRepository? activityRepository,
    AutoPauseDetector? autoPauseDetector,
  })  : _locationService = locationService ?? LocationService(),
        _activityRepository = activityRepository ?? ActivityRepository(),
        _autoPauseDetector = autoPauseDetector ?? AutoPauseDetector() {
    _initNotificationButtonListener();
  }

  void _initNotificationButtonListener() {
    ForegroundServiceHandler.listenToButtonActions(
      onAction: (actionId) {
        if (actionId == 'btn_pause') {
          pauseTracking();
        } else if (actionId == 'btn_resume') {
          resumeTracking();
        } else if (actionId == 'btn_stop') {
          stopAndSaveSession();
        }
      },
    );
  }

  // State Pelacakan
  TrackingStatus _status = TrackingStatus.idle;
  SportsType _sportsType = SportsType.run;

  // Waktu & Stopwatch
  Timer? _tickerTimer;
  int _activeDurationSeconds = 0;
  int _sessionStartTime = 0;
  String _currentSessionId = '';

  // Metrik Real-time
  double _totalDistanceMeters = 0.0;
  double _currentSpeedMps = 0.0;
  double _maxSpeedMps = 0.0;
  double _elevationGain = 0.0;
  double? _lastElevation;

  // Deteksi Waktu Pergerakan untuk Auto-Pause Pintar
  int _lastMovementTimeMs = 0;
  int _consecutiveStationarySeconds = 0;

  // Titik Koordinat
  final List<CoordinatePoint> _coordinates = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _locationSubscription;

  // Getters
  TrackingStatus get status => _status;
  SportsType get sportsType => _sportsType;
  int get activeDurationSeconds => _activeDurationSeconds;
  double get totalDistanceMeters => _totalDistanceMeters;
  double get totalDistanceKm => _totalDistanceMeters / 1000.0;
  double get currentSpeedKmh => _status.isPaused ? 0.0 : _currentSpeedMps * 3.6;
  double get maxSpeedKmh => _maxSpeedMps * 3.6;
  double get elevationGain => _elevationGain;
  List<CoordinatePoint> get coordinates => List.unmodifiable(_coordinates);
  Position? get currentPosition => _currentPosition;
  String get currentSessionId => _currentSessionId;

  /// Kecepatan rata-rata (km/jam)
  double get averageSpeedKmh {
    return PaceCalculator.calculateSpeedKmh(
      _totalDistanceMeters,
      _activeDurationSeconds,
    );
  }

  /// Pace rata-rata (detik per km)
  double get averagePaceSecondsPerKm {
    return PaceCalculator.calculatePaceSecondsPerKm(
      _totalDistanceMeters,
      _activeDurationSeconds,
    );
  }

  /// Format durasi HH:mm:ss atau mm:ss
  String get formattedDuration =>
      PaceCalculator.formatDuration(_activeDurationSeconds);

  /// Format Pace (cth: 5'24" /km)
  String get formattedPace =>
      PaceCalculator.formatPace(averagePaceSecondsPerKm);

  /// Inisialisasi posisi awal pengguna pada peta sebelum tracking dimulai
  Future<void> fetchInitialPosition() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      _currentPosition = pos;
      notifyListeners();
    }
  }

  /// Mengganti jenis olahraga saat status idle
  void setSportsType(SportsType type) {
    if (_status == TrackingStatus.idle) {
      _sportsType = type;
      notifyListeners();
    }
  }

  /// Memulai sesi pelacakan GPS
  Future<bool> startTracking() async {
    final hasPermission = await _locationService.checkAndRequestPermissions();
    if (!hasPermission) return false;

    // Pastikan izin notifikasi aktif di Android 13+ agar tombol pintasan muncul
    await ForegroundServiceHandler.requestNotificationPermission();

    _resetState();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _currentSessionId = 'velora_$_sessionStartTime';
    _lastMovementTimeMs = _sessionStartTime;
    _consecutiveStationarySeconds = 0;
    _status = TrackingStatus.tracking;
    _autoPauseDetector.reset();

    // Jalankan timer stopwatch setiap 1 detik
    _startTimer();

    // Mulai foreground service Android
    await ForegroundServiceHandler.start(
      title: 'Velora: ${_sportsType.displayName}',
      text: 'Mulai melacak rute Anda...',
    );

    // Mulai GPS stream
    _locationSubscription = _locationService.startLocationStream().listen(
      _onPositionUpdate,
      onError: (err) {
        debugPrint('Location stream error: $err');
      },
    );

    notifyListeners();
    return true;
  }

  /// Menghentikan sementara sesi secara manual
  void pauseTracking() {
    if (_status == TrackingStatus.tracking || _status == TrackingStatus.pausedAuto) {
      _status = TrackingStatus.pausedManual;
      _stopTimer();
      _currentSpeedMps = 0.0;
      _updateForegroundNotification();
      notifyListeners();
    }
  }

  /// Melanjutkan sesi yang di-pause manual atau auto-pause
  void resumeTracking() {
    if (_status.isPaused) {
      _status = TrackingStatus.tracking;
      _lastMovementTimeMs = DateTime.now().millisecondsSinceEpoch;
      _consecutiveStationarySeconds = 0;
      _autoPauseDetector.reset();
      _startTimer();
      _updateForegroundNotification();
      notifyListeners();
    }
  }

  /// Mengakhiri sesi pelacakan dan menyimpan ke database SQLite
  Future<ActivitySession?> stopAndSaveSession({String? notes, String? photoPath}) async {
    if (!_status.isRecording && _status != TrackingStatus.completed) {
      return null;
    }

    _status = TrackingStatus.completed;
    _stopTimer();
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stop();
    await ForegroundServiceHandler.stop();

    final endTime = DateTime.now().millisecondsSinceEpoch;

    // Sederhanakan koordinat jika rute sangat panjang menggunakan Douglas-Peucker
    final simplifiedPoints = DouglasPeucker.simplify(_coordinates);

    final session = ActivitySession(
      id: _currentSessionId,
      sportsType: _sportsType,
      startTime: _sessionStartTime,
      endTime: endTime,
      durationSeconds: _activeDurationSeconds,
      distanceMeters: _totalDistanceMeters,
      averageSpeedKmh: averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      elevationGain: _elevationGain,
      notes: notes,
      photoPath: photoPath,
      coordinates: simplifiedPoints,
    );

    // Simpan ke SQLite
    await _activityRepository.insertActivity(session);

    // Reset status pelacakan kembali ke idle agar siap untuk sesi baru berikutnya
    _status = TrackingStatus.idle;
    _resetState();

    notifyListeners();
    return session;
  }

  /// Membatalkan sesi tanpa menyimpan
  Future<void> discardSession() async {
    _status = TrackingStatus.idle;
    _stopTimer();
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stop();
    await ForegroundServiceHandler.stop();
    _resetState();
    notifyListeners();
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    double movedMeters = 0.0;
    if (_coordinates.isNotEmpty) {
      final lastPoint = _coordinates.last;
      movedMeters = Haversine.calculateDistance(
        lastPoint.latitude,
        lastPoint.longitude,
        position.latitude,
        position.longitude,
      );
    }

    final speedMps = position.speed > 0 ? position.speed : 0.0;
    final speedKmh = speedMps * 3.6;
    final isMoving = speedKmh >= 2.0 || movedMeters >= 2.0;

    if (isMoving) {
      _lastMovementTimeMs = nowMs;
      _consecutiveStationarySeconds = 0;
      _currentSpeedMps = speedMps;
      _autoPauseDetector.recordMovement();

      // Jika sebelumnya berada dalam kondisi auto-pause, otomatis lanjutkan pelacakan
      if (_status == TrackingStatus.pausedAuto) {
        _status = TrackingStatus.tracking;
        _updateForegroundNotification();
        notifyListeners();
      }
    } else {
      _currentSpeedMps = 0.0;
    }

    // Deteksi Auto-Pause via AutoPauseDetector
    final isAutoPausedNow = _autoPauseDetector.processPoint(
      speedMps: speedMps,
      timestampMs: nowMs,
      distanceMovedMeters: movedMeters,
    );

    if (isAutoPausedNow && _status == TrackingStatus.tracking) {
      _status = TrackingStatus.pausedAuto;
      _currentSpeedMps = 0.0;
      _updateForegroundNotification();
      notifyListeners();
      return;
    }

    // Jika koleksi koordinat masih kosong, simpan titik start awal
    if (_coordinates.isEmpty && _status == TrackingStatus.tracking) {
      _lastElevation = position.altitude > 0 ? position.altitude : null;
      _coordinates.add(CoordinatePoint(
        activityId: _currentSessionId,
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
        speed: speedMps,
        accuracy: position.accuracy,
        timestamp: nowMs,
        isAutoPaused: false,
      ));
      notifyListeners();
      return;
    }

    // Hanya catat jarak & koordinat saat aktif merekam (tidak paused) dan ada pergerakan
    if (_status == TrackingStatus.tracking && isMoving) {
      _totalDistanceMeters += movedMeters;
      if (_currentSpeedMps > _maxSpeedMps) {
        _maxSpeedMps = _currentSpeedMps;
      }

      // Hitung akumulasi kenaikan elevasi (ascent)
      if (position.altitude > 0) {
        if (_lastElevation != null && position.altitude > _lastElevation!) {
          final diff = position.altitude - _lastElevation!;
          if (diff >= 0.5) {
            _elevationGain += diff;
          }
        }
        _lastElevation = position.altitude;
      }

      // Tambahkan titik koordinat baru
      final newPoint = CoordinatePoint(
        activityId: _currentSessionId,
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
        speed: speedMps,
        accuracy: position.accuracy,
        timestamp: nowMs,
        isAutoPaused: false,
      );

      _coordinates.add(newPoint);
      _updateForegroundNotification();
      notifyListeners();
    }
  }

  void _startTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (_status == TrackingStatus.tracking) {
        // Cek apakah pengguna berhenti bergerak (kecepatan < 2 km/h atau waktu diam >= 3 detik)
        final timeSinceMovementMs = nowMs - _lastMovementTimeMs;
        final isStationary = (_currentSpeedMps * 3.6 < 2.0) || (timeSinceMovementMs >= 3000);

        if (isStationary) {
          _consecutiveStationarySeconds++;
          final isDetectorTimeout = _autoPauseDetector.recordStationaryTick(nowMs);
          if (_consecutiveStationarySeconds >= 3 || isDetectorTimeout) {
            _status = TrackingStatus.pausedAuto;
            _currentSpeedMps = 0.0;
            _updateForegroundNotification();
            notifyListeners();
            return;
          }
        } else {
          _consecutiveStationarySeconds = 0;
          _autoPauseDetector.recordMovement();
        }

        // Tambah durasi aktif jika masih dalam status tracking
        _activeDurationSeconds++;
        // Sinkronisasi pembaruan teks notifikasi setiap 2 detik
        if (_activeDurationSeconds % 2 == 0) {
          _updateForegroundNotification();
        }
        notifyListeners();
      } else if (_status == TrackingStatus.pausedAuto) {
        // Pada kondisi auto-pause, durasi TIDAK bertambah.
      }
    });
  }

  void _stopTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  void _updateForegroundNotification() {
    final distStr = PaceCalculator.formatDistance(_totalDistanceMeters);
    final durStr = formattedDuration;
    final statusStr = _status.displayLabel;

    ForegroundServiceHandler.update(
      title: 'Velora (${_sportsType.shortName}) - $statusStr',
      text: '$distStr • $durStr',
      isPaused: _status.isPaused,
    );
  }

  void _resetState() {
    _activeDurationSeconds = 0;
    _totalDistanceMeters = 0.0;
    _currentSpeedMps = 0.0;
    _maxSpeedMps = 0.0;
    _elevationGain = 0.0;
    _lastElevation = null;
    _coordinates.clear();
    _lastMovementTimeMs = 0;
    _consecutiveStationarySeconds = 0;
  }

  @override
  void dispose() {
    _stopTimer();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
