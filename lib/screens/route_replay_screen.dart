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
import '../services/track_analysis_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/track_milestone_pin.dart';

/// Layar Pemutar Animasi Ulang Lintasan Rute (Route Flyover / 3D-2D Replay ala Strava & Relive)
class RouteReplayScreen extends StatefulWidget {
  final ActivitySession session;

  const RouteReplayScreen({
    super.key,
    required this.session,
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
  bool _mapDarkTheme = true;
  bool _isMapReady = false;

  // Titik aktif & notifikasi milestone
  TrackMilestone? _latestChimeMilestone;
  Timer? _chimeTimer;
  int _lastChimeKm = 0;

  // Matriks OpenStreetMap Mode Gelap Khas Velora
  static const List<double> _darkMatrix = <double>[
    0.45, 0.00, 0.00, 0, -68,
    0.00, 0.48, 0.00, 0, -65,
    0.00, 0.00, 0.58, 0, -55,
    0.00, 0.00, 0.00, 1,   0,
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

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
        setState(() {
          _isPlaying = false;
        });
      }
    });

    _loadAthleteName();

    // Mulai animasi otomatis setelah frame pertama selesai dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.session.coordinates.length >= 2) {
        _animController.forward();
      }
    });
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

    final currentPoint = widget.session.coordinates[index];
    final currentDistMeters = _cumulativeDistances.isNotEmpty
        ? _cumulativeDistances[index]
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
          latitude: currentPoint.latitude,
          longitude: currentPoint.longitude,
          distanceMeters: currentDistMeters,
          elevation: currentPoint.elevation,
          speedKmh: currentPoint.speedKmh,
          title: 'Kilometer $currentKm Tercapai',
          description: 'Split rute aktif',
        ),
      );
      _triggerMilestoneChime(matchedSplit);
    }

    // Kamera mengikuti posisi titik penunjuk atlet jika auto-follow aktif
    if (_autoFollow && _isMapReady) {
      try {
        _mapController.move(
          LatLng(currentPoint.latitude, currentPoint.longitude),
          _mapController.camera.zoom,
        );
      } catch (_) {
        // Abaikan jika map controller belum siap atau belum dirender
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
    final totalPoints = widget.session.coordinates.length;
    final idx = (value * (totalPoints - 1)).floor().clamp(0, totalPoints - 1);
    if (_cumulativeDistances.isNotEmpty) {
      _lastChimeKm = (_cumulativeDistances[idx] / 1000.0).floor();
    }
  }

  void _restartReplay() {
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
    _chimeTimer?.cancel();
    _animController.removeListener(_onAnimationTick);
    _animController.dispose();
    _mapController.dispose();
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
    final currentIndex = (progress * (totalPoints - 1)).floor().clamp(0, totalPoints - 1);
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);

    final currentPt = coords[currentIndex];
    final nextPt = coords[nextIndex];

    // Hitung sudut bearing/rotasi arah kendaraan
    final bearing = Haversine.calculateBearing(
      currentPt.latitude,
      currentPt.longitude,
      nextPt.latitude,
      nextPt.longitude,
    );

    // Titik yang sudah dilalui hingga saat ini
    final traversedPoints = coords
        .sublist(0, currentIndex + 1)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Seluruh rute penuh sebagai latar belakang
    final fullRoutePoints = coords
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Metrik dinamis berjalan
    final currentDistanceM = _cumulativeDistances.isNotEmpty
        ? _cumulativeDistances[currentIndex]
        : 0.0;
    final currentDistKm = currentDistanceM / 1000.0;
    final currentSpeed = currentPt.speedKmh;
    final currentElevation = currentPt.elevation;
    final elapsedSec = ((currentPt.timestamp - coords.first.timestamp) / 1000)
        .round()
        .clamp(0, widget.session.durationSeconds);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Lapisan Peta OpenStreetMap Interaktif
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(currentPt.latitude, currentPt.longitude),
              initialZoom: 16.5,
              minZoom: 4.0,
              maxZoom: 19.0,
              onMapReady: () {
                if (mounted) {
                  _isMapReady = true;
                }
              },
            ),
            children: [
              // Tile OSM (Retina High-Definition Mode, Tajam & Anti-Blur)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'online.nurmancloud.velora',
                tileDisplay: const TileDisplay.instantaneous(),
                retinaMode: true,
                tileBuilder: _mapDarkTheme
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(_darkMatrix),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),

              // Garis Rute Keseluruhan (Transparan / Muted)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: fullRoutePoints,
                    strokeWidth: 5.0,
                    color: Colors.white.withAlpha(45),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),

              // Garis Rute Aktif Tergambar Maju (Glow Neon Cyan)
              if (traversedPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: traversedPoints,
                      strokeWidth: 11.0,
                      color: AppColors.neonCyan.withAlpha(80),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    Polyline(
                      points: traversedPoints,
                      strokeWidth: 6.0,
                      color: AppColors.neonCyan,
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
                    point: LatLng(currentPt.latitude, currentPt.longitude),
                    width: 52,
                    height: 52,
                    child: _buildRiderMarker(bearing),
                  ),
                ],
              ),
            ],
          ),

          // 2. Bar Header Atas (Nama Atlet, Tombol Kembali, Kontrol Kamera)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopHeaderBar(),
          ),

          // 3. Pop-up Chime Banner saat Melewati Milestone KM
          if (_latestChimeMilestone != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: _buildMilestoneChimeCard(_latestChimeMilestone!),
            ),

          // 4. Panel HUD Statistik Berjalan & Pengontrol Pemutaran Bawah
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildBottomHudAndControls(
              currentDistKm: currentDistKm,
              currentSpeedKmh: currentSpeed,
              currentElevation: currentElevation,
              elapsedSeconds: elapsedSec,
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderMarker(double bearingDegrees) {
    final isRide = widget.session.sportsType == SportsType.ride;

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
              angle: (bearingDegrees * math.pi / 180.0),
              child: Icon(
                isRide ? Icons.navigation_rounded : Icons.directions_run_rounded,
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
          // Tombol Mode Gelap/Terang
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _autoFollow
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded,
                      color: _autoFollow ? AppColors.neonCyan : Colors.white38,
                    ),
                    tooltip: 'Pusatkan Posisi Atlet',
                    onPressed: () {
                      setState(() {
                        _autoFollow = true;
                      });
                      final coords = widget.session.coordinates;
                      final totalPoints = coords.length;
                      final idx = (_animController.value * (totalPoints - 1))
                          .floor()
                          .clamp(0, totalPoints - 1);
                      _mapController.move(
                        LatLng(coords[idx].latitude, coords[idx].longitude),
                        16.5,
                      );
                    },
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
}
