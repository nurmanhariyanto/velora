/// Jenis olahraga yang didukung Velora
enum SportsType {
  run,
  ride,
  hike;

  String get displayName {
    switch (this) {
      case SportsType.run:
        return 'Lari (Run)';
      case SportsType.ride:
        return 'Sepeda (Ride)';
      case SportsType.hike:
        return 'Mendaki (Hike)';
    }
  }

  String get shortName {
    switch (this) {
      case SportsType.run:
        return 'RUN';
      case SportsType.ride:
        return 'RIDE';
      case SportsType.hike:
        return 'HIKE';
    }
  }

  String get primaryMetricLabel {
    switch (this) {
      case SportsType.run:
        return 'AVG PACE';
      case SportsType.ride:
        return 'AVG SPEED';
      case SportsType.hike:
        return 'AVG PACE';
    }
  }

  String get primaryMetricUnit {
    switch (this) {
      case SportsType.run:
        return '/km';
      case SportsType.ride:
        return 'km/h';
      case SportsType.hike:
        return '/km';
    }
  }

  static SportsType fromString(String value) {
    final v = value.toLowerCase();
    if (v == 'ride') {
      return SportsType.ride;
    } else if (v == 'hike' || v == 'hiking' || v == 'mendaki') {
      return SportsType.hike;
    }
    return SportsType.run;
  }
}
