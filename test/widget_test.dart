import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/main.dart';
import 'package:velora/widgets/metric_card.dart';
import 'package:velora/widgets/velora_logo.dart';

void main() {
  testWidgets('VeloraLogo merender logo teks dan chevron', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VeloraLogo(size: 40, showTagline: true),
        ),
      ),
    );

    expect(find.text('VELORA'), findsOneWidget);
    expect(find.text('RUN & RIDE'), findsOneWidget);
  });

  testWidgets('MetricCard menampilkan label dan nilai dengan tepat', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'JARAK',
            value: '5.24',
            unit: 'km',
          ),
        ),
      ),
    );

    expect(find.text('JARAK'), findsOneWidget);
    expect(find.text('5.24'), findsOneWidget);
    expect(find.text('km'), findsOneWidget);
  });

  testWidgets('VeloraApp dapat dimuat dan merender navigasi utama', (WidgetTester tester) async {
    await tester.pumpWidget(const VeloraApp());
    await tester.pump();

    // Pastikan bar navigasi bawah memiliki tab Pelacakan dan Riwayat
    expect(find.text('Pelacakan'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
