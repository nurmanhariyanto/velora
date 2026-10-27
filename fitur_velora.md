# Rencana Pembagian Kerja & Spesifikasi Fitur: Proyek Aplikasi Velora (Mode Lokal)

Dokumen ini memuat daftar fitur lengkap untuk aplikasi **Velora: Run & Ride** (beroperasi secara lokal tanpa server) beserta rincian pembagian tugas untuk setiap agen pengembangan.

---

## A. Daftar Fitur Utama Aplikasi Velora

1. **Pelacakan Aktivitas Lintas Olahraga (Run & Ride):** Melacak rute menggunakan GPS secara *real-time* untuk aktivitas lari dan bersepeda, dengan kalkulasi metrik yang disesuaikan (Pace untuk lari, Kecepatan untuk sepeda). *(Status: Selesai)*
2. **Peta Interaktif (OpenStreetMap 100% Bebas API Key):** Menampilkan posisi pengguna saat ini secara *live* di atas peta dasar OpenStreetMap Standard dengan *color matrix filter* untuk tema gelap Velora Neon (`#00E5FF`). Bebas batasan *API key required* dan kamera peta otomatis mengikuti pergerakan pengguna. *(Status: Selesai)*
3. **Pelacakan Latar Belakang (Background Tracking):** Aktivitas tetap terekam secara akurat meskipun layar ponsel dimatikan atau aplikasi disembunyikan, menggunakan *Foreground Service* Android (`FOREGROUND_SERVICE_LOCATION` dan `WAKE_LOCK`). *(Status: Selesai)*
4. **Pintasan Kontrol Notifikasi Latar Belakang (Notification Actions):** Tombol aksi cepat Jeda/Lanjut (*Pause/Resume*) dan Selesai (*Finish*) langsung pada bilah notifikasi dan layar kunci (*lock screen*) tanpa harus membuka aplikasi. *(Status: Selesai)*
5. **Dashboard Statistik Cerdas Bebas Overflow:** Menampilkan metrik *real-time* meliputi Durasi Bersih, Jarak (km), Kecepatan Saat Ini, rata-rata Pace, dan Elevasi Positif (+m) dengan perlindungan *FittedBox* adaptif di semua ukuran layar ponsel. *(Status: Selesai)*
6. **Auto-Pause Adaptif Ganda (Dual-Trigger):** Perekaman waktu dan jarak otomatis berhenti sementara (*pause*) saat pengguna berhenti bergerak (< 2 km/jam selama $\ge 3$ detik), dideteksi secara presisi melalui kombinasi *stream* posisi GPS dan *ticker timer* periodik 1 detik, serta otomatis melanjut (*resume*) seketika saat pergerakan terdeteksi lagi. *(Status: Selesai)*
7. **Riwayat Aktivitas (Local Storage):** Menyimpan daftar aktivitas masa lalu beserta rute koordinatnya langsung di memori internal ponsel menggunakan SQLite (`velora_local.db`), 100% tanpa internet. *(Status: Selesai)*
8. **Social Media Sharing (Ekspor Gambar 9:16):**
   - **Mode Clean Minimalis (Strava Style):** Tampilan ultra-bersih dengan latar hitam solid (`#000000`), metrik vertikal bold putih (`Distance`, `Pace`/`Speed`, `Time`), siluet rute polyline oranye, dan teks branding **`VELORA`** putih (menjadi mode default).
   - **Mode Peta & Foto Saya:** Pilihan latar belakang peta OSM langsung atau foto pengguna dari galeri/kamera dengan overlay metrik resolusi tinggi.
   - **Mode Klasik:** Format kartu lengkap dengan badge sesi dan 4 metrik sekunder.
   - Diekspor via `RepaintBoundary` menjadi gambar resolusi tinggi Full HD untuk Instagram Story atau WhatsApp Status. *(Status: Selesai)*
9. **Pembaruan Otomatis Aplikasi (In-App Auto-Update):** Memeriksa ketersediaan versi rilis baru secara otomatis dan manual dari GitHub Releases API, membandingkan SemVer, menampilkan dialog *changelog*, serta mengunduh file APK langsung. *(Status: Selesai)*

---

## B. Pembagian Kerja Tim (Agen)

### 1. Agent Analisis (Systems & Requirements Analyst)
**Tanggung Jawab:** Merumuskan logika, spesifikasi teknis fitur, dan arsitektur data.
* **Analisis Algoritma GPS:** Menentukan formula kalkulasi jarak (*Haversine*) dan filter *noise/drift* GPS. *(Selesai)*
* **Definisi Logika Auto-Pause:** Menetapkan angka ambang batas ($< 2\text{ km/jam}$ selama 3 detik) dan kondisi *resume*. *(Selesai)*
* **Skema Database (SQLite):** Mendesain struktur tabel `aktivitas` dan `titik_koordinat`. *(Selesai)*
* **Manajemen Performa:** Merumuskan penerapan algoritma penyederhanaan rute (*Douglas-Peucker*). *(Selesai)*
* **Logika Pembaruan Versi:** Menentukan algoritma perbandingan SemVer untuk auto-update. *(Selesai)*

### 2. Agent Desain (UI/UX & Graphic Designer)
**Tanggung Jawab:** Menerjemahkan fitur menjadi pengalaman visual yang menarik dan ergonomis.
* **Branding & Aset:** Menyediakan logo utama Velora (vektor 'V' panah ganda oranye) dan ikon olahraga pendukung. *(Selesai)*
* **Desain Peta Bebas API Key:** Menentukan visualisasi peta OpenStreetMap (tema *dark* berbasis ColorMatrix dan standar) dan rute *polyline* neon cyan 6px dengan efek *glow* 10px. *(Selesai)*
* **UI/UX Layar Tracking & Riwayat:** Desain panel statistik bebas *text overflow* (berbasis `FittedBox`), tombol kontrol besar, dan kartu riwayat. *(Selesai)*
* **Template Overlay Social Share:** Tata letak kanvas 9:16 untuk Instagram/WA dengan efek *vignette/drop-shadow* dan *mini polyline*. *(Selesai)*
* **Desain Dialog Update:** Antarmuka notifikasi versi baru modern dengan catatan rilis. *(Selesai)*

### 3. Agent Coding (Mobile Developer - Flutter)
**Tanggung Jawab:** Membangun aplikasi secara utuh berdasarkan spesifikasi analis dan desainer.
* **Modul Peta & Lokasi (Fitur 1 & 2):** Integrasi `flutter_map` dan `geolocator` dengan filter akurasi dan 100% bebas API key. *(Selesai)*
* **Sistem Latar Belakang (Fitur 3 & 4):** Menerapkan `flutter_foreground_task` dengan notifikasi persisten dan tombol aksi. *(Selesai)*
* **Engine Metrik & Auto-Pause (Fitur 5 & 6):** Logika *Auto-Pause* ganda di `AutoPauseDetector` dan timer periodik di `TrackingProvider`. *(Selesai)*
* **Database Manager (Fitur 7):** Repository `sqflite` untuk menyimpan, membaca, dan menghapus sesi di `ActivityRepository`. *(Selesai)*
* **Modul Social Share (Fitur 8):** Komponen `SocialShareCard` dengan `RepaintBoundary` dan integrasi `SharePlus`. *(Selesai)*
* **Modul Auto-Update (Fitur 9):** Integrasi GitHub API, perbandingan SemVer, dan pengunduhan APK di `UpdateService`. *(Selesai)*

### 4. Agent Pengujian (QA & Testing)
**Tanggung Jawab:** Memastikan setiap fitur bekerja sempurna dan bebas *bug*.
* **Functional & Unit Testing:** 27 pengujian unit dan widget otomatis (100% lolos di `test/`). *(Selesai)*
* **Scenario Testing (Auto-Pause):** Validasi kondisi diam, timer henti berkala, dan bergerak kembali dengan jeda konfirmasi. *(Selesai)*
* **Code Quality Assurance:** Menjalankan `flutter analyze` dengan 0 *warning* dan 0 *error*. *(Selesai)*

### 5. Agent DevOps & Rilis (Release Manager)
**Tanggung Jawab:** Mempersiapkan aplikasi untuk fase rilis dan distribusi ke pengguna.
* **Kompilasi & Build:** Konfigurasi `build.gradle.kts` (minSdk 24, Java 17) dan perizinan lengkap di `AndroidManifest.xml`. *(Selesai)*
* **Keystore & Security:** Konfigurasi *signing* dan aturan keamanan ProGuard/R8 di `proguard-rules.pro`. *(Selesai)*
* **CI/CD & Distribusi GitHub:** Repositori terpusat di `https://github.com/nurmanhariyanto/velora` dengan rilis APK resmi dan *workflow* CI/CD. *(Selesai)*
