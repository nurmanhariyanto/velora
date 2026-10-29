import 'dart:io';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';
import '../algorithms/haversine.dart';
import '../models/activity_session.dart';
import '../models/route_guide_info.dart';

/// Layanan ekspor & impor lintasan GPS ke format universal GPX (GPS Exchange Format v1.1)
/// Memungkinkan ekspor data rute untuk diimpor ke aplikasi pihak ketiga, Garmin Connect, Google Earth,
/// serta pengimporan rute GPX eksternal sebagai panduan rute (route breadcrumbs).
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

  /// Mem-parsing konten string GPX menjadi model panduan rute (RouteGuideInfo)
  /// Mendukung elemen `<trkpt>`, `<rtept>`, dan `<wpt>`.
  static RouteGuideInfo? parseGpx(String xmlString, {String? defaultName}) {
    if (xmlString.trim().isEmpty) return null;

    try {
      final document = XmlDocument.parse(xmlString);

      // Cari nama rute dari metadata atau tag track/route
      String routeName = defaultName ?? 'Rute Panduan';
      final nameElement = document.findAllElements('name').firstOrNull;
      if (nameElement != null && nameElement.innerText.trim().isNotEmpty) {
        routeName = nameElement.innerText.trim();
      }

      // Ambil titik koordinat (prioritas: trkpt -> rtept -> wpt)
      Iterable<XmlElement> pointElements = document.findAllElements('trkpt');
      if (pointElements.isEmpty) {
        pointElements = document.findAllElements('rtept');
      }
      if (pointElements.isEmpty) {
        pointElements = document.findAllElements('wpt');
      }

      if (pointElements.isEmpty) {
        return null;
      }

      final points = <LatLng>[];
      double totalDistance = 0.0;
      double elevationGain = 0.0;
      double? lastElevation;

      for (final elem in pointElements) {
        final latStr = elem.getAttribute('lat');
        final lonStr = elem.getAttribute('lon');

        if (latStr == null || lonStr == null) continue;

        final lat = double.tryParse(latStr);
        final lon = double.tryParse(lonStr);

        if (lat == null || lon == null) continue;

        final currentPoint = LatLng(lat, lon);

        if (points.isNotEmpty) {
          final prevPoint = points.last;
          final dist = Haversine.calculateDistance(
            prevPoint.latitude,
            prevPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );
          totalDistance += dist;
        }

        points.add(currentPoint);

        // Ekstraksi elevasi naik jika ada
        final eleElement = elem.findElements('ele').firstOrNull;
        if (eleElement != null) {
          final ele = double.tryParse(eleElement.innerText.trim());
          if (ele != null) {
            if (lastElevation != null && ele > lastElevation) {
              elevationGain += (ele - lastElevation);
            }
            lastElevation = ele;
          }
        }
      }

      if (points.isEmpty) return null;

      // Ekstraksi waktu rute (metadata time atau point time pertama)
      DateTime? routeTime;
      final timeElem = document.findAllElements('time').firstOrNull;
      if (timeElem != null) {
        try {
          routeTime = DateTime.parse(timeElem.innerText.trim());
        } catch (_) {}
      }

      return RouteGuideInfo(
        name: routeName,
        points: points,
        totalDistanceMeters: totalDistance,
        elevationGain: elevationGain > 0 ? elevationGain : null,
        createdAt: routeTime,
      );
    } catch (_) {
      return null;
    }
  }

  /// Membaca dan mem-parsing file GPX lokal
  static Future<RouteGuideInfo?> parseGpxFile(File file) async {
    try {
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final baseName = p.basenameWithoutExtension(file.path);
      return parseGpx(content, defaultName: baseName);
    } catch (_) {
      return null;
    }
  }
}
