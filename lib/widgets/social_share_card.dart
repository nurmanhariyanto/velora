import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../models/sports_type.dart';
import 'mini_route_painter.dart';
import 'velora_logo.dart';

/// Kartu komposit template untuk dibagikan ke Instagram Story (rasio 9:16)
class SocialShareCard extends StatelessWidget {
  final ActivitySession session;
  final String? backgroundPhotoPath;
  final GlobalKey repaintKey;

  const SocialShareCard({
    super.key,
    required this.session,
    this.backgroundPhotoPath,
    required this.repaintKey,
  });

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
              // 1. Foto Latar Belakang (atau gradasi olahraga dinamis jika tanpa foto)
              if (backgroundPhotoPath != null &&
                  File(backgroundPhotoPath!).existsSync())
                Image.file(
                  File(backgroundPhotoPath!),
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0F2027),
                        Color(0xFF203A43),
                        Color(0xFF2C5364),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

              // 2. Lapisan Bayangan Vignette Gelap (Kontras Tinggi untuk Teks)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(200),
                      Colors.black.withAlpha(40),
                      Colors.black.withAlpha(220),
                    ],
                    stops: const [0.0, 0.45, 0.95],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 3. Konten Teks & Mini Polyline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Atas: Badge Aktivitas & Tanggal
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withAlpha(220),
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
                            'VELORA ${session.sportsType.shortName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 2.0,
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

                    // Bagian Tengah Atas: Metrik Utama dengan Drop Shadow Kuat
                    Column(
                      children: [
                        // Angka Jarak Besar
                        Row(
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

                        const SizedBox(height: 12),

                        // Baris Metrik Sekunder (Waktu, Pace/Speed, Elevasi)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                              width: 1,
                            ),
                          ),
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
                                color: Colors.white24,
                              ),
                              _buildMetricItem(
                                'ELEVASi',
                                '+${session.elevationGain.toStringAsFixed(0)} m',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bagian Tengah: Sketsa Polyline Mini Rute Oranye
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
                    ),

                    // Bagian Bawah: Logo Velora & Tagline Eksklusif
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
