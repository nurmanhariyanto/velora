# Velora: Run & Ride 🏃‍♂️🚴‍♂️

**Velora** adalah aplikasi pelacak kebugaran dan rute GPS mandiri (*standalone*) berbasis Flutter yang beroperasi **100% secara lokal (*offline-first*)** tanpa memerlukan server *backend*, API eksternal berbayar, atau login akun. 

Dibangun berdasarkan spesifikasi [fitur_velora.md](fitur_velora.md) dan rencana kerja tim agen di [task_agent_velora.md](task_agent_velora.md).

---

## 🌟 Fitur Utama

1. **Pelacakan Aktivitas Lintas Olahraga (Run & Ride):**
   - Melacak rute menggunakan GPS secara *real-time* untuk aktivitas Lari dan Bersepeda.
   - Metrik otomatis disesuaikan: **Pace (min/km)** untuk lari, dan **Kecepatan (km/jam)** untuk sepeda.
2. **Peta Interaktif OpenStreetMap (OSM):**
   - Menampilkan posisi langsung pengguna di atas peta OSM & CartoDB Dark.
   - Menggambar rute perjalanan menggunakan garis *polyline* neon cyan (`#00E5FF`) dengan efek *glow*.
   - Kamera peta pintar (*auto-center* dan *auto-follow*).
3. **Pelacakan Latar Belakang (Foreground Service):**
   - GPS tetap merekam saat layar ponsel mati atau aplikasi di latar belakang berkat integrasi Android Foreground Service.
   - Menampilkan notifikasi persisten berisi durasi dan jarak tempuh *real-time*.
4. **Dashboard Statistik Cerdas:**
   - Menampilkan Durasi Bersih (tanpa waktu henti), Jarak Tempuh (km), Kecepatan Saat Ini, Pace Rata-rata, Kecepatan Maksimal, dan Elevasi Positif (+meter).
5. **Auto-Pause Adaptif:**
   - Perekaman waktu dan jarak otomatis berhenti sementara (*pause*) saat pengguna berhenti (kecepatan < 2 km/jam selama $\ge 3$ detik).
   - Otomatis melanjutkan (*resume*) saat pergerakan kembali terdeteksi ($\ge 2.5\text{ km/jam}$ atau perpindahan $> 5\text{ meter}$).
6. **Riwayat Aktivitas & Database Lokal (SQLite):**
   - Seluruh sesi latihan dan koordinat rute tersimpan aman di database SQLite lokal (`velora_local.db`).
   - Algoritma kompresi rute **Douglas-Peucker** diterapkan untuk mencegah *lag* memori pada rute berjarak jauh.
   - Layar rincian aktivitas dengan fitur *route replay* dan ringkasan total pencapaian.
7. **Social Media Sharing (Ekspor Gambar 9:16):**
   - Mengambil foto dari Kamera atau Galeri.
   - Komposisi *watermark* otomatis via `RepaintBoundary`: logo Velora, teks statistik tebal dengan efek *drop shadow*, dan sketsa *mini polyline* rute oranye.
   - Bagikan langsung ke Instagram Story atau status WhatsApp via `SharePlus`.

---

## 🏗️ Struktur Arsitektur & Modul Tim Agen

```
VELORA/
├── .github/workflows/          # [Agent DevOps] CI/CD pipeline GitHub Actions
│   └── build.yml
├── docs/                       # Dokumentasi Spesifikasi & Panduan
│   ├── PRD_VELORA.md           # [Agent Analisis] PRD, Haversine, Auto-pause, Skema DB
│   ├── DESIGN_SYSTEM_VELORA.md # [Agent Desain] Palet warna, tipografi, template share
│   └── RELEASE_GUIDE.md        # [Agent DevOps] Panduan signing keystore & build release
├── lib/                        # [Agent Coding] Kode Sumber Aplikasi
│   ├── algorithms/             # Logika Matematika & Algoritma
│   │   ├── douglas_peucker.dart# Kompresi rute GPS (Ramer-Douglas-Peucker)
│   │   ├── haversine.dart      # Formula Haversine & kalkulasi bearing
│   │   └── pace_calculator.dart# Perhitungan Pace, Speed, & formatters
│   ├── constants/              # Konfigurasi Tema & Warna
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── database/               # Penyimpanan SQLite Lokal
│   │   ├── activity_repository.dart
│   │   └── database_helper.dart
│   ├── models/                 # Model Data Domain
│   │   ├── activity_session.dart
│   │   ├── coordinate_point.dart
│   │   ├── sports_type.dart
│   │   └── tracking_status.dart
│   ├── providers/              # Manajemen State (Provider)
│   │   ├── history_provider.dart
│   │   └── tracking_provider.dart
│   ├── screens/                # Antarmuka Pengguna (UI)
│   │   ├── activity_detail_screen.dart
│   │   ├── history_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── share_preview_screen.dart
│   │   └── tracking_screen.dart
│   ├── services/               # Layanan Sistem & Perangkat Keras
│   │   ├── auto_pause_detector.dart
│   │   ├── foreground_service_handler.dart
│   │   ├── location_service.dart
│   │   └── social_share_service.dart
│   ├── widgets/                # Komponen Visual Kustom
│   │   ├── auto_pause_banner.dart
│   │   ├── control_buttons.dart
│   │   ├── live_map_view.dart
│   │   ├── metric_card.dart
│   │   ├── mini_route_painter.dart
│   │   ├── social_share_card.dart
│   │   └── velora_logo.dart
│   └── main.dart
└── test/                       # [Agent Pengujian] Pengujian Unit & Widget
    ├── algorithms_test.dart    # Uji akurasi Haversine & Douglas-Peucker
    ├── auto_pause_test.dart    # Uji pemicu Auto-Pause & Resume
    ├── models_and_db_test.dart # Uji serialisasi SQLite
    └── widget_test.dart        # Uji rendering UI
```

---

## 🚀 Panduan Menjalankan Aplikasi

### Persyaratan:
- Flutter SDK $\ge 3.24$
- Android SDK (API 24 s/d 35)
- Java JDK 17

### Langkah Instalasi:
```bash
# 1. Unduh pustaka ketergantungan
flutter pub get

# 2. Jalankan pengujian unit & widget
flutter test

# 3. Jalankan aplikasi pada perangkat Android / Linux Desktop
flutter run
```

### Membangun File APK Rilis:
```bash
flutter build apk --release --split-per-abi
```
File APK siap instalasi akan dihasilkan di direktori `build/app/outputs/flutter-apk/`.

---

## 📄 Lisensi
Hak Cipta © 2026 **Velora Team** (`online.nurmancloud.velora`). Semua hak dilindungi undang-undang.
