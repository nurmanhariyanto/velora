import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_update_info.dart';
import '../services/update_service.dart';

enum _DownloadPhase {
  idle,
  downloading,
  readyToInstall,
  error,
}

/// Dialog interaktif pembaruan versi baru dengan progres unduh real-time di dalam aplikasi
class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _DownloadPhase _phase = _DownloadPhase.idle;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  bool _cancelled = false;
  File? _downloadedFile;
  String? _errorMessage;

  double get _progress {
    if (_totalBytes <= 0) return 0.0;
    return (_receivedBytes / _totalBytes).clamp(0.0, 1.0);
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _startDownload() async {
    setState(() {
      _phase = _DownloadPhase.downloading;
      _receivedBytes = 0;
      _totalBytes = 0;
      _cancelled = false;
      _errorMessage = null;
    });

    final fileName = 'velora-v${widget.updateInfo.latestVersion}.apk';

    final file = await UpdateService.downloadApkWithProgress(
      downloadUrl: widget.updateInfo.downloadUrl,
      fileName: fileName,
      onProgress: (received, total) {
        if (mounted && !_cancelled) {
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
      isCancelled: () => _cancelled,
    );

    if (!mounted) return;

    if (_cancelled) {
      setState(() {
        _phase = _DownloadPhase.idle;
      });
      return;
    }

    if (file != null && await file.exists()) {
      setState(() {
        _phase = _DownloadPhase.readyToInstall;
        _downloadedFile = file;
      });

      // Otomatis buka pemasang paket sistem Android
      _installApk();
    } else {
      setState(() {
        _phase = _DownloadPhase.error;
        _errorMessage = 'Gagal mengunduh berkas paket pembaruan.';
      });
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFile != null && await _downloadedFile!.exists()) {
      final success = await UpdateService.installApk(_downloadedFile!.path);
      if (!success && mounted) {
        // Fallback jika installer gagal dipanggil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Silakan berikan izin pemasangan aplikasi tidak dikenal jika diminta.',
            ),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
    }
  }

  void _cancelDownload() {
    _cancelled = true;
    setState(() {
      _phase = _DownloadPhase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _DownloadPhase.downloading,
      child: AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderHighlight, width: 1),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: _buildHeader(),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (_phase) {
      case _DownloadPhase.idle:
        icon = Icons.system_update_rounded;
        iconColor = AppColors.primaryOrange;
        title = 'Pembaruan Tersedia';
        subtitle = 'Versi baru siap dipasang';
        break;
      case _DownloadPhase.downloading:
        icon = Icons.cloud_download_rounded;
        iconColor = AppColors.neonCyan;
        title = 'Mengunduh Pembaruan';
        subtitle = 'Proses unduh dari dalam aplikasi';
        break;
      case _DownloadPhase.readyToInstall:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.neonGreen;
        title = 'Unduhan Selesai';
        subtitle = 'Siap memasang versi terbaru';
        break;
      case _DownloadPhase.error:
        icon = Icons.error_outline_rounded;
        iconColor = AppColors.warningYellow;
        title = 'Gagal Mengunduh';
        subtitle = 'Terjadi kendala koneksi';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(40),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _DownloadPhase.idle:
        return _buildIdleContent();
      case _DownloadPhase.downloading:
        return _buildDownloadingContent();
      case _DownloadPhase.readyToInstall:
        return _buildReadyToInstallContent();
      case _DownloadPhase.error:
        return _buildErrorContent();
    }
  }

  Widget _buildIdleContent() {
    return Column(
      key: const ValueKey('idle'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Badge Perbandingan Versi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saat ini: v${widget.updateInfo.currentVersion}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryOrange,
                size: 16,
              ),
              Text(
                'Baru: v${widget.updateInfo.latestVersion}',
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Judul Rilis
        Text(
          widget.updateInfo.releaseTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        // Catatan Perubahan (Changelog)
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.updateInfo.releaseNotes.isNotEmpty
                  ? widget.updateInfo.releaseNotes
                  : 'Peningkatan performa dan perbaikan bug sistem.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadingContent() {
    final percent = (_progress * 100).toInt();
    final downloadedStr = _formatBytes(_receivedBytes);
    final totalStr = _totalBytes > 0 ? _formatBytes(_totalBytes) : '...';

    return Column(
      key: const ValueKey('downloading'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Persentase Besar
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: AppColors.neonCyan,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 8),

        // Progress Bar Elegan
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _totalBytes > 0 ? _progress : null,
            minHeight: 10,
            backgroundColor: AppColors.darkBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        ),

        const SizedBox(height: 12),

        // Ukuran Terunduh
        Text(
          '$downloadedStr / $totalStr',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Mengunduh langsung di aplikasi. Mohon jangan menutup layar ini...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildReadyToInstallContent() {
    return Column(
      key: const ValueKey('ready'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.done_all_rounded,
            color: AppColors.neonGreen,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Paket Pembaruan Berhasil Diunduh!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pemasang paket sistem akan terbuka untuk menggantikan versi lama secara otomatis tanpa menghapus data riwayat Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Gagal mengunduh pembaruan aplikasi.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.warningYellow,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pastikan koneksi internet aktif. Anda juga dapat mengunduh langsung via peramban web.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildActionButtons() {
    switch (_phase) {
      case _DownloadPhase.idle:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Nanti'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Perbarui Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case _DownloadPhase.downloading:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancelDownload,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Batalkan Unduhan'),
          ),
        );

      case _DownloadPhase.readyToInstall:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tutup'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _installApk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.install_mobile_rounded, size: 18),
                label: const Text(
                  'Pasang Pembaruan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case _DownloadPhase.error:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
    }
  }
}
