# Proguard rules for Velora (online.nurmancloud.velora)
# Maintain Flutter wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Foreground Task Service
-keep class com.pravera.flutter_foreground_task.** { *; }

# SQLite Native
-keep class com.tekartik.sqflite.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
