import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/coordinate_point.dart';

/// Grafik profil elevasi (tanjakan & turunan) sepanjang lintasan aktivitas
class ElevationChart extends StatelessWidget {
  final List<CoordinatePoint> coordinates;
  final double elevationGain;

  const ElevationChart({
    super.key,
    required this.coordinates,
    required this.elevationGain,
  });

  @override
  Widget build(BuildContext context) {
    final validElevations = coordinates
        .where((p) => p.elevation > 0)
        .map((p) => p.elevation)
        .toList();

    if (validElevations.length < 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.terrain_rounded, color: AppColors.textMuted, size: 24),
            SizedBox(width: 12),
            Text(
              'Profil elevasi relatif datar / tidak terdeteksi.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final minElevation = validElevations.reduce(math.min);
    final maxElevation = validElevations.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 18, color: AppColors.neonCyan),
                  SizedBox(width: 8),
                  Text(
                    'PROFIL ELEVASI',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Text(
                '+${elevationGain.toStringAsFixed(0)} m gain',
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _ElevationChartPainter(
                elevations: validElevations,
                minElevation: minElevation,
                maxElevation: maxElevation,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${minElevation.toStringAsFixed(0)} m',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                'Max: ${maxElevation.toStringAsFixed(0)} m',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  final List<double> elevations;
  final double minElevation;
  final double maxElevation;

  _ElevationChartPainter({
    required this.elevations,
    required this.minElevation,
    required this.maxElevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final range = (maxElevation - minElevation);
    final effectiveRange = range > 2.0 ? range : 10.0;
    final w = size.width;
    final h = size.height;

    final path = Path();
    final fillPath = Path();

    final stepX = w / (elevations.length - 1);

    for (int i = 0; i < elevations.length; i++) {
      final normalizedY = 1.0 - ((elevations[i] - minElevation) / effectiveRange);
      final x = i * stepX;
      final y = (normalizedY * h * 0.85) + (h * 0.10);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    // 1. Gambar Area Gradien Bawah
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.neonCyan.withAlpha(70),
          AppColors.neonCyan.withAlpha(5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Gambar Garis Kurva Puncak
    final linePaint = Paint()
      ..color = AppColors.neonCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ElevationChartPainter oldDelegate) {
    return oldDelegate.elevations != elevations;
  }
}
