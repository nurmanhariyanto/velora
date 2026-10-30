import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_colors.dart';
import '../database/activity_repository.dart';
import '../models/activity_session.dart';
import '../models/sports_type.dart';
import '../services/gpx_service.dart';
import '../services/heart_rate_service.dart';
import '../services/map_precache_service.dart';
import '../services/update_service.dart';
import '../services/user_profile_service.dart';
import 'activity_detail_screen.dart';

/// Layanan & Layar Pengaturan Velora (Perangkat & Sensor, Smartwatch, Profil, & Peta)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HeartRateService _hrService = HeartRateService.instance;
  String _athleteName = UserProfileService.currentAthleteName;
  String _appVersion = '1.0.23';
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await UserProfileService.getAthleteName();
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    if (mounted) {
      setState(() {
        _athleteName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Pengaturan & Sensor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<bool>(
        stream: _hrService.connectionStateStream,
        builder: (context, _) {
          return StreamBuilder<int>(
            stream: _hrService.bpmStream,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // 1. Bagian: Perangkat & Sensor Smartwatch
                  _buildSectionHeader(
                    'PERANGKAT & SENSOR SMARTWATCH',
                    Icons.watch_rounded,
                  ),
                  const SizedBox(height: 12),

                  // Impor File GPX Smartwatch (Latihan Mandiri Tanpa Bawa HP)
                  _buildSettingsTile(
                    icon: Icons.file_download_rounded,
                    iconColor: AppColors.neonCyan,
                    title: 'Impor Aktivitas Jam Tangan (GPX)',
                    subtitle: 'Latihan tanpa bawa HP (Haylou, Garmin, Amazfit, Strava)',
                    trailing: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryOrange,
                            ),
                          )
                        : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: _pickAndImportGpxFile,
                  ),
                  const SizedBox(height: 10),

                  // Hubungkan Sensor Detak Jantung BLE
                  _buildSettingsTile(
                    icon: Icons.favorite_rounded,
                    iconColor: _hrService.isConnected ? AppColors.neonRed : AppColors.textMuted,
                    title: 'Sensor Detak Jantung (BLE HRM)',
                    subtitle: _hrService.isConnected
                        ? 'Terhubung: ${_hrService.connectedDeviceName} (${_hrService.currentBpm ?? '--'} BPM)'
                        : 'Hubungkan chest strap / smartwatch broadcast',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _hrService.isConnected
                            ? AppColors.neonGreen.withAlpha(30)
                            : AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hrService.isConnected
                              ? AppColors.neonGreen
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        _hrService.isConnected ? 'TERHUBUNG' : 'PASANGKAN',
                        style: TextStyle(
                          color: _hrService.isConnected
                              ? AppColors.neonGreen
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: _showHeartRateSensorModal,
                  ),
                  const SizedBox(height: 10),

                  // Pengaturan Usia & Zona Detak Jantung
                  _buildSettingsTile(
                    icon: Icons.speed_rounded,
                    iconColor: AppColors.electricAmber,
                    title: 'Zona Detak Jantung Atlet (Z1 - Z5)',
                    subtitle: 'Usia: ${_hrService.userAge} thn • HR Max: ${_hrService.effectiveMaxHr} BPM',
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: _showHeartRateZonesDialog,
                  ),
                  const SizedBox(height: 10),

                  // Panduan Integrasi Smartwatch Mandiri
                  _buildSettingsTile(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.neonGreen,
                    title: 'Panduan Gowes & Lari Tanpa Bawa HP',
                    subtitle: 'Cara merekam di Haylou Solar Neo 2, Garmin, Amazfit & sync',
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: _showSmartwatchGuideDialog,
                  ),

                  const SizedBox(height: 28),

                  // 2. Bagian: Profil Atlet
                  _buildSectionHeader('PROFIL PENGGUNA', Icons.person_rounded),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.badge_rounded,
                    iconColor: AppColors.primaryOrange,
                    title: 'Nama Atlet',
                    subtitle: _athleteName,
                    trailing: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
                    onTap: _showEditNameDialog,
                  ),

                  const SizedBox(height: 28),

                  // 3. Bagian: Peta & Offline Cache
                  _buildSectionHeader('PETA & CACHE OFFLINE', Icons.map_rounded),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.downloading_rounded,
                    iconColor: AppColors.neonCyan,
                    title: 'Pemanasan Cache Peta',
                    subtitle: 'Unduh ubin peta rute umum agar siap digunakan offline',
                    trailing: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      MapPrecacheService.warmUpOnAppStart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pemanasan cache peta offline sedang berjalan di latar belakang.'),
                          backgroundColor: AppColors.cardSurface,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // 4. Bagian: Tentang Aplikasi
                  _buildSectionHeader('TENTANG & PEMBARUAN', Icons.info_outline_rounded),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.system_update_rounded,
                    iconColor: AppColors.electricAmber,
                    title: 'Periksa Pembaruan Aplikasi',
                    subtitle: 'Versi saat ini: v$_appVersion',
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
                    onTap: () => UpdateService.checkForUpdate(context, silent: false),
                  ),

                  const SizedBox(height: 36),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // --- LOGIKA IMPOR FILE GPX DARI SMARTWATCH ---

  static const MethodChannel _gpxPickerChannel =
      MethodChannel('online.nurmancloud.velora/gpx_picker');

  Future<void> _pickAndImportGpxFile() async {
    if (_isImporting) return;

    try {
      setState(() {
        _isImporting = true;
      });

      final result = await _gpxPickerChannel.invokeMapMethod<String, dynamic>('pickGpxFile');

      if (result == null || result['content'] == null) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final fileName = result['name'] as String? ?? 'Aktivitas Smartwatch';
      final xmlContent = result['content'] as String;

      final session = GpxService.parseGpxToActivitySession(
        xmlContent,
        customTitle: fileName.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), ''),
      );

      if (session != null) {
        final repo = ActivityRepository();
        await repo.insertActivity(session);
      }

      setState(() {
        _isImporting = false;
      });

      if (session != null && mounted) {
        _showImportSuccessDialog(session);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membaca lintasan GPS pada file GPX ini.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengimpor file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImportSuccessDialog(ActivitySession session) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aktivitas Berhasil Diimpor!',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.displayTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildImportDetailRow('Jarak', '${session.distanceKm.toStringAsFixed(2)} km'),
              _buildImportDetailRow('Durasi', session.formattedDuration),
              _buildImportDetailRow(
                'Kecepatan Rata-rata',
                session.sportsType == SportsType.run ? session.formattedPace : session.formattedSpeed,
              ),
              if (session.averageHeartRate != null)
                _buildImportDetailRow('Detak Jantung Rata-rata', '${session.averageHeartRate} bpm'),
              if (session.maxHeartRate != null)
                _buildImportDetailRow('Detak Jantung Maks', '${session.maxHeartRate} bpm'),
              _buildImportDetailRow('Elevasi Naik', '+${session.elevationGain.toStringAsFixed(0)} m'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivityDetailScreen(session: session),
                  ),
                );
              },
              child: const Text('Buka Aktivitas'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImportDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // --- MODAL SENSOR DETAK JANTUNG BLE ---

  void _showHeartRateSensorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isScanning = FlutterBluePlus.isScanningNow;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderHighlight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sensor Detak Jantung (BLE)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_hrService.isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.neonGreen),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mendukung chest strap (Polar H10, Garmin HRM, Magene) dan smartwatch dengan fitur siaran detak jantung via Bluetooth.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Status Terhubung Saat Ini
                  if (_hrService.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neonGreen.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.neonRed.withAlpha(35),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.favorite_rounded, color: AppColors.neonRed, size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hrService.connectedDeviceName ?? 'Perangkat Bluetooth',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Detak Jantung: ${_hrService.currentBpm ?? '--'} BPM',
                                  style: const TextStyle(
                                    color: AppColors.electricAmber,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            onPressed: () async {
                              if (_hrService.isSimulationMode) {
                                _hrService.toggleSimulation(false);
                              } else {
                                await _hrService.disconnect();
                              }
                              setModalState(() {});
                              setState(() {});
                            },
                            child: const Text('Putus'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tombol Scan BLE
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: isScanning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.bluetooth_searching_rounded),
                          label: Text(isScanning ? 'Memindai...' : 'Pindai Sensor BLE'),
                          onPressed: isScanning
                              ? () async {
                                  await _hrService.stopScan();
                                  setModalState(() {});
                                }
                              : () async {
                                  await _hrService.startScan();
                                  setModalState(() {});
                                },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Switch Mode Simulasi Demo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Simulasi HR (Demo)',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Gunakan untuk tes tanpa sensor fisik',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        Switch(
                          value: _hrService.isSimulationMode,
                          activeThumbColor: AppColors.primaryOrange,
                          onChanged: (val) {
                            _hrService.toggleSimulation(val);
                            setModalState(() {});
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hasil Scan BLE
                  StreamBuilder<List<ScanResult>>(
                    stream: FlutterBluePlus.scanResults,
                    builder: (context, snapshot) {
                      final results = snapshot.data ?? [];
                      if (results.isEmpty && isScanning) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Mencari sensor detak jantung aktif di sekitar...',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      if (results.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Perangkat Ditemukan:',
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final item = results[index];
                              final deviceName = item.device.platformName.isNotEmpty
                                  ? item.device.platformName
                                  : item.device.remoteId.str;

                              return Card(
                                color: AppColors.cardSurfaceElevated,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: const Icon(Icons.bluetooth_rounded, color: AppColors.neonCyan),
                                  title: Text(
                                    deviceName,
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'RSSI: ${item.rssi} dBm',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryOrange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final ok = await _hrService.connectToDevice(item.device);
                                      if (ok) {
                                        setModalState(() {});
                                        setState(() {});
                                      }
                                    },
                                    child: const Text('Hubungkan'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- DIALOG ZONA DETAK JANTUNG ---

  void _showHeartRateZonesDialog() {
    int tempAge = _hrService.userAge;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final effectiveMax = 220 - tempAge;
            final currentZones = HeartRateService.calculateZones(effectiveMax);

            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.speed_rounded, color: AppColors.electricAmber),
                  SizedBox(width: 10),
                  Text(
                    'Zona Detak Jantung',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zona detak jantung dihitung berdasarkan formula standar (220 - Usia).',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Usia Anda:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                if (tempAge > 12) {
                                  setDialogState(() => tempAge--);
                                }
                              },
                            ),
                            Text(
                              '$tempAge thn',
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                if (tempAge < 95) {
                                  setDialogState(() => tempAge++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Estimasi Max HR: $effectiveMax BPM',
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Distribusi 5 Zona:',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    for (final z in currentZones) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: z.color.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: z.color),
                              ),
                              child: Text(
                                z.label,
                                style: TextStyle(color: z.color, fontSize: 11, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                z.title,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                              ),
                            ),
                            Text(
                              '${z.minBpm} - ${z.maxBpm} bpm',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await _hrService.setUserAge(tempAge);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIALOG PANDUAN SMARTWATCH MANDIRI ---

  void _showSmartwatchGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: AppColors.neonGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Panduan Smartwatch Tanpa HP',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGuideStep(
                  '1',
                  'Haylou Solar Neo 2 & Haylou Series',
                  '• Jam tangan Haylou merekam detak jantung optik, langkah, dan kalkulasi latihan.\n'
                  '• Mulai sesi olahraga di jam Anda tanpa membawa HP.\n'
                  '• Selesai olahraga, buka aplikasi Haylou Fun di HP Anda untuk sinkronisasi otomatis.\n'
                  '• Dari riwayat latihan Haylou Fun / Strava, simpan/ekspor file GPX.\n'
                  '• Masuk ke menu Pengaturan Velora > "Impor Aktivitas Jam Tangan (GPX)" untuk mengimpor rute dan grafik HR.',
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  '2',
                  'Garmin / Coros / Amazfit (Zepp)',
                  '• Semua jam tangan GPS mandiri menyimpan rute dalam format GPX/FIT.\n'
                  '• Ekspor file GPX dari aplikasi Garmin Connect atau Zepp ke penyimpanan HP Anda.\n'
                  '• Impor ke Velora dengan sekali klik.',
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  '3',
                  'Sinkronisasi Balik ke Strava',
                  '• Setiap aktivitas yang direkam di Velora atau diimpor memiliki tombol "Ekspor GPX".\n'
                  '• File GPX Velora menyertakan format standar Garmin `<gpxtpx:hr>` sehingga detak jantung langsung muncul otomatis di Strava.',
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuideStep(String stepNumber, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- DIALOG EDIT NAMA ATLET ---

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _athleteName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Ganti Nama Atlet',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Masukkan nama atlet...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardSurfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await UserProfileService.setAthleteName(newName);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    setState(() {
                      _athleteName = newName;
                    });
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
