import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_session.dart';

/// Layanan ekspor lintasan GPS ke format universal GPX (GPS Exchange Format v1.1)
/// Memungkinkan ekspor data rute untuk diimpor ke aplikasi pihak ketiga, Garmin Connect, Google Earth, dll.
class GpxService {
  /// Mengonversi ActivitySession dan deretan titik koordinatnya ke string XML GPX 1.1
  static String generateGpx(ActivitySession session) {
    final buffer = StringBuffer();
    final isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Velora Run &amp; Ride"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1"');
    buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln('  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');

    // Metadata
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>Velora ${session.sportsType.displayName}</name>');
    buffer.writeln('    <time>${isoFormat.format(DateTime.fromMillisecondsSinceEpoch(session.startTime).toUtc())}</time>');
    buffer.writeln('  </metadata>');

    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>Velora ${session.sportsType.shortName} Track</name>');
    buffer.writeln('    <type>${session.sportsType.name.toUpperCase()}</type>');
    buffer.writeln('    <trkseg>');

    for (final pt in session.coordinates) {
      final timeStr = isoFormat.format(
        DateTime.fromMillisecondsSinceEpoch(pt.timestamp).toUtc(),
      );
      buffer.writeln('      <trkpt lat="${pt.latitude}" lon="${pt.longitude}">');
      if (pt.elevation > 0) {
        buffer.writeln('        <ele>${pt.elevation.toStringAsFixed(1)}</ele>');
      }
      buffer.writeln('        <time>$timeStr</time>');
      if (pt.speed > 0) {
        buffer.writeln('        <speed>${pt.speed.toStringAsFixed(2)}</speed>');
      }
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Menyimpan string GPX ke file lokal dan memicu lembar berbagi (share sheet)
  static Future<void> exportAndShareGpx(ActivitySession session) async {
    final gpxContent = generateGpx(session);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'velora_${session.sportsType.name}_${session.startTime}.gpx';
    final file = File(p.join(tempDir.path, fileName));

    await file.writeAsString(gpxContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/gpx+xml')],
        text: 'File rute GPX Velora: ${session.sportsType.displayName}',
        subject: 'Ekspor Rute GPX Velora',
      ),
    );
  }
}
