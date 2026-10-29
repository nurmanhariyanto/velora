import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/route_guide_info.dart';
import '../models/sports_type.dart';
import '../providers/history_provider.dart';
import '../providers/tracking_provider.dart';
import '../services/route_guide_service.dart';

/// Bottom sheet interaktif untuk mengelola panduan rute GPX (Route Breadcrumbs)
/// dan peringatan keluar jalur (Off-Course Alert)
class RouteGuideSheet extends StatefulWidget {
  final VoidCallback? onFocusRoute;

  const RouteGuideSheet({
    super.key,
    this.onFocusRoute,
  });

  /// Menampilkan bottom sheet panduan rute
  static Future<void> show(BuildContext context, {VoidCallback? onFocusRoute}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RouteGuideSheet(onFocusRoute: onFocusRoute),
    );
  }

  @override
  State<RouteGuideSheet> createState() => _RouteGuideSheetState();
}

class _RouteGuideSheetState extends State<RouteGuideSheet> {
  bool _isSelectingFromHistory = false;
  bool _isLoadingFile = false;

  Future<void> _handlePickGpxFile() async {
    setState(() => _isLoadingFile = true);
    final tracking = context.read<TrackingProvider>();

    try {
      final guide = await RouteGuideService.pickAndLoadGpxFile();
      if (!mounted) return;

      if (guide != null) {
        tracking.setRouteGuide(guide);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Panduan rute "${guide.name}" (${guide.formattedDistance}) berhasil dimuat!',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.cardSurfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memuat file GPX atau tidak ditemukan titik koordinat rute.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            backgroundColor: AppColors.cardSurfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.neonRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    final guide = tracking.routeGuide;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis handle atas
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Konten Berdasarkan Status
              if (_isSelectingFromHistory)
                _buildHistoryPicker(context, tracking)
              else if (guide != null)
                _buildActiveGuideView(context, tracking, guide)
              else
                _buildEmptyGuideView(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilan ketika belum ada panduan rute yang dipilih
  Widget _buildEmptyGuideView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x20818CF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF818CF8).withAlpha(100),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: Color(0xFF818CF8),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan Rute GPX & Peringatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mode manual: ikuti jalur referensi & hindari tersesat',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pilihan 1: Muat File GPX
          InkWell(
            onTap: _isLoadingFile ? null : _handlePickGpxFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoadingFile
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryOrange,
                                ),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.upload_file_rounded,
                            color: AppColors.primaryOrange,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih File GPX dari Perangkat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Muat rute lintasan eksternal (.gpx / .xml)',
                          style: TextStyle(
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pilihan 2: Pilih dari Riwayat Latihan
          InkWell(
            onTap: () => setState(() => _isSelectingFromHistory = true),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.neonCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih dari Riwayat Latihan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gunakan kembali rute sesi yang pernah tersimpan',
                          style: TextStyle(
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Tampilan saat panduan rute sedang aktif
  Widget _buildActiveGuideView(
    BuildContext context,
    TrackingProvider tracking,
    RouteGuideInfo guide,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x25818CF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF818CF8)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: Color(0xFF818CF8),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${guide.formattedDistance} • ${guide.points.length} titik koordinat',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Kartu Informasi Status & Switch Aktif/Nonaktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panduan Rute & Peringatan Jalur',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tracking.isRouteGuideEnabled
                            ? 'Aktif (Garis ungu & alarm keluar rute)'
                            : 'Dinonaktifkan (Sembunyikan garis)',
                        style: TextStyle(
                          fontSize: 11,
                          color: tracking.isRouteGuideEnabled
                              ? const Color(0xFF818CF8)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: tracking.isRouteGuideEnabled,
                  activeThumbColor: const Color(0xFF818CF8),
                  activeTrackColor: const Color(0x60818CF8),
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor: AppColors.borderSubtle,
                  onChanged: (val) => tracking.toggleRouteGuide(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Pusatkan Peta ke Rute
          if (widget.onFocusRoute != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onFocusRoute?.call();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
                  label: const Text('Pusatkan Peta ke Rute Panduan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF818CF8),
                    side: const BorderSide(color: Color(0xFF818CF8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

          // Tombol Ganti Rute & Hapus Panduan
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isSelectingFromHistory = true),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Ganti Rute'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    tracking.clearRouteGuide();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Panduan rute telah dihapus.'),
                        backgroundColor: AppColors.cardSurfaceElevated,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus Rute'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonRed,
                    side: BorderSide(color: AppColors.neonRed.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Tampilan pemilih riwayat latihan tersimpan
  Widget _buildHistoryPicker(BuildContext context, TrackingProvider tracking) {
    final history = context.watch<HistoryProvider>();
    final activities = history.activities;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => setState(() => _isSelectingFromHistory = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pilih dari Riwayat Latihan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),

          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Center(
                child: Text(
                  'Belum ada riwayat aktivitas tersimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: activities.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = activities[index];
                  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
                  final dateStr = dateFormat.format(
                    DateTime.fromMillisecondsSinceEpoch(session.startTime),
                  );

                  final iconData = session.sportsType == SportsType.run
                      ? Icons.directions_run_rounded
                      : (session.sportsType == SportsType.ride
                          ? Icons.directions_bike_rounded
                          : Icons.hiking_rounded);

                  final iconColor = session.sportsType == SportsType.run
                      ? AppColors.primaryOrange
                      : (session.sportsType == SportsType.ride
                          ? AppColors.neonCyan
                          : const Color(0xFF10B981));

                  final distStr = session.distanceKm >= 1.0
                      ? '${session.distanceKm.toStringAsFixed(2)} km'
                      : '${session.distanceMeters.toStringAsFixed(0)} m';

                  return InkWell(
                    onTap: () async {
                      // Ambil detail lengkap beserta koordinat dari database
                      final fullSession = await history.getActivityDetails(session.id);
                      if (!context.mounted) return;

                      if (fullSession != null && fullSession.coordinates.length >= 2) {
                        final guide = RouteGuideInfo.fromSession(fullSession);
                        tracking.setRouteGuide(guide);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Panduan rute "${guide.name}" aktif!',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.cardSurfaceElevated,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Aktivitas ini tidak memiliki titik rute GPS yang mencukupi untuk dijadikan panduan.',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                            backgroundColor: AppColors.cardSurfaceElevated,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: iconColor.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.displayTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dateStr • $distStr',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
