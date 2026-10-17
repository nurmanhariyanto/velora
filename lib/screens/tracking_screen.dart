import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/sports_type.dart';
import '../providers/tracking_provider.dart';
import '../services/update_service.dart';
import '../widgets/auto_pause_banner.dart';
import '../widgets/control_buttons.dart';
import '../widgets/live_map_view.dart';
import '../widgets/metric_card.dart';
import '../widgets/velora_logo.dart';
import 'activity_detail_screen.dart';

/// Layar Pelacakan Utama Velora: Run & Ride
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingProvider>().fetchInitialPosition();
    });
  }

  Future<void> _handleStopSession() async {
    final provider = context.read<TrackingProvider>();
    final session = await provider.stopAndSaveSession();

    if (session != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi latihan berhasil disimpan ke riwayat lokal!'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );

      // Buka rincian sesi yang baru selesai
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(session: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    final currentPos = tracking.currentPosition;
    final currentLatLng = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const VeloraLogo(size: 32, showTagline: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update_rounded, size: 20),
            tooltip: 'Periksa Pembaruan',
            onPressed: () => UpdateService.checkForUpdate(context, silent: false),
          ),
          // Badge Status Kecil di Header
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tracking.status.isActive
                  ? AppColors.neonGreen.withAlpha(40)
                  : (tracking.status.isPaused
                      ? AppColors.warningYellow.withAlpha(40)
                      : AppColors.cardSurfaceElevated),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tracking.status.isActive
                    ? AppColors.neonGreen
                    : (tracking.status.isPaused
                        ? AppColors.warningYellow
                        : AppColors.borderSubtle),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tracking.status.isActive
                        ? AppColors.neonGreen
                        : (tracking.status.isPaused
                            ? AppColors.warningYellow
                            : AppColors.textMuted),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tracking.status.displayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tracking.status.isActive
                        ? AppColors.neonGreen
                        : (tracking.status.isPaused
                            ? AppColors.warningYellow
                            : AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Peta Interaktif OSM
          Positioned.fill(
            bottom: 240, // Beri ruang untuk bottom panel statistik
            child: LiveMapView(
              coordinates: tracking.coordinates,
              currentLocation: currentLatLng,
              isTracking: tracking.status.isRecording,
              autoCenter: true,
            ),
          ),

          // 2. Banner Notifikasi Auto-Pause Melayang
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: AutoPauseBanner(status: tracking.status),
          ),

          // 3. Panel Bawah Ergonomis (Bottom Dashboard & Controls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grid Metrik Statistik Utama
                  Row(
                    children: [
                      // Jarak (Besar)
                      Expanded(
                        child: MetricCard(
                          label: 'JARAK',
                          value: tracking.totalDistanceKm.toStringAsFixed(2),
                          unit: 'km',
                          accentColor: AppColors.neonCyan,
                          isLarge: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Durasi (Besar)
                      Expanded(
                        child: MetricCard(
                          label: 'DURASI',
                          value: tracking.formattedDuration,
                          accentColor: AppColors.primaryOrange,
                          isLarge: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Baris Metrik Sekunder: Pace/Speed + Elevasi
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: tracking.sportsType.primaryMetricLabel,
                          value: tracking.sportsType == SportsType.run
                              ? tracking.formattedPace
                              : tracking.averageSpeedKmh.toStringAsFixed(1),
                          unit: tracking.sportsType.primaryMetricUnit,
                          icon: tracking.sportsType == SportsType.run
                              ? Icons.speed_rounded
                              : Icons.directions_bike_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'ELEVASI',
                          value: '+${tracking.elevationGain.toStringAsFixed(0)}',
                          unit: 'm',
                          icon: Icons.terrain_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'SPEED',
                          value: tracking.currentSpeedKmh.toStringAsFixed(1),
                          unit: 'km/h',
                          icon: Icons.navigation_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tombol Kontrol (Start, Pause, Resume, Stop)
                  ControlButtons(
                    status: tracking.status,
                    sportsType: tracking.sportsType,
                    onStart: () async {
                      final success = await tracking.startTracking();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Harap berikan izin akses GPS untuk memulai pelacakan.',
                            ),
                            backgroundColor: AppColors.neonRed,
                          ),
                        );
                      }
                    },
                    onPause: () => tracking.pauseTracking(),
                    onResume: () => tracking.resumeTracking(),
                    onStop: _handleStopSession,
                    onSportsTypeChanged: (type) => tracking.setSportsType(type),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
