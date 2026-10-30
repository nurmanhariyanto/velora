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
  clean, // Gaya Clean Minimalis ala Strava (Latar Solid Hitam)
  transparent, // Gaya Stiker Transparan PNG (Bisa diedit & ditempel di Instagram Story / Reels)
  photo, // Foto latar belakang pengguna (Kamera / Galeri)
  map, // Peta OpenStreetMap dengan lintasan rute nyata
  minimal, // Desain minimalis gelap klasik
}

/// Kartu komposit template untuk dibagikan ke Instagram Story (rasio 9:16)
class SocialShareCard extends StatelessWidget {
  final ActivitySession session;
  final String? backgroundPhotoPath;
  final ShareCardStyle style;
  final bool mapDarkTheme;
  final GlobalKey repaintKey;
  final String? athleteName;

  const SocialShareCard({
    super.key,
    required this.session,
    this.backgroundPhotoPath,
    this.style = ShareCardStyle.clean,
    this.mapDarkTheme = true,
    required this.repaintKey,
    this.athleteName,
  });

  /// Filter warna matrix untuk mode gelap OpenStreetMap khas Velora
  /// Menghasilkan daratan dark slate (#293250), jalanan terang (#2F395D),
  /// tepian jalan (#192241), air navy (#09244A), dan taman hijau tua (#18302F)
  static const List<double> darkMatrix = <double>[
    0.45, 0.00, 0.00, 0, -68,
    0.00, 0.48, 0.00, 0, -65,
    0.00, 0.00, 0.58, 0, -55,
    0.00, 0.00, 0.00, 1,   0,
  ];
  static const List<double> _darkMatrix = darkMatrix;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
    final formattedDate = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(session.startTime),
    );

    final bool isCleanMode = style == ShareCardStyle.clean ||
        style == ShareCardStyle.photo ||
        style == ShareCardStyle.transparent;

    return RepaintBoundary(
      key: repaintKey,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            color: (style == ShareCardStyle.clean)
                ? Colors.black
                : (style == ShareCardStyle.transparent
                    ? Colors.transparent
                    : AppColors.darkBackground),
            borderRadius: BorderRadius.circular(24),
            boxShadow: (style == ShareCardStyle.transparent)
                ? null
                : const [
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
              // 1. Lapisan Latar Belakang (Hitam Pekat / Transparan / Foto Pengguna / Peta OSM / Minimalis)
              _buildBackground(),

              // 2. Lapisan Bayangan Vignette Gelap (Hanya untuk Peta OSM, Foto, atau Klasik)
              if (style != ShareCardStyle.clean && style != ShareCardStyle.transparent)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha(style == ShareCardStyle.map
                            ? (mapDarkTheme ? 110 : 130)
                            : 180),
                        Colors.black.withAlpha(style == ShareCardStyle.map ? 0 : 30),
                        Colors.black.withAlpha(style == ShareCardStyle.map
                            ? (mapDarkTheme ? 120 : 140)
                            : 200),
                      ],
                      stops: const [0.0, 0.45, 0.95],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

              // 3. Konten Teks & Statistik Aktivitas (Clean Minimalis ala Strava atau Klasik)
              if (isCleanMode)
                _buildCleanContent()
              else
                _buildClassicContent(formattedDate),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilan Clean Minimalis ala Strava (Distance, Pace/Speed, Time, Rute Oranye, VELORA Putih)
  Widget _buildCleanContent() {
    final bool isRun = session.sportsType == SportsType.run;

    final distanceStr = '${session.distanceKm.toStringAsFixed(2)} km';
    final paceOrSpeedStr = isRun
        ? formatCleanPace(session.averagePaceSecondsPerKm)
        : '${session.averageSpeedKmh.toStringAsFixed(1)} km/h';
    final timeStr = formatCleanDuration(session.durationSeconds);

    final bool isPhoto = style == ShareCardStyle.photo;
    final bool isTransparent = style == ShareCardStyle.transparent;
    final List<Shadow>? textShadows = (isPhoto || isTransparent)
        ? const [
            Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1.5)),
            Shadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
          ]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // 1. Metrik Distance
          _buildCleanMetricBlock(
            label: 'Distance',
            value: distanceStr,
            shadows: textShadows,
          ),

          const SizedBox(height: 14),

          // 2. Metrik Pace / Speed
          _buildCleanMetricBlock(
            label: isRun ? 'Pace' : 'Speed',
            value: paceOrSpeedStr,
            shadows: textShadows,
          ),

          const SizedBox(height: 14),

          // 3. Metrik Time
          _buildCleanMetricBlock(
            label: 'Time',
            value: timeStr,
            shadows: textShadows,
          ),

          const Spacer(flex: 3),

          // 4. Sketsa Rute Oranye (Silhouette rute GPS hero size tanpa pin start/finish, persis Strava)
          Expanded(
            flex: 8,
            child: Center(
              child: session.coordinates.length >= 2
                  ? CustomPaint(
                      size: Size.infinite,
                      painter: MiniRoutePainter(
                        coordinates: session.coordinates,
                        routeColor: const Color(0xFFFC5200), // Vibrant Strava Orange
                        strokeWidth: 4.8,
                        paddingFraction: 0.05,
                        hasShadow: true,
                        showMarkers: false,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const Spacer(flex: 2),

          // 5. Teks Brand: VELORA putih tebal bersih persis Strava
          Text(
            'VELORA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.5,
              shadows: textShadows,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildCleanMetricBlock({
    required String label,
    required String value,
    List<Shadow>? shadows,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(220),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            shadows: shadows,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              shadows: shadows,
            ),
          ),
        ),
      ],
    );
  }

  /// Format pace lari clean gaya Strava (contoh: 5:13 /km)
  static String formatCleanPace(double paceSecondsPerKm) {
    if (paceSecondsPerKm.isNaN ||
        paceSecondsPerKm.isInfinite ||
        paceSecondsPerKm <= 0 ||
        paceSecondsPerKm > 3600) {
      return '--:-- /km';
    }
    final int totalSecs = paceSecondsPerKm.round();
    if (totalSecs <= 0 || totalSecs > 3600) {
      return '--:-- /km';
    }
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '$mins:${secs.toString().padLeft(2, '0')} /km';
  }

  /// Format durasi clean gaya Strava (contoh: 54m 27s atau 1h 12m 45s)
  static String formatCleanDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  /// Tampilan kartu klasik lengkap dengan badge olahraga, 4 metrik, dan logo Velora
  Widget _buildClassicContent(String formattedDate) {
    return Padding(
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
                (athleteName != null &&
                        athleteName!.trim().isNotEmpty &&
                        athleteName!.trim() != 'Velora Athlete')
                    ? '${athleteName!.trim()} • $formattedDate'
                    : formattedDate,
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

              // Baris Metrik Sekunder (Waktu, Pace/Speed, Max Speed, Elevasi)
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
                        session.sportsType == SportsType.ride
                            ? 'AVG SPEED'
                            : 'PACE',
                        session.sportsType == SportsType.ride
                            ? session.formattedSpeed
                            : session.formattedPace,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.white24,
                      ),
                      _buildMetricItem(
                        'MAX SPEED',
                        '${session.maxSpeedKmh.toStringAsFixed(1)} km/h',
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

          // Bagian Tengah: Sketsa Rute (Hanya untuk Mode Minimalis / Klasik)
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
                size: 34,
                showTagline: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    switch (style) {
      case ShareCardStyle.clean:
        return Container(color: Colors.black);

      case ShareCardStyle.transparent:
        return const SizedBox.shrink();

      case ShareCardStyle.map:
        return _buildMapBackground();

      case ShareCardStyle.photo:
        if (backgroundPhotoPath != null &&
            File(backgroundPhotoPath!).existsSync()) {
          return Image.file(
            File(backgroundPhotoPath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.black),
          );
        }
        return Container(color: Colors.black);

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

    return Container(
      color: const Color(0xFF141923),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 16.0,
          initialCameraFit: isTinySpread
              ? null
              : CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.only(
                    top: 130,
                    bottom: 100,
                    left: 28,
                    right: 28,
                  ),
                  maxZoom: 17.0,
                  minZoom: 4.0,
                ),
          minZoom: 3.0,
          maxZoom: 18.0,
          backgroundColor: AppColors.darkBackground,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          // Lapisan Peta OpenStreetMap 100% Bebas API Key
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'online.nurmancloud.velora',
            tileDisplay: const TileDisplay.instantaneous(),
            retinaMode: true,
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
    ),
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
