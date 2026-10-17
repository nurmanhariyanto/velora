import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/trophy_badge.dart';

/// Kartu tampilan lencana (Trophy Badge) ala Strava dengan efek glowing gold/orange jika terbuka
/// dan frosted glass dark elegan dengan progress bar jika masih terkunci.
class TrophyBadgeCard extends StatelessWidget {
  final TrophyBadge badge;
  final VoidCallback? onTap;

  const TrophyBadgeCard({
    super.key,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => _showBadgeDetailDialog(context),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? AppColors.cardSurfaceElevated
              : AppColors.cardSurface.withAlpha(200),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isUnlocked
                ? AppColors.primaryOrange.withAlpha(160)
                : AppColors.borderSubtle,
            width: badge.isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withAlpha(45),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ikon Lencana Utama
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: badge.isUnlocked
                        ? const LinearGradient(
                            colors: [
                              AppColors.electricAmber,
                              AppColors.primaryOrange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.cardSurfaceElevated,
                              AppColors.cardSurface,
                            ],
                          ),
                    border: Border.all(
                      color: badge.isUnlocked
                          ? Colors.amber.shade200
                          : AppColors.borderHighlight,
                      width: 1.5,
                    ),
                    boxShadow: badge.isUnlocked
                        ? [
                            BoxShadow(
                              color: AppColors.primaryOrange.withAlpha(80),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    badge.icon,
                    size: 28,
                    color: badge.isUnlocked ? Colors.white : AppColors.textMuted,
                  ),
                ),
                if (!badge.isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Judul Lencana
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: badge.isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Indikator Progres / Status Unlocked
            if (badge.isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryOrange.withAlpha(100),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'TERBUKA',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.progressFraction,
                  minHeight: 5,
                  backgroundColor: AppColors.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.formattedProgress,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBadgeDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: badge.isUnlocked
                    ? const LinearGradient(
                        colors: [
                          AppColors.electricAmber,
                          AppColors.primaryOrange,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.cardSurfaceElevated,
                          AppColors.cardSurface,
                        ],
                      ),
                border: Border.all(
                  color: badge.isUnlocked
                      ? Colors.amber.shade200
                      : AppColors.borderHighlight,
                  width: 2,
                ),
                boxShadow: badge.isUnlocked
                    ? [
                        BoxShadow(
                          color: AppColors.primaryOrange.withAlpha(100),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge.icon,
                size: 38,
                color: badge.isUnlocked ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (badge.isUnlocked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryOrange.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.electricAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      badge.formattedUnlockedDate != null
                          ? 'Terbuka: ${badge.formattedUnlockedDate}'
                          : 'Lencana Telah Terbuka',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progres Pencapaian',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        badge.formattedProgress,
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: badge.progressFraction,
                      minHeight: 8,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
