/// Jenis olahraga yang didukung Velora
enum SportsType {
  run,
  ride;

  String get displayName {
    switch (this) {
      case SportsType.run:
        return 'Lari (Run)';
      case SportsType.ride:
        return 'Sepeda (Ride)';
    }
  }

  String get shortName {
    switch (this) {
      case SportsType.run:
        return 'RUN';
      case SportsType.ride:
        return 'RIDE';
    }
  }

  String get primaryMetricLabel {
    switch (this) {
      case SportsType.run:
        return 'AVG PACE';
      case SportsType.ride:
        return 'AVG SPEED';
    }
  }

  String get primaryMetricUnit {
    switch (this) {
      case SportsType.run:
        return '/km';
      case SportsType.ride:
        return 'km/h';
    }
  }

  static SportsType fromString(String value) {
    if (value.toLowerCase() == 'ride') {
      return SportsType.ride;
    }
    return SportsType.run;
  }
}
