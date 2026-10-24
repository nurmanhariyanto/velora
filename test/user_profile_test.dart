import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/database/activity_repository.dart';
import 'package:velora/providers/achievement_provider.dart';
import 'package:velora/screens/profile_records_screen.dart';
import 'package:velora/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserProfileService.resetCacheForTesting();
  });

  group('UserProfileService Tests', () {
    test('Mengembalikan default "Velora Athlete" jika belum ada nama tersimpan', () async {
      final name = await UserProfileService.getAthleteName();
      expect(name, equals(UserProfileService.defaultAthleteName));
      expect(name, equals('Velora Athlete'));
    });

    test('Menyimpan dan membaca nama kustom atlet', () async {
      final saved = await UserProfileService.setAthleteName('Nurman Rider');
      expect(saved, isTrue);

      final name = await UserProfileService.getAthleteName();
      expect(name, equals('Nurman Rider'));
    });

    test('currentAthleteName mengembalikan nama di memori secara instan', () async {
      expect(UserProfileService.currentAthleteName, equals('Velora Athlete'));
      await UserProfileService.setAthleteName('Speedster');
      expect(UserProfileService.currentAthleteName, equals('Speedster'));
    });

    test('UserProfileService.init melakukan preloading nama dari penyimpanan', () async {
      SharedPreferences.setMockInitialValues({
        'velora_athlete_name': 'Preloaded Rider',
      });
      UserProfileService.resetCacheForTesting();

      await UserProfileService.init();
      expect(UserProfileService.currentAthleteName, equals('Preloaded Rider'));
    });

    test('flushBeforeUpdate mengeksekusi flush multi-tier tanpa exception', () async {
      await UserProfileService.setAthleteName('Master Climber');
      await expectLater(UserProfileService.flushBeforeUpdate(), completes);
    });
  });

  group('ProfileRecordsScreen Athlete Name Editing UI Tests', () {
    testWidgets('Menampilkan nama atlet dan membuka dialog edit nama', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'velora_athlete_name': 'Super Runner',
      });

      final repository = ActivityRepository();
      final achievementProvider = AchievementProvider(repository: repository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: achievementProvider),
          ],
          child: const MaterialApp(
            home: ProfileRecordsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan nama atlet kustom ditampilkan di layar
      expect(find.text('Super Runner'), findsOneWidget);

      // Cari tombol edit ikon pensil
      final editIcon = find.byIcon(Icons.edit_rounded);
      expect(editIcon, findsOneWidget);

      // Ketuk tombol edit untuk memicu dialog
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Verifikasi dialog edit nama profil muncul
      expect(find.text('Edit Nama Profil'), findsOneWidget);
      expect(find.text('Nama Atlet'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Masukkan nama baru ke dalam TextFormField
      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Captain Peloton');
      await tester.pumpAndSettle();

      // Tekan tombol Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verifikasi nama baru segera diperbarui pada profil atlet
      expect(find.text('Captain Peloton'), findsOneWidget);

      // Verifikasi nama baru tersimpan di SharedPreferences
      final savedName = await UserProfileService.getAthleteName();
      expect(savedName, equals('Captain Peloton'));
    });
  });
}
