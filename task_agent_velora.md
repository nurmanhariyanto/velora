# Rencana Pembagian Kerja: Proyek Aplikasi Velora (Mode Lokal)

Dokumen ini merinci pembagian tugas dan status tanggung jawab untuk masing-masing agen/peran dalam pengembangan **Velora: Run & Ride**, aplikasi pelacak kebugaran berbasis GPS (Android/Flutter) yang berjalan secara lokal tanpa server.

---

## 1. Agent Analisis (Systems & Requirements Analyst)

**Fokus:** Mendefinisikan spesifikasi teknis, algoritma, dan struktur data aplikasi Velora.

**Tugas Utama & Realisasi:**

* [x] **Definisi Fitur:** Menulis *Product Requirement Document* (PRD) yang mencakup batasan aplikasi (mode lokal), spesifikasi peta OpenStreetMap (OSM), dan alur berbagi ke media sosial di `docs/PRD_VELORA.md`.
* [x] **Desain Struktur Database (SQLite):** Merancang skema tabel relasional lokal:
  * Tabel `aktivitas` (id, jenis_olahraga, waktu_mulai, waktu_selesai, total_durasi_detik, total_jarak_meter, elevasi_positif, dll).
  * Tabel `titik_koordinat` (id, aktivitas_id, latitude, longitude, elevasi, timestamp, kecepatan, is_auto_paused).
* [x] **Pemodelan Algoritma:**
  * Menentukan parameter formula *Haversine* dalam perhitungan jarak di `lib/algorithms/haversine.dart`.
  * Menetapkan *threshold* kecepatan untuk pemicu fitur **Auto-Pause** (< 2 km/jam selama $\ge 3$ detik) di `lib/services/auto_pause_detector.dart`.
  * Menentukan algoritma kompresi rute **Douglas-Peucker** di `lib/algorithms/douglas_peucker.dart`.
  * Merumuskan logika perbandingan SemVer untuk pembaruan rilis otomatis di `lib/models/app_update_info.dart`.

---

## 2. Agent Desain (UI/UX Designer)

**Fokus:** Merancang antarmuka pengguna, pengalaman pengguna, identitas visual (Branding), dan aset aplikasi.

**Tugas Utama & Realisasi:**

* [x] **Identitas Visual (Branding):** Mengimplementasikan logo **Velora** (ikon panah ganda 'V' berwarna oranye khas dengan gradasi api) di `lib/widgets/velora_logo.dart`.
* [x] **Sistem Desain (Design System):** Menyusun panduan warna, tipografi, dan komponen visual di `docs/DESIGN_SYSTEM_VELORA.md`.
* [x] **Desain Peta (Map Styling):** Menentukan gaya visual peta OSM dasar (tema standar & CartoDB dark) dan gaya *Polyline* neon cyan (`#00E5FF`) dengan efek *glow* di `lib/widgets/live_map_view.dart`.
* [x] **Desain Panel Navigasi:** Merancang panel *bottom-sheet* ergonomis untuk statistik *real-time* (Kecepatan, Pace, Jarak, Waktu, Elevasi) dan desain tombol besar (Play/Pause/Resume/Stop) di `lib/widgets/control_buttons.dart`.
* [x] **Desain Template Berbagi (Social Share 9:16):** Merancang tata letak *overlay* gambar dengan rasio 9:16 untuk IG Story / WA di `lib/widgets/social_share_card.dart` dan `lib/widgets/mini_route_painter.dart`.
* [x] **Desain Dialog Update:** Antarmuka notifikasi versi baru modern dengan badge versi dan catatan rilis di `lib/widgets/update_dialog.dart`.

---

## 3. Agent Coding (Mobile Developer - Flutter)

**Fokus:** Mengimplementasikan kode, logika, dan menyatukan seluruh komponen aplikasi Velora.

**Tugas Utama & Realisasi:**

* [x] **Setup Lingkungan & Pustaka:** Menginisialisasi proyek Flutter dengan package name `online.nurmancloud.velora`. Memasang pustaka utama (`flutter_map`, `latlong2`, `geolocator`, `sqflite`, `share_plus`, `image_picker`, `flutter_foreground_task`, `package_info_plus`, `url_launcher`, `http`).
* [x] **Integrasi Peta & OSM:** Menampilkan *TileLayer* OpenStreetMap & CartoDB dengan penanda posisi live dan *PolylineLayer* yang diperbarui secara dinamis di `lib/widgets/live_map_view.dart`.
* [x] **Layanan Latar Belakang (Foreground Service):** Menggunakan `flutter_foreground_task` agar GPS tetap merekam saat layar ponsel mati atau aplikasi di-*minimize*, serta notifikasi persisten di `lib/services/foreground_service_handler.dart`.
* [x] **Logika Pelacakan (Tracking Logic):** Mengimplementasikan filter GPS, perhitungan jarak *real-time*, akumulasi elevasi, stopwatch waktu aktif, dan sistem *Auto-Pause* di `lib/providers/tracking_provider.dart`.
* [x] **Fitur Ekspor Gambar (RepaintBoundary):** Membangun komponen penangkapan snapshot PNG beresolusi tinggi dan berbagi ke media sosial di `lib/services/social_share_service.dart`.
* [x] **Fitur Auto-Update:** Mengimplementasikan pengecekan otomatis dan manual ke GitHub Releases API di `lib/services/update_service.dart`.

---

## 4. Agent Pengujian (QA & Testing)

**Fokus:** Memastikan aplikasi berjalan bebas *bug*, akurat, dan tidak menguras baterai ponsel.

**Tugas Utama & Realisasi:**

* [x] **Pengujian Fungsional & Unit:** 25 pengujian unit dan widget otomatis (100% lolos di direktori `test/`):
  * `test/algorithms_test.dart`: Haversine, Douglas-Peucker, PaceCalculator.
  * `test/auto_pause_test.dart`: Trigger Auto-Pause dan Auto-Resume.
  * `test/models_and_db_test.dart`: Serialisasi dan mapping SQLite.
  * `test/update_service_test.dart`: Logika perbandingan versi SemVer.
  * `test/widget_test.dart`: Rendering widget UI utama.
* [x] **Linter & Code Health:** Menjalankan `flutter analyze` dengan hasil bersih (0 *errors*, 0 *warnings*).

---

## 5. Agent DevOps & Rilis (Release Manager)

**Fokus:** Otomatisasi proses *build*, manajemen versi, dan distribusi aplikasi.

**Tugas Utama & Realisasi:**

* [x] **Inisialisasi Repositori Git & GitHub:** Membuat repositori di `https://github.com/nurmanhariyanto/velora` dan melakukan push commit `main`.
* [x] **CI/CD Pipeline:** Menyediakan konfigurasi GitHub Actions di `ci/github-actions-build.yml`.
* [x] **Konfigurasi Android & Izin:** Mengatur `AndroidManifest.xml` (Lokasi, Background, Kamera, Foreground Service Type) dan `build.gradle.kts` (minSdk 24, targetSdk 35, Java 17).
* [x] **Optimasi ProGuard/R8:** Menerapkan aturan kompilasi rilis di `android/app/proguard-rules.pro`.
* [x] **Rilis Perdana GitHub (v1.0.0):** Kompilasi file APK rilis dan publikasi rilis di GitHub Releases.
