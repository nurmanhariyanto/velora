import 'package:flutter/foundation.dart';
import '../database/activity_repository.dart';
import '../models/activity_session.dart';
import '../models/best_effort.dart';
import '../models/lifetime_stats.dart';
import '../models/sports_type.dart';
import '../models/trophy_badge.dart';
import '../services/achievement_service.dart';

/// Provider pengelola data All-Time Lifetime Stats, Best Efforts, dan Trophy Case (Lencana)
class AchievementProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  AchievementProvider({ActivityRepository? repository})
      : _repository = repository ?? ActivityRepository();

  SportsType _selectedSports = SportsType.ride;
  LifetimeStats? _lifetimeStats;
  List<BestEffort> _bestEfforts = [];
  List<TrophyBadge> _allBadges = [];
  List<ActivitySession> _allActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  SportsType get selectedSports => _selectedSports;
  LifetimeStats? get lifetimeStats => _lifetimeStats;
  List<BestEffort> get bestEfforts => _bestEfforts;
  List<TrophyBadge> get allBadges => _allBadges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Daftar lencana yang sudah berhasil dibuka
  List<TrophyBadge> get unlockedBadges =>
      _allBadges.where((b) => b.isUnlocked).toList();

  /// Daftar lencana yang relevan dengan olahraga terpilih (atau universal)
  List<TrophyBadge> get currentSportBadges => _allBadges
      .where((b) => b.sportsType == null || b.sportsType == _selectedSports)
      .toList();

  int get unlockedCount => _allBadges.where((b) => b.isUnlocked).length;
  int get totalBadgesCount => _allBadges.length;

  /// Mengubah pilihan olahraga (Sepeda / Lari)
  void setSportsType(SportsType type) {
    if (_selectedSports == type) return;
    _selectedSports = type;
    _recalculateForSelectedSport();
    notifyListeners();
  }

  /// Memuat ulang seluruh capaian dan statistik dari SQLite
  Future<void> loadAchievements({SportsType? sportsType}) async {
    if (sportsType != null) {
      _selectedSports = sportsType;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allActivities = await _repository.getAllActivities();
      _allBadges = AchievementService.evaluateBadges(_allActivities);
      _recalculateForSelectedSport();
    } catch (e) {
      _errorMessage = 'Gagal memuat statistik pencapaian: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _recalculateForSelectedSport() {
    _lifetimeStats = AchievementService.calculateLifetimeStats(
      _selectedSports,
      _allActivities,
    );
    _bestEfforts = AchievementService.extractBestEfforts(
      _selectedSports,
      _allActivities,
    );
  }
}
