# Rencana Pembagian Kerja & Spesifikasi Fitur: Proyek Aplikasi Velora (Mode Lokal)

Dokumen ini memuat daftar fitur lengkap untuk aplikasi **Velora: Run & Ride** (beroperasi secara lokal tanpa server) beserta rincian pembagian tugas untuk setiap agen pengembangan.

---

## A. Daftar Fitur Utama Aplikasi Velora

1. **Pelacakan Aktivitas Lintas Olahraga (Run & Ride):** Melacak rute menggunakan GPS secara *real-time* untuk aktivitas lari dan bersepeda, dengan kalkulasi metrik yang disesuaikan (Pace untuk lari, Kecepatan untuk sepeda).
2. **Peta Interaktif (OpenStreetMap):** Menampilkan posisi pengguna saat ini secara *live* di atas peta dasar (OSM) dan menggambar rute perjalanan menggunakan garis *polyline* yang terus bertambah. Kamera peta otomatis mengikuti pergerakan pengguna.
3. **Pelacakan Latar Belakang (Background Tracking):** Aktivitas tetap terekam secara akurat meskipun layar ponsel dimatikan atau aplikasi disembunyikan, menggunakan *Foreground Service* Android.
4. **Dashboard Statistik Cerdas:** Menampilkan metrik *real-time* meliputi Durasi, Jarak (km), Kecepatan Saat Ini, dan rata-rata Pace.
5. **Auto-Pause:** Perekaman waktu dan jarak otomatis berhenti sementara (*pause*) saat pengguna berhenti bergerak (misal: di lampu merah), dan kembali melanjut (*resume*) saat pergerakan terdeteksi lagi.
6. **Riwayat Aktivitas (Local Storage):** Menyimpan daftar aktivitas masa lalu beserta rute koordinatnya langsung di memori ponsel pengguna menggunakan SQLite, tanpa perlu koneksi internet.
7. **Social Media Sharing (Ekspor Gambar):** Memungkinkan pengguna mengambil foto (atau memilih dari galeri), yang kemudian otomatis ditumpuk (*overlay*) dengan logo Velora, rute *polyline* mini, dan teks metrik aktivitas. Gambar akhir dapat langsung dibagikan ke WhatsApp atau Instagram Story.

---

## B. Pembagian Kerja Tim (Agen)

### 1. Agent Analisis (Systems & Requirements Analyst)
**Tanggung Jawab:** Merumuskan logika, spesifikasi teknis fitur, dan arsitektur data.
* **Analisis Algoritma GPS:** Menentukan formula kalkulasi jarak (misal: *Haversine formula*) dan merumuskan toleransi *noise* GPS (radius akurasi yang dapat diterima).
* **Definisi Logika Auto-Pause:** Menetapkan angka ambang batas (*threshold*). Contoh: Jika kecepatan < 2 km/jam selama 3 detik beruntun, pemicu *Auto-Pause* aktif.
* **Skema Database (SQLite):** Mendesain struktur tabel:
  * `Tabel_Sesi`: id, tipe_olahraga (run/ride), waktu_mulai, waktu_selesai, durasi_aktif, total_jarak.
  * `Tabel_Koordinat`: id, sesi_id, latitude, longitude, kecepatan, timestamp.
* **Manajemen Performa:** Merumuskan penerapan algoritma penyederhanaan rute (*Douglas-Peucker*) untuk mencegah *lag* saat memuat riwayat rute yang panjang.

### 2. Agent Desain (UI/UX & Graphic Designer)
**Tanggung Jawab:** Menerjemahkan fitur menjadi pengalaman visual yang menarik dan ergonomis.
* **Branding & Aset:** Menyediakan logo utama Velora (ikon 'V' panah ganda oranye) dan aset ikon pendukung (sepeda, sepatu lari, ikon *pause/play*).
* **Desain Peta (Map Styling):** Menentukan visualisasi peta OSM (menggunakan *layer basemap* yang bersih/redup) dan warna *polyline* rute (contoh: biru neon semi-transparan dengan ketebalan 8px).
* **UI/UX Layar Tracking:** Membuat desain prototipe untuk halaman utama, penempatan panel statistik (di bagian bawah), dan tombol *floating* untuk kontrol peta (pusatkan GPS, ganti lapisan peta).
* **Template Overlay Social Share:** Membuat tata letak *watermark* foto untuk Instagram/WA. Mengatur posisi metrik utama di tengah atas (menggunakan efek *drop-shadow*), peta *polyline* mini di tengah, dan logo Velora di bagian bawah foto.

### 3. Agent Coding (Mobile Developer - Flutter)
**Tanggung Jawab:** Membangun aplikasi secara utuh berdasarkan spesifikasi analis dan visualisasi desainer.
* **Modul Peta & Lokasi (Fitur 1 & 2):** Mengintegrasikan `flutter_map` dan `geolocator`. Membangun fungsi yang menggambar titik koordinat baru ke dalam *List* yang di-*render* sebagai `PolylineLayer`.
* **Sistem Latar Belakang (Fitur 3):** Menerapkan paket *foreground service* agar Android OS tidak mematikan akses GPS saat ponsel terkunci.
* **Engine Metrik & Auto-Pause (Fitur 4 & 5):** Menerjemahkan logika *Auto-Pause* dari analis menjadi kode *stream listener* di Dart. Mengatur *stopwatch* agar hanya berjalan jika status pengguna sedang "bergerak".
* **Database Manager (Fitur 6):** Membuat *repository* menggunakan `sqflite` untuk *Insert*, *Read*, dan *Delete* data riwayat aktivitas.
* **Modul Social Share (Fitur 7):** Menggunakan `RepaintBoundary` untuk menumpuk antarmuka *widget* (foto kamera + logo + teks + garis mini) dan mengubahnya menjadi *byte array* (gambar PNG), lalu memanggil paket `share_plus` untuk membagikannya ke media sosial.

### 4. Agent Pengujian (QA & Testing)
**Tanggung Jawab:** Memastikan setiap fitur bekerja sempurna di lingkungan dunia nyata.
* **Functional Testing:** Menekan semua tombol antarmuka, memeriksa apakah data tersimpan di riwayat, dan memvalidasi apakah gambar *share* ke Instagram ter-ekspor dengan resolusi tajam.
* **Field / Live Testing:** Melakukan uji coba fisik dengan membawa ponsel berjalan, berlari, dan bersepeda untuk memastikan *polyline* tergambar sesuai jalan, serta kalkulasi jaraknya wajar/akurat.
* **Scenario Testing (Auto-Pause):** Menguji skenario berhenti tiba-tiba di jalan untuk melihat apakah aplikasi dengan cepat mendeteksi status "Pause" dan tidak menambah jarak kosong (*GPS drift*).
* **Battery & Memory Profiling:** Mengukur konsumsi baterai selama 1-2 jam perekaman tanpa henti. Jika baterai boros, meminta Agent Analisis/Coding untuk mengurangi interval ping GPS.

### 5. Agent DevOps & Rilis (Release Manager)
**Tanggung Jawab:** Mempersiapkan aplikasi untuk fase rilis dan distribusi ke ponsel pengguna.
* **Kompilasi & Build:** Mengatur konfigurasi *build.gradle* dan *AndroidManifest.xml* untuk memastikan semua izin yang diperlukan (Kamera, Lokasi Latar Belakang, Penyimpanan) sudah dideklarasikan dengan benar.
* **Signing & Security:** Membuat *Keystore* untuk membubuhkan tanda tangan digital pada file *Release* APK/AAB agar valid di OS Android.
* **App Optimization:** Menjalankan *ProGuard/R8 obfuscation* agar kode aplikasi aman dan ukuran file akhir APK (untuk dibagikan secara lokal/internal) menjadi sangat kecil.
