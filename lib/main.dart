import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/history_provider.dart';
import 'providers/tracking_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/foreground_service_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale bahasa Indonesia untuk formatting tanggal
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Layanan Foreground Service untuk pelacakan latar belakang
  await ForegroundServiceHandler.initService();

  runApp(const VeloraApp());
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'Velora: Run & Ride',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
