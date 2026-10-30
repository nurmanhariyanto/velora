import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/best_effort.dart';
import '../models/lifetime_stats.dart';
import '../models/sports_type.dart';
import '../providers/achievement_provider.dart';
import '../services/user_profile_service.dart';
import '../widgets/trophy_badge_card.dart';
import 'settings_screen.dart';

/// Layar Profil Atlet, Statistik Seumur Hidup, Rekor Terbaik (Best Efforts), dan Lemari Trofi
class ProfileRecordsScreen extends StatefulWidget {
  const ProfileRecordsScreen({super.key});

  @override
  State<ProfileRecordsScreen> createState() => _ProfileRecordsScreenState();
}

class _ProfileRecordsScreenState extends State<ProfileRecordsScreen> {
  String _athleteName = UserProfileService.currentAthleteName;

  @override
  void initState() {
    super.initState();
    _loadAthleteName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementProvider>().loadAchievements();
    });
  }

  Future<void> _loadAthleteName() async {
    final name = await UserProfileService.getAthleteName();
    if (mounted) {
      setState(() {
        _athleteName = name;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadAthleteName();
    if (mounted) {
      context.read<AchievementProvider>().loadAchievements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = context.watch<AchievementProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Profil Atlet & Prestasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Pengaturan & Sensor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _refreshAll());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.primaryOrange,
        backgroundColor: AppColors.cardSurface,
        child: achievement.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryOrange),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Banner Atlet
                    _buildAthleteBanner(achievement),

                    const SizedBox(height: 16),

                    // 2. Pemilih Olahraga (Sepeda / Lari)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSportsSelector(achievement),
                    ),

                    const SizedBox(height: 20),

                    // 3. Statistik Sepanjang Masa (All-Time Stats)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildAllTimeStatsSection(achievement),
                    ),

                    const SizedBox(height: 24),

                    // 4. Rekor Jarak Terbaik (Best Efforts)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildBestEffortsSection(achievement),
                    ),

                    const SizedBox(height: 24),

                    // 5. Lemari Trofi Digital (Trophy Case Badges)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTrophyCaseSection(achievement),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAthleteBanner(AchievementProvider achievement) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.cardSurfaceElevated,
            AppColors.cardSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Atlet
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppColors.electricAmber,
                  AppColors.primaryOrange,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.amber.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withAlpha(80),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Nama & Status Atlet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _showEditNameDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _athleteName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Colors.amber.shade400,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rekor & Pencapaian Offline',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPillTag(
                      Icons.emoji_events_rounded,
                      '${achievement.unlockedCount}/${achievement.totalBadgesCount} Lencana',
                      AppColors.electricAmber,
                    ),
                    const SizedBox(width: 8),
                    _buildPillTag(
                      Icons.offline_pin_rounded,
                      '100% Offline',
                      AppColors.neonGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTag(IconData icon, String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withAlpha(70), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSelector(AchievementProvider achievement) {
    final selected = achievement.selectedSports;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSportsTab(
              icon: Icons.directions_run_rounded,
              label: 'Lari',
              isSelected: selected == SportsType.run,
              onTap: () => achievement.setSportsType(SportsType.run),
            ),
          ),
          Expanded(
            child: _buildSportsTab(
              icon: Icons.directions_bike_rounded,
              label: 'Sepeda',
              isSelected: selected == SportsType.ride,
              onTap: () => achievement.setSportsType(SportsType.ride),
            ),
          ),
          Expanded(
            child: _buildSportsTab(
              icon: Icons.hiking_rounded,
              label: 'Mendaki',
              isSelected: selected == SportsType.hike,
              onTap: () => achievement.setSportsType(SportsType.hike),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimeStatsSection(AchievementProvider achievement) {
    final stats = achievement.lifetimeStats ??
        LifetimeStats.empty(achievement.selectedSports);
    final isRun = achievement.selectedSports == SportsType.run;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STATISTIK SEPANJANG MASA',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${stats.totalWorkouts} Sesi Selesai',
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              title: 'TOTAL JARAK',
              value: stats.formattedTotalDistance,
              icon: Icons.route_rounded,
              color: AppColors.neonCyan,
            ),
            _buildStatCard(
              title: 'TOTAL WAKTU',
              value: stats.formattedTotalDuration,
              icon: Icons.timer_outlined,
              color: AppColors.primaryOrange,
            ),
            _buildStatCard(
              title: isRun
                  ? 'LARI TERJAUH'
                  : (achievement.selectedSports == SportsType.hike
                      ? 'DAKI TERJAUH'
                      : 'GOWES TERJAUH'),
              value: stats.formattedLongestDistance,
              icon: Icons.straighten_rounded,
              color: AppColors.neonGreen,
            ),
            _buildStatCard(
              title: 'TANJAKAN TERBESAR',
              value: stats.formattedBiggestClimb,
              icon: Icons.terrain_rounded,
              color: AppColors.electricAmber,
            ),
            _buildStatCard(
              title: 'TOP SPEED',
              value: stats.formattedMaxSpeed,
              icon: Icons.speed_rounded,
              color: AppColors.neonRed,
            ),
            _buildStatCard(
              title: isRun ? 'PACE TERBAIK' : 'AVG SPEED TERBAIK',
              value: isRun
                  ? stats.formattedBestPace
                  : stats.formattedBestAverageSpeed,
              icon: isRun ? Icons.bolt_rounded : Icons.flash_on_rounded,
              color: Colors.tealAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestEffortsSection(AchievementProvider achievement) {
    final records = achievement.bestEfforts;
    final isRun = achievement.selectedSports == SportsType.run;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REKOR JARAK TERBAIK (BEST EFFORTS)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Icon(
              Icons.stars_rounded,
              size: 16,
              color: Colors.amber.shade400,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Center(
              child: Text(
                'Belum ada rekor jarak yang dicatat.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildBestEffortTile(record, isRun);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBestEffortTile(BestEffort record, bool isRun) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Medali / Status Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: record.isAchieved
                  ? AppColors.primaryOrange.withAlpha(30)
                  : AppColors.cardSurfaceElevated,
              border: Border.all(
                color: record.isAchieved
                    ? AppColors.primaryOrange
                    : AppColors.borderSubtle,
              ),
            ),
            child: Icon(
              record.isAchieved
                  ? Icons.workspace_premium_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: record.isAchieved
                  ? AppColors.electricAmber
                  : AppColors.textMuted,
            ),
          ),

          const SizedBox(width: 14),

          // Label Milestone Jarak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.formattedDate,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Waktu & Metrik Performa (Pace/Speed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.formattedDuration,
                style: TextStyle(
                  color: record.isAchieved
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                record.formattedMetric,
                style: TextStyle(
                  color: record.isAchieved
                      ? (isRun ? AppColors.neonCyan : AppColors.neonGreen)
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyCaseSection(AchievementProvider achievement) {
    final badges = achievement.currentSportBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LEMARI TROFI (TROPHY CASE)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryOrange.withAlpha(90),
                  width: 0.8,
                ),
              ),
              child: Text(
                '${achievement.unlockedCount}/${achievement.totalBadgesCount} Terbuka',
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return TrophyBadgeCard(badge: badge);
          },
        ),
      ],
    );
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _athleteName);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: AppColors.primaryOrange, size: 22),
              SizedBox(width: 10),
              Text(
                'Edit Nama Profil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama ini akan ditampilkan pada profil dan kartu riwayat saat dibagikan ke media sosial.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  maxLength: 28,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx, controller.text.trim());
                    }
                  },
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nama Atlet',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    hintText: 'Misal: John Doe',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    counterStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardSurfaceElevated,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primaryOrange,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.trim().length > 28) {
                      return 'Maksimal 28 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Perbarui state lokal secara instan tanpa menunggu background I/O
      setState(() {
        _athleteName = result;
      });

      await UserProfileService.setAthleteName(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nama profil berhasil disimpan: "$result"'),
            backgroundColor: AppColors.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
