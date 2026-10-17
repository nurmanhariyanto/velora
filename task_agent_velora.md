# Rencana Pembagian Kerja: Proyek Aplikasi Velora (Mode Lokal)

Dokumen ini merinci pembagian tugas dan tanggung jawab untuk masing-masing agen/peran dalam pengembangan **Velora: Run & Ride**, aplikasi pelacak kebugaran berbasis GPS (Android/Flutter) yang berjalan secara lokal tanpa server.

## 1. Agent Analisis (Systems & Requirements Analyst)

**Fokus:** Mendefinisikan spesifikasi teknis, algoritma, dan struktur data aplikasi Velora.

**Tugas Utama:**

* **Definisi Fitur:** Menulis *Product Requirement Document* (PRD) yang mencakup batasan aplikasi (mode lokal), spesifikasi peta OpenStreetMap (OSM), dan alur berbagi ke media sosial.
* **Desain Struktur Database (SQLite):** Merancang skema tabel relasional lokal.
  * Tabel `Aktivitas` (id, jenis_olahraga, waktu_mulai, waktu_selesai, total_jarak, elevasi_total).
  * Tabel `Titik_Koordinat` (id, aktivitas_id, latitude, longitude, elevasi, timestamp).
* **Pemodelan Algoritma:**
  * Menentukan parameter untuk algoritma *Haversine* dalam perhitungan jarak.
  * Menetapkan *threshold* (ambang batas) kecepatan untuk pemicu fitur **Auto-Pause** (misal: < 2km/jam selama 3 detik).
  * Menentukan interval pengambilan GPS (misal: setiap 3 detik atau setiap perpindahan 5 meter) untuk optimasi baterai.

## 2. Agent Desain (UI/UX Designer)

**Fokus:** Merancang antarmuka pengguna, pengalaman pengguna, identitas visual (Branding), dan aset aplikasi.

**Tugas Utama:**

* **Identitas Visual (Branding):** Mengimplementasikan logo **Velora** (ikon panah ganda 'V' berwarna oranye khas) ke seluruh aset aplikasi.
* **Wireframing & Prototyping:** Membuat *mockup* interaktif menggunakan Figma.
* **Desain Peta (Map Styling):** Menentukan gaya visual peta OSM dasar (tema *muted* atau gelap) dan gaya *Polyline* rute GPS (garis biru neon dengan transparansi dan ketebalan spesifik).
* **Desain Panel Navigasi:** Merancang panel *bottom-sheet* untuk statistik *real-time* (Kecepatan, Pace, Jarak, Waktu) dan desain tombol besar (Play/Pause/Stop).
* **Desain Template Berbagi (Social Share):** Merancang tata letak *overlay* rendering gambar lokal:
  * **Top/Tengah:** Teks metrik (Jarak, Kenaikan Elev, Waktu) dengan efek bayangan (vignette/drop shadow) agar kontras.
  * **Tengah:** Mini Polyline berwarna oranye untuk menampilkan bentuk rute perjalanan.
  * **Bawah:** Logo "VELORA: RUN & RIDE" ditempatkan di bagian bawah tengah gambar.

## 3. Agent Coding (Mobile Developer - Flutter)

**Fokus:** Mengimplementasikan kode, logika, dan menyatukan seluruh komponen aplikasi Velora.

**Tugas Utama:**

* **Setup Lingkungan & Pustaka:** Menginisialisasi proyek Flutter dengan package name `online.nurmancloud.velora`. Memasang pustaka utama (`flutter_map`, `geolocator`, `sqflite`, `share_plus`, `image_picker`).
* **Integrasi Peta & OSM:** Menampilkan *TileLayer* OpenStreetMap dan mengonfigurasi *MapController* agar kamera mengikuti pergerakan kursor pengguna.
* **Layanan Latar Belakang (Foreground Service):** Menulis *native channel* atau menggunakan paket Flutter untuk memastikan GPS tetap merekam saat layar mati atau aplikasi di-*minimize*.
* **Logika Pelacakan (Tracking Logic):** Mengimplementasikan filter GPS, perhitungan jarak *real-time*, dan sistem logika *Auto-Pause*.
* **Fitur Ekspor Gambar (RepaintBoundary):** Membangun komponen UI tersembunyi yang menumpuk foto jepretan pengguna dengan data statistik dan logo Velora, lalu mengubahnya menjadi file gambar (PNG) untuk dibagikan ke Instagram/WhatsApp.

## 4. Agent Pengujian (QA & Testing)

**Fokus:** Memastikan aplikasi berjalan bebas *bug*, akurat, dan tidak menguras baterai ponsel.

**Tugas Utama:**

* **Pengujian Fungsional:** Memastikan tombol berfungsi, *auto-pause* terpicu tepat waktu, dan render gambar fitur *share* menghasilkan resolusi yang tajam.
* **Pengujian Lapangan (Field Testing):** Menguji aplikasi secara fisik di luar ruangan (misal: rute Jl. Danau Sentarum) untuk lari dan bersepeda guna memvalidasi akurasi GPS.
* **Pengujian Performa (Stress Test):** Mensimulasikan data rute panjang untuk melihat apakah peta menjadi *lagging*. Jika ya, menginstruksikan penerapan algoritma *Douglas-Peucker* (penyederhanaan garis).
* **Pengujian Baterai:** Memantau tingkat konsumsi daya baterai selama 1 jam penggunaan konstan di latar belakang.

## 5. Agent DevOps & Rilis (Release Manager)

**Fokus:** Otomatisasi proses *build*, manajemen versi, dan distribusi aplikasi.

**Tugas Utama:**

* **CI/CD Pipeline:** Mengatur *workflow* di GitHub Actions/GitLab CI untuk kompilasi otomatis.
* **Manajemen Keystore & Signing:** Membuat dan mengamankan kunci untuk proses *build* aplikasi Android (.APK) versi *Release*.
* **Optimasi Build:** Melakukan *obfuscation* dan memangkas ukuran aplikasi agar APK sekecil mungkin.
* **Distribusi Internal:** Mengunggah versi beta ke platform (seperti Firebase App Distribution) agar tim penguji (*QA*) dapat mengunduh dan menguji coba Velora.
