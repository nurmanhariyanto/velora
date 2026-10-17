# Changelog: Velora Run & Ride

Semua perubahan dan riwayat rilis pada aplikasi **Velora** dicatat dalam dokumen ini.

---

## [v1.0.1] - 2026-10-17

### 🐛 Perbaikan Bug & Peningkatan (Hotfix)
- **Mesin Auto-Pause Ganda (Dual-Trigger Detection):** Memperbaiki kendala auto-pause yang tidak terpicu saat pengguna berhenti karena pemancar GPS melambat saat diam. Kini dilengkapi pengecekan periodik berbasis ticker timer (3 detik henti) tersinkronisasi dengan `AutoPauseDetector`, memastikan jeda otomatis aktif seketika dan resume instan saat mulai bergerak.
- **Peta Bebas API Key (100% Free OpenStreetMap):** Mengganti endpoint CartoDB yang kini mewajibkan API key berbayar dengan OpenStreetMap Standard (`tile.openstreetmap.org`) yang dilengkapi *matrix color filter* untuk mode gelap Velora Neon. Tidak ada lagi pesan *"api key required"*.
- **Pencegahan Text Overflow UI:** Menambahkan `FittedBox` dengan `BoxFit.scaleDown` pada komponen `MetricCard` serta menyederhanakan label menjadi `SPEED` dan `ELEVASI`, memastikan seluruh tampilan angka dan teks pas sempurna pada semua resolusi layar ponsel Android tanpa overflow.

---

## [v1.0.1] - 2026-10-17

### 🐛 Perbaikan Bug & Peningkatan Performa
- **Perbaikan Mesin Auto-Pause (Timer-based Confirmation):** Mengintegrasikan evaluasi berbasis timer periodik 1 detik di `TrackingProvider` dan `AutoPauseDetector`. Sistem kini secara andal mendeteksi kondisi pengguna diam (< 2 km/jam atau tanpa pergerakan selama $\ge 3$ detik), menghentikan penambahan durasi aktif secara instan, serta melakukan *Auto-Resume* otomatis saat kecepatan kembali $\ge 2.0$ km/jam.
- **Peta Bebas Kunci API (100% Free OpenStreetMap):** Mengganti ketergantungan CartoDB (yang meminta API Key) dengan standar OpenStreetMap (`tile.openstreetmap.org`) yang diperkaya *ColorMatrix* tema gelap Velora (`#1A1A24`). Navigasi peta kini dapat diakses bebas tanpa registrasi maupun API key pihak ketiga.
- **Pencegahan Text Overflow & UI Responsif:** Menambahkan `FittedBox` adaptif pada komponen `MetricCard` agar teks angka metrik dan label tidak pernah keluar batas layar (*overflow*) pada ponsel dengan layar sempit atau pengaturan font besar.
- **Koreksi Tipografi & Label Ergonomis:** Memperbaiki label metrik kecepatan menjadi `'SPEED'` dan membetulkan tipografi label `'ELEVASI'` pada layar pelacakan dan detail aktivitas.
- **Optimasi Stream GPS (Location Service):** Mengatur `distanceFilter: 0` dan memperluas ambang batas akurasi hingga 35 meter agar sinyal GPS saat pengguna diam tetap diterima dan diolah oleh detektor henti alih-alih diabaikan.

---

## [v1.0.0] - 2026-10-17

### 🚀 Fitur Baru (Initial Release)
- **Pelacakan Lintas Olahraga (Run & Ride):** Pelacakan rute GPS mandiri secara *real-time* untuk aktivitas Lari dan Bersepeda dengan metrik adaptif (Pace untuk lari, Kecepatan untuk sepeda).
- **Peta Interaktif OpenStreetMap (OSM):** Visualisasi rute *live* dengan pilihan lapisan peta standar OSM dan CartoDB Dark, dilengkapi garis lintasan neon cyan (`#00E5FF`) dengan efek cahaya (*glow*).
- **Pelacakan Latar Belakang (Android Foreground Service):** Aktivitas tetap terekam tanpa henti saat layar ponsel dimatikan atau aplikasi disembunyikan berkat integrasi `FOREGROUND_SERVICE_LOCATION` dan `WAKE_LOCK`.
- **Pintasan Notifikasi Latar Belakang (Notification Actions):** Tombol aksi cepat Jeda/Lanjut (*Pause/Resume*) dan Selesai (*Finish*) langsung di bilah notifikasi dan *lock screen*.
- **Mesin Auto-Pause Pintar:** Penghentian waktu dan jarak otomatis saat pengguna berhenti bergerak (kecepatan $< 2\text{ km/jam}$ selama $\ge 3\text{ detik}$) dan *auto-resume* saat bergerak kembali.
- **Penyimpanan Lokal Mandiri (SQLite Database):** Database lokal `velora_local.db` untuk mencatat seluruh ringkasan sesi dan koordinat rute tanpa memerlukan koneksi internet (*100% offline-first*).
- **Optimasi Douglas-Peucker:** Algoritma penyederhanaan titik koordinat untuk menjaga performa rendering peta pada rute jarak jauh (puluhan kilometer).
- **Ekspor Gambar Media Sosial (Rasio 9:16):** Penangkapan *widget* beresolusi tinggi via `RepaintBoundary` untuk menghasilkan *watermark* foto Instagram Story / WhatsApp Status lengkap dengan logo Velora, metrik tebal, dan sketsa rute oranye.
- **Pembaruan Otomatis Aplikasi (In-App Auto-Update):** Pemeriksaan otomatis dan manual ke GitHub Releases API untuk mendeteksi rilis versi baru serta pengunduhan file APK langsung dari aplikasi.

### 🛡️ Kualitas & Keamanan
- 25 Pengujian Unit, Algoritma, dan Widget lolos 100%.
- Kode sumber bersih dengan 0 *lint warnings* / *errors* (`flutter analyze`).
- Optimasi ProGuard / R8 pada kompilasi rilis Android APK.
