import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Layanan untuk menjaga layar perangkat tetap aktif (Wakelock)
/// selama proses komputasi intensif seperti rendering video MP4
/// agar sistem operasi tidak mematikan layar atau menangguhkan raster grafis.
class WakelockService {
  static const _channel = MethodChannel('online.nurmancloud.velora/wakelock');
  static bool _isEnabled = false;

  /// Status apakah proteksi layar aktif sedang berjalan
  static bool get isEnabled => _isEnabled;

  /// Mengaktifkan pencegahan layar mati (Keep Screen On & CPU WakeLock)
  static Future<bool> enable() async {
    try {
      final res = await _channel.invokeMethod<bool>('keepScreenOn', {'enable': true});
      _isEnabled = res ?? true;
      debugPrint('WakelockService: Layar dijaga tetap aktif selama proses render berlangsung.');
      return _isEnabled;
    } catch (e) {
      debugPrint('WakelockService: Gagal mengaktifkan wakelock: $e');
      return false;
    }
  }

  /// Menonaktifkan pencegahan layar mati dan mengembalikan timeout layar default perangkat
  static Future<bool> disable() async {
    try {
      final res = await _channel.invokeMethod<bool>('keepScreenOn', {'enable': false});
      _isEnabled = false;
      debugPrint('WakelockService: Proteksi layar aktif dilepas.');
      return res ?? true;
    } catch (e) {
      debugPrint('WakelockService: Gagal melepas wakelock: $e');
      return false;
    }
  }
}
