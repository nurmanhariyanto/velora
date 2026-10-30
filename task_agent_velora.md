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
  * Merumuskan formulasi matematis `formatCleanPace` ($M:SS\text{ /km}$) dan `formatCleanDuration` ($XX\text{m }YY\text{s}$ atau $X\text{h }YY\text{m }ZZ\text{s}$) untuk mode Clean Strava di `docs/PRD_VELORA.md`.
  * Merumuskan algoritma jarak tegak lurus terdekat (*Cross-Track Distance*) berbasis proyeksi ekuirektangular planar $O(N)$ CPU-friendly (< 0.1 ms) di `lib/services/route_guide_service.dart`.
  * Menetapkan ambang batas peringatan keluar jalur (> 50 m), histeresis pemulihan kembali ke jalur ($\le 30$ m), dan filter anti-jitter (2 sinyal GPS berturut-turut) untuk fitur **Off-Course Alert**.
  * Merumuskan spesifikasi mode manual opsional panduan rute (bisa digunakan, bisa tidak) tanpa mengganggu pelacakan bebas.

---

## 2. Agent Desain (UI/UX Designer)

**Fokus:** Merancang antarmuka pengguna, pengalaman pengguna, identitas visual (Branding), dan aset aplikasi.

**Tugas Utama & Realisasi:**

* [x] **Identitas Visual (Branding):** Mengimplementasikan logo **Velora** (ikon panah ganda 'V' berwarna oranye khas dengan gradasi api) di `lib/widgets/velora_logo.dart`.
* [x] **Sistem Desain (Design System):** Menyusun panduan warna, tipografi, dan komponen visual di `docs/DESIGN_SYSTEM_VELORA.md`.
* [x] **Desain Peta (Map Styling):** Menentukan gaya visual peta OSM dasar (tema standar & tema gelap dengan filter matriks neon) dan gaya *Polyline* neon cyan (`#00E5FF`) dengan efek *glow* di `lib/widgets/live_map_view.dart`. Bebas ketergantungan API key pihak ketiga.
* [x] **Desain Suar Titik Lokasi Peta (Luminous Beacon GPS Dot):** Merancang penanda titik lokasi saat ini berdesain multi-lapis (halo pendar luar 44px, cincin pembatas bergaris 28px, dan titik inti neon cyan 16px dengan border putih tebal serta *center dot* presisi) yang sangat kontras di tema gelap maupun terang.
* [x] **Desain Panel Navigasi Bebas Overflow:** Merancang panel *bottom-sheet* ergonomis untuk statistik *real-time* (Kecepatan, Pace, Jarak, Waktu, Elevasi) dengan perlindungan *FittedBox* dan desain tombol besar (Play/Pause/Resume/Stop) di `lib/widgets/control_buttons.dart` dan `lib/widgets/metric_card.dart`.
* [x] **Desain Template Berbagi (Social Share 9:16):**
  * Merancang tata letak *overlay* gambar klasik dengan rasio 9:16 untuk IG Story / WA di `lib/widgets/social_share_card.dart` dan `lib/widgets/mini_route_painter.dart`.
  * Merancang template **Clean Minimalis ala Strava** di `docs/DESIGN_SYSTEM_VELORA.md`: latar solid `#000000`, 3 metrik vertikal bold putih (`Distance`, `Pace`/`Speed`, `Time`), siluet rute polyline oranye tanpa pin, serta branding teks tebal **`VELORA`** putih (letter-spacing 4.5).
  * Merancang tombol pintasan cepat ke Video Flyover 3D di AppBar `SharePreviewScreen` agar pengguna dapat langsung beralih format tanpa harus kembali ke halaman awal.
* [x] **Desain Dialog Update:** Antarmuka notifikasi versi baru modern dengan badge versi dan catatan rilis di `lib/widgets/update_dialog.dart`.
* [x] **Desain Aksesibilitas Fitur Video Permanen:** Menetapkan tombol `PUTAR RUTE` dan opsi `Video Flyover (MP4)` selalu tampil di antarmuka; memberikan feedback informatif jika sesi latihan belum merekam rute bergerak.
* [x] **Desain Anti-Occlusion Banner Puncak & Proporsi Badge 3D:** Merancang ulang banner notifikasi puncak elevasi (`_buildPeakSummitBanner`) menjadi *capsule pill* horizontal ultra-kompak (28px) dengan efek *frosted glass* semi-transparan (`BackdropFilter` sigma 10) di zona langit atas aman (`padding.top + 52`), membebaskan area cakrawala peta dari tumpang-tindih visual terhadap pin 3D di peta, serta merampingkan dimensi pin penanda 3D (`MountainPeakPin`, `RoadTrackPin`, `RegencyFlagPin`) agar proporsional, elegan, dan bebas silau.
* [x] **Desain Pemuatan Instan Penanda Jalan Putaran Pertama:** Merancang pengalaman visual tanpa jeda (*zero-delay visual experience*) di mana penanda nama ruas jalan di rute 3D langsung tampil di detik pertama putaran pertama tanpa harus menunggu putaran kedua atau koneksi internet yang lambat.
* [x] **Desain Badge Menu Pemilihan Olahraga & Mode Mendaki:** Merancang antarmuka pemilihan aktivitas berbasis *Modal Bottom Sheet* elegan yang terpicu saat menekan tombol "MULAI LATIHAN" (dengan 3 kartu badge informatif: Lari, Sepeda, dan Mendaki), serta merancang tata letak metrik dinamis mendaki yang menonjolkan ketinggian aktual (*Altitude mdpl*) dan elevasi lereng (*Elevation Gain*).
* [x] **Desain Visual Panduan Rute & Banner Keluar Jalur:** Merancang lapisan polyline rute referensi berlapis indigo (`#6366F1` & `#818CF8`) dengan penanda awal hijau dan akhir merah pada `lib/widgets/live_map_view.dart`, tombol mengambang aksi panduan rute (`Icons.alt_route_rounded`), dialog lembar pengaturan `RouteGuideSheet`, dan banner peringatan melayang berdenyut amber-merah `OffCourseBanner`.

---

## 3. Agent Coding (Mobile Developer - Flutter)

**Fokus:** Mengimplementasikan kode, logika, dan menyatukan seluruh komponen aplikasi Velora.

**Tugas Utama & Realisasi:**

* [x] **Setup Lingkungan & Pustaka:** Menginisialisasi proyek Flutter dengan package name `online.nurmancloud.velora`. Memasang pustaka utama (`flutter_map`, `latlong2`, `geolocator`, `sqflite`, `share_plus`, `image_picker`, `flutter_foreground_task`, `package_info_plus`, `url_launcher`, `http`).
* [x] **Integrasi Peta & OSM Bebas API Key:** Menampilkan *TileLayer* OpenStreetMap dengan penanda posisi live dan *PolylineLayer* yang diperbarui secara dinamis di `lib/widgets/live_map_view.dart` tanpa memerlukan token berbayar.
* [x] **Layanan Latar Belakang (Foreground Service):** Menggunakan `flutter_foreground_task` agar GPS tetap merekam saat layar ponsel mati atau aplikasi di-*minimize*, serta notifikasi persisten di `lib/services/foreground_service_handler.dart`.
* [x] **Logika Pelacakan (Tracking Logic) & Auto-Pause Dual-Trigger:** Mengimplementasikan filter GPS, perhitungan jarak *real-time*, akumulasi elevasi, stopwatch waktu aktif, dan sistem *Auto-Pause* sinkron antara stream GPS dan ticker timer periodik di `lib/providers/tracking_provider.dart`.
* [x] **Pemuatan Posisi Seketika & Smart Recenter:** Integrasi *instant last known position*, stream posisi pasif mode idle, tombol pusatkan lokasi interaktif dengan auto re-fetch & diagnosis status GPS di `lib/services/location_service.dart`, `lib/providers/tracking_provider.dart`, dan `lib/screens/tracking_screen.dart`.
* [x] **Fitur Ekspor Gambar (RepaintBoundary):** Membangun komponen penangkapan snapshot PNG beresolusi tinggi dan berbagi ke media sosial di `lib/services/social_share_service.dart`.
* [x] **Implementasi Template Clean Strava-Style & Akses Video:** Menambahkan enum `ShareCardStyle.clean`, fungsi `formatCleanPace`, `formatCleanDuration`, komponen `_buildCleanContent` pada `SocialShareCard`, serta pembaruan antarmuka pemilih tab 4 mode dan pintasan video di `SharePreviewScreen`.
* [x] **Persistensi & Feedback Fitur Video:** Memastikan tombol `PUTAR RUTE` dan modal `Video Flyover Rute (MP4 Sinematik)` di `ActivityDetailScreen` selalu dapat diakses secara persisten, dilengkapi SnackBar penjelas jika rute belum mencukupi.
* [x] **Fitur Auto-Update:** Mengimplementasikan pengecekan otomatis dan manual ke GitHub Releases API di `lib/services/update_service.dart`.
* [x] **Sinkronisasi Pemutar Rute & Auto-Play Instan:** Mengoreksi kondisi inisialisasi controller animasi rute di `lib/screens/route_replay_screen.dart`, menyinkronkan status visual tombol Pause/Play secara langsung dengan `_animController.isAnimating`, memperbaiki scrubbing linimasa, serta menjamin rute langsung berputar mulus tanpa jeda atau klik ganda saat dibuka.
* [x] **Anti-Occlusion Banner & Refaktorisasi Pin 3D Rute:** Mengimplementasikan banner selebrasi puncak elevasi dan batas wilayah berbasis *frosted glass capsule pill* dalam `Column` terpadu anti-tumpang-tindih pada `lib/screens/route_replay_screen.dart`, mengamankan visibilitas badge penanda ketinggian rute (`PUNCAK XXM`), serta mengecilkan skala pin gunung dari 190x84 ke 130x58 dan pin lintasan dari 220x76 ke 150x52 untuk keterbacaan optimal.
* [x] **Pemuatan Instan Nama Jalan & Pra-Pemuatan Detail Aktivitas:** Mengimplementasikan arsitektur dua tahap (*Two-Tier Fast Pass*) pada `lib/services/road_geocoding_service.dart` (fast pass sinkron 0 ms dan targeted online upgrade dengan timeout ketat 1,2 detik), integrasi `onProgressUpdate` pada `lib/screens/route_replay_screen.dart`, pra-pemuatan otomatis di `lib/screens/activity_detail_screen.dart`, serta perluasan koridor offline lokal Pontianak (Uray Bawadi, Sutan Syahrir, Kesehatan, Harapan Jaya, Ampera, Prof. M. Yamin, Wahidin).
* [x] **Mode Olahraga Mendaki (Hike) & Integrasi Modal Pemilih Olahraga:** Mengintegrasikan enum `SportsType.hike`, penyederhanaan tombol "MULAI LATIHAN" pada `lib/widgets/control_buttons.dart` yang memicu modal badge 3 olahraga pada `lib/screens/tracking_screen.dart`, dashboard metrik dinamis ketinggian (Altitude mdpl, Elev Gain, Pace), toleransi auto-pause tanjakan curam di `lib/providers/tracking_provider.dart`, penyesuaian rekor jarak daki di `lib/services/achievement_service.dart`, serta integrasi UI riwayat, detail, dan video 3D.
* [x] **Panduan Rute GPX & Deteksi Keluar Jalur (Off-Course Alert):** Mengintegrasikan model data `RouteGuideInfo` di `lib/models/route_guide_info.dart`, parser GPX universal di `lib/services/gpx_service.dart`, layanan perhitungan proyeksi planar tercepat `RouteGuideService.calculateDistanceToPolyline` di `lib/services/route_guide_service.dart`, manajemen state panduan rute dan evaluasi berkala di `lib/providers/tracking_provider.dart`, pemilih berkas GPX via `file_picker`, serta integrasi UI pada `TrackingScreen`, `LiveMapView`, `OffCourseBanner`, dan `RouteGuideSheet`.

---

## 4. Agent Pengujian (QA & Testing)

**Fokus:** Memastikan aplikasi berjalan bebas *bug*, akurat, dan tidak menguras baterai ponsel.

**Tugas Utama & Realisasi:**

* [x] **Pengujian Fungsional & Unit:** 175 pengujian unit dan widget otomatis (100% lolos di direktori `test/`):
  * `test/route_guide_service_test.dart`: Validasi algoritma kalkulasi jarak tegak lurus terdekat (*Cross-Track Distance*), proyeksi planar segmen rute, titik persis di rute, dan penanganan polylines edge cases.
  * `test/route_guide_widget_test.dart`: Validasi rendering banner peringatan keluar jalur `OffCourseBanner` (meter & km), rendering `RouteGuideSheet` (mode kosong, mode rute aktif, switch toggle, hapus rute, pemilih riwayat latihan), rendering polyline referensi dan tombol aksi mengambang pada `LiveMapView`, serta konversi `RouteGuideInfo.fromSession`.
  * `test/tracking_screen_sport_selection_test.dart`: Validasi penekanan tombol "MULAI LATIHAN" memunculkan badge modal 3 olahraga, verifikasi pemilihan mode Mendaki (hike), dan pengujian metrik dinamis mendaki (`ALTITUDE mdpl`, `ELEV GAIN`, `PACE`).
  * `test/road_geocoding_test.dart`: Validasi pemformatan nama jalan, pengenalan koridor rute offline Pontianak & kota-kota besar, deduplikasi transisi, callback instan `onProgressUpdate` (0 ms), dan pemanasan memori `precacheRoadTransitions`.
  * `test/route_replay_test.dart`, `test/route_replay_interaction_test.dart` & `test/route_replay_layout_audit_test.dart`: Validasi siklus pemutaran rute otomatis, transisi Play/Pause satu sentuhan tanpa freeze, scrubber linimasa, audit tata letak pada berbagai rasio layar, serta validasi banner selebrasi puncak elevasi anti-occlusion pada zona aman atas.
  * `test/map_precache_test.dart`: Validasi konversi koordinat tile OSM, pemotongan batas, kalkulasi ubin rute, pembersihan cache memori, penanganan pembatalan, inisialisasi direktori cache ubin, pemeriksaan internet, warm-up startup, dan precache rute aktivitas.
  * `test/activity_detail_share_test.dart`: Validasi keterlihatan permanen tombol `PUTAR RUTE` dan modal opsi `Video Flyover Rute (MP4 Sinematik)` baik pada sesi dengan rute maupun sesi kosong/minim koordinat.
  * `test/location_recenter_test.dart`: Validasi callback tombol pusatkan lokasi, penanganan `currentLocation == null`, dan siklus hidup idle location stream.
  * `test/social_share_test.dart`: Validasi rendering kartu Clean Strava untuk Lari (`10.44 km`, `5:13 /km`, `54m 27s`, `VELORA`) dan Sepeda (`25.40 km`, `25.4 km/h`, `1h 0m 0s`), serta ekspor Full HD PNG capture.
  * `test/algorithms_test.dart`: Haversine, Douglas-Peucker, PaceCalculator.
  * `test/auto_pause_test.dart`: Trigger Auto-Pause dan Auto-Resume, serta evaluasi timer berkala henti stasioner.
  * `test/models_and_db_test.dart`: Serialisasi dan mapping SQLite.
  * `test/update_service_test.dart`: Logika perbandingan versi SemVer.
  * `test/gpx_service_test.dart`: Validitas struktur XML GPX 1.1 dan parsing GPX tracks/routes/waypoints menjadi `RouteGuideInfo`.
  * `test/widget_test.dart`: Rendering widget UI utama, logo, dan metric card bebas overflow.
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
* [x] **Rilis Pembaruan GitHub (v1.0.1 s/d v1.0.11):** Publikasi rilis patch dan fitur lanjutan.
* [x] **Rilis Pembaruan GitHub (v1.0.12):** Integrasi format Clean Minimalis ala Strava dan pemutakhiran dokumentasi tim agen.
* [x] **Rilis Pembaruan GitHub (v1.0.13):** Pelacakan lokasi aktif, suar GPS neon pendar & tombol pusatkan lokasi pintar.
* [x] **Rilis Pembaruan GitHub (v1.0.14):** Peningkatan ketahanan pembaruan in-app (bypass rate limit raw fallback, external cache storage OEM-friendly, browser download alternative), serta visibilitas permanen fitur Video Flyover 3D & Putar Rute.
* [x] **Rilis Pembaruan GitHub (v1.0.15):** Pemanasan peta cerdas saat aplikasi dibuka (Smart Early Map Pre-Caching jika ada internet / skip jika offline), precache koridor rute di detail & replay, dan dekode GPU instan saat render video.
* [x] **Rilis Pembaruan GitHub (v1.0.16):** Perbaikan desinkronisasi status Play/Pause pemutar rute (Route Replay) dan auto-play instan rute GPX.
* [x] **Rilis Pembaruan GitHub (v1.0.17):** Optimalisasi penanda puncak elevasi rute bebas tumpang-tindih (anti-occlusion banner) dan desain badge 3D ramping proporsional.
* [x] **Rilis Pembaruan GitHub (v1.0.18):** Pemuatan instan nama jalan putaran pertama (Instant Road Geocoding & Early Pre-Warming).
* [x] **Rilis Pembaruan GitHub (v1.0.19):** Mode olahraga Mendaki (Hiking / Trekking), antarmuka modal badge pemilih olahraga saat tombol Mulai ditekan, dan dashboard metrik elevasi dinamis.
* [x] **Rilis Pembaruan GitHub (v1.0.20):** Panduan rute GPX (Route Breadcrumbs) & peringatan keluar jalur (Off-Course Alert) berbasis mode manual opsional, impor GPX universal via file_picker, dan banner peringatan haptik getar.
* [x] **Rilis Pembaruan GitHub (v1.0.21):** Redesain kartu berbagi Clean Minimalis persis Strava (siluet rute oranye hero 4.8px, tipografi seimbang 14sp & 27sp, spasi 14px rapat), mode stiker PNG transparan untuk Instagram Story & Reels dengan drop shadow pelindung kontras, pratinjau papan catur transparansi, serta simpan langsung stiker PNG ke galeri ponsel (`Pictures/Velora/`).
* [x] **Rilis Pembaruan GitHub (v1.0.22):** Peningkatan responsivitas tata letak kartu clean dan stiker transparan dengan LayoutBuilder adaptif bebas overflow, tombol aksi langsung `[ BUKA IG ]` pada notifikasi simpan stiker, perlindungan FittedBox logo Velora, dan integrasi suite pengujian komprehensif 5 gaya (191 tests passing).
* [x] **Rilis Pembaruan GitHub (v1.1.1 - Major Release):** Integrasi ekosistem Smartwatch & Sensor Detak Jantung BLE HRM (GATT 0x180D), impor GPX olahraga mandiri tanpa bawa HP, 5 Zona Latihan Detak Jantung atlet (Z1-Z5), live HUD BPM, layar Pengaturan terpadu (`SettingsScreen`), panel pemindaian BLE sekitar terbuka dengan deteksi Bluetooth otomatis, serta dialog interaktif pemanasan cache & periksa update (200 tests passing).
* [x] **Rilis Pembaruan GitHub (v1.1.2):** Perbaikan modal sensor BLE fixed-height anti-amblas (bebas layar abu-abu kosong saat scroll), integrasi perangkat bonded/paired Bluetooth HP untuk smartwatch (Haylou/Garmin/Amazfit), dan perizinan neverForLocation Android 12+ anti-sensor nama.
* [x] **Rilis Pembaruan GitHub (v1.1.3):** Perbaikan kotak abu-abu (RenderErrorBox) dan eliminasi crash overscroll pada modal sensor BLE, penyematan tombol Pindai BLE permanen (Pinned Action Bar) anti-tenggelam, serta kategorisasi cerdas perangkat Bluetooth (smartwatch vs audio/TV).
