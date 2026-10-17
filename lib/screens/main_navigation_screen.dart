import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'history_screen.dart';
import 'tracking_screen.dart';

import '../services/foreground_service_handler.dart';
import '../services/update_service.dart';

/// Navigasi Utama Aplikasi Velora (Pelacakan & Riwayat)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context, silent: true);
      ForegroundServiceHandler.requestNotificationPermission();
    });
  }

  final List<Widget> _screens = const [
    TrackingScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.cardSurface,
          indicatorColor: AppColors.primaryOrange.withAlpha(40),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on_rounded, color: AppColors.primaryOrange),
              label: 'Pelacakan',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_toggle_off_rounded, color: AppColors.primaryOrange),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }
}
