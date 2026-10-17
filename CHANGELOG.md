# Changelog: Velora Run & Ride

Semua perubahan dan riwayat rilis pada aplikasi **Velora** dicatat dalam dokumen ini.

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
