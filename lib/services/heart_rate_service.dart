import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/coordinate_point.dart';

/// Jenis Zona Detak Jantung (Heart Rate Zones) Z1 - Z5
enum HeartRateZoneType {
  zone1, // 50% - 60% HRmax: Pemulihan / Sangat Ringan
  zone2, // 60% - 70% HRmax: Daya Tahan Aerobik / Bakar Lemak
  zone3, // 70% - 80% HRmax: Aerobik Tempo / Kardio
  zone4, // 80% - 90% HRmax: Ambang Batas Laktat / Threshold
  zone5, // 90% - 100% HRmax: Anaerobik / VO2 Max Maksimal
}

/// Rincian informasi satu zona detak jantung
class HeartRateZoneInfo {
  final HeartRateZoneType zone;
  final String label;
  final String title;
  final String description;
  final int minBpm;
  final int maxBpm;
  final Color color;

  const HeartRateZoneInfo({
    required this.zone,
    required this.label,
    required this.title,
    required this.description,
    required this.minBpm,
    required this.maxBpm,
    required this.color,
  });

  bool contains(int bpm) => bpm >= minBpm && bpm <= maxBpm;
}

/// Distribusi waktu aktivitas pada masing-masing Zona Detak Jantung
class HeartRateZoneDistribution {
  final Map<HeartRateZoneType, int> secondsPerZone;
  final Map<HeartRateZoneType, double> percentPerZone;
  final int totalSecondsWithHr;
  final HeartRateZoneType dominantZone;

  const HeartRateZoneDistribution({
    required this.secondsPerZone,
    required this.percentPerZone,
    required this.totalSecondsWithHr,
    required this.dominantZone,
  });
}

/// Layanan terpadu untuk Sensor Detak Jantung BLE, Zona HR, dan Integrasi Smartwatch
class HeartRateService {
  static HeartRateService? _instance;
  static HeartRateService get instance => _instance ??= HeartRateService._();

  HeartRateService._() {
    _initPreferences();
  }

  // UUID Standar Bluetooth SIG untuk Heart Rate
  static final Guid heartRateServiceUuid = Guid('0000180d-0000-1000-8000-00805f9b34fb');
  static final Guid heartRateMeasurementCharUuid = Guid('00002a37-0000-1000-8000-00805f9b34fb');

  // Pengaturan Pengguna
  int _userAge = 28;
  int? _customMaxHr;

  int get userAge => _userAge;
  int? get customMaxHr => _customMaxHr;

  /// Detak jantung maksimum efektif (custom jika ada, atau 220 - usia)
  int get effectiveMaxHr => _customMaxHr ?? (220 - _userAge);

  // Status Koneksi BLE
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceName;
  bool _isConnecting = false;
  int? _currentBpm;
  StreamSubscription<List<int>>? _hrCharSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;

  // Mode Simulasi (untuk pengujian & demo tanpa sensor fisik)
  bool _isSimulationMode = false;
  Timer? _simulationTimer;

  // Stream Controllers
  final _bpmController = StreamController<int>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<int> get bpmStream => _bpmController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _connectedDevice != null || _isSimulationMode;
  bool get isSimulationMode => _isSimulationMode;
  int? get currentBpm => _currentBpm;
  String? get connectedDeviceName =>
      _isSimulationMode ? 'Simulasi Sensor HRM' : _connectedDeviceName;

  /// Memuat preferensi usia dan detak jantung maksimal dari SharedPreferences
  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userAge = prefs.getInt('velora_user_age') ?? 28;
      _customMaxHr = prefs.getInt('velora_user_custom_max_hr');
    } catch (_) {}
  }

  /// Memperbarui usia pengguna dan menyimpannya secara persisten
  Future<void> setUserAge(int age) async {
    if (age < 10 || age > 110) return;
    _userAge = age;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('velora_user_age', age);
    } catch (_) {}
  }

  /// Menetapkan custom Max HR atau null untuk kembali menggunakan formula 220 - usia
  Future<void> setCustomMaxHr(int? maxHr) async {
    _customMaxHr = maxHr;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (maxHr == null) {
        await prefs.remove('velora_user_custom_max_hr');
      } else {
        await prefs.setInt('velora_user_custom_max_hr', maxHr);
      }
    } catch (_) {}
  }

  // --- KALKULASI ZONA DETAK JANTUNG ---

  /// Menghitung batas BPM untuk masing-masing dari 5 zona detak jantung
  static List<HeartRateZoneInfo> calculateZones(int maxHr) {
    final z1Min = (maxHr * 0.50).round();
    final z1Max = (maxHr * 0.60).round() - 1;

    final z2Min = (maxHr * 0.60).round();
    final z2Max = (maxHr * 0.70).round() - 1;

    final z3Min = (maxHr * 0.70).round();
    final z3Max = (maxHr * 0.80).round() - 1;

    final z4Min = (maxHr * 0.80).round();
    final z4Max = (maxHr * 0.90).round() - 1;

    final z5Min = (maxHr * 0.90).round();
    final z5Max = maxHr;

    return [
      HeartRateZoneInfo(
        zone: HeartRateZoneType.zone1,
        label: 'Z1',
        title: 'Pemulihan Santai',
        description: 'Pemanasan, pendinginan, dan pemulihan aktif (50%-60%)',
        minBpm: z1Min,
        maxBpm: z1Max,
        color: AppColors.neonCyan,
      ),
      HeartRateZoneInfo(
        zone: HeartRateZoneType.zone2,
        label: 'Z2',
        title: 'Daya Tahan & Bakar Lemak',
        description: 'Zona dasar aerobik, efisiensi bahan bakar lemak (60%-70%)',
        minBpm: z2Min,
        maxBpm: z2Max,
        color: AppColors.neonGreen,
      ),
      HeartRateZoneInfo(
        zone: HeartRateZoneType.zone3,
        label: 'Z3',
        title: 'Aerobik Tempo',
        description: 'Meningkatkan kapasitas kardiovaskular & daya tahan (70%-80%)',
        minBpm: z3Min,
        maxBpm: z3Max,
        color: AppColors.warningYellow,
      ),
      HeartRateZoneInfo(
        zone: HeartRateZoneType.zone4,
        label: 'Z4',
        title: 'Ambang Batas (Threshold)',
        description: 'Meningkatkan ambang laktat dan kecepatan balapan (80%-90%)',
        minBpm: z4Min,
        maxBpm: z4Max,
        color: AppColors.primaryOrange,
      ),
      HeartRateZoneInfo(
        zone: HeartRateZoneType.zone5,
        label: 'Z5',
        title: 'Maksimal (VO2 Max)',
        description: 'Kekuatan anaerobik puncak & sprint habis-habisan (90%-100%)',
        minBpm: z5Min,
        maxBpm: z5Max,
        color: AppColors.neonRed,
      ),
    ];
  }

  /// Menentukan zona detak jantung untuk nilai BPM tertentu
  static HeartRateZoneInfo getZoneForBpm(int bpm, int maxHr) {
    final zones = calculateZones(maxHr);
    if (bpm < zones.first.minBpm) return zones.first;
    for (final z in zones) {
      if (bpm <= z.maxBpm) return z;
    }
    return zones.last;
  }

  /// Menghitung akumulasi waktu dan persentase untuk setiap zona HR dari titik koordinat
  static HeartRateZoneDistribution calculateDistribution(
    List<CoordinatePoint> points,
    int maxHr,
  ) {
    final seconds = <HeartRateZoneType, int>{
      HeartRateZoneType.zone1: 0,
      HeartRateZoneType.zone2: 0,
      HeartRateZoneType.zone3: 0,
      HeartRateZoneType.zone4: 0,
      HeartRateZoneType.zone5: 0,
    };

    if (points.length < 2) {
      return HeartRateZoneDistribution(
        secondsPerZone: seconds,
        percentPerZone: {for (final z in HeartRateZoneType.values) z: 0.0},
        totalSecondsWithHr: 0,
        dominantZone: HeartRateZoneType.zone2,
      );
    }

    int totalSecs = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final hr = p1.heartRate ?? p2.heartRate;
      if (hr == null || hr <= 0) continue;

      final diffMs = p2.timestamp - p1.timestamp;
      if (diffMs <= 0 || diffMs > 30000) continue; // Abaikan jeda abnormal > 30s
      final dt = (diffMs / 1000).round();
      if (dt <= 0) continue;

      totalSecs += dt;
      final zoneInfo = getZoneForBpm(hr, maxHr);
      seconds[zoneInfo.zone] = (seconds[zoneInfo.zone] ?? 0) + dt;
    }

    final percents = <HeartRateZoneType, double>{};
    HeartRateZoneType dominant = HeartRateZoneType.zone2;
    int maxSec = -1;

    for (final z in HeartRateZoneType.values) {
      final sec = seconds[z] ?? 0;
      percents[z] = totalSecs > 0 ? (sec / totalSecs) * 100.0 : 0.0;
      if (sec > maxSec) {
        maxSec = sec;
        dominant = z;
      }
    }

    return HeartRateZoneDistribution(
      secondsPerZone: seconds,
      percentPerZone: percents,
      totalSecondsWithHr: totalSecs,
      dominantZone: dominant,
    );
  }

  // --- PARSING PROTOKOL BLUETOOTH SIG GATT (0x2A37) ---

  /// Parsing payload byte Heart Rate Measurement standar Bluetooth SIG
  static int parseHeartRateBytes(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    final flags = bytes[0];
    final is16Bit = (flags & 0x01) != 0;

    if (is16Bit) {
      if (bytes.length >= 3) {
        return bytes[1] + (bytes[2] << 8);
      }
    } else {
      if (bytes.length >= 2) {
        return bytes[1];
      }
    }
    return 0;
  }

  // --- KONEKSI DAN PEMINDAIAN BLUETOOTH LOW ENERGY ---

  /// Memulai pemindaian perangkat BLE (Smartwatch, Smart Band, Chest Strap)
  /// Mengembalikan pesan kesalahan jika Bluetooth tidak aktif/gagal, atau null jika berhasil
  Future<String?> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        return 'Ponsel ini tidak mendukung Bluetooth Low Energy (BLE).';
      }

      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
        final stateRecheck = await FlutterBluePlus.adapterState.first;
        if (stateRecheck != BluetoothAdapterState.on) {
          return 'Bluetooth HP belum aktif. Silakan nyalakan Bluetooth Anda.';
        }
      }

      if (await FlutterBluePlus.isScanning.first) {
        await FlutterBluePlus.stopScan();
      }

      // Pindai seluruh perangkat BLE tanpa filter ketat agar jam tangan / band sekitar terdeteksi
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );
      return null;
    } catch (e) {
      debugPrint('Error starting BLE scan: $e');
      return 'Gagal memulai pemindaian Bluetooth: $e';
    }
  }

  /// Menghentikan pemindaian BLE
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  /// Mengambil daftar perangkat yang telah di-pairing / di-bond di pengaturan Bluetooth HP
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return [];
      return await FlutterBluePlus.bondedDevices;
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  /// Menghubungkan ke perangkat Bluetooth Low Energy
  Future<({bool success, bool hasHeartRateService, String? errorMessage})> connectToDevice(
    BluetoothDevice device,
  ) async {
    if (_isConnecting) {
      return (success: false, hasHeartRateService: false, errorMessage: 'Sedang menghubungkan ke perangkat...');
    }
    _isConnecting = true;

    // Matikan simulasi jika sedang aktif
    if (_isSimulationMode) {
      toggleSimulation(false);
    }

    try {
      await stopScan();
      await disconnect();

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );

      _connectedDevice = device;
      _connectedDeviceName = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.str;

      // Pantau status koneksi perangkat
      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnected();
        }
      });

      // Cari Service 0x180D dan Karakteristik 0x2A37
      bool foundHr = false;
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid == heartRateServiceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == heartRateMeasurementCharUuid) {
              foundHr = true;
              await characteristic.setNotifyValue(true);
              _hrCharSubscription = characteristic.onValueReceived.listen((value) {
                final bpm = parseHeartRateBytes(value);
                if (bpm > 0) {
                  _currentBpm = bpm;
                  _bpmController.add(bpm);
                }
              });
              break;
            }
          }
        }
      }

      _connectionStateController.add(true);
      _isConnecting = false;
      return (success: true, hasHeartRateService: foundHr, errorMessage: null);
    } catch (e) {
      debugPrint('Error connecting to BLE device: $e');
      _isConnecting = false;
      await disconnect();
      return (success: false, hasHeartRateService: false, errorMessage: e.toString());
    }
  }

  /// Memutuskan koneksi perangkat BLE saat ini
  Future<void> disconnect() async {
    _hrCharSubscription?.cancel();
    _hrCharSubscription = null;

    _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
      _connectedDeviceName = null;
    }

    _currentBpm = null;
    _connectionStateController.add(false);
  }

  void _handleDisconnected() {
    _connectedDevice = null;
    _connectedDeviceName = null;
    _currentBpm = null;
    _connectionStateController.add(false);
  }

  // --- MODE SIMULASI / DEMO HR ---

  /// Mengaktifkan atau menonaktifkan simulasi HR untuk pengujian tanpa sensor fisik
  void toggleSimulation(bool enabled) {
    _isSimulationMode = enabled;
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (enabled) {
      disconnect();
      _currentBpm = 138;
      _connectionStateController.add(true);

      final random = Random();
      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isSimulationMode) {
          timer.cancel();
          return;
        }
        // Variasi detak jantung halus antara 130 - 165 BPM
        final delta = random.nextInt(5) - 2;
        int nextBpm = (_currentBpm ?? 138) + delta;
        if (nextBpm < 125) nextBpm = 125;
        if (nextBpm > 175) nextBpm = 175;
        _currentBpm = nextBpm;
        _bpmController.add(nextBpm);
      });
    } else {
      _currentBpm = null;
      _connectionStateController.add(false);
    }
  }

  void dispose() {
    _simulationTimer?.cancel();
    _hrCharSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _bpmController.close();
    _connectionStateController.close();
  }
}
