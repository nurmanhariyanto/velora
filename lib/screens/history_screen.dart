import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../models/sports_type.dart';
import '../providers/history_provider.dart';
import 'activity_detail_screen.dart';
import 'share_preview_screen.dart';

/// Layar Daftar Riwayat Aktivitas Tersimpan (SQLite Lokal)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: () => history.loadActivities(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => history.loadActivities(),
        color: AppColors.primaryOrange,
        backgroundColor: AppColors.cardSurface,
        child: history.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryOrange),
              )
            : CustomScrollView(
                slivers: [
                  // Banner Ringkasan Statistik Agregat
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _buildSummaryHeader(history),
                    ),
                  ),

                  // Daftar Aktivitas
                  if (history.activities.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final session = history.activities[index];
                            return _buildActivityCard(context, session);
                          },
                          childCount: history.activities.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryHeader(HistoryProvider history) {
    final totalHours = (history.totalDurationSeconds / 3600.0).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardSurfaceElevated, AppColors.cardSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL PENCAPAIAN LOKAL',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatSummaryItem(
                history.totalDistanceKm.toStringAsFixed(1),
                'KM',
                'TOTAL JARAK',
                AppColors.neonCyan,
              ),
              Container(width: 1, height: 36, color: AppColors.borderSubtle),
              _buildStatSummaryItem(
                totalHours,
                'JAM',
                'TOTAL WAKTU',
                AppColors.primaryOrange,
              ),
              Container(width: 1, height: 36, color: AppColors.borderSubtle),
              _buildStatSummaryItem(
                '${history.totalWorkouts}',
                'SESI',
                'LATIHAN',
                AppColors.neonGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSummaryItem(
    String value,
    String unit,
    String label,
    Color accentColor,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivitySession session) {
    final dateFormat = DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID');
    final dateStr = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(session.startTime),
    );

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Hapus Aktivitas?'),
            content: const Text('Data sesi dan koordinat rute ini akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<HistoryProvider>().deleteActivity(session.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final fullSession =
                await context.read<HistoryProvider>().getActivityDetails(session.id);
            if (fullSession != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityDetailScreen(session: fullSession),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        session.sportsType == SportsType.run
                            ? Icons.directions_run_rounded
                            : Icons.pedal_bike_rounded,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.displayTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                      onPressed: () async {
                        final fullSession = await context
                            .read<HistoryProvider>()
                            .getActivityDetails(session.id);
                        if (fullSession != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SharePreviewScreen(session: fullSession),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricSnippet('JARAK', '${session.distanceKm.toStringAsFixed(2)} km'),
                    _buildMetricSnippet('DURASI', session.formattedDuration),
                    _buildMetricSnippet(
                      session.sportsType.primaryMetricLabel,
                      session.sportsType == SportsType.run
                          ? session.formattedPace
                          : session.formattedSpeed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSnippet(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 64,
              color: AppColors.textMuted.withAlpha(120),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Aktivitas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai sesi latihan lari atau bersepeda di tab Pelacakan. Catatan koordinat dan statistik akan tersimpan secara otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
