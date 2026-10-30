import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders all smartwatch and sensor settings tiles', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Check title
    expect(find.text('Pengaturan & Sensor'), findsOneWidget);

    // Check smartwatch & sensor section
    expect(find.text('PERANGKAT & SENSOR SMARTWATCH'), findsOneWidget);
    expect(find.text('Impor Aktivitas Jam Tangan (GPX)'), findsOneWidget);
    expect(find.text('Sensor Detak Jantung (BLE HRM)'), findsOneWidget);
    expect(find.text('Zona Detak Jantung Atlet (Z1 - Z5)'), findsOneWidget);
    expect(find.text('Panduan Gowes & Lari Tanpa Bawa HP'), findsOneWidget);

    // Check profile and offline sections
    expect(find.text('PROFIL PENGGUNA'), findsOneWidget);
    expect(find.text('PETA & CACHE OFFLINE'), findsOneWidget);
    expect(find.text('TENTANG & PEMBARUAN'), findsOneWidget);
  });

  testWidgets('Tapping Smartwatch Guide opens detailed dialog with Haylou instructions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the guide tile
    await tester.tap(find.text('Panduan Gowes & Lari Tanpa Bawa HP'));
    await tester.pumpAndSettle();

    // Verify dialog contents
    expect(find.text('Panduan Smartwatch Tanpa HP'), findsOneWidget);
    expect(find.text('Haylou Solar Neo 2 & Haylou Series'), findsOneWidget);
    expect(find.textContaining('Haylou Fun'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Smartwatch Tanpa HP'), findsNothing);
  });

  testWidgets('Tapping Heart Rate Zones opens calculation and preview dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the zones tile
    await tester.tap(find.text('Zona Detak Jantung Atlet (Z1 - Z5)'));
    await tester.pumpAndSettle();

    // Verify dialog contents
    expect(find.text('Zona Detak Jantung'), findsOneWidget);
    expect(find.text('Distribusi 5 Zona:'), findsOneWidget);
    expect(find.text('Z1'), findsOneWidget);
    expect(find.text('Z2'), findsOneWidget);
    expect(find.text('Z5'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Zona Detak Jantung'), findsNothing);
  });
}
