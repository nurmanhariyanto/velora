import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../models/sports_type.dart';
import 'mini_route_painter.dart';
import 'velora_logo.dart';

/// Gaya tampilan kartu berbagi media sosial
enum ShareCardStyle {
  map, // Peta OpenStreetMap dengan lintasan rute nyata (Default ala Strava)
  photo, // Foto latar belakang pengguna (Kamera / Galeri)
  minimal, // Desain minimalis gelap futuristik
}

/// Kartu komposit template untuk dibagikan ke Instagram Story (rasio 9:16)
class SocialShareCard extends StatelessWidget {
  final ActivitySession session;
  final String? backgroundPhotoPath;
  final ShareCardStyle style;
  final bool mapDarkTheme;
  final GlobalKey repaintKey;

  const SocialShareCard({
    super.key,
    required this.session,
    this.backgroundPhotoPath,
    this.style = ShareCardStyle.map,
    this.mapDarkTheme = true,
    required this.repaintKey,
  });

  // Filter warna matrix untuk mode gelap OpenStreetMap
  static const List<double> _darkMatrix = <double>[
    -0.2, -0.7, -0.1, 0, 235,
    -0.2, -0.7, -0.1, 0, 235,
    -0.2, -0.7, -0.1, 0, 235,
    0,    0,    0,    1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
    final formattedDate = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(session.startTime),
    );

    return RepaintBoundary(
      key: repaintKey,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Lapisan Latar Belakang (Peta OSM / Foto Pengguna / Gradasi Minimalis)
              _buildBackground(),

              // 2. Lapisan Bayangan Vignette Gelap (Memastikan Kontras Tinggi untuk Teks)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(style == ShareCardStyle.map ? 180 : 200),
                      Colors.black.withAlpha(style == ShareCardStyle.map ? 30 : 50),
                      Colors.black.withAlpha(style == ShareCardStyle.map ? 190 : 220),
                    ],
                    stops: const [0.0, 0.45, 0.95],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 3. Konten Teks & Statistik Aktivitas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Atas: Badge Olahraga & Tanggal
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withAlpha(230),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            session.displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bagian Atas: Angka Jarak Besar & Ringkasan Metrik
                    Column(
                      children: [
                        // Angka Jarak Besar
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                session.distanceKm.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 68,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'KM',
                                style: TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Baris Metrik Sekunder (Waktu, Pace/Speed, Elevasi)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                              width: 1,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMetricItem(
                                  'DURASI',
                                  session.formattedDuration,
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  color: Colors.white24,
                                ),
                                _buildMetricItem(
                                  session.sportsType.primaryMetricLabel,
                                  session.sportsType == SportsType.run
                                      ? session.formattedPace
                                      : session.formattedSpeed,
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  color: Colors.white24,
                                ),
                                _buildMetricItem(
                                  'ELEVASI',
                                  '+${session.elevationGain.toStringAsFixed(0)} m',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bagian Tengah: Sketsa Rute (Hanya untuk Mode Foto / Minimalis)
                    // Pada Mode Peta, lintasan rute sudah digambar langsung di atas OpenStreetMap!
                    if (style != ShareCardStyle.map)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: MiniRoutePainter(
                              coordinates: session.coordinates,
                              routeColor: AppColors.primaryOrange,
                              strokeWidth: 4.5,
                              showMarkers: true,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    // Bagian Bawah: Logo Velora & Aksen Garis
                    Column(
                      children: [
                        Container(
                          height: 2,
                          width: 80,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.electricAmber,
                                AppColors.primaryOrange,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const VeloraLogo(
                          size: 38,
                          showTagline: true,
                        ),
                      ],
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

  Widget _buildBackground() {
    switch (style) {
      case ShareCardStyle.map:
        return _buildMapBackground();

      case ShareCardStyle.photo:
        if (backgroundPhotoPath != null &&
            File(backgroundPhotoPath!).existsSync()) {
          return Image.file(
            File(backgroundPhotoPath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildMinimalBackground(),
          );
        }
        return _buildMinimalBackground();

      case ShareCardStyle.minimal:
        return _buildMinimalBackground();
    }
  }

  Widget _buildMapBackground() {
    if (session.coordinates.length < 2) {
      return _buildMinimalBackground();
    }

    final polylinePoints = session.coordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();

    // Singkirkan titik dengan koordinat tidak valid (NaN)
    polylinePoints.removeWhere((p) => p.latitude.isNaN || p.longitude.isNaN);
    if (polylinePoints.length < 2) {
      return _buildMinimalBackground();
    }

    final bounds = LatLngBounds.fromPoints(polylinePoints);
    final latDiff = (bounds.north - bounds.south).abs();
    final lngDiff = (bounds.east - bounds.west).abs();

    // Jika selisih koordinat sangat kecil (rute diam atau uji coba indoor)
    final bool isTinySpread = latDiff < 0.0005 && lngDiff < 0.0005;
    final center = bounds.center;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16.0,
        initialCameraFit: isTinySpread
            ? null
            : CameraFit.bounds(
                bounds: bounds,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                maxZoom: 17.0,
                minZoom: 4.0,
              ),
        minZoom: 3.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        // Lapisan Peta OpenStreetMap 100% Bebas API Key
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'online.nurmancloud.velora',
          tileBuilder: mapDarkTheme
              ? (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_darkMatrix),
                    child: tileWidget,
                  );
                }
              : null,
        ),

        // Garis Lintasan Rute Olahraga (Glow & Garis Oranye Khas Velora)
        PolylineLayer(
          polylines: [
            Polyline(
              points: polylinePoints,
              strokeWidth: 8.0,
              color: AppColors.primaryOrange.withAlpha(90),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
            Polyline(
              points: polylinePoints,
              strokeWidth: 4.5,
              color: AppColors.primaryOrange,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),

        // Penanda Titik Start & Finish
        MarkerLayer(
          markers: [
            Marker(
              point: polylinePoints.first,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded, size: 12, color: Colors.black),
                ),
              ),
            ),
            Marker(
              point: polylinePoints.last,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neonRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.flag_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF0F0F14),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
