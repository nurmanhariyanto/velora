import 'package:flutter/foundation.dart';
import '../database/activity_repository.dart';
import '../models/activity_session.dart';

/// Provider pengelola daftar riwayat aktivitas dan statistik agregat
class HistoryProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  HistoryProvider({ActivityRepository? repository})
      : _repository = repository ?? ActivityRepository();

  List<ActivitySession> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  double _totalDistanceMeters = 0.0;
  int _totalDurationSeconds = 0;
  int _totalWorkouts = 0;

  List<ActivitySession> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalDistanceKm => _totalDistanceMeters / 1000.0;
  int get totalDurationSeconds => _totalDurationSeconds;
  int get totalWorkouts => _totalWorkouts;

  /// Memuat riwayat aktivitas dari SQLite
  Future<void> loadActivities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activities = await _repository.getAllActivities();
      final stats = await _repository.getAggregatedStats();
      _totalDistanceMeters = stats.totalDistanceMeters;
      _totalDurationSeconds = stats.totalDurationSeconds;
      _totalWorkouts = stats.totalWorkouts;
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengambil detail lengkap aktivitas beserta semua koordinat
  Future<ActivitySession?> getActivityDetails(String id) async {
    try {
      return await _repository.getActivityById(id);
    } catch (e) {
      debugPrint('Error getting activity details: $e');
      return null;
    }
  }

  /// Menghapus aktivitas dari SQLite
  Future<bool> deleteActivity(String id) async {
    try {
      final rows = await _repository.deleteActivity(id);
      if (rows > 0) {
        _activities.removeWhere((item) => item.id == id);
        final stats = await _repository.getAggregatedStats();
        _totalDistanceMeters = stats.totalDistanceMeters;
        _totalDurationSeconds = stats.totalDurationSeconds;
        _totalWorkouts = stats.totalWorkouts;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return false;
    }
  }
}
