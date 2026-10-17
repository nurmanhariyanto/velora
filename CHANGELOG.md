# Changelog: Velora Run & Ride

Semua perubahan dan riwayat rilis pada aplikasi **Velora** dicatat dalam dokumen ini.

## [v1.0.3] - 2026-10-17

### 🚀 Fitur Baru & Peningkatan (Latest Release)
- **Statistik Sepanjang Masa (All-Time Lifetime Stats) Ala Strava:** Menampilkan rekor seumur hidup untuk Bersepeda & Lari secara terpisah (Tanjakan Tertinggi / *Biggest Climb*, Jarak Terjauh / *Longest Ride*, Kecepatan Puncak / *Top Speed*, Kecepatan Rata-Rata Terbaik, Pace Terbaik, serta akumulasi total kilometer, waktu, elevasi, dan sesi).
- **Pencapaian Terbaik (Best Efforts):** Ekstraksi rekor waktu tercepat pada jarak patokan standar (1K, 5K, 10K, Half Marathon 21.1K, 40K Time Trial) dengan algoritma sliding window GPS dan estimasi segmen.
- **Lemari Trofi Digital (Trophy Case & Badges):** 11 lencana prestasi offline (Gran Fondo 100km, Half Fondo 50km, Century Rider 160.9km, Speed Demon >30km/h, 5K/10K/Half-Marathon Finisher, Climbing Legend >=1000m, King of the Hill >=500m, Early Bird, Night Owl, Consistent Athlete) dengan kartu berdesain emas bercahaya dan progress bar.
- **Deteksi Waktu Aktivitas Cerdas (Time-of-Day Activity Naming):** Otomatis menamai kegiatan berdasarkan jam mulai ("Bersepeda Pagi", "Bersepeda Siang Hari", "Bersepeda Sore Hari", "Bersepeda Malam Hari", "Bersepeda Subuh", "Lari Pagi", dsb) tanpa karakter gender, dan otomatis memprioritaskan catatan khusus jika diisi.
- **Tab Baru "Profil & Rekor":** Menambahkan tab ketiga di bilah navigasi utama untuk mengakses profil atlet, rekor, dan trofi.

---

## [v1.0.2] - 2026-10-17

### 🚀 Fitur Baru & Peningkatan (Latest Release)
- **Pintasan Kontrol Notifikasi Status Bar & Lockscreen:** Tombol aksi kontrol cepat (`JEDA`, `LANJUT`, dan `SELESAI`) kini selalu tampil aktif dan dapat ditekan langsung dari bilah notifikasi maupun layar kunci ponsel saat aplikasi di-minimize.
- **Izin Notifikasi Runtime Android 13+ (POST_NOTIFICATIONS) & Saluran Notifikasi Prioritas Tinggi:** Memperbarui konfigurasi saluran notifikasi ke `HIGH` importance (`velora_tracking_channel_v2`) dengan visibilitas publik serta menambahkan dialog perizinan notifikasi otomatis saat aplikasi dibuka maupun saat sesi pelacakan dimulai.
- **Sinkronisasi Durasi Real-Time Notifikasi:** Notifikasi foreground kini memperbarui waktu berjalan setiap 2 detik secara hening (*onlyAlertOnce*) tanpa getaran atau bunyi berulang.
- **Kartu Berbagi Media Sosial Ala Strava (Default Map Background):** Menampilkan latar belakang peta OpenStreetMap Dark Mode secara otomatis dengan zoom presisi pada rute aktivitas, garis polyline oranye menyala, serta penanda Start & Finish. Pengguna juga dapat memilih foto pribadi atau mode minimalis.
- **Pembaruan Mandiri di Dalam Aplikasi (In-App Streaming Updater):** Mengunduh berkas pembaruan APK langsung dari aplikasi dengan progress bar, persentase real-time, dan pemanggil otomatis paket instalasi Android (`FileProvider`).
- **Pembersihan Otomatis Cache APK:** Menghapus berkas APK lama di memori sementara secara otomatis.
- **Logo Aplikasi Resmi Velora:** Seluruh logo bawaan Flutter digantikan dengan simbol V chevron oranye neon Velora.

---

## [v1.0.1] - 2026-10-17

### 🚀 Fitur Baru & Peningkatan
- **Pembaruan Mandiri di Dalam Aplikasi (In-App Streaming Updater):** Mengganti pengalihan browser dengan pengunduhan langsung di dalam aplikasi melalui *HTTP stream* dengan progress bar, persentase *real-time*, dan jumlah MB terunduh. Setelah selesai, dialog sistem Android secara otomatis memicu pemasangan (`FileProvider`) untuk menimpa/memperbarui aplikasi lama secara mulus tanpa kehilangan data riwayat SQLite.
- **Pembersihan Otomatis Berkas APK Lama (Cache Cleanup):** Berkas APK versi lama di direktori penyimpanan sementara (*temporary cache*) otomatis dibersihkan saat unduhan atau pengecekan pembaruan dilakukan.
- **Logo Aplikasi Resmi Velora (Custom Launcher Icon):** Menggantikan seluruh logo bawaan Flutter dengan logo resmi Velora (simbol panah ganda *chevron* V bercahaya oranye neon di atas latar titanium gelap), lengkap dengan *round icon* dan *adaptive icon* untuk Android 8.0+.

### 🐛 Perbaikan Bug (Hotfix)
- **Mesin Auto-Pause Ganda (Dual-Trigger Detection):** Memperbaiki kendala auto-pause yang tidak terpicu saat pengguna berhenti karena pemancar GPS melambat saat diam. Kini dilengkapi pengecekan periodik berbasis ticker timer (3 detik henti) tersinkronisasi dengan `AutoPauseDetector`, memastikan jeda otomatis aktif seketika dan resume instan saat mulai bergerak.
- **Peta Bebas API Key (100% Free OpenStreetMap):** Mengganti endpoint CartoDB yang kini mewajibkan API key berbayar dengan OpenStreetMap Standard (`tile.openstreetmap.org`) yang dilengkapi *matrix color filter* untuk mode gelap Velora Neon. Tidak ada lagi pesan *"api key required"*.
- **Pencegahan Text Overflow UI:** Menambahkan `FittedBox` dengan `BoxFit.scaleDown` pada komponen `MetricCard` serta menyederhanakan label menjadi `SPEED` dan `ELEVASI`, memastikan seluruh tampilan angka dan teks pas sempurna pada semua resolusi layar ponsel Android tanpa overflow.
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
