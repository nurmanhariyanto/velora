/// Titik koordinat GPS individual dalam lintasan pelacakan
class CoordinatePoint {
  final int? id;
  final String activityId;
  final double latitude;
  final double longitude;
  final double elevation;
  final double speed; // m/s
  final double accuracy; // meter
  final int timestamp; // epoch ms
  final bool isAutoPaused;

  const CoordinatePoint({
    this.id,
    required this.activityId,
    required this.latitude,
    required this.longitude,
    this.elevation = 0.0,
    this.speed = 0.0,
    this.accuracy = 0.0,
    required this.timestamp,
    this.isAutoPaused = false,
  });

  /// Konversi kecepatan dari m/s ke km/jam
  double get speedKmh => speed * 3.6;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'aktivitas_id': activityId,
      'latitude': latitude,
      'longitude': longitude,
      'elevasi': elevation,
      'kecepatan': speed,
      'akurasi': accuracy,
      'timestamp': timestamp,
      'is_auto_paused': isAutoPaused ? 1 : 0,
    };
  }

  factory CoordinatePoint.fromMap(Map<String, dynamic> map) {
    return CoordinatePoint(
      id: map['id'] as int?,
      activityId: map['aktivitas_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      elevation: (map['elevasi'] as num?)?.toDouble() ?? 0.0,
      speed: (map['kecepatan'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['akurasi'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as int,
      isAutoPaused: (map['is_auto_paused'] as int?) == 1,
    );
  }
}
