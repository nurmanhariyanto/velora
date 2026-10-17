import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Top-level callback entry point untuk TaskHandler Foreground Service
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(VeloraTaskHandler());
}

/// TaskHandler yang menangani event tombol notifikasi latar belakang
class VeloraTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    // Kirim pesan aksi tombol (btn_pause / btn_stop) ke main isolate UI
    FlutterForegroundTask.sendDataToMain(id);
  }
}

/// Pengendali Layanan Latar Belakang (Foreground Service)
/// Memastikan pelacakan GPS tetap aktif saat ponsel terkunci / aplikasi di-minimize
/// serta menyediakan tombol pintasan notifikasi (JEDA, LANJUT, SELESAI)
class ForegroundServiceHandler {
  static bool _isInitialized = false;

  /// Inisialisasi konfigurasi notifikasi Android & port komunikasi
  static Future<void> initService() async {
    if (_isInitialized) return;

    FlutterForegroundTask.initCommunicationPort();

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

  /// Mendaftarkan listener untuk menangkap aksi penekanan tombol notifikasi dari latar belakang
  static void listenToButtonActions({
    required Function(String actionId) onAction,
  }) {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is String) {
        onAction(data);
      } else if (data is Map && data.containsKey('action')) {
        onAction(data['action'].toString());
      }
    });
  }

  /// Memulai layanan latar belakang dengan tombol pintasan kontrol
  static Future<void> start({
    required String title,
    required String text,
    bool isPaused = false,
  }) async {
    try {
      await initService();

      if (await FlutterForegroundTask.isRunningService) {
        await update(title: title, text: text, isPaused: isPaused);
        return;
      }

      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.location],
        notificationTitle: title,
        notificationText: text,
        callback: startCallback,
        notificationButtons: [
          NotificationButton(
            id: 'btn_pause',
            text: isPaused ? 'LANJUT' : 'JEDA',
          ),
          const NotificationButton(
            id: 'btn_stop',
            text: 'SELESAI',
          ),
        ],
      );
    } catch (_) {
      // Fallback jika platform bukan android/ios atau izin belum siap
    }
  }

  /// Memperbarui teks notifikasi dan label tombol pintasan (JEDA / LANJUT)
  static Future<void> update({
    required String title,
    required String text,
    bool isPaused = false,
  }) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
          notificationButtons: [
            NotificationButton(
              id: 'btn_pause',
              text: isPaused ? 'LANJUT' : 'JEDA',
            ),
            const NotificationButton(
              id: 'btn_stop',
              text: 'SELESAI',
            ),
          ],
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
