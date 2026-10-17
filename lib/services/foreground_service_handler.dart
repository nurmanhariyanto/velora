import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Pengendali Layanan Latar Belakang (Foreground Service)
/// Memastikan pelacakan GPS tetap aktif saat ponsel terkunci / aplikasi di-minimize
class ForegroundServiceHandler {
  static bool _isInitialized = false;

  /// Inisialisasi konfigurasi notifikasi Android & iOS
  static Future<void> initService() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'velora_tracking_channel',
        channelName: 'Velora Active Tracking',
        channelDescription:
            'Menampilkan status pelacakan durasi dan jarak rute Velora.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );

    _isInitialized = true;
  }

  /// Memulai layanan latar belakang dengan judul dan teks awal
  static Future<void> start({
    required String title,
    required String text,
  }) async {
    try {
      await initService();

      if (await FlutterForegroundTask.isRunningService) {
        await update(title: title, text: text);
        return;
      }

      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.location],
        notificationTitle: title,
        notificationText: text,
      );
    } catch (_) {
      // Fallback jika platform bukan android/ios atau izin belum siap
    }
  }

  /// Memperbarui teks notifikasi (cth: "4.82 km | 00:24:12")
  static Future<void> update({
    required String title,
    required String text,
  }) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      }
    } catch (_) {}
  }

  /// Menghentikan layanan latar belakang
  static Future<void> stop() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }
}
