import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../models/coordinate_point.dart';
import '../models/sports_type.dart';
import '../models/track_milestone.dart';
import '../services/gpx_service.dart';
import '../services/heart_rate_service.dart';
import '../services/map_precache_service.dart';
import '../services/road_geocoding_service.dart';
import '../services/track_analysis_service.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/live_map_view.dart';
import '../widgets/metric_card.dart';
import 'route_replay_screen.dart';
import 'share_preview_screen.dart';

/// Layar Rincian Hasil Latihan & Replay Rute dengan Penanda Lintasan
class ActivityDetailScreen extends StatefulWidget {
  final ActivitySession session;

  const ActivityDetailScreen({
    super.key,
    required this.session,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late final List<TrackMilestone> _milestones;
  late final List<CoordinatePoint>? _fastest1kSegment;
  List<CoordinatePoint>? _highlightedSegment;
  bool _highlightFastestActive = true;

  @override
  void initState() {
    super.initState();
    _milestones = TrackAnalysisService.analyzeTrack(
      widget.session.coordinates,
      widget.session.sportsType,
    );
    _fastest1kSegment = TrackAnalysisService.findFastestSegment(
      widget.session.coordinates,
    );
    _highlightedSegment = _fastest1kSegment;

    // Mulai unduh ubin rute & nama jalan di latar belakang saat layar rincian dibuka jika ada internet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.session.coordinates.length >= 2) {
        MapPrecacheService.precacheActivityRoute(widget.session.coordinates);
        RoadGeocodingService.precacheRoadTransitions(widget.session.coordinates);
      }
    });
  }

  void _toggleHighlightFastest() {
    setState(() {
      _highlightFastestActive = !_highlightFastestActive;
      _highlightedSegment = _highlightFastestActive ? _fastest1kSegment : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
    final formattedStartTime = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(widget.session.startTime),
    );

    final kmSplits = _milestones
        .where((m) => m.type == TrackMilestoneType.kmSplit)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          widget.session.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primaryOrange),
            tooltip: 'Bagikan Aktivitas',
            onPressed: () => _showShareChoiceModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tampilan Peta Replay Rute dengan Penanda Lintasan Langsung (Bersih tanpa tombol yang menghalangi badge)
            SizedBox(
              height: 290,
              width: double.infinity,
              child: LiveMapView(
                coordinates: widget.session.coordinates,
                isTracking: false,
                autoCenter: true,
                showTrackMilestones: true,
                sportsType: widget.session.sportsType,
                highlightedSegment: _highlightedSegment,
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
                              widget.session.sportsType == SportsType.run
                                  ? Icons.directions_run_rounded
                                  : (widget.session.sportsType == SportsType.hike
                                      ? Icons.hiking_rounded
                                      : Icons.pedal_bike_rounded),
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.session.sportsType.shortName,
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
                          value: widget.session.distanceKm.toStringAsFixed(2),
                          unit: 'km',
                          accentColor: AppColors.neonCyan,
                          isLarge: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'DURASI AKTIF',
                          value: widget.session.formattedDuration,
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
                          label: widget.session.sportsType.primaryMetricLabel,
                          value: widget.session.sportsType == SportsType.run
                              ? widget.session.formattedPace
                              : widget.session.formattedSpeed,
                          unit: widget.session.sportsType.primaryMetricUnit,
                          icon: Icons.speed_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'MAX SPEED',
                          value: widget.session.maxSpeedKmh.toStringAsFixed(1),
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
                          value: '+${widget.session.elevationGain.toStringAsFixed(0)}',
                          unit: 'meter',
                          icon: Icons.terrain_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'TITIK RUTE',
                          value: '${widget.session.coordinates.length}',
                          unit: 'pts',
                          icon: Icons.timeline_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4. Grafik Profil Elevasi Rute
                  ElevationChart(
                    coordinates: widget.session.coordinates,
                    elevationGain: widget.session.elevationGain,
                  ),

                  // 4b. Analisis Detak Jantung & Distribusi Zona (jika tersedia data HR)
                  if (widget.session.hasHeartRateData) _buildHeartRateSection(),

                  // 5. Analisis Split Kilometer & Rekor Lintasan
                  _buildSplitsAndRecordsSection(kmSplits),

                  if (widget.session.notes != null && widget.session.notes!.isNotEmpty) ...[
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
                        widget.session.notes!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Menu Aksi Utama Minimalis (Putar Rute & Bagikan)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (widget.session.coordinates.length < 2) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Aktivitas ini belum merekam rute bergerak (butuh minimal 2 titik GPS) untuk memutar video flyover.',
                                    ),
                                    backgroundColor: AppColors.cardSurfaceElevated,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RouteReplayScreen(session: widget.session),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.session.coordinates.length >= 2
                                  ? AppColors.primaryOrange
                                  : AppColors.cardSurfaceElevated,
                              foregroundColor: widget.session.coordinates.length >= 2
                                  ? Colors.white
                                  : AppColors.textMuted,
                              elevation: widget.session.coordinates.length >= 2 ? 3 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: widget.session.coordinates.length >= 2
                                      ? Colors.transparent
                                      : AppColors.borderSubtle,
                                ),
                              ),
                            ),
                            icon: Icon(
                              widget.session.coordinates.length >= 2
                                  ? Icons.play_arrow_rounded
                                  : Icons.videocam_outlined,
                              size: 24,
                            ),
                            label: const Text(
                              'PUTAR RUTE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _showShareChoiceModal(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.electricAmber,
                              side: const BorderSide(
                                color: AppColors.electricAmber,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 20),
                            label: const Text(
                              'BAGIKAN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareChoiceModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 1.2),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indikator geser
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Bagikan Aktivitas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih format konten yang ingin Anda bagikan ke media sosial',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 18),

              // Opsi 1: Ringkasan Poster HD
              _buildShareChoiceCard(
                icon: Icons.photo_library_rounded,
                iconColor: AppColors.primaryOrange,
                title: 'Poster Ringkasan Latihan (HD)',
                subtitle: 'Poster foto & peta visual HD untuk Instagram Story, WhatsApp Status, atau Galeri.',
                badgeText: 'FOTO & PETA',
                badgeColor: AppColors.primaryOrange,
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

              const SizedBox(height: 12),

              // Opsi 2: Video Flyover Rute POV (MP4 Sinematik)
              _buildShareChoiceCard(
                icon: Icons.movie_filter_rounded,
                iconColor: AppColors.neonCyan,
                title: 'Video Flyover Rute (MP4 Sinematik)',
                subtitle: widget.session.coordinates.length >= 2
                    ? 'Animasi kamera POV 3D Full HD dengan speedometer & elevasi untuk Reels, TikTok, atau WhatsApp.'
                    : 'Membutuhkan minimal 2 titik GPS bergerak untuk membuat video flyover 3D.',
                badgeText: widget.session.coordinates.length >= 2 ? 'VIDEO MP4' : 'MIN 2 TITIK GPS',
                badgeColor: widget.session.coordinates.length >= 2 ? AppColors.neonCyan : AppColors.textMuted,
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.session.coordinates.length < 2) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Aktivitas ini belum merekam rute bergerak (butuh min. 2 titik GPS) untuk dibuatkan video flyover.',
                        ),
                        backgroundColor: AppColors.cardSurfaceElevated,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteReplayScreen(
                        session: widget.session,
                        autoStartVideoExport: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Opsi 3: Ekspor Berkas GPX
              _buildShareChoiceCard(
                icon: Icons.file_download_outlined,
                iconColor: const Color(0xFF818CF8),
                title: 'Ekspor Berkas GPS (GPX)',
                subtitle: 'Simpan atau bagikan koordinat rute mentah dalam format standar GPX.',
                badgeText: 'FILE GPX',
                badgeColor: const Color(0xFF818CF8),
                onTap: () {
                  Navigator.pop(ctx);
                  GpxService.exportAndShareGpx(widget.session);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareChoiceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withAlpha(90), width: 1.2),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 14),
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
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withAlpha(120), width: 0.8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitsAndRecordsSection(List<TrackMilestone> kmSplits) {
    if (kmSplits.isEmpty && _fastest1kSegment == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SPLIT KILOMETER & REKOR LINTASAN',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            if (_fastest1kSegment != null)
              InkWell(
                onTap: _toggleHighlightFastest,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _highlightFastestActive
                        ? AppColors.electricAmber.withAlpha(35)
                        : AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _highlightFastestActive
                          ? AppColors.electricAmber
                          : AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: _highlightFastestActive
                            ? AppColors.electricAmber
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _highlightFastestActive ? 'Segmen 1K Aktif' : 'Sorot 1K',
                        style: TextStyle(
                          color: _highlightFastestActive
                              ? AppColors.electricAmber
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (kmSplits.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kmSplits.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.borderSubtle,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final split = kmSplits[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: split.isFastestKm
                          ? AppColors.electricAmber.withAlpha(40)
                          : AppColors.cardSurfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: split.isFastestKm
                            ? AppColors.electricAmber
                            : AppColors.borderSubtle,
                        width: split.isFastestKm ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${split.kmNumber}',
                        style: TextStyle(
                          color: split.isFastestKm
                              ? AppColors.electricAmber
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'KM ${split.kmNumber}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (split.isFastestKm) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.electricAmber.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.electricAmber,
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            '⚡ TERCEPAT',
                            style: TextStyle(
                              color: AppColors.electricAmber,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    split.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    split.formattedSplitDuration,
                    style: TextStyle(
                      color: split.isFastestKm
                          ? AppColors.electricAmber
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeartRateSection() {
    final maxHr = HeartRateService.instance.effectiveMaxHr;
    final distribution = HeartRateService.calculateDistribution(
      widget.session.coordinates,
      maxHr,
    );
    final zones = HeartRateService.calculateZones(maxHr);
    final dominantInfo = zones.firstWhere(
      (z) => z.zone == distribution.dominantZone,
      orElse: () => zones[1],
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.favorite_rounded, color: AppColors.neonRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'DETAK JANTUNG & ZONA',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dominantInfo.color.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dominantInfo.color),
                ),
                child: Text(
                  'Dominan: ${dominantInfo.label}',
                  style: TextStyle(
                    color: dominantInfo.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metrik Ringkas: Rata-rata dan Detak Jantung Puncak
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RATA-RATA',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.session.formattedHeartRate,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MAKSIMAL',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.session.formattedMaxHeartRate,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Baris Segmen Distribusi Zona HR (Visual horizontal progress bar)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final z in zones)
                    if ((distribution.percentPerZone[z.zone] ?? 0) > 0)
                      Expanded(
                        flex: (distribution.percentPerZone[z.zone]! * 10).round().clamp(1, 1000),
                        child: Container(color: z.color),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Rincian 5 Zona
          for (final z in zones) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 18,
                    decoration: BoxDecoration(
                      color: z.color.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: z.color, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        z.label,
                        style: TextStyle(color: z.color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${z.title} (${z.minBpm}-${z.maxBpm} bpm)',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatZoneDuration(distribution.secondsPerZone[z.zone] ?? 0),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(distribution.percentPerZone[z.zone] ?? 0).toStringAsFixed(0)}%',
                      style: TextStyle(color: z.color, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatZoneDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
