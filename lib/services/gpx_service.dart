import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';
import '../algorithms/haversine.dart';
import '../algorithms/pace_calculator.dart';
import '../database/activity_repository.dart';
import '../models/activity_session.dart';
import '../models/coordinate_point.dart';
import '../models/route_guide_info.dart';
import '../models/sports_type.dart';

/// Layanan ekspor & impor lintasan GPS ke format universal GPX (GPS Exchange Format v1.1)
/// Mendukung ekstensi detak jantung standar Garmin & Strava (TrackPointExtension hr),
/// serta pengimporan rute mandiri dari smartwatch (Haylou, Garmin, Amazfit, Coros, Strava).
class GpxService {
  /// Mengonversi ActivitySession dan deretan titik koordinatnya ke string XML GPX 1.1
  /// Termasuk tag ekstensi Garmin TrackPointExtension `<gpxtpx:hr>` jika ada data HR
  static String generateGpx(ActivitySession session) {
    final buffer = StringBuffer();
    final isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Velora Run &amp; Ride"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1"');
    buffer.writeln('  xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"');
    buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln('  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd');
    buffer.writeln('  http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd">');

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

      // Standar Garmin / Strava TrackPointExtension untuk detak jantung (HR)
      if (pt.heartRate != null && pt.heartRate! > 0) {
        buffer.writeln('        <extensions>');
        buffer.writeln('          <gpxtpx:TrackPointExtension>');
        buffer.writeln('            <gpxtpx:hr>${pt.heartRate}</gpxtpx:hr>');
        buffer.writeln('          </gpxtpx:TrackPointExtension>');
        buffer.writeln('        </extensions>');
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

  /// Mem-parsing string GPX dari jam tangan pintar/aplikasi luar menjadi ActivitySession lengkap
  /// Mendukung parsing detak jantung `<gpxtpx:hr>` atau `<hr>`
  static ActivitySession? parseGpxToActivitySession(
    String xmlString, {
    SportsType sportsType = SportsType.ride,
    String? customTitle,
  }) {
    if (xmlString.trim().isEmpty) return null;

    try {
      final document = XmlDocument.parse(xmlString);

      // Cari nama/judul aktivitas jika ada
      String sessionTitle = customTitle ?? '';
      if (sessionTitle.isEmpty) {
        final nameElem = document.findAllElements('name').firstOrNull;
        if (nameElem != null && nameElem.innerText.trim().isNotEmpty) {
          sessionTitle = nameElem.innerText.trim();
        }
      }

      // Cari jenis olahraga jika dicantumkan di tag <type>
      SportsType detectedSport = sportsType;
      final typeElem = document.findAllElements('type').firstOrNull;
      if (typeElem != null) {
        final t = typeElem.innerText.trim().toLowerCase();
        if (t.contains('run') || t.contains('jog')) {
          detectedSport = SportsType.run;
        } else if (t.contains('bike') || t.contains('ride') || t.contains('cycl')) {
          detectedSport = SportsType.ride;
        } else if (t.contains('hike') || t.contains('walk')) {
          detectedSport = SportsType.hike;
        }
      }

      // Ambil titik koordinat
      Iterable<XmlElement> pointElements = document.findAllElements('trkpt');
      if (pointElements.isEmpty) {
        pointElements = document.findAllElements('rtept');
      }
      if (pointElements.isEmpty) {
        pointElements = document.findAllElements('wpt');
      }

      if (pointElements.isEmpty) return null;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final sessionId = 'velora_gpx_$nowMs';

      final coordinates = <CoordinatePoint>[];
      double totalDistance = 0.0;
      double elevationGain = 0.0;
      double? lastElevation;
      double maxSpeedMps = 0.0;

      int? firstTimeMs;
      int? lastTimeMs;

      for (int i = 0; i < pointElements.length; i++) {
        final elem = pointElements.elementAt(i);
        final latStr = elem.getAttribute('lat');
        final lonStr = elem.getAttribute('lon');

        if (latStr == null || lonStr == null) continue;

        final lat = double.tryParse(latStr);
        final lon = double.tryParse(lonStr);
        if (lat == null || lon == null) continue;

        // Elevasi
        double elevation = 0.0;
        final eleElem = elem.findElements('ele').firstOrNull;
        if (eleElem != null) {
          final parsedEle = double.tryParse(eleElem.innerText.trim());
          if (parsedEle != null) {
            elevation = parsedEle;
            if (lastElevation != null && elevation > lastElevation) {
              elevationGain += (elevation - lastElevation);
            }
            lastElevation = elevation;
          }
        }

        // Timestamp
        int timestamp = nowMs + (i * 1000);
        final timeElem = elem.findElements('time').firstOrNull;
        if (timeElem != null) {
          try {
            final dt = DateTime.parse(timeElem.innerText.trim());
            timestamp = dt.millisecondsSinceEpoch;
          } catch (_) {}
        }

        firstTimeMs ??= timestamp;
        lastTimeMs = timestamp;

        // Kecepatan
        double speed = 0.0;
        final speedElem = elem.findElements('speed').firstOrNull;
        if (speedElem != null) {
          speed = double.tryParse(speedElem.innerText.trim()) ?? 0.0;
        }

        // Detak Jantung (Heart Rate - cari tag dengan nama lokal 'hr')
        int? heartRate;
        final hrElem = elem.findAllElements('*').where((e) => e.name.local == 'hr').firstOrNull;
        if (hrElem != null) {
          heartRate = int.tryParse(hrElem.innerText.trim());
        }

        // Hitung jarak akumulasi
        if (coordinates.isNotEmpty) {
          final prevPt = coordinates.last;
          final dist = Haversine.calculateDistance(
            prevPt.latitude,
            prevPt.longitude,
            lat,
            lon,
          );
          totalDistance += dist;

          // Jika tag speed tidak disediakan, estimasi kecepatan dari jarak & waktu
          if (speed == 0.0 && timestamp > prevPt.timestamp) {
            final dtSeconds = (timestamp - prevPt.timestamp) / 1000.0;
            if (dtSeconds > 0) {
              speed = dist / dtSeconds;
            }
          }
        }

        if (speed > maxSpeedMps && speed < 50.0) {
          maxSpeedMps = speed;
        }

        coordinates.add(CoordinatePoint(
          activityId: sessionId,
          latitude: lat,
          longitude: lon,
          elevation: elevation,
          speed: speed,
          accuracy: 5.0,
          timestamp: timestamp,
          heartRate: heartRate,
        ));
      }

      if (coordinates.isEmpty) return null;

      final startMs = firstTimeMs ?? nowMs;
      final endMs = lastTimeMs ?? (startMs + 60000);
      int durationSecs = ((endMs - startMs) / 1000).round();
      if (durationSecs <= 0) {
        durationSecs = (coordinates.length * 2);
      }

      final avgSpeedKmh = PaceCalculator.calculateSpeedKmh(totalDistance, durationSecs);
      final maxSpeedKmh = maxSpeedMps * 3.6;
      final avgPaceSecs = PaceCalculator.calculatePaceSecondsPerKm(totalDistance, durationSecs);

      // Hitung detak jantung rata-rata & maksimal jika ada
      final hrPoints = coordinates.where((c) => c.heartRate != null && c.heartRate! > 0).toList();
      int? avgHr;
      int? maxHr;
      if (hrPoints.isNotEmpty) {
        final sumHr = hrPoints.fold<int>(0, (prev, c) => prev + c.heartRate!);
        avgHr = (sumHr / hrPoints.length).round();
        maxHr = hrPoints.map((c) => c.heartRate!).reduce((a, b) => a > b ? a : b);
      }

      return ActivitySession(
        id: sessionId,
        sportsType: detectedSport,
        startTime: startMs,
        endTime: endMs,
        durationSeconds: durationSecs,
        distanceMeters: totalDistance,
        averageSpeedKmh: avgSpeedKmh,
        maxSpeedKmh: maxSpeedKmh,
        averagePaceSecondsPerKm: avgPaceSecs,
        elevationGain: elevationGain,
        notes: sessionTitle.isNotEmpty ? sessionTitle : null,
        coordinates: coordinates,
        averageHeartRate: avgHr,
        maxHeartRate: maxHr,
      );
    } catch (e) {
      debugPrint('Error parsing GPX to ActivitySession: $e');
      return null;
    }
  }

  /// Membaca dan mem-parsing file GPX lokal menjadi RouteGuideInfo
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

  /// Membaca dan mengimpor file GPX smartwatch langsung ke database aktivitas Velora
  static Future<ActivitySession?> importGpxFileToDatabase(
    File file, {
    SportsType sportsType = SportsType.ride,
  }) async {
    try {
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final baseName = p.basenameWithoutExtension(file.path);

      final session = parseGpxToActivitySession(
        content,
        sportsType: sportsType,
        customTitle: baseName,
      );

      if (session != null) {
        final repo = ActivityRepository();
        await repo.insertActivity(session);
        return session;
      }
      return null;
    } catch (e) {
      debugPrint('Error importing GPX file to database: $e');
      return null;
    }
  }
}
