/// Informasi pembaruan aplikasi dari rilis GitHub
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String releaseHtmlUrl;
  final String? publishedAt;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releaseHtmlUrl,
    this.publishedAt,
  });

  /// Bandingkan dua string versi semantik (cth: "1.0.1" > "1.0.0")
  static bool isNewerVersion(String current, String latest) {
    final cleanCurrent = current.split('+').first.split('-').first.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanLatest = latest.split('+').first.split('-').first.replaceAll(RegExp(r'[^0-9.]'), '');

    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = currentParts.length > latestParts.length ? currentParts.length : latestParts.length;

    for (int i = 0; i < maxLen; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;

      if (l > c) return true;
      if (l < c) return false;
    }

    return false;
  }
}
