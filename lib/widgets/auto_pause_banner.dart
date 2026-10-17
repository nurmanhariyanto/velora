import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/tracking_status.dart';

/// Banner status Auto-Pause / Dihentikan Sementara
class AutoPauseBanner extends StatefulWidget {
  final TrackingStatus status;

  const AutoPauseBanner({
    super.key,
    required this.status,
  });

  @override
  State<AutoPauseBanner> createState() => _AutoPauseBannerState();
}

class _AutoPauseBannerState extends State<AutoPauseBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.status.isPaused) {
      return const SizedBox.shrink();
    }

    final isAuto = widget.status.isAutoPaused;
    final color = isAuto ? AppColors.warningYellow : AppColors.electricAmber;
    final text = isAuto
        ? 'AUTO-PAUSE AKTIF (BERHENTI BERGERAK)'
        : 'PELACAKAN DIHENTIKAN SEMENTARA';

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha((40 * _pulseAnimation.value).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withAlpha((180 * _pulseAnimation.value).toInt()),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAuto ? Icons.motion_photos_paused_rounded : Icons.pause_circle_filled_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
