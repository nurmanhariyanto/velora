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
import '../widgets/update_dialog.dart';
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
  String _appVersion = '1.1.3';
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
                    onTap: _showPrecacheDialog,
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
                    onTap: _showCheckUpdateDialog,
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

  String _resolveDeviceDisplayName(BluetoothDevice device, AdvertisementData advData) {
    final advName = advData.advName.trim();
    if (advName.isNotEmpty) return advName;

    final platName = device.platformName.trim();
    if (platName.isNotEmpty) return platName;

    // Cek Service UUID
    final hasHr = advData.serviceUuids.any((u) => u.toString().toLowerCase().contains('180d'));
    if (hasHr) return 'Sensor Detak Jantung BLE';

    // Cek Manufacturer ID
    if (advData.manufacturerData.containsKey(0x0087)) return 'Garmin Watch';
    if (advData.manufacturerData.containsKey(0x006B)) return 'Polar HRM';
    if (advData.manufacturerData.containsKey(0x0157)) return 'Amazfit / Zepp Watch';
    if (advData.manufacturerData.containsKey(0x038F)) return 'Xiaomi Smart Band';
    if (advData.manufacturerData.containsKey(0x027D)) return 'Huawei Watch';
    if (advData.manufacturerData.containsKey(0x004C)) return 'Apple Device';
    if (advData.manufacturerData.containsKey(0x0075)) return 'Samsung Galaxy Watch';

    return '';
  }

  void _showHeartRateSensorModal() {
    List<BluetoothDevice> pairedDevices = [];
    bool showUnnamed = false;
    bool showAllPaired = false;
    bool hasFetchedPaired = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (!hasFetchedPaired) {
              hasFetchedPaired = true;
              _hrService.getBondedDevices().then((list) {
                if (modalCtx.mounted) {
                  setModalState(() {
                    pairedDevices = list;
                  });
                }
              });
            }

            // Pisahkan perangkat smartwatch/fitness vs perangkat bluetooth biasa (TWS, Car Audio, TV)
            final watchPaired = <BluetoothDevice>[];
            final otherPaired = <BluetoothDevice>[];

            for (final d in pairedDevices) {
              final name = d.platformName.trim().toLowerCase();
              final isWatch = name.contains('watch') ||
                  name.contains('haylou') ||
                  name.contains('band') ||
                  name.contains('garmin') ||
                  name.contains('fit') ||
                  name.contains('polar') ||
                  name.contains('coros') ||
                  name.contains('amazfit') ||
                  name.contains('strap') ||
                  name.contains('heart') ||
                  name.contains('hr');
              if (isWatch) {
                watchPaired.add(d);
              } else {
                otherPaired.add(d);
              }
            }

            final sortedPaired = [...watchPaired, ...otherPaired];
            final displayedPaired = showAllPaired || sortedPaired.length <= 3
                ? sortedPaired
                : sortedPaired.take(3).toList();

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.88,
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // --- PINNED HEADER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                    child: Column(
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Sensor Detak Jantung (BLE)',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_hrService.isConnected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                              onPressed: () => Navigator.pop(modalCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pindai dan hubungkan smartwatch atau sensor dada (chest strap).',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 12),

                        // Tombol Scan BLE Pinned Permanen (Tidak pernah tertutup atau terdorong scroll)
                        StreamBuilder<bool>(
                          stream: FlutterBluePlus.isScanning,
                          initialData: false,
                          builder: (btnCtx, scanSnap) {
                            final isScanning = scanSnap.data ?? false;

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isScanning ? Colors.grey.shade800 : AppColors.primaryOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon: isScanning
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.bluetooth_searching_rounded),
                                label: Text(
                                  isScanning ? 'Sedang Memindai... (Tekan untuk Berhenti)' : 'Pindai Sensor BLE Sekitar',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                onPressed: () async {
                                  if (isScanning) {
                                    await _hrService.stopScan();
                                  } else {
                                    final err = await _hrService.startScan();
                                    if (err != null && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
                                      );
                                    }
                                  }
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),

                  // --- SCROLLABLE BODY ---
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        // Status Terhubung Saat Ini
                        if (_hrService.isConnected) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.neonGreen.withAlpha(120)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.neonRed.withAlpha(35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.favorite_rounded, color: AppColors.neonRed, size: 26),
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
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Detak Jantung: ${_hrService.currentBpm ?? '--'} BPM',
                                        style: const TextStyle(
                                          color: AppColors.electricAmber,
                                          fontWeight: FontWeight.bold,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  child: const Text('Putus', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Switch Mode Simulasi Demo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
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
                                    'Gunakan untuk uji coba live BPM tanpa alat fisik',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _hrService.isSimulationMode,
                                activeThumbColor: AppColors.primaryOrange,
                                activeTrackColor: AppColors.primaryOrange.withAlpha(80),
                                inactiveThumbColor: AppColors.textMuted,
                                inactiveTrackColor: AppColors.borderSubtle,
                                onChanged: (enabled) {
                                  _hrService.toggleSimulation(enabled);
                                  setModalState(() {});
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 1. DAFTAR PERANGKAT YANG SUDAH TERPASANG / DI-BOND DI HP
                        if (sortedPaired.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.neonCyan.withAlpha(60)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.watch_rounded, color: AppColors.neonCyan, size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Smartwatch Terpasang di Ponsel (Paired)',
                                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonCyan.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${sortedPaired.length}',
                                        style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...displayedPaired.map((d) {
                                  final pName = d.platformName.trim().isNotEmpty ? d.platformName.trim() : 'Smartwatch (${d.remoteId.str})';
                                  final isConn = _hrService.connectedDeviceName == pName || _hrService.connectedDeviceName == d.remoteId.str;
                                  final lower = pName.toLowerCase();
                                  IconData devIcon = Icons.watch_rounded;
                                  Color iconClr = AppColors.primaryOrange;
                                  if (lower.contains('audio') || lower.contains('car') || lower.contains('buds') || lower.contains('bt') || lower.contains('head') || lower.contains('sound') || lower.contains('jbl') || lower.contains('rb') || lower.contains('tune')) {
                                    devIcon = Icons.headphones_rounded;
                                    iconClr = AppColors.neonCyan;
                                  } else if (lower.contains('tv')) {
                                    devIcon = Icons.tv_rounded;
                                    iconClr = AppColors.electricAmber;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isConn ? AppColors.neonGreen.withAlpha(20) : AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isConn ? AppColors.neonGreen : AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: iconClr.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(devIcon, color: iconClr, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text('${d.remoteId.str} • Siap Hubungkan', style: const TextStyle(color: AppColors.neonGreen, fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isConn ? AppColors.neonGreen : AppColors.primaryOrange,
                                            foregroundColor: isConn ? Colors.black87 : Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: isConn
                                              ? () async {
                                                  await _hrService.disconnect();
                                                  setModalState(() {});
                                                  setState(() {});
                                                }
                                              : () async {
                                                  final res = await _hrService.connectToDevice(d);
                                                  setModalState(() {});
                                                  setState(() {});
                                                  if (!res.success && mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(res.errorMessage ?? 'Gagal menghubungkan.'), backgroundColor: Colors.redAccent),
                                                    );
                                                  } else if (!res.hasHeartRateService && mounted) {
                                                    _showDeviceConnectedNoticeDialog(pName);
                                                  }
                                                },
                                          child: Text(isConn ? 'Terhubung' : 'Hubungkan', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                // Tombol ekspansi jika perangkat Bluetooth banyak
                                if (sortedPaired.length > 3)
                                  InkWell(
                                    onTap: () => setModalState(() => showAllPaired = !showAllPaired),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            showAllPaired
                                                ? 'Sembunyikan perangkat tambahan'
                                                : 'Lihat ${sortedPaired.length - 3} perangkat terpasang lainnya',
                                            style: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            showAllPaired ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: AppColors.neonCyan,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // 2. TAB / PANEL: Perangkat Bluetooth di Sekitar
                        StreamBuilder<List<ScanResult>>(
                          stream: FlutterBluePlus.scanResults,
                          builder: (scanResCtx, snapshot) {
                            final rawResults = snapshot.data ?? [];
                            final Map<String, ScanResult> uniqueMap = {};
                            for (final r in rawResults) {
                              uniqueMap[r.device.remoteId.str] = r;
                            }
                            final allScanned = uniqueMap.values.toList();

                            // Filter perangkat bernama vs tanpa nama
                            final namedDevices = <({ScanResult result, String name})>[];
                            final unnamedDevices = <ScanResult>[];

                            for (final item in allScanned) {
                              final name = _resolveDeviceDisplayName(item.device, item.advertisementData);
                              if (name.isNotEmpty) {
                                namedDevices.add((result: item, name: name));
                              } else {
                                unnamedDevices.add(item);
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurfaceElevated,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.bluetooth_audio_rounded, color: AppColors.neonCyan, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Perangkat BLE di Sekitar',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${namedDevices.length} Terdeteksi',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: AppColors.borderSubtle, height: 20),

                                  StreamBuilder<bool>(
                                    stream: FlutterBluePlus.isScanning,
                                    initialData: false,
                                    builder: (scanStreamCtx, scanSnap) {
                                      final isScanning = scanSnap.data ?? false;

                                      if (isScanning && namedDevices.isEmpty && unnamedDevices.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 24),
                                          child: Center(
                                            child: Column(
                                              children: [
                                                CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
                                                SizedBox(height: 12),
                                                Text(
                                                  'Mencari smartwatch & sensor di sekitar...',
                                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      if (namedDevices.isEmpty && unnamedDevices.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                          child: Column(
                                            children: const [
                                              Icon(Icons.devices_other_rounded, size: 40, color: AppColors.textMuted),
                                              SizedBox(height: 10),
                                              Text(
                                                'Belum ada perangkat terdeteksi.',
                                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                '1. Pastikan jam tangan / sensor dalam keadaan aktif.\\n2. Tekan tombol "Pindai Sensor BLE Sekitar" di atas.\\n3. Perangkat di sekitar Anda akan langsung muncul di daftar ini.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Daftar perangkat yang memiliki nama jelas
                                          if (namedDevices.isNotEmpty)
                                            ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: namedDevices.length,
                                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                                              itemBuilder: (itemCtx, index) {
                                                final entry = namedDevices[index];
                                                final item = entry.result;
                                                final deviceName = entry.name;
                                                final isThisConnected = _hrService.connectedDeviceName == deviceName ||
                                                    _hrService.connectedDeviceName == item.device.remoteId.str;

                                                IconData deviceIcon = Icons.bluetooth_rounded;
                                                Color iconColor = AppColors.neonCyan;
                                                final lowerName = deviceName.toLowerCase();
                                                if (lowerName.contains('watch') ||
                                                    lowerName.contains('haylou') ||
                                                    lowerName.contains('band') ||
                                                    lowerName.contains('garmin') ||
                                                    lowerName.contains('amazfit') ||
                                                    lowerName.contains('fit')) {
                                                  deviceIcon = Icons.watch_rounded;
                                                  iconColor = AppColors.electricAmber;
                                                } else if (lowerName.contains('hr') ||
                                                    lowerName.contains('heart') ||
                                                    lowerName.contains('polar') ||
                                                    lowerName.contains('magene') ||
                                                    lowerName.contains('strap')) {
                                                  deviceIcon = Icons.favorite_rounded;
                                                  iconColor = AppColors.neonRed;
                                                }

                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.cardSurface,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isThisConnected ? AppColors.neonGreen : AppColors.borderSubtle,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 38,
                                                        height: 38,
                                                        decoration: BoxDecoration(
                                                          color: iconColor.withAlpha(30),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(deviceIcon, color: iconColor, size: 20),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              deviceName,
                                                              style: const TextStyle(
                                                                color: AppColors.textPrimary,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 13,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              '${item.device.remoteId.str} • Sinyal ${item.rssi} dBm',
                                                              style: const TextStyle(
                                                                color: AppColors.textSecondary,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: isThisConnected ? AppColors.neonGreen : AppColors.primaryOrange,
                                                          foregroundColor: isThisConnected ? Colors.black87 : Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        onPressed: isThisConnected
                                                            ? () async {
                                                                await _hrService.disconnect();
                                                                setModalState(() {});
                                                                setState(() {});
                                                              }
                                                            : () async {
                                                                final res = await _hrService.connectToDevice(item.device);
                                                                setModalState(() {});
                                                                setState(() {});
                                                                if (!res.success && mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(res.errorMessage ?? 'Gagal menghubungkan ke perangkat.'),
                                                                      backgroundColor: Colors.redAccent,
                                                                    ),
                                                                  );
                                                                } else if (!res.hasHeartRateService && mounted) {
                                                                  _showDeviceConnectedNoticeDialog(deviceName);
                                                                }
                                                              },
                                                        child: Text(
                                                          isThisConnected ? 'Terhubung' : 'Hubungkan',
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),

                                          // Bagian Perangkat Anonim Tanpa Nama (Collapsible agar tidak memenuhi layar)
                                          if (unnamedDevices.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            InkWell(
                                              onTap: () => setModalState(() => showUnnamed = !showUnnamed),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.cardSurface,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppColors.borderSubtle),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.devices_other_rounded, size: 16, color: AppColors.textMuted),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '${unnamedDevices.length} Perangkat Anonim / Tanpa Nama',
                                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                                        ),
                                                      ],
                                                    ),
                                                    Icon(
                                                      showUnnamed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                      size: 18,
                                                      color: AppColors.textMuted,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (showUnnamed) ...[
                                              const SizedBox(height: 8),
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: unnamedDevices.length,
                                                itemBuilder: (unnamedCtx, uIdx) {
                                                  final item = unnamedDevices[uIdx];
                                                  final fallbackName = 'BLE Device (${item.device.remoteId.str.substring(0, 5)}...)';
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.darkBackground,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.bluetooth_rounded, size: 16, color: AppColors.textMuted),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            '${item.device.remoteId.str} (${item.rssi} dBm)',
                                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          style: TextButton.styleFrom(
                                                            foregroundColor: AppColors.primaryOrange,
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            minimumSize: Size.zero,
                                                          ),
                                                          onPressed: () async {
                                                            final res = await _hrService.connectToDevice(item.device);
                                                            setModalState(() {});
                                                            setState(() {});
                                                            if (!res.success && mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text(res.errorMessage ?? 'Gagal.'), backgroundColor: Colors.redAccent),
                                                              );
                                                            } else if (!res.hasHeartRateService && mounted) {
                                                              _showDeviceConnectedNoticeDialog(fallbackName);
                                                            }
                                                          },
                                                          child: const Text('Hubungkan', style: TextStyle(fontSize: 10)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeviceConnectedNoticeDialog(String deviceName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: AppColors.electricAmber),
              SizedBox(width: 10),
              Expanded(
                child: Text('Perangkat Terhubung', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ],
          ),
          content: Text(
            'Berhasil terhubung ke $deviceName!\n\nNamun, jam tangan ini belum memancarkan sinyal detak jantung terbuka (GATT 0x180D).\n\nTips:\n1. Buka aplikasi pendamping jam (misal Haylou Fun / Zepp) dan aktifkan fitur "Siarkan Detak Jantung" jika tersedia.\n2. Atau, Anda dapat merekam olahraga langsung di jam tanpa bawa HP, lalu ekspor file GPX dan gunakan tombol "Impor Aktivitas Jam Tangan (GPX)" di Velora.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
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

  // --- DIALOG PEMANASAN CACHE PETA OFFLINE ---

  void _showPrecacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isWarming = false;
        bool isDone = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.downloading_rounded, color: AppColors.neonCyan),
                  SizedBox(width: 10),
                  Text('Cache Peta Offline', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pemanasan cache peta akan mengunduh ubin peta rute umum ke penyimpanan lokal HP Anda.\n\nPeta akan tetap terbuka cepat dan mulus meskipun Anda berolahraga di area tanpa sinyal internet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (isWarming) ...[
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.neonCyan),
                          SizedBox(height: 12),
                          Text('Mengunduh ubin peta rute...', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else if (isDone) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neonGreen),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: AppColors.neonGreen),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cache peta offline berhasil dihangatkan!',
                              style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isDone ? 'Tutup' : 'Batal', style: const TextStyle(color: AppColors.textSecondary)),
                ),
                if (!isDone)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isWarming
                        ? null
                        : () async {
                            setDialogState(() => isWarming = true);
                            await MapPrecacheService.warmUpOnAppStart();
                            await Future.delayed(const Duration(milliseconds: 1500));
                            if (dialogCtx.mounted) {
                              setDialogState(() {
                                isWarming = false;
                                isDone = true;
                              });
                            }
                          },
                    child: const Text('Hangatkan Cache Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIALOG PERIKSA PEMBARUAN APLIKASI ---

  Future<void> _showCheckUpdateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Row(
            children: const [
              CircularProgressIndicator(color: AppColors.primaryOrange),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Memeriksa pembaruan di server...',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );

    final updateInfo = await UpdateService.checkLatestRelease();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Tutup loading dialog

    if (updateInfo != null && updateInfo.hasUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(updateInfo: updateInfo),
      );
    } else if (updateInfo != null && !updateInfo.hasUpdate) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.verified_rounded, color: AppColors.neonGreen, size: 26),
                SizedBox(width: 10),
                Text('Versi Terbaru', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              'Aplikasi Velora Anda sudah menggunakan versi paling mutakhir (v${updateInfo.currentVersion}).\n\nSeluruh fitur integrasi Smartwatch, Sensor Detak Jantung, dan Mode Rute Strava sudah aktif.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.wifi_off_rounded, color: AppColors.neonRed),
                SizedBox(width: 10),
                Text('Koneksi Gagal', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: const Text(
              'Tidak dapat memeriksa pembaruan. Pastikan ponsel Anda terhubung ke jaringan internet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      );
    }
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
