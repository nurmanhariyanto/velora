/// Status siklus hidup pelacakan Velora
enum TrackingStatus {
  idle,
  tracking,
  pausedManual,
  pausedAuto,
  completed;

  bool get isActive => this == TrackingStatus.tracking;
  bool get isPaused => this == TrackingStatus.pausedManual || this == TrackingStatus.pausedAuto;
  bool get isAutoPaused => this == TrackingStatus.pausedAuto;
  bool get isRecording => isActive || isPaused;

  String get displayLabel {
    switch (this) {
      case TrackingStatus.idle:
        return 'SIAP';
      case TrackingStatus.tracking:
        return 'MEREKAM';
      case TrackingStatus.pausedManual:
        return 'DIHENTIKAN';
      case TrackingStatus.pausedAuto:
        return 'AUTO-PAUSE';
      case TrackingStatus.completed:
        return 'SELESAI';
    }
  }
}
