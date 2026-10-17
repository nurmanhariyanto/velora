import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/sports_type.dart';
import 'package:velora/models/tracking_status.dart';
import 'package:velora/widgets/control_buttons.dart';

void main() {
  group('ControlButtons & Session Completion Flow', () {
    testWidgets('ControlButtons menampilkan MULAI LATIHAN saat status idle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlButtons(
              status: TrackingStatus.idle,
              sportsType: SportsType.ride,
              onStart: () {},
              onPause: () {},
              onResume: () {},
              onStop: () {},
              onSportsTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('MULAI LATIHAN'), findsOneWidget);
      expect(find.text('LANJUT'), findsNothing);
      expect(find.text('SELESAI'), findsNothing);
    });

    testWidgets('ControlButtons tetap menampilkan MULAI LATIHAN saat status completed (bukan LANJUT)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlButtons(
              status: TrackingStatus.completed,
              sportsType: SportsType.run,
              onStart: () {},
              onPause: () {},
              onResume: () {},
              onStop: () {},
              onSportsTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('MULAI LATIHAN'), findsOneWidget);
      expect(find.text('LANJUT'), findsNothing);
      expect(find.text('SELESAI'), findsNothing);
    });

    testWidgets('ControlButtons menampilkan JEDA & SELESAI saat aktif tracking',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlButtons(
              status: TrackingStatus.tracking,
              sportsType: SportsType.run,
              onStart: () {},
              onPause: () {},
              onResume: () {},
              onStop: () {},
              onSportsTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('JEDA'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);
      expect(find.text('MULAI LATIHAN'), findsNothing);
    });

    testWidgets('ControlButtons menampilkan LANJUT & SELESAI hanya saat di-pause',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlButtons(
              status: TrackingStatus.pausedManual,
              sportsType: SportsType.run,
              onStart: () {},
              onPause: () {},
              onResume: () {},
              onStop: () {},
              onSportsTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('LANJUT'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);
      expect(find.text('MULAI LATIHAN'), findsNothing);
    });
  });
}
