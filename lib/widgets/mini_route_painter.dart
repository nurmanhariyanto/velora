import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/coordinate_point.dart';

/// Painter kanvas kustom untuk merender sketsa rute polyline mini
/// Menormalkan koordinat GPS ke dalam dimensi kanvas dengan menjaga rasio aspek
class MiniRoutePainter extends CustomPainter {
  final List<CoordinatePoint> coordinates;
  final Color routeColor;
  final double strokeWidth;
  final bool showMarkers;

  MiniRoutePainter({
    required this.coordinates,
    this.routeColor = AppColors.primaryOrange,
    this.strokeWidth = 3.5,
    this.showMarkers = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.length < 2) {
      // Gambar garis placeholder jika belum ada koordinat
      final paint = Paint()
        ..color = routeColor.withAlpha(80)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.5),
        Offset(size.width * 0.8, size.height * 0.5),
        paint,
      );
      return;
    }

    // Cari bounding box koordinat (minLat, maxLat, minLon, maxLon)
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final pt in coordinates) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLon) minLon = pt.longitude;
      if (pt.longitude > maxLon) maxLon = pt.longitude;
    }

    final latRange = (maxLat - minLat).abs();
    final lonRange = (maxLon - minLon).abs();

    if (latRange == 0 && lonRange == 0) return;

    // Tambahkan padding di sekitar kanvas (15%)
    const paddingFraction = 0.15;
    final usableW = size.width * (1.0 - paddingFraction * 2);
    final usableH = size.height * (1.0 - paddingFraction * 2);

    // Hitung skala seragam untuk menjaga rasio aspek geospasial
    // 1 derajat lat ~ 111 km, 1 derajat lon ~ 111 * cos(lat) km
    final avgLatRad = ((minLat + maxLat) / 2.0) * (math.pi / 180.0);
    final cosLat = math.cos(avgLatRad).abs().clamp(0.1, 1.0);

    final geoWidth = lonRange * cosLat;
    final geoHeight = latRange;

    final scaleX = geoWidth > 0 ? usableW / geoWidth : 1.0;
    final scaleY = geoHeight > 0 ? usableH / geoHeight : 1.0;
    final scale = math.min(scaleX, scaleY);

    // Pusat kanvas
    final renderedW = geoWidth * scale;
    final renderedH = geoHeight * scale;
    final offsetX = (size.width - renderedW) / 2.0;
    final offsetY = (size.height - renderedH) / 2.0;

    Offset project(CoordinatePoint pt) {
      final normX = (pt.longitude - minLon) * cosLat;
      final normY = (maxLat - pt.latitude); // Invert Y karena kanvas Y ke bawah
      final px = offsetX + (normX * scale);
      final py = offsetY + (normY * scale);
      return Offset(px, py);
    }

    // Siapkan Path rute
    final path = Path();
    final firstPoint = project(coordinates.first);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < coordinates.length; i++) {
      final p = project(coordinates[i]);
      path.lineTo(p.dx, p.dy);
    }

    // 1. Gambar efek glow lembut di belakang garis utama
    final glowPaint = Paint()
      ..color = routeColor.withAlpha(70)
      ..strokeWidth = strokeWidth * 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // 2. Gambar garis polyline utama
    final linePaint = Paint()
      ..color = routeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    if (showMarkers) {
      // Titik Start (Hijau)
      final startPos = firstPoint;
      final startPaint = Paint()..color = AppColors.neonGreen;
      final markerBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(startPos, 5.0, startPaint);
      canvas.drawCircle(startPos, 5.0, markerBorder);

      // Titik Finish (Merah)
      final endPos = project(coordinates.last);
      final endPaint = Paint()..color = AppColors.neonRed;
      canvas.drawCircle(endPos, 5.0, endPaint);
      canvas.drawCircle(endPos, 5.0, markerBorder);
    }
  }

  @override
  bool shouldRepaint(covariant MiniRoutePainter oldDelegate) {
    return oldDelegate.coordinates.length != coordinates.length ||
        oldDelegate.routeColor != routeColor;
  }
}
