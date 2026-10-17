import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../models/sports_type.dart';
import '../services/gpx_service.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/live_map_view.dart';
import '../widgets/metric_card.dart';
import 'share_preview_screen.dart';

/// Layar Rincian Hasil Latihan & Replay Rute
class ActivityDetailScreen extends StatelessWidget {
  final ActivitySession session;

  const ActivityDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
    final formattedStartTime = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(session.startTime),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          session.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.neonCyan),
            tooltip: 'Ekspor GPX',
            onPressed: () => GpxService.exportAndShareGpx(session),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primaryOrange),
            tooltip: 'Bagikan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SharePreviewScreen(session: session),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tampilan Peta Replay Rute
            SizedBox(
              height: 280,
              width: double.infinity,
              child: LiveMapView(
                coordinates: session.coordinates,
                isTracking: false,
                autoCenter: true,
              ),
            ),

            // 2. Konten Ringkasan & Tanggal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryOrange),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              session.sportsType == SportsType.run
                                  ? Icons.directions_run_rounded
                                  : Icons.pedal_bike_rounded,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              session.sportsType.shortName,
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formattedStartTime,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Grid Statistik Lengkap
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'TOTAL JARAK',
                          value: session.distanceKm.toStringAsFixed(2),
                          unit: 'km',
                          accentColor: AppColors.neonCyan,
                          isLarge: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'DURASI AKTIF',
                          value: session.formattedDuration,
                          accentColor: AppColors.primaryOrange,
                          isLarge: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: session.sportsType.primaryMetricLabel,
                          value: session.sportsType == SportsType.run
                              ? session.formattedPace
                              : session.formattedSpeed,
                          unit: session.sportsType.primaryMetricUnit,
                          icon: Icons.speed_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'MAX SPEED',
                          value: session.maxSpeedKmh.toStringAsFixed(1),
                          unit: 'km/h',
                          icon: Icons.bolt_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'ELEVASI',
                          value: '+${session.elevationGain.toStringAsFixed(0)}',
                          unit: 'meter',
                          icon: Icons.terrain_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'TITIK RUTE',
                          value: '${session.coordinates.length}',
                          unit: 'pts',
                          icon: Icons.timeline_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4. Grafik Profil Elevasi Rute
                  ElevationChart(
                    coordinates: session.coordinates,
                    elevationGain: session.elevationGain,
                  ),

                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'CATATAN LATIHAN',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        session.notes!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Tombol Bagikan ke Media Sosial
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharePreviewScreen(session: session),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 22),
                      label: const Text(
                        'BAGIKAN KE MEDIA SOSIAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol Ekspor File GPX
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => GpxService.exportAndShareGpx(session),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: const Text(
                        'EKSPOR FILE GPX (STRAVA / GARMIN)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
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
}
