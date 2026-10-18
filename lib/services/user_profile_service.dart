import 'package:shared_preferences/shared_preferences.dart';

/// Layar layanan lokal untuk membaca dan menyimpan profil atlet secara persisten
class UserProfileService {
  static const String _keyAthleteName = 'velora_athlete_name';
  static const String defaultAthleteName = 'Velora Athlete';

  /// Mendapatkan nama atlet tersimpan (atau 'Velora Athlete' jika belum disetel)
  static Future<String> getAthleteName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyAthleteName)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    } catch (_) {}
    return defaultAthleteName;
  }

  /// Menyimpan nama atlet baru ke penyimpanan lokal
  static Future<bool> setAthleteName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        return await prefs.setString(_keyAthleteName, defaultAthleteName);
      }
      return await prefs.setString(_keyAthleteName, trimmed);
    } catch (_) {
      return false;
    }
  }
}
