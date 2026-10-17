import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/coordinate_point.dart';

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

  const LiveMapView({
    super.key,
    required this.coordinates,
    this.currentLocation,
    this.isTracking = false,
    this.autoCenter = true,
  });

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  late final MapController _mapController;
  MapThemeMode _currentTheme = MapThemeMode.dark;
  bool _userInteracted = false;

  // Koordinat default jika GPS belum didapatkan
  static const LatLng _defaultLocation = LatLng(-0.026330, 109.342504);

  // Filter warna matrix untuk mengubah OpenStreetMap menjadi Dark Mode tanpa API key
  static const List<double> _darkMatrix = <double>[
    -0.2, -0.7, -0.1, 0, 235,
    -0.2, -0.7, -0.1, 0, 235,
    -0.2, -0.7, -0.1, 0, 235,
    0,    0,    0,    1, 0,
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoCenter &&
        !_userInteracted &&
        widget.currentLocation != null &&
        widget.currentLocation != oldWidget.currentLocation) {
      _mapController.move(widget.currentLocation!, _mapController.camera.zoom);
    }
  }

  void _recenterMap() {
    setState(() {
      _userInteracted = false;
    });
    if (widget.currentLocation != null) {
      _mapController.move(widget.currentLocation!, 16.5);
    } else if (widget.coordinates.isNotEmpty) {
      final last = widget.coordinates.last;
      _mapController.move(LatLng(last.latitude, last.longitude), 16.5);
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

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16.5,
            minZoom: 4.0,
            maxZoom: 19.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                _userInteracted = true;
              }
            },
          ),
          children: [
            // 1. Lapisan Tile OpenStreetMap (100% Bebas API Key)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'online.nurmancloud.velora',
              tileBuilder: _currentTheme == MapThemeMode.dark
                  ? (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(_darkMatrix),
                        child: tileWidget,
                      );
                    }
                  : null,
            ),

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

            // 3. Lapisan Marker (Start Point & Current Location)
            MarkerLayer(
              markers: [
                // Titik Start (Hijau)
                if (polylinePoints.isNotEmpty)
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
                    width: 44,
                    height: 44,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withAlpha(60),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.neonCyan,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
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
