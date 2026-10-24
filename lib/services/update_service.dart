import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/app_update_info.dart';
import '../widgets/update_dialog.dart';
import 'user_profile_service.dart';

/// Layanan pemeriksaan dan pembaruan otomatis aplikasi langsung dari GitHub Releases
class UpdateService {
  static const String githubOwner = 'nurmanhariyanto';
  static const String githubRepo = 'velora';
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static const MethodChannel _installerChannel =
      MethodChannel('online.nurmancloud.velora/app_installer');

  static const String appVersionFallback = '1.0.10';
  static bool _hasCheckedAutoUpdateThisSession = false;

  /// Membersihkan sisa file APK lama di direktori temporary
  static Future<void> cleanOldApks() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = tempDir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Memeriksa rilis terbaru dari GitHub API
  static Future<AppUpdateInfo?> checkLatestRelease() async {
    try {
      // Bersihkan file APK lama saat mengecek pembaruan
      await cleanOldApks();

      final packageInfo = await PackageInfo.fromPlatform().catchError((_) {
        return PackageInfo(
          appName: 'Velora',
          packageName: 'online.nurmancloud.velora',
          version: appVersionFallback,
          buildNumber: '37',
        );
      });

      final currentVersion = packageInfo.version.isNotEmpty ? packageInfo.version : appVersionFallback;

      final checkUri = Uri.parse(
        '$latestReleaseApiUrl?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(
        checkUri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Velora-App',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rawTag = data['tag_name'] as String? ?? '';
      final latestVersion = rawTag.replaceAll(RegExp(r'^[vV]'), '');
      final releaseTitle = data['name'] as String? ?? 'Versi $rawTag';
      final releaseNotes = data['body'] as String? ?? 'Pembaruan aplikasi Velora.';
      final releaseHtmlUrl = data['html_url'] as String? ?? '';
      final publishedAt = data['published_at'] as String?;

      // Cari file APK pada daftar assets rilis
      String downloadUrl = releaseHtmlUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null && assets.isNotEmpty) {
        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          final assetName = (assetMap['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk')) {
            downloadUrl = assetMap['browser_download_url'] as String? ?? downloadUrl;
            break;
          }
        }
      }

      final hasUpdate = AppUpdateInfo.isNewerVersion(currentVersion, latestVersion);

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        hasUpdate: hasUpdate,
        releaseTitle: releaseTitle,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        releaseHtmlUrl: releaseHtmlUrl,
        publishedAt: publishedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Mengunduh file APK langsung dari aplikasi dengan laporan progres real-time
  static Future<File?> downloadApkWithProgress({
    required String downloadUrl,
    required String fileName,
    required void Function(int receivedBytes, int totalBytes) onProgress,
    bool Function()? isCancelled,
  }) async {
    HttpClient? client;
    IOSink? sink;
    File? tempFile;

    try {
      await cleanOldApks();

      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/$fileName');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      client = HttpClient();
      client.autoUncompress = false;
      client.connectionTimeout = const Duration(seconds: 20);

      final uri = Uri.parse(downloadUrl);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Velora-App');

      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final totalBytes = response.contentLength;
      sink = tempFile.openWrite();

      int receivedBytes = 0;
      await for (final chunk in response) {
        if (isCancelled != null && isCancelled()) {
          await sink.flush();
          await sink.close();
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          return null;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      return tempFile;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      try {
        await sink?.close();
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  /// Membuka pemasang paket Android (Package Installer) untuk menginstal APK
  static Future<bool> installApk(String filePath) async {
    try {
      // Pastikan seluruh lapisan profil tersimpan dan ter-flush ke disk sebelum installer dipanggil
      await UserProfileService.flushBeforeUpdate();

      if (Platform.isAndroid) {
        final result = await _installerChannel.invokeMethod<bool>(
          'installApk',
          {'filePath': filePath},
        );
        return result ?? false;
      }
    } catch (e) {
      debugPrint('Error triggering package installer: $e');
    }
    return false;
  }

  /// Memeriksa pembaruan dan menampilkan dialog jika ada versi baru
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool silent = false,
  }) async {
    if (silent && _hasCheckedAutoUpdateThisSession) return;
    if (silent) {
      _hasCheckedAutoUpdateThisSession = true;
    }

    final updateInfo = await checkLatestRelease();

    if (!context.mounted) return;

    if (updateInfo != null && updateInfo.hasUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(updateInfo: updateInfo),
      );
    } else if (!silent) {
      final currentVer = updateInfo?.currentVersion ?? '1.0.0';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aplikasi sudah menggunakan versi terbaru (v$currentVer).',
          ),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
    }
  }

  /// Membuka tautan unduhan APK di peramban / pengunduh eksternal (sebagai fallback)
  static Future<bool> launchDownload(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
