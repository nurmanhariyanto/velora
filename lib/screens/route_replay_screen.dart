import 'dart:async';
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
import 'package:share_plus/share_plus.dart';
import '../services/map_precache_service.dart';
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
  String _athleteName = UserProfileService.defaultAthleteName;

  // Status pemutaran animasi
  bool _isPlaying = true;
  double _playbackSpeed = 2.0; // 1x, 2x, 4x, 8x
  bool _autoFollow = true;
  bool _mapDarkTheme = false;
  bool _isSatelliteMode = true; // Default: Citra Satelit HD Asli (seperti video referensi)
  bool _isMapReady = false;
  bool _povMode = false; // Default: Mode Flyover Stabil & Mulus (Peta Menghadap Utara, Bebas Pusing)
  bool _is3dTilted = true; // Default: Sudut Pandang 3D Menyamping (Perspective Tilt Oblique Bird's Eye View)
  double _smoothedBearing = 0.0;

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

  // Status Mode Rekam Layar Bersih (Clean Screen Record)
  bool _cleanRecordMode = false;
  bool _showRecordTooltip = false;
  Timer? _recordTooltipTimer;

  // Status Pre-buffering Tile Peta untuk 60 FPS Mulus di Semua HP
  bool _isPreloadingTiles = true;
  double _preloadProgress = 0.0;
  int _preloadLoaded = 0;
  int _preloadTotal = 0;
  Timer? _precacheTimer;

  // Matriks OpenStreetMap Mode Gelap Khas Velora
  static const List<double> _darkMatrix = <double>[
    0.45, 0.00, 0.00, 0, -68,
    0.00, 0.48, 0.00, 0, -65,
    0.00, 0.00, 0.58, 0, -55,
    0.00, 0.00, 0.00, 1,   0,
  ];

  late final TileProvider _tileProvider;

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate: _isSatelliteMode
          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'online.nurmancloud.velora',
      tileProvider: _tileProvider,
      panBuffer: 4,
      keepBuffer: 16,
      tileDisplay: _isRenderingVideo
          ? const TileDisplay.instantaneous()
          : const TileDisplay.fadeIn(
              duration: Duration(milliseconds: 100),
            ),
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
    _tileProvider = NetworkTileProvider();

    // 1. Hitung akumulasi jarak per titik koordinat
    _cumulativeDistances = _precomputeCumulativeDistances(widget.session.coordinates);

    // 2. Ekstrak penanda milestone rute (KM Splits, Puncak, Max Speed)
    _milestones = TrackAnalysisService.analyzeTrack(
      widget.session.coordinates,
      widget.session.sportsType,
    );

    // 3. Durasi dasar animasi flyover (sekitar 30 detik pada kecepatan 1x)
    const baseDuration = Duration(seconds: 30);
    _animController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (baseDuration.inMilliseconds / _playbackSpeed).round(),
      ),
    );

    _animController.addListener(_onAnimationTick);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final wasCleanRecord = _cleanRecordMode;
        setState(() {
          _isPlaying = false;
          _cleanRecordMode = false;
        });
        if (wasCleanRecord && mounted) {
          _showCleanRecordCompletedDialog();
        }
      }
    });

    _loadAthleteName();

    // Memuat awal (pre-cache) tile peta di sepanjang rute untuk performa 60 FPS mulus di semua ponsel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTilePrecache();
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

    const baseDuration = Duration(seconds: 30);
    final remainingProgress = 1.0 - _animController.value;

    setState(() {
      _playbackSpeed = newSpeed;
      _animController.duration = Duration(
        milliseconds: (baseDuration.inMilliseconds / _playbackSpeed).round(),
      );
      if (_isPlaying) {
        _animController.animateTo(
          1.0,
          duration: Duration(
            milliseconds: (baseDuration.inMilliseconds *
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
    if (!_isPlaying) {
      _togglePlayPause();
    } else {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _precacheTimer?.cancel();
    _chimeTimer?.cancel();
    _recordTooltipTimer?.cancel();
    _animController.removeListener(_onAnimationTick);
    _animController.dispose();
    _mapController.dispose();
    _tileProvider.dispose();
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
    final progress = _animController.value;
    final rawIndex = progress * (totalPoints - 1);
    final currentIndex = rawIndex.floor().clamp(0, totalPoints - 1);
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);
    final fraction = rawIndex - currentIndex;

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

    // Metrik dinamis berjalan terinterpolasi
    final currentDistanceM = _cumulativeDistances.isNotEmpty
        ? (_cumulativeDistances[currentIndex] +
            (_cumulativeDistances[nextIndex] - _cumulativeDistances[currentIndex]) * fraction)
        : 0.0;
    final currentDistKm = currentDistanceM / 1000.0;
    final currentSpeed = currentPt.speedKmh + (nextPt.speedKmh - currentPt.speedKmh) * fraction;
    final currentElevation = currentPt.elevation + (nextPt.elevation - currentPt.elevation) * fraction;
    final elapsedSec = ((currentPt.timestamp - coords.first.timestamp) / 1000)
        .round()
        .clamp(0, widget.session.durationSeconds);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RepaintBoundary(
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

                          // 2. Map Satelit 3D Diperluas & Dimiringkan Sinematik (~47° Tilt Oblique Perspektif)
                          Positioned(
                            top: -screenH * 0.18,
                            bottom: -screenH * 0.40,
                            left: -screenW * 0.30,
                            right: -screenW * 0.30,
                            child: Transform(
                              alignment: const FractionalOffset(0.5, 0.5),
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(0.82), // ~47° kemiringan perspektif 3D menyamping sinematik
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
                            height: screenH * 0.26,
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
              top: MediaQuery.of(context).padding.top + 14,
              left: 18,
              child: Container(
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
                    Text(
                      '• $_athleteName',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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

          // 4. Panel HUD Statistik Berjalan & Pengontrol Pemutaran Bawah
          Positioned(
            bottom: _cleanRecordMode ? 36 : 24,
            left: 16,
            right: 16,
            child: _cleanRecordMode
                ? _buildCleanRecordHud(
                    currentDistKm: currentDistKm,
                    currentSpeedKmh: currentSpeed,
                    currentElevation: currentElevation,
                    elapsedSeconds: elapsedSec,
                  )
                : _buildBottomHudAndControls(
                    currentDistKm: currentDistKm,
                    currentSpeedKmh: currentSpeed,
                    currentElevation: currentElevation,
                    elapsedSeconds: elapsedSec,
                    progress: progress,
                  ),
          ),

          // 5. Toast / Tooltip saat Mode Rekam Bersih Baru Dimulai
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Pre-buffering Loading Overlay (Menyiapkan Peta untuk 60 FPS Mulus di Semua HP)
          if (_isPreloadingTiles)
            _buildPreloadingOverlay(),
        ],
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
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
            const SizedBox(height: 16),
            const Text(
              'Menyiapkan Peta Rute',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
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
            const SizedBox(height: 18),
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
                Text(
                  _preloadTotal > 0
                      ? '$_preloadLoaded / $_preloadTotal Tile'
                      : 'Menghitung rute...',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11.5,
                  ),
                ),
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
            const SizedBox(height: 16),
            TextButton.icon(
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
          ],
        ),
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
              color: _isSatelliteMode
                  ? Colors.white.withAlpha(70)
                  : Colors.white.withAlpha(45),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),

        // Garis Rute Aktif Tergambar Maju (Glow Kuning Emas Menyala Sinematik)
        if (traversedPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Lapisan Pendaran Cahaya (Outer Glow)
              Polyline(
                points: traversedPoints,
                strokeWidth: 12.0,
                color: _isSatelliteMode
                    ? const Color(0xFFFFD600).withAlpha(120)
                    : AppColors.neonCyan.withAlpha(80),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              // Garis Inti Terang
              Polyline(
                points: traversedPoints,
                strokeWidth: 5.5,
                color: _isSatelliteMode
                    ? const Color(0xFFFFEA00)
                    : AppColors.neonCyan,
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
    if (_isSatelliteMode) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Pendaran Aura Luar Emas Lembut
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600).withAlpha(50),
                shape: BoxShape.circle,
              ),
            ),
            // 2. Lingkar Dalam Emas Bersinar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEA00).withAlpha(190),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD600).withAlpha(220),
                    blurRadius: 10,
                    spreadRadius: 2,
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
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efek Denyut Halo Bersinar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withAlpha(60),
              shape: BoxShape.circle,
            ),
          ),
          // Lingkaran Inti Atlet
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.electricAmber, AppColors.primaryOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: (_povMode ? 0.0 : bearingDegrees) *
                  math.pi /
                  180.0,
              child: const Icon(
                Icons.navigation_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
        12,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
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
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Kembali',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.session.displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryOrange,
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'FLYOVER REPLAY',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_athleteName • $formattedDate',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tombol Mode POV Flyover (Chase Cam vs Flyover Stabil Utara)
          IconButton(
            icon: Icon(
              _povMode ? Icons.explore_rounded : Icons.explore_off_rounded,
              color: _povMode ? AppColors.electricAmber : Colors.white60,
              size: 22,
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
            icon: Icon(
              _is3dTilted ? Icons.view_in_ar_rounded : Icons.layers_rounded,
              color: _is3dTilted ? AppColors.electricAmber : Colors.white60,
              size: 22,
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
            icon: Icon(
              _autoFollow ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: _autoFollow ? AppColors.neonCyan : Colors.white60,
              size: 22,
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
            icon: Icon(
              _isSatelliteMode
                  ? Icons.satellite_alt_rounded
                  : Icons.map_rounded,
              color: _isSatelliteMode ? AppColors.electricAmber : Colors.white70,
              size: 22,
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
              icon: Icon(
                _mapDarkTheme
                    ? Icons.brightness_medium_rounded
                    : Icons.wb_sunny_rounded,
                color: _mapDarkTheme ? AppColors.electricAmber : Colors.white70,
                size: 22,
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
            icon: const Icon(
              Icons.videocam_rounded,
              color: AppColors.primaryOrange,
              size: 24,
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
                    Text(
                      milestone.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Baris 4 Metrik Dinamis HUD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHudMetric(
                label: 'JARAK',
                value: currentDistKm.toStringAsFixed(2),
                unit: 'KM',
                accentColor: AppColors.neonCyan,
              ),
              _buildVerticalDivider(),
              _buildHudMetric(
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
              _buildVerticalDivider(),
              _buildHudMetric(
                label: 'ELEVASI',
                value: '+${currentElevation.toStringAsFixed(0)}',
                unit: 'M',
                accentColor: const Color(0xFF6366F1),
              ),
              _buildVerticalDivider(),
              _buildHudMetric(
                label: 'WAKTU',
                value: PaceCalculator.formatDuration(elapsedSeconds),
                unit: '',
                accentColor: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Timeline Scrubber Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              activeTrackColor: AppColors.primaryOrange,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.primaryOrange,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _seekTo,
            ),
          ),

          // 3. Tombol Kontrol Pemutaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pengubah Kecepatan Pemutaran (1x, 2x, 4x, 8x)
              InkWell(
                onTap: _changePlaybackSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${_playbackSpeed.toStringAsFixed(0)}x',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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
                    onPressed: _restartReplay,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.electricAmber,
                            AppColors.primaryOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Persentase Progress Rute
              Container(
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: accentColor.withAlpha(160),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
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

  /// Merender animasi flyover rute menjadi berkas video MP4 secara otomatis
  Future<void> _startInAppVideoRender() async {
    // 1. Jeda pemutaran animasi jika sedang aktif
    if (_isPlaying) {
      _togglePlayPause();
    }

    bool isCancelled = false;
    double exportProgress = 0.0;
    int currentFrameNum = 0;
    const totalFrames = 240; // ~8 detik video flyover super mulus pada 30 FPS
    String renderPhase = 'precache'; // 'precache' atau 'encode'
    int precacheLoaded = 0;
    int precacheTotal = 0;
    StateSetter? dialogSetState;

    // 2. Aktifkan clean record mode & rendering flag
    setState(() {
      _cleanRecordMode = true;
      _isRenderingVideo = true;
      _autoFollow = true;
    });

    // Tampilkan modal dialog progres rendering MP4
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            final isPrecache = renderPhase == 'precache';
            final percent = isPrecache
                ? (precacheTotal > 0 ? ((precacheLoaded / precacheTotal) * 100).toInt() : 0)
                : (exportProgress * 100).clamp(0, 100).toInt();

            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
              ),
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
                      isPrecache ? 'Menyiapkan Peta Satelit HD' : 'Merender Video Flyover 1080p',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPrecache
                        ? 'Memuat potongan citra satelit rute ke memori agar hasil video bebas kotak hitam...'
                        : 'Mengenkode animasi flyover ke berkas MP4 Full HD (18 Mbps) beresolusi tinggi...',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: isPrecache
                          ? (precacheTotal > 0 ? (precacheLoaded / precacheTotal).clamp(0.0, 1.0) : null)
                          : exportProgress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPrecache
                            ? 'Tile $precacheLoaded / $precacheTotal'
                            : 'Frame $currentFrameNum / $totalFrames',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: AppColors.neonCyan, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Hardware MediaCodec • 100% Offline',
                          style: TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'BATALKAN',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // 3. Pre-cache 100% tile rute ke RAM sebelum mulai render agar video bebas kotak hitam
    try {
      await MapPrecacheService.precacheRouteTiles(
        coordinates: widget.session.coordinates,
        context: context,
        tileProvider: _tileProvider,
        tileLayer: _buildTileLayer(),
        zoom: 16,
        maxTiles: 200,
        urlTemplate: _isSatelliteMode
            ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        onProgress: (progress, loaded, total) {
          precacheLoaded = loaded;
          precacheTotal = total;
          if (dialogSetState != null) {
            dialogSetState!(() {});
          }
        },
        timeout: const Duration(seconds: 12),
      );
    } catch (_) {}

    if (isCancelled) {
      if (mounted) {
        setState(() {
          _cleanRecordMode = false;
          _isRenderingVideo = false;
        });
      }
      return;
    }

    // Ubah fase ke 'encode'
    renderPhase = 'encode';
    if (dialogSetState != null) {
      dialogSetState!(() {});
    }

    // 4. Jalankan loop render frame-by-frame
    String? exportedVideoPath;
    try {
      exportedVideoPath = await VideoExportService.renderWidgetToVideo(
        boundaryKey: _recordBoundaryKey,
        totalFrames: totalFrames,
        fps: 30,
        targetWidth: 1080,
        bitrate: 18000000,
        isCancelled: () => isCancelled,
        onStepFrame: (frameIndex, progress) async {
          _animController.value = progress;
          _lastCameraMoveTime = null; // paksa kamera bergerak mengikuti titik rute
          _onAnimationTick();
          if (mounted) setState(() {});
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 30));
        },
        onProgress: (progress, currentFrame, total) {
          exportProgress = progress;
          currentFrameNum = currentFrame;
          if (dialogSetState != null) {
            dialogSetState!(() {});
          }
        },
      );
    } catch (e) {
      debugPrint('Error during video render: $e');
    }

    // 5. Tutup dialog progress jika masih terbuka
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Kembalikan clean record mode & flag rendering ke false
    if (mounted) {
      setState(() {
        _cleanRecordMode = false;
        _isRenderingVideo = false;
      });
    }

    if (isCancelled) return;

    // 6. Tampilkan dialog hasil video MP4 yang siap dibagikan ke sosmed dan tersimpan di galeri
    if (exportedVideoPath != null && mounted) {
      final fileName = exportedVideoPath.split('/').last;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.neonGreen, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 28),
              SizedBox(width: 10),
              Text(
                'Video Berhasil Dibuat!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Tersimpan di Galeri Ponsel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonGreen.withAlpha(120), width: 1.2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.download_done_rounded, color: AppColors.neonGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tersimpan Otomatis di Galeri Ponsel',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Video flyover rute MP4 Full HD (1080p) telah selesai dibuat dan tersimpan permanen di memori ponsel. Anda dapat langsung membagikannya atau kembali ke menu opsi.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.movie_rounded, color: AppColors.primaryOrange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Download/Velora/$fileName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('SELESAI', style: TextStyle(color: AppColors.textMuted)),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showShareVideoSheet();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderHighlight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.menu_rounded, size: 17, color: Colors.white70),
              label: const Text(
                'MENU OPSI LAIN',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await VideoExportService.shareVideo(
                  exportedVideoPath!,
                  text: 'Flyover Rute Latihan • Velora',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
              label: const Text(
                'BAGIKAN VIDEO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
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

  void _showStartRecordConfirmDialog() {
    Navigator.of(context, rootNavigator: true).pop();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.videocam_rounded, color: AppColors.primaryOrange, size: 28),
            SizedBox(width: 10),
            Text(
              'Siapkan Perekam Layar',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _enterCleanRecordMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
            label: const Text(
              'MULAI PUTAR RUTE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showCleanRecordCompletedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 28),
            SizedBox(width: 10),
            Text(
              'Putar Rute Selesai!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('TUTUP', style: TextStyle(color: AppColors.textMuted)),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _startInAppVideoRender();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.neonGreen,
              side: const BorderSide(color: AppColors.neonGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.movie_creation_rounded, size: 16),
            label: const Text(
              'EKSPOR VIDEO MP4',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndShareRecordedVideo();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.neonCyan,
              side: const BorderSide(color: AppColors.neonCyan),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.video_library_rounded, size: 16),
            label: const Text(
              'PILIH DARI GALERI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
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
            ),
            icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
            label: const Text(
              'BAGIKAN KARTU HD',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
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

  Future<void> _showShareVideoSheet() async {
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      _togglePlayPause();
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
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
                          'Bagikan Video Flyover Rute',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Instagram Reels, TikTok, YouTube Shorts & WhatsApp',
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
              const SizedBox(height: 20),

              // Opsi 1: Ekspor Video Flyover (MP4) Otomatis
              _buildShareActionTile(
                icon: Icons.movie_creation_rounded,
                iconColor: AppColors.primaryOrange,
                title: 'Ekspor Video MP4 (Simpan ke Galeri & Bagikan)',
                subtitle:
                    'Video flyover rute MP4 Full HD otomatis dirender, disimpan langsung ke Galeri HP (Download/Velora), dan siap dibagikan ke WhatsApp, Reels, atau TikTok.',
                badge: 'OTOMATIS TERSIMPAN KE GALERI',
                badgeColor: AppColors.neonGreen,
                onTap: () {
                  Navigator.pop(ctx);
                  _startInAppVideoRender();
                },
              ),
              const SizedBox(height: 10),

              // Opsi 2: Mode Rekam Layar Bersih
              _buildShareActionTile(
                icon: Icons.fiber_smart_record_rounded,
                iconColor: AppColors.neonCyan,
                title: 'Mulai Mode Rekam Layar Bersih',
                subtitle:
                    'Sembunyikan tombol antarmuka dan putar rute dari KM 0 untuk direkam dengan Perekam Layar bawaan HP.',
                onTap: _showStartRecordConfirmDialog,
              ),
              const SizedBox(height: 10),

              // Opsi 3: Bagikan Video dari Galeri
              _buildShareActionTile(
                icon: Icons.upload_file_rounded,
                iconColor: AppColors.neonCyan,
                title: 'Bagikan Berkas Video dari Galeri',
                subtitle:
                    'Kirim langsung hasil rekaman layar ke WhatsApp, Instagram Reels, TikTok, atau aplikasi lainnya.',
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndShareRecordedVideo();
                },
              ),
              const SizedBox(height: 10),

              // Opsi 4: Bagikan Kartu Ringkasan (Foto & Peta HD)
              _buildShareActionTile(
                icon: Icons.photo_library_rounded,
                iconColor: AppColors.electricAmber,
                title: 'Bagikan Kartu Ringkasan (Foto & Peta HD)',
                subtitle:
                    'Buat gambar poster statistik Full HD rasio 9:16 untuk Instagram Story atau Status WA.',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SharePreviewScreen(session: widget.session),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
    );
  }

  Future<void> _pickAndShareRecordedVideo() async {
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
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
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanRecordHud({
    required double currentDistKm,
    required double currentSpeedKmh,
    required double currentElevation,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. JARAK
          _buildHudMetricColumn(
            icon: Icons.straighten_rounded,
            label: 'JARAK',
            value: currentDistKm.toStringAsFixed(2),
            unit: 'KM',
            valueColor: AppColors.neonCyan,
          ),
          _buildHudDivider(),

          // 2. SPEED / PACE
          _buildHudMetricColumn(
            icon: Icons.speed_rounded,
            label: speedLabel,
            value: speedValue,
            unit: speedUnit,
            valueColor: AppColors.primaryOrange,
          ),
          _buildHudDivider(),

          // 3. ELEVASI
          _buildHudMetricColumn(
            icon: Icons.terrain_rounded,
            label: 'ELEVASI',
            value: '+${currentElevation.toStringAsFixed(0)}',
            unit: 'M',
            valueColor: const Color(0xFF818CF8),
          ),
          _buildHudDivider(),

          // 4. WAKTU
          _buildHudMetricColumn(
            icon: Icons.timer_outlined,
            label: 'WAKTU',
            value: PaceCalculator.formatDuration(elapsedSeconds),
            unit: '',
            valueColor: Colors.white,
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
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2.5),
              Text(
                unit,
                style: TextStyle(
                  color: valueColor.withAlpha(200),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
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
      height: 30,
      color: Colors.white12,
    );
  }
}
