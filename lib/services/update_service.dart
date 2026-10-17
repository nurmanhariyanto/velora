import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/app_update_info.dart';
import '../widgets/update_dialog.dart';

/// Layanan pemeriksaan dan pembaruan otomatis aplikasi langsung dari GitHub Releases
class UpdateService {
  static const String githubOwner = 'nurmanhariyanto';
  static const String githubRepo = 'velora';
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// Memeriksa rilis terbaru dari GitHub API
  static Future<AppUpdateInfo?> checkLatestRelease() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform().catchError((_) {
        return PackageInfo(
          appName: 'Velora',
          packageName: 'online.nurmancloud.velora',
          version: '1.0.0',
          buildNumber: '1',
        );
      });

      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(latestReleaseApiUrl),
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Velora-App',
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

  /// Memeriksa pembaruan dan menampilkan dialog jika ada versi baru
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool silent = false,
  }) async {
    final updateInfo = await checkLatestRelease();

    if (!context.mounted) return;

    if (updateInfo != null && updateInfo.hasUpdate) {
      showDialog(
        context: context,
        barrierDismissible: true,
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

  /// Membuka tautan unduhan APK di peramban / pengunduh eksternal
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
