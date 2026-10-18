import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/sports_type.dart';
import '../models/track_milestone.dart';

/// Widget Pin Penanda Titik Penting di Atas Garis Lintasan Peta
class TrackMilestonePin extends StatelessWidget {
  final TrackMilestone milestone;
  final SportsType sportsType;
  final VoidCallback? onTap;

  const TrackMilestonePin({
    super.key,
    required this.milestone,
    this.sportsType = SportsType.ride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildPinBody(),
    );
  }

  Widget _buildPinBody() {
    switch (milestone.type) {
      case TrackMilestoneType.start:
        return _buildCirclePin(
          color: AppColors.neonGreen,
          borderColor: Colors.white,
          child: const Icon(
            Icons.flag_rounded,
            size: 13,
            color: Colors.black87,
          ),
        );

      case TrackMilestoneType.finish:
        return _buildCirclePin(
          color: AppColors.primaryOrange,
          borderColor: Colors.white,
          child: const Icon(
            Icons.sports_score_rounded,
            size: 14,
            color: Colors.white,
          ),
        );

      case TrackMilestoneType.kmSplit:
        if (milestone.isFastestKm) {
          // Kilometer Tercepat (Aksen Emas Menyala)
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.electricAmber,
                  AppColors.primaryOrange,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricAmber.withAlpha(160),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${milestone.kmNumber}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }

        // Kilometer Reguler
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonCyan, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${milestone.kmNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

      case TrackMilestoneType.maxSpeed:
        return _buildCirclePin(
          color: AppColors.electricAmber,
          borderColor: Colors.white,
          child: const Icon(
            Icons.bolt_rounded,
            size: 14,
            color: Colors.black87,
          ),
        );

      case TrackMilestoneType.peakElevation:
        return _buildCirclePin(
          color: const Color(0xFF6366F1), // Indigo Peak
          borderColor: Colors.white,
          child: const Icon(
            Icons.terrain_rounded,
            size: 13,
            color: Colors.white,
          ),
        );

      case TrackMilestoneType.bestEffort:
        return _buildCirclePin(
          color: Colors.amber.shade400,
          borderColor: Colors.white,
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 13,
            color: Colors.black87,
          ),
        );
    }
  }

  Widget _buildCirclePin({
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
