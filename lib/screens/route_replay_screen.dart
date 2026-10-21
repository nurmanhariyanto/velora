import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import '../algorithms/haversine.dart';
import '../algorithms/pace_calculator.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../models/coordinate_point.dart';
import '../models/sports_type.dart';
import '../models/track_milestone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/foreground_service_handler.dart';
import '../services/map_precache_service.dart';
import '../services/region_geocoding_service.dart';
import '../services/road_geocoding_service.dart';
import '../services/track_analysis_service.dart';
import '../services/user_profile_service.dart';
import '../services/video_export_service.dart';
import '../widgets/track_milestone_pin.dart';
import 'share_preview_screen.dart';

/// Layar Pemutar Animasi Ulang Lintasan Rute (Route Flyover Replay Sinematik)
class RouteReplayScreen extends StatefulWidget {
  final ActivitySession session;
  final bool autoStartVideoExport;

  const RouteReplayScreen({
    super.key,
    required this.session,
    this.autoStartVideoExport = false,
  });

  @override
  State<RouteReplayScreen> createState() => _RouteReplayScreenState();
}

class _RouteReplayScreenState extends State<RouteReplayScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _animController;

  // Analisis lintasan & data pendukung
  late final List<TrackMilestone> _milestones;
  late final List<double> _cumulativeDistances;
  late final List<double> _cumulativeElevationGains;
  String _athleteName = UserProfileService.defaultAthleteName;

  // Status pemutaran animasi
  static const Duration _baseDuration = Duration(seconds: 18);
  bool _isPlaying = true;
  bool _wasPlayingBeforeScrub = false;
  double _playbackSpeed = 2.0; // 1x, 2x, 4x, 8x
  bool _autoFollow = true;
  bool _mapDarkTheme = false;
  bool _isSatelliteMode = true; // Default: Citra Satelit HD Asli (seperti video referensi)
  bool _isMapReady = false;
  bool _povMode = false; // Default: Mode Flyover Stabil & Mulus (Peta Menghadap Utara, Bebas Pusing)
  bool _is3dTilted = true; // Default: Sudut Pandang 3D Menyamping (Perspective Tilt Oblique Bird's Eye View)
  double _smoothedBearing = 0.0;

  // Simulasi Mendaki Gunung 3D (3D Dynamic Mountain Climbing Engine)
  double _currentGrade = 0.0; // Persentase kemiringan lereng tanjakan (+ mendaki, - turunan)
  double _currentClimbTilt = 0.0; // Offset kemiringan sudut kamera mendaki (radians)
  double _currentClimbLift = 0.0; // Offset pengangkatan vertikal kamera (pixels)
  bool get _isClimbing => _currentGrade >= 3.0; // Status sedang menempuh tanjakan mendaki gunung

  // Titik aktif & notifikasi milestone
  TrackMilestone? _latestChimeMilestone;
  Timer? _chimeTimer;
  int _lastChimeKm = 0;

  // Kamera throttled update untuk mencegah spam request tile OSM (kotak hitam/putih)
  DateTime? _lastCameraMoveTime;
  LatLng? _lastCameraPos;

  // Kunci RepaintBoundary untuk Menangkap Snapshot Render Video Flyover MP4
  final GlobalKey _recordBoundaryKey = GlobalKey();
  bool _isRenderingVideo = false;

  // Status Ekspor Video di Latar Belakang (Non-Blocking)
  bool _isRenderMinimized = false;
  double _renderProgress = 0.0;
  int _renderCurrentFrame = 0;
  int _renderTotalFrames = 540;
  String _renderPhase = 'precache';
  int _renderPrecacheLoaded = 0;
  int _renderPrecacheTotal = 0;
  bool _isRenderCancelled = false;
  VoidCallback? _reopenRenderDialog;

  // Status Mode Rekam Layar Bersih (Clean Screen Record)
  bool _cleanRecordMode = false;
  bool _showRecordTooltip = false;
  Timer? _recordTooltipTimer;
  bool _isPickingVideo = false;

  // Status Pre-buffering Tile Peta untuk 60 FPS Mulus di Semua HP
  bool _isPreloadingTiles = true;
  double _preloadProgress = 0.0;
  int _preloadLoaded = 0;
  int _preloadTotal = 0;
  Timer? _precacheTimer;

  // Penanda Batas Wilayah Kabupaten/Kota (Flag Pin & Alert Banner)
  List<RegencyBorderEvent> _regencyBorders = [];
  RegencyBorderEvent? _activeBorderEvent;
  Timer? _borderEventTimer;
  final Set<int> _triggeredBorderIndices = <int>{};

  // Penanda Nama Jalan & Transisi Rute (Badge Jalan Sinematik)
  List<RoadTransitionEvent> _roadTransitions = [];
  RoadTransitionEvent? _activeRoadEvent;
  Timer? _roadEventTimer;
  final Set<int> _triggeredRoadIndices = <int>{};
  bool _showRoadNameBadge = true;

  // Zona Aman Tampilan Video untuk IG Story/Reels & WA Status (Anti Terpotong Kolom Balas)
  bool _enableSocialSafeZone = true;

  // Matriks OpenStreetMap Mode Gelap Khas Velora
  static const List<double> _darkMatrix = <double>[
    0.45, 0.00, 0.00, 0, -68,
    0.00, 0.48, 0.00, 0, -65,
    0.00, 0.00, 0.58, 0, -55,
    0.00, 0.00, 0.00, 1,   0,
  ];

  String? _cacheDir;
  TileProvider _tileProvider = NetworkTileProvider();

  TileLayer _buildTileLayer() {
    final tileProvider = _cacheDir != null
        ? VeloraTileProvider(
            cacheDir: _cacheDir!,
            providerType: _isSatelliteMode ? 'satellite' : 'osm',
          )
        : _tileProvider;

    return TileLayer(
      urlTemplate: _isSatelliteMode
          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'online.nurmancloud.velora',
      tileProvider: tileProvider,
      panBuffer: 8,
      keepBuffer: 64,
      tileDisplay: const TileDisplay.instantaneous(),
      retinaMode: false,
      maxNativeZoom: 19,
      tileBuilder: (!_isSatelliteMode && _mapDarkTheme)
          ? (context, tileWidget, tile) {
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix(_darkMatrix),
                child: tileWidget,
              );
            }
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    getApplicationDocumentsDirectory().then((dir) {
      if (mounted) {
        setState(() {
          _cacheDir = '${dir.path}/velora_tile_cache';
          _tileProvider = VeloraTileProvider(
            cacheDir: _cacheDir!,
            providerType: _isSatelliteMode ? 'satellite' : 'osm',
          );
        });
      }
    });

    // 1. Hitung akumulasi jarak per titik koordinat
    _cumulativeDistances = _precomputeCumulativeDistances(widget.session.coordinates);
    _cumulativeElevationGains = _precomputeCumulativeElevationGains(widget.session.coordinates);

    // 2. Ekstrak penanda milestone rute (KM Splits, Puncak, Max Speed)
    _milestones = TrackAnalysisService.analyzeTrack(
      widget.session.coordinates,
      widget.session.sportsType,
    );

    // 3. Durasi dasar animasi flyover (18 detik pada kecepatan 1x / 540 frame @ 30 FPS)
    _animController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_baseDuration.inMilliseconds / _playbackSpeed).round(),
      ),
    );

    _animController.addListener(_onAnimationTick);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final wasManualCleanRecord = _cleanRecordMode && !_isRenderingVideo;
        setState(() {
          _isPlaying = false;
          _cleanRecordMode = false;
        });
        if (wasManualCleanRecord && mounted) {
          _showCleanRecordCompletedDialog();
        }
      }
    });

    _loadAthleteName();
    _detectRegencyBorders();
    _detectRoadTransitions();

    // Memuat awal (pre-cache) tile peta di sepanjang rute untuk performa 60 FPS mulus di semua ponsel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTilePrecache();
    });
  }

  Future<void> _detectRegencyBorders() async {
    try {
      final borders = await RegionGeocodingService.detectRegencyBorders(
        coordinates: widget.session.coordinates,
        cumulativeDistances: _cumulativeDistances,
      );
      if (mounted) {
        setState(() {
          _regencyBorders = borders;
        });
      }
    } catch (_) {}
  }

  void _triggerRegencyBorderAlert(RegencyBorderEvent border) {
    _borderEventTimer?.cancel();
    setState(() {
      _activeBorderEvent = border;
    });
    _borderEventTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() {
          _activeBorderEvent = null;
        });
      }
    });
  }

  Future<void> _detectRoadTransitions() async {
    try {
      final transitions = await RoadGeocodingService.detectRoadTransitions(
        coordinates: widget.session.coordinates,
        cumulativeDistances: _cumulativeDistances,
      );
      if (mounted) {
        setState(() {
          _roadTransitions = transitions;
        });
      }
    } catch (_) {}
  }

  void _triggerRoadTransitionAlert(RoadTransitionEvent roadEvent) {
    _roadEventTimer?.cancel();
    setState(() {
      _activeRoadEvent = roadEvent;
    });
    _roadEventTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _activeRoadEvent = null;
        });
      }
    });
  }

  Future<void> _startTilePrecache() async {
    if (!mounted || widget.session.coordinates.length < 2) {
      if (mounted) {
        setState(() => _isPreloadingTiles = false);
      }
      return;
    }

    try {
      await MapPrecacheService.precacheRouteTiles(
        coordinates: widget.session.coordinates,
        context: context,
        tileProvider: _tileProvider,
        tileLayer: _buildTileLayer(),
        zoom: 16,
        maxTiles: 120,
        urlTemplate: _isSatelliteMode
            ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        onProgress: (progress, loaded, total) {
          if (mounted) {
            setState(() {
              _preloadProgress = progress;
              _preloadLoaded = loaded;
              _preloadTotal = total;
            });
          }
        },
        timeout: const Duration(milliseconds: 4500),
        onTimerCreated: (t) => _precacheTimer = t,
        isCancelled: () => !mounted || !_isPreloadingTiles,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isPreloadingTiles = false;
      });
      // Mulai playback otomatis setelah peta siap
      if (!_isPlaying && widget.session.coordinates.length >= 2) {
        _animController.forward();
        _isPlaying = true;
      }

      // Jika dibuka dengan permintaan ekspor video otomatis dari detail aktivitas
      if (widget.autoStartVideoExport) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startInAppVideoRender();
          }
        });
      }
    }
  }

  Future<void> _loadAthleteName() async {
    final name = await UserProfileService.getAthleteName();
    if (mounted) {
      setState(() {
        _athleteName = name;
      });
    }
  }

  List<double> _precomputeCumulativeDistances(List<CoordinatePoint> points) {
    if (points.isEmpty) return const [];
    final distances = List<double>.filled(points.length, 0.0);
    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += Haversine.calculateDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
      distances[i] = total;
    }
    return distances;
  }

  List<double> _precomputeCumulativeElevationGains(List<CoordinatePoint> points) {
    if (points.isEmpty) return const [];
    final gains = List<double>.filled(points.length, 0.0);
    double totalGain = 0.0;
    for (int i = 1; i < points.length; i++) {
      final diff = points[i].elevation - points[i - 1].elevation;
      if (diff > 0) {
        totalGain += diff;
      }
      gains[i] = totalGain;
    }
    return gains;
  }

  void _onAnimationTick() {
    if (!mounted || widget.session.coordinates.length < 2) return;

    final progress = _animController.value;
    final totalPoints = widget.session.coordinates.length;
    final rawIndex = progress * (totalPoints - 1);
    final index = rawIndex.floor().clamp(0, totalPoints - 1);
    final nextIdx = (index + 1).clamp(0, totalPoints - 1);
    final fraction = rawIndex - index;

    final currentPoint = widget.session.coordinates[index];
    final nextPoint = widget.session.coordinates[nextIdx];

    // Posisi terinterpolasi sub-frame yang sangat halus (menghilangkan lonjakan patah-patah)
    final interpLat = currentPoint.latitude + (nextPoint.latitude - currentPoint.latitude) * fraction;
    final interpLng = currentPoint.longitude + (nextPoint.longitude - currentPoint.longitude) * fraction;
    final targetPos = LatLng(interpLat, interpLng);

    // Hitung kemiringan tanjakan lereng gunung (% grade) secara real-time
    double instantaneousGrade = 0.0;
    final lookAheadIdx = (index + 4).clamp(0, totalPoints - 1);
    if (lookAheadIdx > index) {
      final pA = widget.session.coordinates[index];
      final pB = widget.session.coordinates[lookAheadIdx];
      final elevDelta = pB.elevation - pA.elevation;
      final distDelta = Haversine.calculateDistance(pA.latitude, pA.longitude, pB.latitude, pB.longitude);
      if (distDelta >= 6.0) {
        instantaneousGrade = (elevDelta / distDelta) * 100.0;
      }
    }
    // Haluskan transisi kemiringan lereng tanjakan (smooth grade damping)
    _currentGrade = _currentGrade + (instantaneousGrade - _currentGrade) * 0.12;

    // Respon kemiringan sudut kamera mendaki 3D:
    // Saat mendaki gunung (tanjakan > 0%): kamera mendongak menengadah menatap lereng (+0.18 rad) & terangkat naik (+32 px)
    // Saat turunan (< 0%): kamera sedikit menunduk menatap lembah
    final targetClimbTilt = _currentGrade > 0
        ? (_currentGrade.clamp(0.0, 16.0) / 16.0) * 0.18
        : (_currentGrade.clamp(-14.0, 0.0) / 14.0) * 0.09;
    final targetClimbLift = _currentGrade > 0
        ? (_currentGrade.clamp(0.0, 16.0) / 16.0) * 32.0
        : (_currentGrade.clamp(-14.0, 0.0) / 14.0) * 16.0;

    _currentClimbTilt = _currentClimbTilt + (targetClimbTilt - _currentClimbTilt) * 0.10;
    _currentClimbLift = _currentClimbLift + (targetClimbLift - _currentClimbLift) * 0.10;

    // Hitung jarak kumulatif terinterpolasi
    final currentDistMeters = _cumulativeDistances.isNotEmpty
        ? (_cumulativeDistances[index] +
            (_cumulativeDistances[nextIdx] - _cumulativeDistances[index]) * fraction)
        : 0.0;

    // Periksa apakah melintasi kilometer baru untuk menampilkan pop-up chime
    final currentKm = (currentDistMeters / 1000.0).floor();
    if (currentKm > _lastChimeKm) {
      _lastChimeKm = currentKm;
      final matchedSplit = _milestones.firstWhere(
        (m) => m.type == TrackMilestoneType.kmSplit && m.kmNumber == currentKm,
        orElse: () => TrackMilestone(
          type: TrackMilestoneType.kmSplit,
          kmNumber: currentKm,
          latitude: targetPos.latitude,
          longitude: targetPos.longitude,
          distanceMeters: currentDistMeters,
          elevation: currentPoint.elevation + (nextPoint.elevation - currentPoint.elevation) * fraction,
          speedKmh: currentPoint.speedKmh + (nextPoint.speedKmh - currentPoint.speedKmh) * fraction,
          title: 'Kilometer $currentKm Tercapai',
          description: 'Split rute aktif',
        ),
      );
      _triggerMilestoneChime(matchedSplit);
    }

    // Periksa apakah melintasi batas kabupaten/kota baru untuk memunculkan bendera / badge nama kabupaten
    final totalRouteDist = widget.session.distanceMeters > 0 ? widget.session.distanceMeters : 1000.0;
    final bannerWindowMeters = math.max(totalRouteDist * 0.12, 600.0);
    for (int bIdx = 0; bIdx < _regencyBorders.length; bIdx++) {
      final border = _regencyBorders[bIdx];
      final isInsideTriggerZone = _isRenderingVideo
          ? (currentDistMeters >= border.distanceMeters &&
              currentDistMeters <= border.distanceMeters + bannerWindowMeters)
          : (currentDistMeters >= border.distanceMeters);

      if (isInsideTriggerZone) {
        if (!_triggeredBorderIndices.contains(bIdx)) {
          _triggeredBorderIndices.add(bIdx);
          _triggerRegencyBorderAlert(border);
        }
      } else if (_isRenderingVideo && _activeBorderEvent == border) {
        _activeBorderEvent = null;
      }
    }
    // Bersihkan trigger jika posisi animasi di-scrub mundur
    _triggeredBorderIndices.removeWhere((idx) {
      if (idx < _regencyBorders.length) {
        return currentDistMeters < _regencyBorders[idx].distanceMeters;
      }
      return false;
    });

    // Pemicu Badge Nama Jalan saat melintasi transisi ruas jalan baru
    if (_showRoadNameBadge) {
      final roadWindowMeters = math.min(math.max(totalRouteDist * 0.10, 300.0), totalRouteDist * 0.25);
      for (int rIdx = 0; rIdx < _roadTransitions.length; rIdx++) {
        final road = _roadTransitions[rIdx];
        final isInsideTriggerZone = _isRenderingVideo
            ? (currentDistMeters >= road.distanceMeters &&
                currentDistMeters <= road.distanceMeters + roadWindowMeters)
            : (currentDistMeters >= road.distanceMeters);

        if (isInsideTriggerZone) {
          if (!_triggeredRoadIndices.contains(rIdx)) {
            _triggeredRoadIndices.add(rIdx);
            _triggerRoadTransitionAlert(road);
          }
        } else if (_isRenderingVideo && _activeRoadEvent == road) {
          _activeRoadEvent = null;
        }
      }
      _triggeredRoadIndices.removeWhere((idx) {
        if (idx < _roadTransitions.length) {
          return currentDistMeters < _roadTransitions[idx].distanceMeters;
        }
        return false;
      });
    } else {
      if (_activeRoadEvent != null) {
        _activeRoadEvent = null;
      }
    }

    // Hitung arah hadap kendaraan (bearing) ke titik rute berikutnya
    final rawBearing = Haversine.calculateBearing(
      currentPoint.latitude,
      currentPoint.longitude,
      nextPoint.latitude,
      nextPoint.longitude,
    );

    // Interpolasi sudut rotasi halus untuk ikon penunjuk arah atlet
    if (_smoothedBearing == 0.0) {
      _smoothedBearing = rawBearing;
    } else {
      double diff = (rawBearing - _smoothedBearing) % 360;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      _smoothedBearing = (_smoothedBearing + diff * 0.25) % 360;
    }

    // Kamera mengikuti posisi titik penunjuk atlet jika auto-follow aktif
    if (_autoFollow && _isMapReady) {
      final now = DateTime.now();
      final shouldMoveCamera = _isRenderingVideo ||
          _lastCameraMoveTime == null ||
          now.difference(_lastCameraMoveTime!).inMilliseconds >= 80 ||
          (_lastCameraPos != null &&
              Haversine.calculateDistance(
                    _lastCameraPos!.latitude,
                    _lastCameraPos!.longitude,
                    targetPos.latitude,
                    targetPos.longitude,
                  ) >= 8.0);

      if (shouldMoveCamera) {
        _lastCameraMoveTime = now;
        _lastCameraPos = targetPos;
        try {
          final targetZoom = _isRenderingVideo ? 16.0 : _mapController.camera.zoom;
          if (_povMode) {
            // Mode POV Berputar (opsional manual jika diaktifkan atlet)
            _mapController.moveAndRotate(
              targetPos,
              targetZoom,
              -_smoothedBearing,
            );
          } else {
            // Mode Flyover Mulus & Stabil:
            // Peta tenang menghadap Utara tetap (rotasi 0.0), kamera meluncur mulus
            // tanpa berputar-putar yang membuat pusing.
            _mapController.moveAndRotate(
              targetPos,
              targetZoom,
              0.0,
            );
          }
        } catch (_) {
          // Abaikan jika map controller belum siap atau belum dirender
        }
      }
    }

    setState(() {});
  }

  void _triggerMilestoneChime(TrackMilestone milestone) {
    _chimeTimer?.cancel();
    setState(() {
      _latestChimeMilestone = milestone;
    });
    _chimeTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _latestChimeMilestone = null;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _animController.stop();
        _isPlaying = false;
      } else {
        if (_animController.isCompleted) {
          _animController.reset();
          _lastChimeKm = 0;
        }
        _animController.forward();
        _isPlaying = true;
      }
    });
  }

  void _changePlaybackSpeed() {
    final speeds = [1.0, 2.0, 4.0, 8.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final newSpeed = speeds[nextIndex];

    final remainingProgress = 1.0 - _animController.value;

    setState(() {
      _playbackSpeed = newSpeed;
      _animController.duration = Duration(
        milliseconds: (_baseDuration.inMilliseconds / _playbackSpeed).round(),
      );
      if (_isPlaying) {
        _animController.animateTo(
          1.0,
          duration: Duration(
            milliseconds: (_baseDuration.inMilliseconds *
                    remainingProgress /
                    _playbackSpeed)
                .round(),
          ),
        );
      }
    });
  }

  void _seekTo(double value) {
    _animController.value = value;
    _lastCameraMoveTime = null;
    _lastCameraPos = null;
    final totalPoints = widget.session.coordinates.length;
    final idx = (value * (totalPoints - 1)).floor().clamp(0, totalPoints - 1);
    if (_cumulativeDistances.isNotEmpty) {
      _lastChimeKm = (_cumulativeDistances[idx] / 1000.0).floor();
    }
    if (_autoFollow && _isMapReady) {
      try {
        final p = widget.session.coordinates[idx];
        _mapController.move(LatLng(p.latitude, p.longitude), _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  void _restartReplay() {
    _lastCameraMoveTime = null;
    _lastCameraPos = null;
    _seekTo(0.0);
    _lastChimeKm = 0;
    _triggeredBorderIndices.clear();
    _activeBorderEvent = null;
    _borderEventTimer?.cancel();
    _triggeredRoadIndices.clear();
    _activeRoadEvent = null;
    _roadEventTimer?.cancel();
    if (!_isPlaying) {
      _togglePlayPause();
    } else {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _isPreloadingTiles = false;
    _isRenderCancelled = true;
    _precacheTimer?.cancel();
    _chimeTimer?.cancel();
    _borderEventTimer?.cancel();
    _roadEventTimer?.cancel();
    _recordTooltipTimer?.cancel();
    _animController.removeListener(_onAnimationTick);
    _animController.dispose();
    _mapController.dispose();
    _tileProvider.dispose();
    ForegroundServiceHandler.stopRenderProgress();
    MapPrecacheService.cleanupMemoryCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coords = widget.session.coordinates;
    if (coords.length < 2) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('Putar Ulang Rute')),
        body: const Center(
          child: Text(
            'Titik koordinat tidak cukup untuk animasi flyover rute.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final totalPoints = coords.length;
    final progress = _animController.value.clamp(0.0, 1.0);
    final rawIndex = progress * (totalPoints - 1);
    final currentIndex = rawIndex.floor().clamp(0, totalPoints - 1);
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);
    final fraction = (rawIndex - currentIndex).clamp(0.0, 1.0);

    final currentPt = coords[currentIndex];
    final nextPt = coords[nextIndex];

    // Posisi sub-frame terinterpolasi untuk penunjuk atlet & ujung polyline
    final interpLat = currentPt.latitude + (nextPt.latitude - currentPt.latitude) * fraction;
    final interpLng = currentPt.longitude + (nextPt.longitude - currentPt.longitude) * fraction;
    final currentInterpPos = LatLng(interpLat, interpLng);

    // Titik yang sudah dilalui hingga saat ini, ditambah posisi terinterpolasi di ujungnya
    final traversedPoints = <LatLng>[
      ...coords.sublist(0, currentIndex + 1).map((p) => LatLng(p.latitude, p.longitude)),
      currentInterpPos,
    ];

    // Seluruh rute penuh sebagai latar belakang
    final fullRoutePoints = coords
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Metrik dinamis berjalan terinterpolasi dengan proteksi NaN dan pembagian nol
    final rawDistanceM = _cumulativeDistances.isNotEmpty
        ? (_cumulativeDistances[currentIndex] +
            (_cumulativeDistances[nextIndex] - _cumulativeDistances[currentIndex]) * fraction)
        : 0.0;
    final currentDistanceM = (rawDistanceM.isNaN || rawDistanceM.isInfinite || rawDistanceM < 0)
        ? 0.0
        : rawDistanceM;
    final currentDistKm = currentDistanceM / 1000.0;

    final rawSpeed = currentPt.speedKmh + (nextPt.speedKmh - currentPt.speedKmh) * fraction;
    final currentSpeed = (rawSpeed.isNaN || rawSpeed.isInfinite || rawSpeed < 0)
        ? 0.0
        : rawSpeed;

    final rawElevation = currentPt.elevation + (nextPt.elevation - currentPt.elevation) * fraction;
    final currentElevation = (rawElevation.isNaN || rawElevation.isInfinite)
        ? 0.0
        : rawElevation;

    final double rawElevationGain = _cumulativeElevationGains.isNotEmpty
        ? (_cumulativeElevationGains[currentIndex] +
            (_cumulativeElevationGains[nextIndex] - _cumulativeElevationGains[currentIndex]) * fraction)
        : (widget.session.elevationGain > 0 ? widget.session.elevationGain * progress : 0.0);
    final currentElevationGain = (rawElevationGain.isNaN || rawElevationGain.isInfinite || rawElevationGain < 0)
        ? 0.0
        : rawElevationGain;

    final int totalDuration = widget.session.durationSeconds > 0
        ? widget.session.durationSeconds
        : ((coords.last.timestamp - coords.first.timestamp) / 1000).round();

    int elapsedSec;
    if (coords.last.timestamp > coords.first.timestamp) {
      final interpTimestamp = currentPt.timestamp +
          ((nextPt.timestamp - currentPt.timestamp) * fraction);
      final rawSec = ((interpTimestamp - coords.first.timestamp) / 1000).round();
      elapsedSec = rawSec.clamp(0, totalDuration > 0 ? totalDuration : 864000);
    } else {
      elapsedSec = (progress * (totalDuration > 0 ? totalDuration : 0)).round();
    }

    return PopScope(
      canPop: !_isRenderingVideo,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isRenderingVideo) {
          final isPrecache = _renderPhase == 'precache';
          final percent = isPrecache
              ? (_renderPrecacheTotal > 0
                  ? ((_renderPrecacheLoaded / _renderPrecacheTotal) * 100).toInt()
                  : 0)
              : (_renderProgress * 100).clamp(0, 100).toInt();

          showDialog<void>(
            context: context,
            builder: (confirmCtx) => AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
              ),
              actionsOverflowDirection: VerticalDirection.down,
              title: const Row(
                children: [
                  Icon(Icons.movie_filter_rounded, color: AppColors.primaryOrange, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Render Sedang Berjalan',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(
                  'Video flyover sedang dibuat di latar belakang ($percent%).\n\n'
                  'Video akan otomatis tersimpan ke Galeri HP (Movies/Velora) begitu selesai. Jika Anda keluar sekarang, proses render akan dibatalkan.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(confirmCtx),
                  child: const Text('TETAP DI SINI', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () {
                    _isRenderCancelled = true;
                    Navigator.pop(confirmCtx);
                    Navigator.pop(context);
                  },
                  child: const Text('BATALKAN RENDER', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: _recordBoundaryKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
          // 1. Lapisan Peta Citra Satelit / OSM Interaktif (Mendukung Perspektif 3D Menyamping Sinematik)
          _is3dTilted
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = constraints.maxWidth;
                    final screenH = constraints.maxHeight;
                    return ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Latar Belakang Luar Angkasa / Horizon Biru Gelap
                          const ColoredBox(color: Color(0xFF0F172A)),

                          // 2. Map Satelit 3D Diperluas & Dimiringkan Sinematik (Perspektif Menghadap ke Depan / Forward Aerial View)
                          Positioned(
                            top: -screenH * 0.85,
                            bottom: -screenH * 0.20,
                            left: -screenW * 0.45,
                            right: -screenW * 0.45,
                            child: Transform(
                              alignment: const FractionalOffset(0.5, 0.71),
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..setTranslationRaw(0.0, _currentClimbLift, 0.0)
                                ..rotateX(-0.70 + _currentClimbTilt), // Kemiringan 3D dinamis: mendongak menatap lereng saat mendaki gunung
                              child: _buildFlutterMap(
                                currentInterpPos: currentInterpPos,
                                fullRoutePoints: fullRoutePoints,
                                traversedPoints: traversedPoints,
                                currentDistanceM: currentDistanceM,
                              ),
                            ),
                          ),

                          // 3. Efek Gradien Horison / Atmosfer Langit di Bagian Atas
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: screenH * 0.24,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF0B1120),
                                      const Color(0xFF0F172A).withAlpha(220),
                                      const Color(0xFF1E293B).withAlpha(120),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.35, 0.70, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : _buildFlutterMap(
                  currentInterpPos: currentInterpPos,
                  fullRoutePoints: fullRoutePoints,
                  traversedPoints: traversedPoints,
                  currentDistanceM: currentDistanceM,
                ),

          // Watermark Logo Velora & Nama Atlet (Tampil Sinematik saat Clean Mode / Render Video)
          if (_cleanRecordMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_enableSocialSafeZone ? 24 : 14),
              left: 18,
              right: 18,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 36,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: AppColors.primaryOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'VELORA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• $_athleteName',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Area Ketukan Layar untuk Keluar dari Mode Rekam Bersih
          if (_cleanRecordMode && !_isRenderingVideo)
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('exit_clean_record_tap_area'),
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    _cleanRecordMode = false;
                  });
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Keluar dari Mode Rekam Bersih'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),

          // 2. Bar Header Atas (Nama Atlet, Tombol Kembali, Kontrol Kamera, Tombol Bagikan Video)
          if (!_cleanRecordMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopHeaderBar(),
            ),

          // 3. Pop-up Chime Banner saat Melewati Milestone KM
          if (_latestChimeMilestone != null && !_cleanRecordMode)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: _buildMilestoneChimeCard(_latestChimeMilestone!),
            ),

          // 3b. Pop-up Badge Bendera Saat Melintasi Batas Wilayah Kabupaten Baru (Tampil di Replay & Video MP4)
          if (_activeBorderEvent != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_cleanRecordMode ? (_enableSocialSafeZone ? 66 : 52) : 74),
              left: 20,
              right: 20,
              child: _buildRegencyBorderBanner(_activeBorderEvent!),
            ),


          // 4. Panel HUD Statistik Berjalan & Pengontrol Pemutaran Bawah
          Positioned(
            bottom: _cleanRecordMode
                ? (_enableSocialSafeZone ? 88 : 36)
                : 24,
            left: 16,
            right: 16,
            child: _cleanRecordMode
                ? _buildCleanRecordHud(
                    currentDistKm: currentDistKm,
                    currentSpeedKmh: currentSpeed,
                    currentElevation: currentElevation,
                    currentElevationGain: currentElevationGain,
                    elapsedSeconds: elapsedSec,
                  )
                : _buildBottomHudAndControls(
                    currentDistKm: currentDistKm,
                    currentSpeedKmh: currentSpeed,
                    currentElevation: currentElevation,
                    currentElevationGain: currentElevationGain,
                    elapsedSeconds: elapsedSec,
                    progress: progress,
                  ),
          ),
        ],
      ),
    ),

    // Tombol melayang "Fokus ke Atlet" saat mode kamera bebas
    if (!_autoFollow && !_cleanRecordMode)
      Positioned(
        bottom: 125,
        right: 20,
        child: _buildRecenterFloatingButton(currentInterpPos),
      ),

    // 5. Toast / Tooltip saat Mode Rekam Bersih Baru Dimulai (Overlay di luar video)
    if (_cleanRecordMode && _showRecordTooltip && !_isRenderingVideo)
      Positioned(
        top: MediaQuery.of(context).padding.top + 56,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(210),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryOrange.withAlpha(150),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fiber_manual_record_rounded,
                color: Colors.redAccent,
                size: 14,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mode Rekam Aktif • Ketuk layar untuk keluar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),

    // 6. Pre-buffering Loading Overlay (Overlay di luar video)
    if (_isPreloadingTiles)
      _buildPreloadingOverlay(),

    // 7. Floating Card Progres Render di Latar Belakang (Overlay di luar video)
    if (_isRenderingVideo && _isRenderMinimized)
      Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        child: _buildMinimizedRenderBanner(),
      ),
    ],
  ),
),
);
  }

  Widget _buildRecenterFloatingButton(LatLng currentPos) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _autoFollow = true;
          });
          if (_isMapReady) {
            _mapController.move(currentPos, _mapController.camera.zoom);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withAlpha(240),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neonCyan.withAlpha(180), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gps_fixed_rounded, color: AppColors.neonCyan, size: 16),
              SizedBox(width: 6),
              Text(
                'Fokus ke Atlet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreloadingOverlay() {
    final percent = (_preloadProgress * 100).clamp(0, 100).toInt();

    return Container(
      color: Colors.black.withAlpha(200),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.neonCyan.withAlpha(120),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withAlpha(50),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: AppColors.neonCyan,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Menyiapkan Peta Rute',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Memuat tile ke memori untuk animasi 60 FPS mulus di semua ponsel...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _preloadProgress > 0 ? _preloadProgress : null,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _preloadTotal > 0
                          ? '$_preloadLoaded / $_preloadTotal Tile'
                          : 'Menghitung rute...',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: TextButton.icon(
                  onPressed: () {
                    _precacheTimer?.cancel();
                    setState(() {
                      _isPreloadingTiles = false;
                    });
                    if (!_isPlaying && widget.session.coordinates.length >= 2) {
                      _animController.forward();
                      _isPlaying = true;
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryOrange, size: 18),
                  label: const Text(
                    'Lewati & Langsung Putar',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedRenderBanner() {
    final isPrecache = _renderPhase == 'precache';
    final percent = isPrecache
        ? (_renderPrecacheTotal > 0
            ? ((_renderPrecacheLoaded / _renderPrecacheTotal) * 100).toInt()
            : 0)
        : (_renderProgress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryOrange, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.movie_creation_rounded,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isPrecache ? 'Unduh Peta Satelit HD' : 'Render Video HD Latar Belakang',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPrecache
                          ? 'Ubin di Disk: $_renderPrecacheLoaded / $_renderPrecacheTotal • Latar Belakang'
                          : 'Frame $_renderCurrentFrame / $_renderTotalFrames • Otomatis ke Galeri',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Tombol Buka Status Dialog Penuh
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.open_in_full_rounded, color: AppColors.neonCyan, size: 18),
                tooltip: 'Buka Dialog',
                onPressed: () {
                  _reopenRenderDialog?.call();
                },
              ),
              // Tombol Batalkan Render
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                tooltip: 'Batalkan Render',
                onPressed: () {
                  _isRenderCancelled = true;
                  setState(() {
                    _cleanRecordMode = false;
                    _isRenderingVideo = false;
                    _isRenderMinimized = false;
                  });
                  ForegroundServiceHandler.stopRenderProgress();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isPrecache
                  ? (_renderPrecacheTotal > 0
                      ? (_renderPrecacheLoaded / _renderPrecacheTotal).clamp(0.0, 1.0)
                      : null)
                  : _renderProgress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlutterMap({
    required LatLng currentInterpPos,
    required List<LatLng> fullRoutePoints,
    required List<LatLng> traversedPoints,
    required double currentDistanceM,
  }) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentInterpPos,
        initialZoom: 16.0,
        minZoom: 4.0,
        maxZoom: 19.0,
        backgroundColor: _isSatelliteMode
            ? const Color(0xFF1E293B)
            : AppColors.darkBackground,
        onMapReady: () {
          if (mounted) {
            _isMapReady = true;
          }
        },
      ),
      children: [
        // Tile Citra Satelit HD Asli (ESRI World Imagery) atau OpenStreetMap
        _buildTileLayer(),

        // Garis Rute Keseluruhan (Muted Transparan di atas foto satelit)
        PolylineLayer(
          polylines: [
            Polyline(
              points: fullRoutePoints,
              strokeWidth: 4.5,
              color: Colors.white.withAlpha(65),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),

        // Garis Rute Aktif Tergambar Maju (Glow Kuning Emas Menyala Sinematik Multi-Layer)
        if (traversedPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Lapisan 1: Pendaran Cahaya Luar (Berubah menjadi Oranye Api saat Mendaki Gunung)
              Polyline(
                points: traversedPoints,
                strokeWidth: 14.0,
                color: _isClimbing
                    ? const Color(0xFFFF3D00).withAlpha(150)
                    : const Color(0xFFFFD600).withAlpha(130),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              // Lapisan 2: Berkas Emas Terang / Amber Api
              Polyline(
                points: traversedPoints,
                strokeWidth: 6.5,
                color: _isClimbing
                    ? const Color(0xFFFF6D00)
                    : const Color(0xFFFFEA00),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              // Lapisan 3: Inti Sinar Laser Putih Terang (White Hot Core)
              Polyline(
                points: traversedPoints,
                strokeWidth: 2.2,
                color: Colors.white.withAlpha(235),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // Pin Milestone Lintasan
        MarkerLayer(
          markers: [
            // Milestone yang sudah atau akan dilewati
            ..._milestones.map((m) {
              final isPassed = m.distanceMeters <= currentDistanceM;
              if (m.type == TrackMilestoneType.peakElevation) {
                return Marker(
                  point: LatLng(m.latitude, m.longitude),
                  width: 170,
                  height: 64,
                  alignment: Alignment.bottomCenter,
                  child: _buildMountainPeakPin(m, isPassed),
                );
              }
              return Marker(
                point: LatLng(m.latitude, m.longitude),
                width: m.isFastestKm ? 28 : 24,
                height: m.isFastestKm ? 28 : 24,
                child: Opacity(
                  opacity: isPassed ? 1.0 : 0.5,
                  child: TrackMilestonePin(
                    milestone: m,
                    sportsType: widget.session.sportsType,
                  ),
                ),
              );
            }),

            // Penanda Nama Kabupaten/Kota Tepat di Atas Garis Rute (Batas Wilayah)
            ..._regencyBorders.map((b) {
              final isPassed = b.distanceMeters <= currentDistanceM;
              return Marker(
                point: LatLng(b.latitude, b.longitude),
                width: 180,
                height: 48,
                alignment: Alignment.center,
                child: _buildRegencyFlagPin(b, isPassed),
              );
            }),

            // Animasi Penanda Nama Ruas Jalan 3D di Atas Jalur Rute GPS (3D Billboard Pin)
            // Muncul saat dilewati dengan animasi 3D, dan TETAP BERADA DI TEMPATNYA (tidak hilang setelah dilalui)
            if (_showRoadNameBadge)
              ..._roadTransitions.map((road) {
                final distDiff = currentDistanceM - road.distanceMeters;
                // Belum dilalui: jangan tampilkan terlebih dahulu agar muncul dengan animasi saat dilewati
                if (distDiff < 0) return null;

                // Saat atlet melintasi titik masuk jalan (0 s/d 220 meter): Animasi 3D Aktif (Pop-up, Elevasi Naik, Pendaran Cahaya)
                final isActive = _activeRoadEvent == road || (distDiff >= 0 && distDiff <= 220);
                // Setelah dilalui: TETAP TAMPIL PERMANEN di atas jalur peta (TIDAK PERNAH HILANG)
                final isPassed = distDiff > 220;

                return Marker(
                  point: LatLng(road.latitude, road.longitude),
                  width: 220,
                  height: 76,
                  alignment: Alignment.bottomCenter,
                  child: _buildRoadTrackPin(
                    road: road,
                    isActive: isActive,
                    isPassed: isPassed,
                  ),
                );
              }).whereType<Marker>(),

            // Penunjuk Avatar Atlet yang Sedang Bergerak Maju
            Marker(
              point: currentInterpPos,
              width: 52,
              height: 52,
              child: _buildRiderMarker(_smoothedBearing),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiderMarker(double bearingDegrees) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Pendaran Aura Luar Emas Lembut
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD600).withAlpha(60),
              shape: BoxShape.circle,
            ),
          ),
          // 2. Lingkar Dalam Emas Bersinar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEA00).withAlpha(200),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD600).withAlpha(240),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          // 3. Bola Cahaya Inti Putih Terang (Glowing White Beacon seperti di video referensi)
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFEA00), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegencyFlagPin(RegencyBorderEvent border, bool isPassed) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 350),
      scale: isPassed ? 1.05 : 0.95,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isPassed ? 1.0 : 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pita Cahaya Garis Batas Wilayah Lintas Aspal / Satelit
            Container(
              width: 140,
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isPassed ? const Color(0xFFFF5722) : const Color(0xFFFFD600),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPassed ? const Color(0xFFFF5722) : const Color(0xFFFFD600),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Badge Nama Kabupaten Tepat di Atas Garis Rute
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withAlpha(245),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPassed ? const Color(0xFFFF5722) : const Color(0xFFFFD600),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPassed
                        ? const Color(0xFFFF5722).withAlpha(140)
                        : const Color(0xFFFFD600).withAlpha(100),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🚩', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    border.regencyName.toUpperCase(),
                    style: TextStyle(
                      color: isPassed ? Colors.white : const Color(0xFFFFEA00),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegencyBorderBanner(RegencyBorderEvent border) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withAlpha(245),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF5722), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withAlpha(110),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withAlpha(45),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF5722).withAlpha(180)),
              ),
              child: const Text('🚩', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BATAS WILAYAH DAERAH',
                    style: TextStyle(
                      color: Color(0xFFFF8A65),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Memasuki ${border.regencyName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMountainPeakPin(TrackMilestone m, bool isPassed) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(_isSatelliteMode ? (0.70 - _currentClimbTilt) : 0.0),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        scale: isPassed ? 1.08 : 0.95,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isPassed ? 1.0 : 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Puncak Gunung 3D (Sunset Crimson Gradient)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF5722),
                      Color(0xFFE64A19),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withAlpha(isPassed ? 220 : 130),
                      blurRadius: isPassed ? 16 : 8,
                      spreadRadius: isPassed ? 2 : 0,
                      offset: const Offset(0, 3),
                    ),
                    const BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏔️', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      'PUNCAK ${m.elevation.toStringAsFixed(0)}M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Pointer segitiga ke bawah
              Transform.translate(
                offset: const Offset(0, -2),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE64A19),
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 0.8),
                        right: BorderSide(color: Colors.white, width: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              // Tiang vertikal 3D
              Container(
                width: 2.0,
                height: 12.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFFF8A65),
                      Color(0xFFFF5722),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withAlpha(160),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // Ground Anchor
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF5722),
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFFF5722),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoadTrackPin({
    required RoadTransitionEvent road,
    required bool isActive,
    required bool isPassed,
  }) {
    // Warna biru elektrik cerah seperti pada video referensi 3D Map
    const primaryBlue = Color(0xFF0284C7);
    const brightBlue = Color(0xFF38BDF8);
    const deepBlue = Color(0xFF0369A1);

    // Hitung status visual & animasi 3D:
    // - Memasuki/melintasi ruas jalan (isActive): membesar (scale 1.18), mengambang naik, dan memancarkan pendaran 3D
    // - Sudah dilewati (isPassed): tetap tersemat rapi di peta (scale 0.88), tidak pernah hilang sepanjang rute
    final scale = isActive ? 1.18 : (isPassed ? 0.88 : 0.0);
    final opacity = isActive ? 1.0 : (isPassed ? 0.88 : 0.0);

    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(_isSatelliteMode ? (0.70 - _currentClimbTilt) : 0.0), // Melawan kemiringan kanvas 3D dinamis agar pin berdiri tegak lurus (billboard 3D) menghadap kamera
      child: AnimatedScale(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        scale: scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Badge Kapsul Kotak Warna Biru Solid 3D (Mengambang di Atas Tiang)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                transform: Matrix4.translationValues(0, isActive ? -8.0 : 0.0, 0),
                constraints: const BoxConstraints(maxWidth: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 11 : 9,
                  vertical: isActive ? 5.5 : 4.5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isActive
                        ? const [brightBlue, primaryBlue]
                        : const [primaryBlue, deepBlue],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white,
                    width: isActive ? 1.6 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withAlpha(isActive ? 220 : 130),
                      blurRadius: isActive ? 16 : 8,
                      spreadRadius: isActive ? 3 : 0,
                      offset: const Offset(0, 3),
                    ),
                    const BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.navigation_rounded : Icons.alt_route_rounded,
                      size: isActive ? 13 : 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        road.roadName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isActive ? 12 : 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Segitiga Penunjuk Biru ke Aspal Lintasan
              Transform.translate(
                offset: const Offset(0, -3),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive ? primaryBlue : deepBlue,
                      border: const Border(
                        bottom: BorderSide(color: Colors.white, width: 0.8),
                        right: BorderSide(color: Colors.white, width: 0.8),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Tiang Penanda Vertikal 3D (Menghubungkan Pin Mengambang ke Aspal Rute)
              Container(
                width: 2.0,
                height: isActive ? 16.0 : 11.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFF38BDF8),
                      Color(0xFF0284C7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withAlpha(160),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

              // 4. Titik Pendaran Tanah & Bayangan 3D di Permukaan Aspal (Ground Anchor)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Bayangan elips di permukaan aspal
                  Container(
                    width: 14,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Titik Suar Ground Beacon
                  Container(
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0284C7),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8),
                          blurRadius: isActive ? 10 : 5,
                          spreadRadius: isActive ? 3 : 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar() {
    final dateFormat = DateFormat('d MMMM yyyy • HH:mm', 'id_ID');
    final formattedDate = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(widget.session.startTime),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        6,
        MediaQuery.of(context).padding.top + 6,
        6,
        8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withAlpha(220),
            Colors.black.withAlpha(140),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            tooltip: 'Kembali',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.session.displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withAlpha(50),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primaryOrange,
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'FLYOVER REPLAY',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$_athleteName • $formattedDate',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          // Tombol Mode POV Flyover (Chase Cam vs Flyover Stabil Utara)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _povMode ? Icons.explore_rounded : Icons.explore_off_rounded,
              color: _povMode ? AppColors.electricAmber : Colors.white60,
              size: 20,
            ),
            tooltip: _povMode ? 'Mode POV Berputar Aktif' : 'Mode Flyover Stabil (Utara)',
            onPressed: () {
              setState(() {
                _povMode = !_povMode;
                if (!_povMode) {
                  _mapController.rotate(0.0);
                }
              });
            },
          ),
          // Tombol Sudut Pandang 3D Menyamping (Perspective Tilt vs 2D Datar)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _is3dTilted ? Icons.view_in_ar_rounded : Icons.layers_rounded,
              color: _is3dTilted ? AppColors.electricAmber : Colors.white60,
              size: 20,
            ),
            tooltip: _is3dTilted ? 'Perspektif 3D Menyamping Aktif' : 'Tampilan 2D Datar',
            onPressed: () {
              setState(() {
                _is3dTilted = !_is3dTilted;
              });
            },
          ),
          // Tombol Kunci Kamera Follow
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _autoFollow ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: _autoFollow ? AppColors.neonCyan : Colors.white60,
              size: 20,
            ),
            tooltip: _autoFollow ? 'Kamera Mengikuti Atlet' : 'Kamera Bebas',
            onPressed: () {
              setState(() {
                _autoFollow = !_autoFollow;
              });
            },
          ),
          // Tombol Mode Satelit HD vs Peta Jalan OSM
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _isSatelliteMode
                  ? Icons.satellite_alt_rounded
                  : Icons.map_rounded,
              color: _isSatelliteMode ? AppColors.electricAmber : Colors.white70,
              size: 20,
            ),
            tooltip: _isSatelliteMode ? 'Mode Satelit HD Aktif' : 'Mode Peta Jalan',
            onPressed: () {
              setState(() {
                _isSatelliteMode = !_isSatelliteMode;
              });
            },
          ),
          // Tombol Mode Gelap/Terang (aktif saat mode peta jalan)
          if (!_isSatelliteMode)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _mapDarkTheme
                    ? Icons.brightness_medium_rounded
                    : Icons.wb_sunny_rounded,
                color: _mapDarkTheme ? AppColors.electricAmber : Colors.white70,
                size: 20,
              ),
              tooltip: 'Ubah Tema Peta',
              onPressed: () {
                setState(() {
                  _mapDarkTheme = !_mapDarkTheme;
                });
              },
            ),
          // Tombol Rekam & Bagikan Video
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.videocam_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
            tooltip: 'Rekam & Bagikan Video',
            onPressed: _showShareVideoSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneChimeCard(TrackMilestone milestone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withAlpha(245),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: milestone.isFastestKm
              ? AppColors.electricAmber
              : AppColors.primaryOrange,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (milestone.isFastestKm
                    ? AppColors.electricAmber
                    : AppColors.primaryOrange)
                .withAlpha(90),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          TrackMilestonePin(
            milestone: milestone,
            sportsType: widget.session.sportsType,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        milestone.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (milestone.isFastestKm) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.electricAmber,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHudAndControls({
    required double currentDistKm,
    required double currentSpeedKmh,
    required double currentElevation,
    required double currentElevationGain,
    required int elapsedSeconds,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Baris 5 Metrik Dinamis HUD
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildHudMetric(
                    label: 'JARAK',
                    value: currentDistKm.toStringAsFixed(2),
                    unit: 'KM',
                    accentColor: AppColors.neonCyan,
                  ),
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildHudMetric(
                    label: widget.session.sportsType == SportsType.run
                        ? 'PACE'
                        : 'SPEED',
                    value: widget.session.sportsType == SportsType.run
                        ? (currentSpeedKmh > 1.0
                            ? PaceCalculator.formatPace(3600.0 / currentSpeedKmh)
                            : "--'--\"")
                        : currentSpeedKmh.toStringAsFixed(1),
                    unit: widget.session.sportsType == SportsType.run
                        ? '/KM'
                        : 'KM/H',
                    accentColor: AppColors.primaryOrange,
                  ),
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildHudMetric(
                    label: _isClimbing ? '▲ +${_currentGrade.toStringAsFixed(1)}%' : 'ELEVASI',
                    value: currentElevation.toStringAsFixed(0),
                    unit: 'M',
                    accentColor: _isClimbing ? const Color(0xFFFF5722) : const Color(0xFF818CF8),
                  ),
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildHudMetric(
                    label: 'GAIN',
                    value: '+${currentElevationGain.toStringAsFixed(0)}',
                    unit: 'M',
                    accentColor: AppColors.neonGreen,
                  ),
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildHudMetric(
                    label: 'WAKTU',
                    value: PaceCalculator.formatDuration(elapsedSeconds),
                    unit: '',
                    accentColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Timeline Scrubber Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              activeTrackColor: AppColors.primaryOrange,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.primaryOrange,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _isRenderingVideo ? null : _seekTo,
              onChangeStart: _isRenderingVideo
                  ? null
                  : (val) {
                      _wasPlayingBeforeScrub = _isPlaying;
                      if (_isPlaying) {
                        _animController.stop();
                      }
                    },
              onChangeEnd: _isRenderingVideo
                  ? null
                  : (val) {
                      if (_wasPlayingBeforeScrub && !_animController.isAnimating) {
                        _animController.repeat();
                      }
                    },
            ),
          ),

          // 3. Tombol Kontrol Pemutaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pengubah Kecepatan Pemutaran (1x, 2x, 4x, 8x)
              Material(
                color: AppColors.cardSurfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _isRenderingVideo ? null : _changePlaybackSpeed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '${_playbackSpeed.toStringAsFixed(0)}x',
                      style: TextStyle(
                        color: _isRenderingVideo
                            ? AppColors.textSecondary.withAlpha(120)
                            : AppColors.primaryOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Tombol Utama (Play / Pause / Replay)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_rounded, color: Colors.white70),
                    tooltip: 'Ulangi dari Awal',
                    onPressed: _isRenderingVideo ? null : _restartReplay,
                  ),
                  const SizedBox(width: 8),
                  Material(
                    shape: const CircleBorder(),
                    color: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    child: Ink(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _isRenderingVideo
                            ? LinearGradient(
                                colors: [
                                  AppColors.cardSurfaceElevated,
                                  AppColors.cardSurfaceElevated.withAlpha(200),
                                ],
                              )
                            : const LinearGradient(
                                colors: [
                                  AppColors.electricAmber,
                                  AppColors.primaryOrange,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isRenderingVideo ? null : _togglePlayPause,
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 32,
                          color: _isRenderingVideo ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Persentase Progress Rute
              Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudMetric({
    required String label,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: accentColor.withAlpha(160),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white12,
    );
  }

  // ==========================================
  // FITUR REKAM & BAGIKAN VIDEO KE MEDIA SOSIAL
  // ==========================================

  /// Merender animasi flyover rute menjadi berkas video MP4 secara otomatis (Full HD 9:16 atau 4K Ultra HD)
  Future<void> _startInAppVideoRender({bool is4K = false}) async {
    // 0. Cegah eksekusi ganda jika proses render sedang berjalan
    if (_isRenderingVideo) {
      debugPrint('Proses render video sedang berjalan, mengabaikan pemicu duplikat.');
      return;
    }

    // 1. Jeda pemutaran animasi jika sedang aktif
    if (_isPlaying) {
      _togglePlayPause();
    }

    _isRenderCancelled = false;
    _renderProgress = 0.0;
    _renderCurrentFrame = 0;
    _renderTotalFrames = 540; // 18 detik video flyover pada 30 FPS (sinematik, tenang, dan detail)
    _renderPhase = 'precache';
    _renderPrecacheLoaded = 0;
    _renderPrecacheTotal = 0;
    _isRenderMinimized = false;

    StateSetter? dialogSetState;
    BuildContext? dialogCtx;

    // 2. Aktifkan clean record mode & rendering flag
    setState(() {
      _cleanRecordMode = true;
      _isRenderingVideo = true;
      _autoFollow = true;
    });

    void openDialog() {
      if (!mounted || !_isRenderingVideo) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogCtx = ctx;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              dialogSetState = setDialogState;
              final isPrecache = _renderPhase == 'precache';
              final percent = isPrecache
                  ? (_renderPrecacheTotal > 0 ? ((_renderPrecacheLoaded / _renderPrecacheTotal) * 100).toInt() : 0)
                  : (_renderProgress * 100).clamp(0, 100).toInt();

              return AlertDialog(
                backgroundColor: AppColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                ),
                actionsOverflowDirection: VerticalDirection.down,
                title: Row(
                  children: [
                    Icon(
                      isPrecache ? Icons.cloud_download_rounded : Icons.movie_creation_rounded,
                      color: AppColors.primaryOrange,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPrecache
                            ? 'Mengunduh Peta Satelit HD'
                            : (is4K ? 'Merender Video 4K Ultra HD' : 'Merender Video Full HD Utuh'),
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPrecache
                            ? 'Menyimpan potongan citra satelit rute zoom 17 HD langsung ke penyimpanan ponsel agar video tajam bebas kotak hitam...'
                            : (is4K
                                ? 'Mengenkode animasi flyover 18 detik ke berkas MP4 4K (45 Mbps) tanpa terpotong...'
                                : 'Mengenkode animasi flyover 18 detik ke berkas MP4 Full HD (25 Mbps) tanpa terpotong...'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: isPrecache
                              ? (_renderPrecacheTotal > 0 ? (_renderPrecacheLoaded / _renderPrecacheTotal).clamp(0.0, 1.0) : null)
                              : _renderProgress,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isPrecache
                                  ? 'Ubin di Disk: $_renderPrecacheLoaded / $_renderPrecacheTotal'
                                  : 'Frame $_renderCurrentFrame / $_renderTotalFrames',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPrecache ? Icons.save_alt_rounded : Icons.bolt_rounded,
                              color: AppColors.neonCyan,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isPrecache
                                    ? 'Download Peta HD ke Disk • Bebas Kotak Hitam'
                                    : (is4K ? '4K Ultra HD (45 Mbps) • Layar Utuh • 18s' : 'Full HD 1080p (25 Mbps) • Layar Utuh • 18s'),
                                style: const TextStyle(
                                  color: AppColors.neonCyan,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _isRenderCancelled
                        ? null
                        : () {
                            _isRenderCancelled = true;
                            if (dialogCtx != null && Navigator.canPop(dialogCtx!)) {
                              Navigator.pop(dialogCtx!);
                            }
                            dialogCtx = null;
                            dialogSetState = null;
                            ForegroundServiceHandler.stopRenderProgress();
                            MapPrecacheService.cleanupMemoryCache();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Render video dibatalkan.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    child: const Text(
                      'BATALKAN',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (dialogCtx != null && Navigator.canPop(dialogCtx!)) {
                        Navigator.pop(dialogCtx!);
                      }
                      dialogCtx = null;
                      dialogSetState = null;
                      if (mounted) {
                        setState(() {
                          _isRenderMinimized = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.picture_in_picture_alt_rounded, color: AppColors.neonCyan, size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('Render berlanjut di latar belakang. Video otomatis ke Galeri.'),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.picture_in_picture_alt_rounded, size: 16),
                    label: const Text(
                      'LATAR BELAKANG',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    _reopenRenderDialog = openDialog;
    openDialog();

    // 3. Unduh & simpan 100% ubin rute langsung ke disk penyimpanan internal HP sebelum render dimulai
    try {
      if (_cacheDir == null) {
        final dir = await getApplicationDocumentsDirectory();
        _cacheDir = '${dir.path}/velora_tile_cache';
      }
      await MapPrecacheService.downloadAndCacheRouteTiles(
        coordinates: widget.session.coordinates,
        cacheDir: _cacheDir!,
        providerType: _isSatelliteMode ? 'satellite' : 'osm',
        urlTemplate: _isSatelliteMode
            ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        onProgress: (progress, loaded, total) {
          _renderPrecacheLoaded = loaded;
          _renderPrecacheTotal = total;
          _renderProgress = progress;
          if (dialogSetState != null) {
            dialogSetState!(() {});
          }
          if (_isRenderMinimized && mounted) {
            setState(() {});
          }
          ForegroundServiceHandler.startOrUpdatePrecacheProgress(
            progress: progress,
            loaded: loaded,
            total: total,
            isSatellite: _isSatelliteMode,
          );
        },
        timeout: const Duration(seconds: 60),
        isCancelled: () => _isRenderCancelled,
      );
    } catch (_) {}

    if (_isRenderCancelled) {
      if (mounted) {
        setState(() {
          _cleanRecordMode = false;
          _isRenderingVideo = false;
          _isRenderMinimized = false;
        });
      }
      await ForegroundServiceHandler.stopRenderProgress();
      MapPrecacheService.cleanupMemoryCache();
      return;
    }

    // Ubah fase ke 'encode'
    _renderPhase = 'encode';
    _renderCurrentFrame = 0;
    _renderProgress = 0.0;
    if (dialogSetState != null) {
      dialogSetState!(() {});
    }
    if (_isRenderMinimized && mounted) {
      setState(() {});
    }
    ForegroundServiceHandler.startOrUpdateRenderProgress(
      progress: 0.0,
      currentFrame: 0,
      totalFrames: _renderTotalFrames,
      customTitle: '🎬 Velora: Merender Video Flyover (0%)',
      customText: 'Memulai penulisan frame ke encoder hardware...',
    );

    // Hangatkan kanvas dan pastikan peta pada titik awal ter-render 100% sempurna sebelum perekaman dimulai
    _animController.value = 0.0;
    _lastCameraMoveTime = null;
    _onAnimationTick();

    // Precache & pre-decode ubin di sekitar titik awal langsung ke memori GPU Flutter
    if (widget.session.coordinates.isNotEmpty && _cacheDir != null) {
      final startPt = widget.session.coordinates.first;
      _mapController.move(LatLng(startPt.latitude, startPt.longitude), 16.0);
      final startZ16 = MapPrecacheService.latLonToTile(startPt.latitude, startPt.longitude, 16);
      final startZ17 = MapPrecacheService.latLonToTile(startPt.latitude, startPt.longitude, 17);
      for (final zoomTile in [startZ16, startZ17]) {
        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -2; dy <= 2; dy++) {
            final fPath = VeloraTileProvider.getTileFilePath(
              _cacheDir!,
              _isSatelliteMode ? 'satellite' : 'osm',
              zoomTile.z,
              zoomTile.x + dx,
              zoomTile.y + dy,
            );
            final f = File(fPath);
            if (mounted && f.existsSync() && f.lengthSync() > 100) {
              precacheImage(FileImage(f), context).catchError((_) {});
            }
          }
        }
      }
    }

    if (mounted) setState(() {});
    await WidgetsBinding.instance.endOfFrame;
    // Beri jeda 2 detik agar GPU dan flutter_map selesai melukis seluruh ubin pada titik awal secara sempurna
    await Future.delayed(const Duration(milliseconds: 2000));
    await WidgetsBinding.instance.endOfFrame;

    // 4. Jalankan loop render frame-by-frame
    String? exportedVideoPath;
    try {
      exportedVideoPath = await VideoExportService.renderWidgetToVideo(
        boundaryKey: _recordBoundaryKey,
        totalFrames: _renderTotalFrames,
        fps: 30,
        is4K: is4K,
        targetWidth: is4K ? 2160 : 1080,
        bitrate: is4K ? 35000000 : 20000000,
        isCancelled: () => _isRenderCancelled,
        onStepFrame: (frameIndex, progress) async {
          _animController.value = progress;
          _lastCameraMoveTime = null; // paksa kamera bergerak mengikuti titik rute
          _onAnimationTick();
          if (mounted) setState(() {});
          await WidgetsBinding.instance.endOfFrame;
          // Memberi waktu yang cukup bagi GPU dan flutter_map untuk merender tile secara sempurna
          await Future.delayed(const Duration(milliseconds: 85));
        },
        onProgress: (progress, currentFrame, total) {
          _renderProgress = progress;
          _renderCurrentFrame = currentFrame;
          if (dialogSetState != null) {
            dialogSetState!(() {});
          }
          if (_isRenderMinimized && mounted) {
            setState(() {});
          }
          final percent = (progress * 100).clamp(0, 100).toInt();
          ForegroundServiceHandler.startOrUpdateRenderProgress(
            progress: progress,
            currentFrame: currentFrame,
            totalFrames: total,
            customTitle: '🎬 Velora: Merender Video Flyover ($percent%)',
            customText: 'Frame $currentFrame / $total • Menulis ke Galeri & Download/Velora',
          );
        },
      );
    } catch (e) {
      debugPrint('Error during video render: $e');
    }

    // 5. Tutup dialog progress jika masih terbuka
    if (dialogCtx != null && dialogCtx!.mounted && Navigator.canPop(dialogCtx!)) {
      Navigator.pop(dialogCtx!);
      dialogCtx = null;
      dialogSetState = null;
    }

    // Beritahukan layanan foreground bahwa video selesai
    if (exportedVideoPath != null) {
      await ForegroundServiceHandler.showRenderCompletedNotification(
        title: '🎬 Video Flyover Berhasil Dibuat!',
        text: 'Tersimpan di Galeri & Download/Velora. Siap dibagikan!',
      );
    } else {
      await ForegroundServiceHandler.stopRenderProgress();
    }

    // Kembalikan clean record mode & flag rendering ke false
    if (mounted) {
      setState(() {
        _cleanRecordMode = false;
        _isRenderingVideo = false;
        _isRenderMinimized = false;
      });
    }

    if (_isRenderCancelled) {
      MapPrecacheService.cleanupMemoryCache();
      return;
    }

    // 6. Tampilkan satu-satunya menu hasil ekspor video yang lengkap
    if (exportedVideoPath != null && mounted) {
      _showVideoExportSuccessSheet(exportedVideoPath, is4K: is4K);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat berkas video MP4. Silakan coba kembali.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Menampilkan menu tunggal hasil ekspor video dengan opsi lengkap & konfirmasi galeri
  void _showVideoExportSuccessSheet(String videoPath, {bool is4K = false}) {
    final fileName = videoPath.split('/').last;
    bool isActionBusy = false;
    String? busyActionId;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: AppColors.neonGreen, width: 2),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header Sukses & Badge Galeri
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withAlpha(40),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.neonGreen, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.neonGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Video Berhasil Dibuat!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              is4K
                                  ? '4K Ultra HD • Layar Penuh Utuh • Kristal Jernih'
                                  : 'Full HD 1080p • Layar Penuh Utuh • Bebas Blur',
                              style: const TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Banner Informasi Tersimpan di Galeri
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neonGreen.withAlpha(100), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, color: AppColors.neonGreen, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tersimpan Otomatis di Galeri Ponsel',
                                style: TextStyle(
                                  color: AppColors.neonGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Album Movies > Velora ($fileName)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pilihan Berbagi
                  _buildShareActionTile(
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFFE1306C),
                    title: 'Bagikan ke Instagram (Reels & Story)',
                    subtitle: 'Kirim langsung video flyover 9:16 rasio asli ke Instagram tanpa blur.',
                    badge: 'LANGSUNG KE INSTAGRAM',
                    badgeColor: const Color(0xFFE1306C),
                    enabled: !isActionBusy,
                    isLoading: isActionBusy && busyActionId == 'instagram',
                    onTap: () async {
                      if (isActionBusy) return;
                      setSheetState(() {
                        isActionBusy = true;
                        busyActionId = 'instagram';
                      });
                      if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                        Navigator.pop(sheetCtx);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE1306C),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Membuka Instagram...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      await VideoExportService.shareToInstagram(videoPath);
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildShareActionTile(
                    icon: Icons.chat_rounded,
                    iconColor: const Color(0xFF25D366),
                    title: 'Bagikan ke WhatsApp',
                    subtitle: 'Kirim video MP4 langsung ke Status atau chat WhatsApp.',
                    badge: 'WHATSAPP',
                    badgeColor: const Color(0xFF25D366),
                    enabled: !isActionBusy,
                    isLoading: isActionBusy && busyActionId == 'whatsapp',
                    onTap: () async {
                      if (isActionBusy) return;
                      setSheetState(() {
                        isActionBusy = true;
                        busyActionId = 'whatsapp';
                      });
                      if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                        Navigator.pop(sheetCtx);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF25D366),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Membuka WhatsApp...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      await VideoExportService.shareToWhatsApp(videoPath);
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildShareActionTile(
                    icon: Icons.share_rounded,
                    iconColor: AppColors.primaryOrange,
                    title: 'Bagikan ke Aplikasi Lainnya',
                    subtitle: 'Pilih aplikasi lain seperti TikTok, Telegram, Drive, dsb.',
                    enabled: !isActionBusy,
                    isLoading: isActionBusy && busyActionId == 'other',
                    onTap: () async {
                      if (isActionBusy) return;
                      setSheetState(() {
                        isActionBusy = true;
                        busyActionId = 'other';
                      });
                      if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                        Navigator.pop(sheetCtx);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Membuka menu berbagi...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      await VideoExportService.shareVideo(
                        videoPath,
                        text: 'Flyover Rute Latihan • Velora',
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildShareActionTile(
                    icon: Icons.photo_library_rounded,
                    iconColor: AppColors.electricAmber,
                    title: 'Bagikan Kartu Ringkasan (Foto & Peta HD)',
                    subtitle: 'Buat poster statistik Full HD untuk story atau status.',
                    enabled: !isActionBusy,
                    isLoading: isActionBusy && busyActionId == 'summary_card',
                    onTap: () {
                      if (isActionBusy) return;
                      setSheetState(() {
                        isActionBusy = true;
                        busyActionId = 'summary_card';
                      });
                      if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                        Navigator.pop(sheetCtx);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SharePreviewScreen(session: widget.session),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isActionBusy
                          ? null
                          : () {
                              if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                                Navigator.pop(sheetCtx);
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'SELESAI',
                        style: TextStyle(
                          color: isActionBusy ? AppColors.textMuted.withAlpha(100) : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  void _showStartRecordConfirmDialog() {
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.videocam_rounded, color: AppColors.primaryOrange, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Siapkan Perekam Layar',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Tarik bar status/notifikasi atas ponsel Anda ke bawah.\n'
                  '2. Nyalakan fitur "Perekam Layar" (Screen Recorder) bawaan HP.\n'
                  '3. Tekan "MULAI PUTAR RUTE" di bawah.\n\n'
                  'Seluruh tombol akan disembunyikan dan hasil video rekaman layar otomatis tersimpan di Galeri ponsel Anda.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                        Navigator.pop(dialogCtx);
                      }
                    },
              child: const Text('BATAL', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () {
                      setDialogState(() => isSubmitting = true);
                      if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                        Navigator.pop(dialogCtx);
                      }
                      _enterCleanRecordMode();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
              label: const Text(
                'MULAI PUTAR RUTE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCleanRecordCompletedDialog() {
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Putar Rute Selesai!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rute animasi flyover telah selesai diputar.\n',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '• Ingin Berkas Video Flyover Langsung Jadi?\n'
                  'Tekan tombol "EKSPOR VIDEO MP4" untuk membuat file video MP4 siap bagikan!\n\n'
                  '• Sudah Merekam Layar HP?\n'
                  'Tekan "PILIH DARI GALERI" untuk membagikan file video rekaman layar tersebut.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                        Navigator.pop(dialogCtx);
                      }
                    },
              child: const Text('TUTUP', style: TextStyle(color: AppColors.textMuted)),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () {
                      setDialogState(() => isSubmitting = true);
                      if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                        Navigator.pop(dialogCtx);
                      }
                      _startInAppVideoRender();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonGreen,
                side: const BorderSide(color: AppColors.neonGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.movie_creation_rounded, size: 16),
              label: const Text(
                'EKSPOR VIDEO MP4',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () {
                      setDialogState(() => isSubmitting = true);
                      if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                        Navigator.pop(dialogCtx);
                      }
                      _pickAndShareRecordedVideo();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonCyan,
                side: const BorderSide(color: AppColors.neonCyan),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.video_library_rounded, size: 16),
              label: const Text(
                'PILIH DARI GALERI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () {
                      setDialogState(() => isSubmitting = true);
                      if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                        Navigator.pop(dialogCtx);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SharePreviewScreen(session: widget.session),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
              label: const Text(
                'BAGIKAN KARTU HD',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterCleanRecordMode() {
    setState(() {
      _cleanRecordMode = true;
      _showRecordTooltip = true;
      _autoFollow = true;
    });

    // Reset dan putar dari awal
    _animController.reset();
    _lastChimeKm = 0;
    _lastCameraMoveTime = null;
    _lastCameraPos = null;
    _animController.forward();
    _isPlaying = true;

    _recordTooltipTimer?.cancel();
    _recordTooltipTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showRecordTooltip = false;
        });
      }
    });
  }

  Future<void> _showShareVideoSheet() => _showExportOptionsSheet();

  Future<void> _showExportOptionsSheet() async {
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      _togglePlayPause();
    }

    bool isActionBusy = false;
    String? busyActionId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.9,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: AppColors.borderHighlight, width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle drag indicator
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Judul & Deskripsi
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primaryOrange.withAlpha(120),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.video_library_rounded,
                            color: AppColors.primaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bagikan Video Rute',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Animasi sinematik perjalanan Anda',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pengaturan Tampilan & Format Video
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: AppColors.electricAmber,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'PENGATURAN TAMPILAN',
                                    style: TextStyle(
                                      color: AppColors.electricAmber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Toggle 1: Tata Letak Proporsional
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.neonCyan.withAlpha(90),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fit_screen_rounded,
                                  color: AppColors.neonCyan,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tata Letak Proporsional',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Menyesuaikan posisi statistik agar selalu terlihat rapi saat dibagikan.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _enableSocialSafeZone,
                                activeThumbColor: AppColors.neonCyan,
                                activeTrackColor: AppColors.neonCyan.withAlpha(140),
                                onChanged: isActionBusy
                                    ? null
                                    : (val) {
                                        setSheetState(() {
                                          _enableSocialSafeZone = val;
                                        });
                                        if (mounted) setState(() {});
                                      },
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16),

                          // Toggle 2: Nama Jalan di Jalur
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF0284C7).withAlpha(120),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.alt_route_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama Jalan di Jalur',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Menampilkan penanda nama jalan berwarna biru di rute.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _showRoadNameBadge,
                                activeThumbColor: const Color(0xFF0284C7),
                                activeTrackColor: const Color(0xFF0284C7).withAlpha(140),
                                onChanged: isActionBusy
                                    ? null
                                    : (val) {
                                        setSheetState(() {
                                          _showRoadNameBadge = val;
                                        });
                                        if (mounted) setState(() {});
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opsi 1: Ekspor Video Flyover MP4 Full HD
                    _buildShareActionTile(
                      icon: Icons.movie_creation_rounded,
                      iconColor: AppColors.primaryOrange,
                      title: 'Ekspor Video Full HD',
                      subtitle:
                          'Animasi 1080p jernih dan tajam, otomatis tersimpan ke Galeri.',
                      badge: '1080P',
                      badgeColor: AppColors.neonGreen,
                      enabled: !isActionBusy,
                      isLoading: isActionBusy && busyActionId == 'fhd',
                      onTap: () {
                        if (isActionBusy || _isRenderingVideo) return;
                        setSheetState(() {
                          isActionBusy = true;
                          busyActionId = 'fhd';
                        });
                        if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                          Navigator.pop(sheetCtx);
                        }
                        if (mounted) {
                          _startInAppVideoRender(is4K: false);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Opsi 2: Ekspor Video Flyover 4K Ultra HD
                    _buildShareActionTile(
                      icon: Icons.hd_rounded,
                      iconColor: AppColors.electricAmber,
                      title: 'Ekspor Video Ultra HD',
                      subtitle:
                          'Resolusi 4K dengan kualitas sinematik maksimal, otomatis tersimpan ke Galeri.',
                      badge: '4K UHD',
                      badgeColor: AppColors.electricAmber,
                      enabled: !isActionBusy,
                      isLoading: isActionBusy && busyActionId == '4k',
                      onTap: () {
                        if (isActionBusy || _isRenderingVideo) return;
                        setSheetState(() {
                          isActionBusy = true;
                          busyActionId = '4k';
                        });
                        if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                          Navigator.pop(sheetCtx);
                        }
                        if (mounted) {
                          _startInAppVideoRender(is4K: true);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Opsi 3: Mode Rekam Layar
                    _buildShareActionTile(
                      icon: Icons.fiber_smart_record_rounded,
                      iconColor: AppColors.neonCyan,
                      title: 'Mode Rekam Layar',
                      subtitle:
                          'Menampilkan rute tanpa tombol antarmuka untuk direkam secara manual.',
                      enabled: !isActionBusy,
                      isLoading: isActionBusy && busyActionId == 'clean_record',
                      onTap: () {
                        if (isActionBusy) return;
                        setSheetState(() {
                          isActionBusy = true;
                          busyActionId = 'clean_record';
                        });
                        if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                          Navigator.pop(sheetCtx);
                        }
                        if (mounted) {
                          _showStartRecordConfirmDialog();
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Opsi 4: Bagikan Berkas Video dari Galeri
                    _buildShareActionTile(
                      icon: Icons.upload_file_rounded,
                      iconColor: AppColors.neonCyan,
                      title: 'Bagikan Berkas Video',
                      subtitle:
                          'Kirim video yang telah tersimpan di Galeri ke aplikasi lain.',
                      enabled: !isActionBusy,
                      isLoading: isActionBusy && busyActionId == 'gallery',
                      onTap: () async {
                        if (isActionBusy) return;
                        setSheetState(() {
                          isActionBusy = true;
                          busyActionId = 'gallery';
                        });
                        if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                          Navigator.pop(sheetCtx);
                        }
                        await _pickAndShareRecordedVideo();
                      },
                    ),
                    const SizedBox(height: 10),

                    // Opsi 5: Bagikan Kartu Ringkasan
                    _buildShareActionTile(
                      icon: Icons.photo_library_rounded,
                      iconColor: AppColors.electricAmber,
                      title: 'Bagikan Kartu Ringkasan',
                      subtitle:
                          'Buat poster statistik beresolusi tinggi rasio vertikal siap dibagikan.',
                      enabled: !isActionBusy,
                      isLoading: isActionBusy && busyActionId == 'summary_card',
                      onTap: () {
                        if (isActionBusy) return;
                        setSheetState(() {
                          isActionBusy = true;
                          busyActionId = 'summary_card';
                        });
                        if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                          Navigator.pop(sheetCtx);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharePreviewScreen(session: widget.session),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tombol Tutup / Batal
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: isActionBusy
                            ? null
                            : () {
                                if (sheetCtx.mounted && Navigator.canPop(sheetCtx)) {
                                  Navigator.pop(sheetCtx);
                                }
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'TUTUP',
                          style: TextStyle(
                            color: isActionBusy
                                ? AppColors.textMuted.withAlpha(100)
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  Future<void> _pickAndShareRecordedVideo() async {
    if (_isPickingVideo) return;
    _isPickingVideo = true;
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final sportsName = widget.session.sportsType == SportsType.ride
            ? 'Gowes'
            : 'Lari';
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(video.path)],
            text:
                'Rute $sportsName: ${widget.session.displayTitle} (${(widget.session.distanceMeters / 1000).toStringAsFixed(2)} km) • Velora',
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Belum ada video rekaman yang dipilih. Tekan "BAGIKAN KARTU HD" untuk membagikan poster rute & foto!',
              ),
              backgroundColor: AppColors.primaryOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka galeri: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isPickingVideo = false;
    }
  }

  Widget _buildShareActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return Material(
      color: AppColors.cardSurfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: enabled && !isLoading ? onTap : null,
        splashColor: iconColor.withAlpha(50),
        highlightColor: Colors.white.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withAlpha(90), width: 1.2),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                        )
                      : Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: enabled ? Colors.white : AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? AppColors.primaryOrange)
                                    .withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: badgeColor ?? AppColors.primaryOrange,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: badgeColor ?? AppColors.primaryOrange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled ? AppColors.textSecondary : AppColors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textMuted),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled ? Colors.white38 : Colors.white12,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanRecordHud({
    required double currentDistKm,
    required double currentSpeedKmh,
    required double currentElevation,
    required double currentElevationGain,
    required int elapsedSeconds,
  }) {
    final isRun = widget.session.sportsType == SportsType.run;
    final speedValue = isRun
        ? (currentSpeedKmh > 1.0
            ? PaceCalculator.formatPace(3600.0 / currentSpeedKmh)
            : "--'--\"")
        : currentSpeedKmh.toStringAsFixed(1);
    final speedUnit = isRun ? '/KM' : 'KM/H';
    final speedLabel = isRun ? 'PACE' : 'SPEED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(225),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // 1. JARAK
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHudMetricColumn(
                icon: Icons.straighten_rounded,
                label: 'JARAK',
                value: currentDistKm.toStringAsFixed(2),
                unit: 'KM',
                valueColor: AppColors.neonCyan,
              ),
            ),
          ),
          _buildHudDivider(),

          // 2. SPEED / PACE
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHudMetricColumn(
                icon: Icons.speed_rounded,
                label: speedLabel,
                value: speedValue,
                unit: speedUnit,
                valueColor: AppColors.primaryOrange,
              ),
            ),
          ),
          _buildHudDivider(),

          // 3. ELEVASI
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHudMetricColumn(
                icon: _isClimbing ? Icons.trending_up_rounded : Icons.terrain_rounded,
                label: _isClimbing ? '▲ +${_currentGrade.toStringAsFixed(1)}%' : 'ELEVASI',
                value: currentElevation.toStringAsFixed(0),
                unit: 'M',
                valueColor: _isClimbing ? const Color(0xFFFF5722) : const Color(0xFF818CF8),
              ),
            ),
          ),
          _buildHudDivider(),

          // 4. GAIN
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHudMetricColumn(
                icon: Icons.arrow_upward_rounded,
                label: 'GAIN',
                value: '+${currentElevationGain.toStringAsFixed(0)}',
                unit: 'M',
                valueColor: AppColors.neonGreen,
              ),
            ),
          ),
          _buildHudDivider(),

          // 5. WAKTU
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHudMetricColumn(
                icon: Icons.timer_outlined,
                label: 'WAKTU',
                value: PaceCalculator.formatDuration(elapsedSeconds),
                unit: '',
                valueColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudMetricColumn({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2.5),
              Text(
                unit,
                style: TextStyle(
                  color: valueColor.withAlpha(200),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHudDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white12,
    );
  }
}

