import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/coordinate_point.dart';
import '../models/sports_type.dart';
import '../models/track_milestone.dart';
import '../services/map_precache_service.dart';
import '../services/track_analysis_service.dart';
import 'track_milestone_pin.dart';

enum MapThemeMode {
  dark,
  standard,
}

/// Tampilan Peta Interaktif OpenStreetMap dengan rendering Polyline rute neon
/// Menggunakan OpenStreetMap 100% bebas API key dengan filter tema gelap Velora
class LiveMapView extends StatefulWidget {
  final List<CoordinatePoint> coordinates;
  final LatLng? currentLocation;
  final bool isTracking;
  final bool autoCenter;
  final bool showTrackMilestones;
  final SportsType sportsType;
  final List<CoordinatePoint>? highlightedSegment;
  final void Function(TrackMilestone)? onMilestoneTapped;
  final VoidCallback? onRecenter;
  final List<LatLng>? referenceRoute;
  final VoidCallback? onRouteGuidePressed;

  const LiveMapView({
    super.key,
    required this.coordinates,
    this.currentLocation,
    this.isTracking = false,
    this.autoCenter = true,
    this.showTrackMilestones = false,
    this.sportsType = SportsType.ride,
    this.highlightedSegment,
    this.onMilestoneTapped,
    this.onRecenter,
    this.referenceRoute,
    this.onRouteGuidePressed,
  });

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  late final MapController _mapController;
  MapThemeMode _currentTheme = MapThemeMode.dark;
  bool _userInteracted = false;
  late bool _showMilestones;
  TrackMilestone? _selectedMilestone;

  // Koordinat default jika GPS belum didapatkan
  static const LatLng _defaultLocation = LatLng(-0.026330, 109.342504);

  // Filter warna matrix untuk mengubah OpenStreetMap menjadi Dark Mode tanpa API key
  // Menghasilkan daratan dark slate (#293250), jalanan terang (#2F395D),
  // tepian jalan (#192241), air navy (#09244A), dan taman hijau tua (#18302F)
  static const List<double> _darkMatrix = <double>[
    0.45, 0.00, 0.00, 0, -68,
    0.00, 0.48, 0.00, 0, -65,
    0.00, 0.00, 0.58, 0, -55,
    0.00, 0.00, 0.00, 1,   0,
  ];

  String? _cacheDir;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _showMilestones = widget.showTrackMilestones;
    MapPrecacheService.getTileCacheDir().then((dir) {
      if (mounted) {
        setState(() {
          _cacheDir = dir;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showTrackMilestones != oldWidget.showTrackMilestones) {
      _showMilestones = widget.showTrackMilestones;
    }

    final isFirstLocation = oldWidget.currentLocation == null && widget.currentLocation != null;
    if (isFirstLocation) {
      _safeMoveMap(widget.currentLocation!, 16.5);
    } else if (widget.autoCenter &&
        !_userInteracted &&
        widget.currentLocation != null &&
        widget.currentLocation != oldWidget.currentLocation) {
      final currentZoom = () {
        try {
          return _mapController.camera.zoom;
        } catch (_) {
          return 16.5;
        }
      }();
      _safeMoveMap(widget.currentLocation!, currentZoom);
    }
  }

  void _safeMoveMap(LatLng target, double zoom) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(target, zoom);
        } catch (_) {}
      });
    }
  }

  void _recenterMap() {
    setState(() {
      _userInteracted = false;
    });
    if (widget.currentLocation != null) {
      _safeMoveMap(widget.currentLocation!, 16.5);
    } else if (widget.coordinates.isNotEmpty) {
      final last = widget.coordinates.last;
      _safeMoveMap(LatLng(last.latitude, last.longitude), 16.5);
    }
    widget.onRecenter?.call();
  }

  /// Memusatkan kamera peta untuk mencakup seluruh rute referensi panduan
  void centerOnReferenceRoute() {
    if (widget.referenceRoute != null && widget.referenceRoute!.isNotEmpty) {
      setState(() => _userInteracted = true);
      if (widget.referenceRoute!.length == 1) {
        _safeMoveMap(widget.referenceRoute!.first, 16.0);
      } else {
        try {
          final bounds = LatLngBounds.fromPoints(widget.referenceRoute!);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(48),
            ),
          );
        } catch (_) {
          _safeMoveMap(widget.referenceRoute!.first, 15.0);
        }
      }
    }
  }

  void _toggleMapTheme() {
    setState(() {
      _currentTheme = _currentTheme == MapThemeMode.dark
          ? MapThemeMode.standard
          : MapThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.currentLocation ??
        (widget.coordinates.isNotEmpty
            ? LatLng(
                widget.coordinates.last.latitude,
                widget.coordinates.last.longitude,
              )
            : _defaultLocation);

    final polylinePoints = widget.coordinates
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final highlightedPoints = widget.highlightedSegment != null
        ? widget.highlightedSegment!
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList()
        : const <LatLng>[];

    final milestones = (_showMilestones && widget.coordinates.length >= 2)
        ? TrackAnalysisService.analyzeTrack(widget.coordinates, widget.sportsType)
        : const <TrackMilestone>[];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16.0,
            minZoom: 4.0,
            maxZoom: 19.0,
            backgroundColor: AppColors.darkBackground,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                _userInteracted = true;
              }
            },
          ),
          children: [
            // 1. Lapisan Tile OpenStreetMap (100% Bebas API Key, Smooth Caching & Buffering)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'online.nurmancloud.velora',
              tileProvider: _cacheDir != null
                  ? VeloraTileProvider(
                      cacheDir: _cacheDir!,
                      providerType: 'osm',
                    )
                  : NetworkTileProvider(),
              panBuffer: 2,
              keepBuffer: 6,
              tileDisplay: const TileDisplay.fadeIn(
                duration: Duration(milliseconds: 150),
              ),
              retinaMode: false,
              maxNativeZoom: 19,
              tileBuilder: _currentTheme == MapThemeMode.dark
                  ? (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(_darkMatrix),
                        child: tileWidget,
                      );
                    }
                  : null,
            ),

            // 1b. Lapisan Polyline Panduan Rute Referensi (GPX Breadcrumbs)
            if (widget.referenceRoute != null && widget.referenceRoute!.isNotEmpty) ...[
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.referenceRoute!,
                    strokeWidth: 9.0,
                    color: const Color(0x606366F1), // Indigo halo glow
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  Polyline(
                    points: widget.referenceRoute!,
                    strokeWidth: 4.5,
                    color: const Color(0xFF818CF8), // Crisp Indigo
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            ],

            // 2. Lapisan Polyline Garis Lintasan Neon
            if (polylinePoints.isNotEmpty) ...[
              // Lapisan Glow di bawah garis utama
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 10.0,
                    color: AppColors.neonCyan.withAlpha(80),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 6.0,
                    color: AppColors.neonCyan,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            ],

            // 2b. Sorotan Segmen Rekor / Tercepat (Highlight Polyline Emas)
            if (highlightedPoints.isNotEmpty) ...[
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: highlightedPoints,
                    strokeWidth: 12.0,
                    color: AppColors.electricAmber.withAlpha(90),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  Polyline(
                    points: highlightedPoints,
                    strokeWidth: 7.0,
                    color: AppColors.electricAmber,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            ],

            // 3. Lapisan Marker (Penanda Lintasan & Lokasi Pengguna)
            MarkerLayer(
              markers: [
                // Penanda Awal Panduan Rute (Pin Hijau Panduan)
                if (widget.referenceRoute != null && widget.referenceRoute!.isNotEmpty) ...[
                  Marker(
                    point: widget.referenceRoute!.first,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Penanda Akhir Panduan Rute (Pin Merah / Finish)
                  if (widget.referenceRoute!.length > 1)
                    Marker(
                      point: widget.referenceRoute!.last,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sports_score_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],

                // Jika Penanda Lintasan Aktif, Tampilkan Seluruh Milestone
                if (_showMilestones && milestones.isNotEmpty)
                  ...milestones.map(
                    (m) => Marker(
                      point: LatLng(m.latitude, m.longitude),
                      width: m.isFastestKm ? 30 : 26,
                      height: m.isFastestKm ? 30 : 26,
                      child: TrackMilestonePin(
                        milestone: m,
                        sportsType: widget.sportsType,
                        onTap: () {
                          setState(() => _selectedMilestone = m);
                          widget.onMilestoneTapped?.call(m);
                        },
                      ),
                    ),
                  )
                else if (polylinePoints.isNotEmpty)
                  // Mode Minimalis (Titik Start Standar Hijau)
                  Marker(
                    point: polylinePoints.first,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.flag_rounded, size: 12, color: Colors.black),
                      ),
                    ),
                  ),

                // Titik Posisi Saat Ini (Current User Location)
                if (widget.currentLocation != null)
                  Marker(
                    point: widget.currentLocation!,
                    width: 48,
                    height: 48,
                    child: _buildCurrentLocationMarker(),
                  ),
              ],
            ),
          ],
        ),

        // Kontrol Peta Mengambang (Floating Action Buttons di Kanan Atas)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingActionBtn(
                icon: Icons.my_location_rounded,
                tooltip: 'Pusatkan Lokasi',
                color: _userInteracted
                    ? AppColors.textSecondary
                    : AppColors.primaryOrange,
                onPressed: _recenterMap,
              ),
              if (widget.onRouteGuidePressed != null) ...[
                const SizedBox(height: 10),
                _buildFloatingActionBtn(
                  icon: Icons.alt_route_rounded,
                  tooltip: 'Panduan Rute GPX & Jalur',
                  color: (widget.referenceRoute != null && widget.referenceRoute!.isNotEmpty)
                      ? const Color(0xFF818CF8)
                      : AppColors.textSecondary,
                  onPressed: widget.onRouteGuidePressed!,
                ),
              ],
              const SizedBox(height: 10),
              _buildFloatingActionBtn(
                icon: _currentTheme == MapThemeMode.dark
                    ? Icons.brightness_medium_rounded
                    : Icons.wb_sunny_rounded,
                tooltip: _currentTheme == MapThemeMode.dark
                    ? 'Mode Peta Terang'
                    : 'Mode Peta Gelap',
                color: AppColors.neonCyan,
                onPressed: _toggleMapTheme,
              ),
              if (widget.coordinates.length >= 2) ...[
                const SizedBox(height: 10),
                _buildFloatingActionBtn(
                  icon: Icons.flag_circle_rounded,
                  tooltip: _showMilestones
                      ? 'Sembunyikan Penanda Rute'
                      : 'Tampilkan Penanda Rute (KM & Rekor)',
                  color: _showMilestones
                      ? AppColors.electricAmber
                      : AppColors.textSecondary,
                  onPressed: () {
                    setState(() {
                      _showMilestones = !_showMilestones;
                      if (!_showMilestones) _selectedMilestone = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),

        // Banner Detail Penanda Milestone saat Disentuh (Bottom Tooltip)
        if (_selectedMilestone != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardSurface.withAlpha(245),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedMilestone!.isFastestKm
                      ? AppColors.electricAmber
                      : AppColors.borderSubtle,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TrackMilestonePin(
                    milestone: _selectedMilestone!,
                    sportsType: widget.sportsType,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedMilestone!.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedMilestone!.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _selectedMilestone = null),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Halo pendar luar bercahaya
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withAlpha(45),
            shape: BoxShape.circle,
          ),
        ),
        // 2. Ring pendar menengah bergaris halus
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withAlpha(85),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.neonCyan.withAlpha(150),
              width: 1.2,
            ),
          ),
        ),
        // 3. Titik Inti Biru Neon Velora dengan border putih tebal & bayangan tajam
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.neonCyan,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withAlpha(220),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
