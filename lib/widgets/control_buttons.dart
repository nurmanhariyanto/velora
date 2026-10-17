import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/sports_type.dart';
import '../models/tracking_status.dart';

/// Tombol kontrol besar ergonomis untuk Start, Pause, Resume, dan Stop
class ControlButtons extends StatelessWidget {
  final TrackingStatus status;
  final SportsType sportsType;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final ValueChanged<SportsType> onSportsTypeChanged;

  const ControlButtons({
    super.key,
    required this.status,
    required this.sportsType,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSportsTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (status == TrackingStatus.idle) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pemilih Jenis Olahraga (Run / Ride)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSportTypeChip(
                  type: SportsType.run,
                  icon: Icons.directions_run_rounded,
                  label: 'LARI',
                ),
                const SizedBox(width: 4),
                _buildSportTypeChip(
                  type: SportsType.ride,
                  icon: Icons.directions_bike_rounded,
                  label: 'SEPEDA',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tombol Mulai Besar
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text(
                'MULAI LATIHAN',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Sedang Merekam / Dihentikan Sementara
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tombol Pause / Resume
        if (status.isActive)
          _buildCircleButton(
            icon: Icons.pause_rounded,
            label: 'JEDA',
            color: AppColors.electricAmber,
            onPressed: onPause,
          )
        else
          _buildCircleButton(
            icon: Icons.play_arrow_rounded,
            label: 'LANJUT',
            color: AppColors.neonGreen,
            onPressed: onResume,
          ),

        // Tombol Selesai / Stop
        _buildCircleButton(
          icon: Icons.stop_rounded,
          label: 'SELESAI',
          color: AppColors.neonRed,
          onPressed: () => _confirmStop(context),
        ),
      ],
    );
  }

  Widget _buildSportTypeChip({
    required SportsType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = sportsType == type;
    return GestureDetector(
      onTap: () => onSportsTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  void _confirmStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Akhiri Aktivitas?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menyelesaikan sesi latihan ini dan menyimpannya ke riwayat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onStop();
            },
            child: const Text('Simpan & Selesai'),
          ),
        ],
      ),
    );
  }
}
