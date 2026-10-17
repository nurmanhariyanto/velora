import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Komponen visual Logo resmi Velora: Run & Ride (Panah ganda 'V' Oranye)
class VeloraLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color? color;

  const VeloraLogo({
    super.key,
    this.size = 40.0,
    this.showTagline = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _VeloraChevronPainter(color: color),
        ),
        if (showTagline) ...[
          SizedBox(width: size * 0.28),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VELORA',
                style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'RUN & RIDE',
                style: TextStyle(
                  color: color != null
                      ? color!.withAlpha(200)
                      : AppColors.primaryOrange,
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VeloraChevronPainter extends CustomPainter {
  final Color? color;

  _VeloraChevronPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final Paint paint1 = Paint()
      ..shader = (color == null)
          ? const LinearGradient(
              colors: [AppColors.electricAmber, AppColors.primaryOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, w, h))
          : null
      ..color = color ?? AppColors.primaryOrange
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint paint2 = Paint()
      ..shader = (color == null)
          ? const LinearGradient(
              colors: [AppColors.primaryOrange, AppColors.orangeGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, w, h))
          : null
      ..color = color ?? AppColors.orangeGradientEnd
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Chevron Luar (Outer Arrow)
    final path1 = Path()
      ..moveTo(w * 0.10, h * 0.25)
      ..lineTo(w * 0.50, h * 0.72)
      ..lineTo(w * 0.90, h * 0.25)
      ..lineTo(w * 0.90, h * 0.45)
      ..lineTo(w * 0.50, h * 0.92)
      ..lineTo(w * 0.10, h * 0.45)
      ..close();

    // Chevron Dalam (Inner Arrow)
    final path2 = Path()
      ..moveTo(w * 0.25, h * 0.12)
      ..lineTo(w * 0.50, h * 0.42)
      ..lineTo(w * 0.75, h * 0.12)
      ..lineTo(w * 0.75, h * 0.28)
      ..lineTo(w * 0.50, h * 0.58)
      ..lineTo(w * 0.25, h * 0.28)
      ..close();

    canvas.drawPath(path1, paint2);
    canvas.drawPath(path2, paint1);
  }

  @override
  bool shouldRepaint(covariant _VeloraChevronPainter oldDelegate) =>
      oldDelegate.color != color;
}
