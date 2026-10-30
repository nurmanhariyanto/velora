import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/sports_type.dart';
import '../models/tracking_status.dart';
import '../providers/achievement_provider.dart';
import '../providers/history_provider.dart';
import '../providers/tracking_provider.dart';
import '../services/heart_rate_service.dart';
import '../services/update_service.dart';
import '../widgets/auto_pause_banner.dart';
import '../widgets/control_buttons.dart';
import '../widgets/live_map_view.dart';
import '../widgets/metric_card.dart';
import '../widgets/off_course_banner.dart';
import '../widgets/route_guide_sheet.dart';
import '../widgets/velora_logo.dart';
import 'activity_detail_screen.dart';
import 'settings_screen.dart';

/// Layar Pelacakan Utama Velora: Run & Ride
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final GlobalKey<dynamic> _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracking = context.read<TrackingProvider>();
      tracking.fetchInitialPosition();
      tracking.startIdleLocationListener();
    });
  }

  void _showRouteGuideModal() {
    RouteGuideSheet.show(
      context,
      onFocusRoute: () {
        final state = _mapKey.currentState;
        if (state != null) {
          try {
            (state as dynamic).centerOnReferenceRoute();
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _handleRecenter() async {
    final tracking = context.read<TrackingProvider>();

    // Jika posisi GPS belum didapatkan, lakukan pencarian eksplisit dan tampilkan status
    if (tracking.currentPosition == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mencari titik lokasi GPS terkini...',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.cardSurfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );

      final result = await tracking.refreshLocation();
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (result.position != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 20),
                SizedBox(width: 10),
                Text(
                  'Lokasi GPS berhasil ditemukan!',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.cardSurfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_off_rounded, color: AppColors.neonRed, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.message!,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.cardSurfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleStopSession() async {
    final provider = context.read<TrackingProvider>();
    final session = await provider.stopAndSaveSession();

    if (session != null && mounted) {
      // Perbarui daftar riwayat dan pencapaian trofi secara otomatis
      context.read<HistoryProvider>().loadActivities();
      context.read<AchievementProvider>().loadAchievements();

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
            icon: Icon(
              tracking.isHeartRateConnected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: tracking.isHeartRateConnected ? AppColors.neonRed : AppColors.textSecondary,
            ),
            tooltip: tracking.isHeartRateConnected
                ? 'Sensor HR: ${tracking.currentHeartRate ?? '--'} BPM'
                : 'Sensor & Smartwatch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
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
              key: _mapKey,
              coordinates: tracking.coordinates,
              currentLocation: currentLatLng,
              isTracking: tracking.status.isRecording,
              autoCenter: true,
              referenceRoute: tracking.referenceRoutePoints,
              onRouteGuidePressed: _showRouteGuideModal,
              onRecenter: _handleRecenter,
            ),
          ),

          // 2. Banner Notifikasi Melayang (Auto-Pause & Peringatan Keluar Jalur)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoPauseBanner(status: tracking.status),
                if (tracking.isOffCourse) ...[
                  const SizedBox(height: 8),
                  OffCourseBanner(
                    isOffCourse: tracking.isOffCourse,
                    distanceMeters: tracking.offCourseDistanceMeters,
                  ),
                ],
              ],
            ),
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
                  // Badge Olahraga Aktif saat sesi sedang berjalan
                  if (tracking.status != TrackingStatus.idle &&
                      tracking.status != TrackingStatus.completed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSportAccentColor(tracking.sportsType)
                              .withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getSportAccentColor(tracking.sportsType)
                                .withAlpha(90),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSportIcon(tracking.sportsType),
                              size: 14,
                              color: _getSportAccentColor(tracking.sportsType),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tracking.sportsType.displayName.toUpperCase(),
                              style: TextStyle(
                                color: _getSportAccentColor(tracking.sportsType),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

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
                  if (tracking.isHeartRateConnected && tracking.currentHeartRate != null) ...[
                    const SizedBox(height: 10),
                    _buildLiveHeartRateHUD(tracking.currentHeartRate!),
                  ],
                  const SizedBox(height: 10),

                  // Baris Metrik Sekunder: Dinamis Menyesuaikan Olahraga (Lari / Sepeda / Mendaki)
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: tracking.sportsType == SportsType.hike
                              ? 'ALTITUDE'
                              : tracking.sportsType.primaryMetricLabel,
                          value: tracking.sportsType == SportsType.run
                              ? tracking.formattedPace
                              : (tracking.sportsType == SportsType.hike
                                  ? tracking.currentAltitude.toStringAsFixed(0)
                                  : tracking.averageSpeedKmh.toStringAsFixed(1)),
                          unit: tracking.sportsType == SportsType.hike
                              ? 'mdpl'
                              : tracking.sportsType.primaryMetricUnit,
                          icon: tracking.sportsType == SportsType.run
                              ? Icons.speed_rounded
                              : (tracking.sportsType == SportsType.hike
                                  ? Icons.filter_hdr_rounded
                                  : Icons.directions_bike_rounded),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: tracking.sportsType == SportsType.hike
                              ? 'ELEV GAIN'
                              : 'ELEVASI',
                          value: '+${tracking.elevationGain.toStringAsFixed(0)}',
                          unit: 'm',
                          icon: Icons.terrain_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: tracking.sportsType == SportsType.hike
                              ? 'PACE'
                              : 'SPEED',
                          value: tracking.sportsType == SportsType.hike
                              ? tracking.formattedPace
                              : tracking.currentSpeedKmh.toStringAsFixed(1),
                          unit: tracking.sportsType == SportsType.hike
                              ? '/km'
                              : 'km/h',
                          icon: tracking.sportsType == SportsType.hike
                              ? Icons.speed_rounded
                              : Icons.navigation_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tombol Kontrol: Mulai Membuka Badge Menu Pemilihan Olahraga
                  ControlButtons(
                    status: tracking.status,
                    sportsType: tracking.sportsType,
                    onStart: () => _showSportSelectionModal(context, tracking),
                    onPause: () => tracking.pauseTracking(),
                    onResume: () => tracking.resumeTracking(),
                    onStop: _handleStopSession,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(SportsType sport) {
    switch (sport) {
      case SportsType.run:
        return Icons.directions_run_rounded;
      case SportsType.ride:
        return Icons.directions_bike_rounded;
      case SportsType.hike:
        return Icons.hiking_rounded;
    }
  }

  Color _getSportAccentColor(SportsType sport) {
    switch (sport) {
      case SportsType.run:
        return AppColors.primaryOrange;
      case SportsType.ride:
        return AppColors.neonCyan;
      case SportsType.hike:
        return AppColors.electricAmber;
    }
  }

  /// Menampilkan modal badge menu pemilihan jenis olahraga saat tombol Mulai ditekan
  void _showSportSelectionModal(BuildContext context, TrackingProvider tracking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'PILIH JENIS OLAHRAGA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih aktivitas untuk menyesuaikan metrik dan pelacakan GPS',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildSportOptionBadge(
                context: modalCtx,
                tracking: tracking,
                sport: SportsType.run,
                icon: Icons.directions_run_rounded,
                accentColor: AppColors.primaryOrange,
                title: 'Lari (Run)',
                subtitle: 'Pelacak pace (/km), ritme langkah & jarak lari',
              ),
              const SizedBox(height: 12),
              _buildSportOptionBadge(
                context: modalCtx,
                tracking: tracking,
                sport: SportsType.ride,
                icon: Icons.directions_bike_rounded,
                accentColor: AppColors.neonCyan,
                title: 'Sepeda (Ride)',
                subtitle: 'Pelacak kecepatan (km/h) & rute gowes',
              ),
              const SizedBox(height: 12),
              _buildSportOptionBadge(
                context: modalCtx,
                tracking: tracking,
                sport: SportsType.hike,
                icon: Icons.hiking_rounded,
                accentColor: AppColors.electricAmber,
                title: 'Mendaki (Hike / Trekking)',
                subtitle: 'Pelacak ketinggian (mdpl), elevasi lereng & tanjakan',
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildSportOptionBadge({
    required BuildContext context,
    required TrackingProvider tracking,
    required SportsType sport,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          tracking.setSportsType(sport);
          final success = await tracking.startTracking();
          if (!success && mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Harap berikan izin akses GPS untuk memulai pelacakan.',
                ),
                backgroundColor: AppColors.neonRed,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withAlpha(90)),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveHeartRateHUD(int bpm) {
    final zone = HeartRateService.getZoneForBpm(
      bpm,
      HeartRateService.instance.effectiveMaxHr,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: zone.color.withAlpha(120)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: zone.color, size: 20),
              const SizedBox(width: 8),
              Text(
                '$bpm BPM',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: zone.color.withAlpha(35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: zone.color),
            ),
            child: Text(
              '${zone.label} • ${zone.title}',
              style: TextStyle(
                color: zone.color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
