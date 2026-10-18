import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sports_type.dart';

/// Model medali atau lencana prestasi (Digital Trophy / Badge)
class TrophyBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final SportsType? sportsType;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final double currentProgress;
  final double targetValue;
  final String unit;

  const TrophyBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.sportsType,
    required this.isUnlocked,
    this.unlockedDate,
    required this.currentProgress,
    required this.targetValue,
    required this.unit,
  });

  /// Rasio progres pencapaian lencana dari 0.0 sampai 1.0
  double get progressFraction {
    if (isUnlocked) return 1.0;
    if (targetValue <= 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  /// String teks progres (cth: "42.5 / 100 km" atau "650 / 1000 m")
  String get formattedProgress {
    if (isUnlocked) {
      return 'Tercapai!';
    }
    if (unit == 'km') {
      return '${currentProgress.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(0)} $unit';
    } else if (unit == 'm') {
      return '${currentProgress.toStringAsFixed(0)} / ${targetValue.toStringAsFixed(0)} $unit';
    } else if (unit == 'km/h') {
      return '${currentProgress.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(0)} $unit';
    }
    return '${currentProgress.toInt()} / ${targetValue.toInt()} $unit';
  }

  /// Format tanggal saat lencana berhasil dibuka
  String? get formattedUnlockedDate {
    if (!isUnlocked || unlockedDate == null) return null;
    return DateFormat('d MMMM yyyy', 'id_ID').format(unlockedDate!);
  }

  TrophyBadge copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    SportsType? sportsType,
    bool? isUnlocked,
    DateTime? unlockedDate,
    double? currentProgress,
    double? targetValue,
    String? unit,
  }) {
    return TrophyBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      sportsType: sportsType ?? this.sportsType,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      currentProgress: currentProgress ?? this.currentProgress,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
    );
  }
}
