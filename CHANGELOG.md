# Changelog: Velora Run & Ride

Semua perubahan dan riwayat rilis pada aplikasi **Velora** dicatat dalam dokumen ini.

## [v1.0.5.3] - 2026-10-19

### 🎬 Opsi Video 4K & Full HD 9:16 Anti-Blur Instagram, MediaStore Galeri Otomatis, Pita Batas Wilayah di Garis Rute & Perbaikan Menu Ganda
- **Opsi Ekspor Video 4K Ultra HD & Format 9:16 Anti-Blur Instagram:**
  - Menyediakan 2 pilihan resolusi ekspor video MP4 pada dialog berbagi:
    1. *Full HD 1080p (1080x1920) 9:16 (Rekomendasi Instagram Reels & Stories):* Format standar rasio 9:16 native dengan bitrate 20 Mbps yang dipotong secara presisi sehingga server Instagram tidak melakukan downscaling atau peregangan yang menyebabkan video buram/blur.
    2. *4K Ultra HD (2160x3840) 9:16 (Bitrate 35 Mbps):* Resolusi ultra tinggi untuk kejernihan kristal maksimal di layar beresolusi tinggi.
  - Memperbaiki MIME type pada intent berbagi langsung ke Instagram Story dan WhatsApp (`video/mp4` untuk video, bukan `image/png`), sehingga video diterima sebagai konten video bergerak utuh tanpa distorsi.
- **Integrasi Native Android MediaStore (Video Pasti Muncul di Galeri HP):**
  - Mengintegrasikan penyimpanan langsung melalui Android `MediaStore.Video.Media` di folder `Movies/Velora`.
  - Memanggil `MediaScannerConnection.scanFile()` secara otomatis segera setelah render selesai, menjamin video langsung terindeks dan muncul seketika di aplikasi Galeri bawaan ponsel (Google Photos, Galeri Samsung, Xiaomi, dsb).
- **Penanda Batas Wilayah Kabupaten Langsung di Atas Garis Rute:**
  - Mengubah penanda batas kabupaten/kota menjadi gerbang perbatasan (*boundary ribbon gate*) yang terpasang tepat di atas garis rute:
    - Pita garis bercahaya melintang di atas aspal/satelit.
    - Badge nama kabupaten/kota tebal berlatar gelap elegan (`🚩 KABUPATEN [NAMA]`) di tengah garis lintasan.
    - Ketika penunjuk atlet melintasi titik tersebut, penanda menyala terang dengan efek pendaran oranye neon.
- **Eliminasi Menu Ganda & Desain Ulang Lembar Berbagi Pasca-Render:**
  - Memperbaiki bug status listener animasi yang sebelumnya memicu dialog penyelesaian rekam layar bersih saat render video otomatis selesai, sehingga pengguna tidak lagi melihat dua kotak dialog yang saling menumpuk.
  - Menghadirkan satu *Bottom Sheet* berbagi yang elegan dan lengkap setelah render selesai dengan konfirmasi tersimpan di galeri, tombol langsung bagikan ke Instagram Story/Reels, WhatsApp, bagikan video umum, dan bagikan kartu ringkasan HD.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.3` (`versionCode = 26`).

## [v1.0.5.2] - 2026-10-19

### 🌄 Koreksi Sudut Perspektif 3D Maju ke Depan & Restorasi Rute Emas Menyala Multi-Layer Laser
- **Koreksi Arah Sudut Perspektif 3D Kamera (Forward Aerial Perspective):**
  - Mengoreksi arah transformasi kemiringan 3D kamera (`rotateX(-0.70)`) sehingga proyeksi perspektif bekerja sesuai penglihatan manusia dan simulator penerbangan: cakrawala di bagian atas layar menyempit secara natural menuju titik lenyap (*vanishing point*), sementara area dekat di bagian bawah layar melebar luas (*foreground perspective*).
  - Mengeliminasi distorsi perspektif terbalik yang sebelumnya membuat peta terlihat seolah-olah dipandang dari belakang atau terbalik.
  - Memperluas area kanvas dinamis (lebar 190%, tinggi 205%) dan menyesuaikan titik tumpu (*pivot alignment*) ke `FractionalOffset(0.5, 0.71)` sehingga seluruh layar tertutup sempurna oleh citra satelit tanpa celah hitam di sudut maupun sisi samping.
  - Menempatkan posisi marker atlet secara optimal di sepertiga bawah layar menghadap lintasan maju ke depan.
- **Restorasi & Peningkatan Garis Rute Emas Menyala Multi-Layer Laser:**
  - Mengembalikan tampilan rute aktif kuning emas khas Velora yang sangat disukai dengan arsitektur multi-layer:
    1. *Lapisan 1 (Outer Glow):* Pendaran aura neon amber lebar 14.0px (`#FFD600` alpha 130).
    2. *Lapisan 2 (Vibrant Gold Beam):* Berkas garis emas pekat 6.5px (`#FFE500`).
    3. *Lapisan 3 (White Hot Laser Core):* Inti sinar laser putih terang 2.2px (`Colors.white` alpha 230).
  - Garis rute kuning emas menyala ini kini aktif konsisten dan tajam di segala mode peta.
  - Menstandarkan penunjuk marker atlet dengan bola suar cahaya emas bersinar (*glowing gold beacon*) dan inti putih terang.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.2` (`versionCode = 25`).

## [v1.0.5.1] - 2026-10-19

### 🚩 Penanda Batas Wilayah Kabupaten/Kota Baru (Flag Pin Peta & Pop-up Badge Real-Time)
- **Deteksi Batas Wilayah Kabupaten/Kota Otomatis (`RegionGeocodingService`):**
  - Mengintegrasikan engine geolokasi wilayah cerdas offline yang mengenali batas wilayah kabupaten/kota di seluruh Indonesia (Kalimantan Barat seperti Kota Pontianak, Kab. Kubu Raya, Kab. Mempawah, dll., serta kota/kabupaten besar lainnya di Indonesia).
  - Dilengkapi mekanisme reverse geocoding online OpenStreetMap Nominatim dengan in-memory cache untuk mengenali batas administratif daerah mana pun di dunia.
- **Pin Bendera Batas Daerah di Atas Peta (`MarkerLayer`):**
  - Menampilkan penanda pin bendera 3D (`🚩 [Nama Kabupaten]`) langsung di atas titik permukaan jalan saat rute memasuki kabupaten/kota baru.
  - Pin dilengkapi styling glow neon berlatar gelap elegan yang terlihat jelas di atas foto citra satelit.
- **Banner Pop-up Badge Wilayah Real-Time:**
  - Saat posisi penunjuk atlet melintasi perbatasan, muncul banner mengambang: *"🚩 BATAS WILAYAH DAERAH • Memasuki [Nama Kabupaten/Kota]"*.
  - Banner tertangkap dan tampil secara sinematik baik dalam mode pemutaran langsung, mode rekam layar bersih, maupun dalam berkas ekspor video MP4 Full HD 1080p.
- **Kualitas Maksimum Tanpa Kompromi:**
  - Mempertahankan rendering MP4 Full HD 1080p, bitrate tinggi 18 Mbps, 30 FPS, dan pre-caching ubin citra satelit penuh tanpa pengurangan kualitas resolusi sedikit pun.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.1` (`versionCode = 24`).

## [v1.0.5.0] - 2026-10-19

### 🎬 Eliminasi Kotak Hitam Render, Kemiringan 3D Sinematik (~47°) & Perbaikan Dialog Simpan Galeri
- **Eliminasi Total Kotak Hitam (Black Tiles) pada Render Video:**
  - Menghubungkan engine `MapPrecacheService` secara langsung ke `TileProvider` native `flutter_map` sehingga seluruh potongan ubin citra satelit di sepanjang koridor rute diunduh dan didekode 100% ke RAM sebelum perekaman frame dimulai.
  - Memperbesar kapasitas memori `ImageCache` Flutter menjadi 250 MB (2500 entri) untuk mencegah eviksi ubin peta selama rendering 240 frame.
  - Menambahkan jeda rasterizer GPU `WidgetsBinding.instance.endOfFrame` dan sinkronisasi frame 30ms pada setiap langkah frame untuk memastikan rendering sempurna tanpa ubin kosong.
- **Penyempurnaan Kemiringan Peta Perspektif 3D Aerial (~47° Tilt):**
  - Mengatur sudut pandang kemiringan kamera menjadi **~47° (`rotateX(0.82)`)** dengan proyeksi perspektif `setEntry(3, 2, 0.001)`.
  - Menggunakan `LayoutBuilder` responsif yang memperluas kanvas peta (160% lebar, 158% tinggi) sehingga ubin satelit menutupi seluruh layar tanpa sudut/tepi hitam yang terpotong.
  - Menempatkan titik marker atlet secara stabil di posisi sepertiga bawah layar (Y = 61%), menghadap rute bentang alam luas ke depan menuju cakrawala.
  - Menghadirkan gradien atmosfer horison langit biru gelap (`Color(0xFF0F172A)`) di bagian atas kanvas untuk menciptakan efek cakrawala bumi fotorealistis.
- **Penyempurnaan Menu Berbagi & Dialog Konfirmasi Galeri:**
  - Memperjelas opsi ekspor video di bottom sheet: *"Ekspor Video MP4 (Simpan ke Galeri & Bagikan)"* dengan badge hijau *"OTOMATIS TERSIMPAN KE GALERI"*.
  - Menyematkan badge hijau konfirmasi *"Tersimpan Otomatis di Galeri Ponsel (Download/Velora/)"* pada dialog penyelesaian render.
  - Menambahkan tombol *"MENU OPSI LAIN"* pada dialog akhir agar atlet dapat kembali ke menu opsi berbagi (seperti Rekam Layar Bersih atau Kartu Statistik) tanpa kehilangan menu.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.0` (`versionCode = 23`).

## [v1.0.4.9] - 2026-10-19

### 🛰️ Citra Satelit Nyata HD, Garis Emas Menyala & Resolusi Video Full HD 18 Mbps (Bebas Blur)
- **Peta Citra Satelit Asli Resolusi Tinggi (ESRI World Imagery):**
  - Menghadirkan citra satelit fotografi udara nyata beresolusi tinggi (ESRI World Imagery) yang menampilkan atap rumah, pepohonan hijau, jalan aspal, persawahan, dan sungai asli dari angkasa.
  - Menghapus filter hitam-gelap default agar warna alami foto satelit tampil jernih, tajam, dan realistis.
  - Menambahkan tombol sakelar di bar header atas (`Icons.satellite_alt_rounded`) untuk beralih antara Citra Satelit HD dan Peta Jalan.
- **Garis Rute Kuning Emas Menyala (Signature Glowing Gold Route):**
  - Mengubah garis rute aktif menjadi kuning emas neon berkilau (`#FFD600` / `#FFE500`) dengan lapisan pendaran aura cahaya (*outer glow*) di atas foto satelit.
- **Penunjuk Ujung Rute Bola Putih Bersinar (Glowing White Beacon Orb):**
  - Penunjuk posisi atlet diubah menjadi bola cahaya putih bersinar terang dengan denyut aura emas di ujung garis rute, persis seperti gaya flyover sinematik.
- **Peningkatan Resolusi Video Ekspor (Full HD 1080p, Bitrate 18.0 Mbps, Bebas Blur):**
  - Menaikkan bitrate encoder video MediaCodec hardware menjadi **18.0 Mbps** (lebih dari 2x lipat) untuk menghilangkan kompresi blur.
  - Mengeliminasi pembesaran berlebih 1.45x dan menggantinya dengan kemiringan 3D natural (~20°) agar piksel tekstur ubin peta tetap 100% tajam pada resolusi aslinya.
  - Menjamin ubin peta ter-render penuh seketika (`instantaneous`) saat ekspor video tanpa efek transparansi/fade-in.
  - Sinkronisasi pipeline rasterizer GPU (`endOfFrame`) pada tiap frame sebelum penangkapan gambar.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.9` (`versionCode = 22`).

## [v1.0.4.8] - 2026-10-19

### 🌄 Sudut Pandang Kamera 3D Perspektif Menyamping (2.5D Oblique Tilt)
- **Sudut Pandang 3D Menyamping Sinematik:**
  - Mengimplementasikan proyeksi transformasi matriks 3D pada kanvas peta dengan kemiringan ~35.5° (`rotateX(0.62)`) dan distorsi kedalaman z-axis (`setEntry(3, 2, 0.0012)`).
  - Peta dan garis rute tampak rebah ke belakang menuju cakrawala (tampak dari atas menyamping layaknya pemandangan kokpit pesawat), menghadirkan efek kedalaman 3D yang elegan.
  - Bekerja 100% mandiri secara offline di perangkat tanpa memerlukan server cloud GPU.
- **Tombol Sakelar Perspektif 3D / 2D:**
  - Menambahkan tombol sakelar instan di bar header atas (`Icons.view_in_ar_rounded`) untuk beralih kapan saja antara mode **Perspektif 3D Menyamping** dan mode **Tampilan 2D Datar**.
- **HUD & Telemetri Tetap Tajam & Tegak:**
  - Panel statistik bawah (Jarak, Kecepatan, Elevasi, Waktu), pin milestone lintasan, dan watermark Velora tetap tegak lurus horizontal tanpa distorsi.
- **Dukungan Ekspor Video MP4 3D:**
  - Perekaman video animasi MP4 Full HD 1080p secara otomatis menggunakan perspektif 3D miring ini secara konsisten.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.8` (`versionCode = 21`).

## [v1.0.4.7] - 2026-10-19

### 🕊️ Flyover Rute Super Halus & Peta Stabil Sinematik Bebas Pusing
- **Peta Stabil Menghadap Utara (Anti-Pusing):**
  - Mengeliminasi putaran peta yang terlalu drastis saat atlet berbelok di persimpangan jalan, yang sebelumnya dapat menimbulkan rasa pusing bagi penonton.
  - Orientasi peta kini dijadikan default **Peta Stabil (Utara Tetap, rotasi 0.0)** sehingga daratan, nama jalan, dan kontur lingkungan tetap tegak dan tenang.
  - Mode POV kamera berputar tetap tersedia sebagai opsi manual via tombol AppBar bagi atlet yang menginginkannya.
- **Ikon Penunjuk Arah Atlet Dinamis di Peta Tenang:**
  - Ikon penunjuk arah atlet (`Icons.navigation_rounded`) berputar halus mengikuti sudut laju kendaraan (*smoothed bearing*), sementara peta di bawahnya tetap stabil.
- **Interpolasi Sub-Frame (Ultra Smooth Movement):**
  - Mengimplementasikan interpolasi posisi sub-frame antara dua titik GPS terdekat sehingga pergerakan kamera, ujung garis polyline, dan penunjuk avatar mengalir lembut (*silky smooth*) tanpa hentakan atau patah-patah.
  - Angka metrik telemetri (kecepatan, jarak, elevasi) juga terinterpolasi secara mulus di setiap frame.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.7` (`versionCode = 20`).

## [v1.0.4.6] - 2026-10-19

### 🎥 Sudut Pandang Kamera POV Flyover Dinamis & Video Full HD 1080p (Bebas Blur)
- **Kamera POV Dinamis (Chase Cam Bearing Follow):**
  - Mengimplementasikan sudut pandang kamera POV (*Point of View*) yang berputar secara mulus mengikuti arah laju kendaraan (*bearing follow*).
  - Peta di bawah atlet berputar halus secara dinamis dengan interpolasi sudut sehingga atlet selalu melaju menghadap ke atas layar (*forward-facing chase camera*).
  - Dilengkapi tombol sakelar kompas di AppBar atas untuk beralih antara **Mode POV Kamera Dinamis** dan **Mode Peta Datar (Utara)** kapan saja.
- **Video Full HD 1080p & Bitrate Tinggi 8.0 Mbps:**
  - Mengatasi kendala video buram (*blurry video*) dengan meningkatkan rasio piksel render RepaintBoundary secara adaptif menargetkan lebar 1080px (`effectivePixelRatio: 2.5 - 3.5`).
  - Bitrate video MediaCodec hardware H.264 ditingkatkan drastis menjadi **8,000,000 bps (8.0 Mbps)** dengan profile `ProfileLevel.highAutoLevel` untuk kualitas visual tajam tanpa artefak kompresi.
- **Penyimpanan Ganda & Otomatis Terdeteksi di Galeri Ponsel:**
  - Video MP4 yang diekspor kini secara otomatis disalin ke folder publik perangkat di `/storage/emulated/0/Download/Velora/` dan `/storage/emulated/0/Movies/Velora/`.
  - Berkas video langsung terdeteksi di aplikasi **Galeri Ponsel / Google Photos / File Manager**, siap dibagikan ke Instagram Reels, TikTok, YouTube Shorts, atau WhatsApp Status.

### 📊 Telemetri HUD Lengkap pada Video (Jarak, Speed/Pace, Elevasi & Waktu)
- Pada saat video dirender dan mode rekam layar bersih aktif, HUD telemetri 4-kolom berdesain *broadcast* ditampilkan dengan kontras tinggi di bagian bawah:
  1. 📏 **JARAK**: Jarak tempuh dinamis per frame (contoh: `5.24 KM`).
  2. ⚡ **SPEED / PACE**: Kecepatan aktual (`28.4 KM/H` untuk sepeda, atau `5'12" /KM` untuk lari).
  3. ⛰️ **ELEVASI**: Ketinggian elevasi aktual (+M).
  4. ⏱️ **WAKTU**: Stopwatch durasi latihan yang berjalan (`HH:MM:SS`).
- Posisi HUD ditinggikan dengan *safe margin* (`bottom: 36`) agar tidak tertutup oleh tombol navigasi atau *progress bar* pemutar video media sosial.

### 📤 Menu Bagikan Satu Pintu (Unified Share Modal)
- **Tombol Bagikan Ringkas & Terpadu (`ActivityDetailScreen`):**
  - Menggabungkan menu ekspor/berbagi ke dalam satu tombol `[📤 BAGIKAN]` di bagian bawah layar dan ikon share tunggal di AppBar.
  - Membuka lembar pilihan format modern (*Modal Bottom Sheet*) dengan opsi terpisah:
    1. 📸 **Poster Ringkasan Latihan (HD)**: Membuka layar pratinjau kartu foto & peta visual HD untuk Story dan Status.
    2. 🎬 **Video Flyover Rute (MP4 Sinematik)**: Langsung membuka layar pemutar dan otomatis memulai pembuatan video.
    3. 📄 **Ekspor Berkas GPS (GPX)**: Berkas data lintasan mentah.
- **Desain Kartu Sosial Media Lebih Bersih Tanpa Tagline:**
  - Menghilangkan teks tagline "RUN & RIDE" pada poster sosial media sehingga ruang kartu lebih lapang, bersih, dan fokus pada data statistik olahraga.

### 🛡️ Perbaikan Nama Profil Atlet (100% Persisten & Anti-Reset)
- **Sinkronisasi Memori & State Seketika:**
  - Perubahan nama atlet di dialog profil kini langsung diperbarui di layar secara instan (*zero latency*).
  - Menambahkan dukungan tombol **Enter / Done** pada keyboard Android untuk langsung menyimpan nama.
  - Mengintegrasikan *static in-memory cache* pada `UserProfileService` yang terikat kuat ke tabel database SQLite `user_settings` dan file cadangan lokal sehingga nama profil **dijamin tidak akan pernah kembali ke default saat aplikasi di-update**.

- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.6` (`versionCode = 19`).

## [v1.0.4.5] - 2026-10-19

### 🎬 Ekspor Video Flyover Rute Nyata (MP4 Otomatis 100% Offline)
- **Pembuatan Berkas Video MP4 Otomatis di Perangkat:**
  - Menghadirkan fitur baru **"Ekspor Video Flyover (MP4)"** pada `RouteReplayScreen` dan lembar aksi berbagi video.
  - Aplikasi kini secara nyata **merender dan menghasilkan berkas video `.mp4` asli** langsung di memori perangkat pengguna menggunakan encoder hardware bawaan Android (`MediaCodec`).
  - Tidak lagi mewajibkan pengguna untuk membuka control center dan menyalakan *Screen Recorder* secara manual—cukup tekan satu tombol, video langsung jadi!
- **Modal Progres Rendering Interaktif:**
  - Menampilkan dialog progres persentase yang informatif (`Frame 0/150 - 100%`) saat video sedang dienkode.
  - Video berdurasi ideal ~6.25 detik (150 frame pada 24 FPS), sangat pas dan siap pakai untuk WhatsApp Status, Instagram Reels, TikTok, YouTube Shorts, atau disimpan ke galeri ponsel.
- **Watermark Sinematik Eksklusif:**
  - Video flyover yang diekspor dilengkapi dengan watermark minimalis di pojok kiri atas berupa logo panah ganda `VELORA` dan nama atlet kustom pengguna.
- **Berbagi Langsung 1-Klik:**
  - Setelah render selesai, dialog hasil menampilkan nama berkas video MP4 dan tombol instan **`[BAGIKAN VIDEO SEKARANG]`** yang langsung membuka lembar berbagi sistem ke WhatsApp, Instagram Reels, Google Drive, atau simpan ke memori HP.

## [v1.0.4.4] - 2026-10-19

### 🛡️ Ketahanan Profil Atlet (Anti-Reset Saat Pembaruan Aplikasi)
- **Penyimpanan Profil Berlapis Tiga (Triple-Layer Persistence):**
  - Mengimplementasikan sistem penyimpanan persisten 3 lapis untuk nama profil atlet (`UserProfileService`):
    1. **SharedPreferences:** Akses cepat instan dengan sinkronisasi `prefs.reload()`.
    2. **File Cadangan JSON:** Berkas `velora_profile.json` tersimpan aman di direktori dokumen aplikasi.
    3. **Database SQLite (`velora_local.db`):** Tabel `user_settings` yang tahan banting dan memiliki daur hidup permanen sama seperti seluruh riwayat aktivitas pengguna.
  - Menambahkan konfigurasi `android:allowBackup="true"` pada `AndroidManifest.xml` agar data profil tidak terhapus saat pembaruan paket APK maupun pembersihan berkas cache.
  - Memastikan nama atlet kustom tidak akan pernah kembali ke nama bawaan *"Velora Athlete"* saat memperbarui aplikasi.

### 🎨 Desain Kartu Berbagi Lebih Ringkas & Hemat Ruang
- **Penghapusan Tulisan Tagline 'RUN & RIDE' pada Kartu Berbagi:**
  - Menghilangkan teks subtitle *'RUN & RIDE'* pada kartu berbagi media sosial (`SocialShareCard`) dan hanya menampilkan logo ikon panah ganda serta nama merk utama *'VELORA'*.
  - Menghemat ruang vertikal secara signifikan sehingga peta rute, foto latar belakang, dan statistik aktivitas tampil lebih lega dan dominan tanpa terdesak teks branding.
  - Memperbarui teks pesan bawaan saat berbagi tautan video agar lebih ringkas (*'• Velora'*).

### 📤 Opsi Berbagi Instan "BAGIKAN KARTU HD" Tanpa Perlu Perekam Layar
- **Solusi Berkas Galeri Kosong Saat Berbagi:**
  - Menjelaskan secara transparan pada dialog pasca pemutaran rute bahwa tombol *"Bagikan dari Galeri"* ditujukan jika pengguna menyalakan fitur *Screen Recorder* bawaan ponsel.
  - Menyediakan tombol utama **`[BAGIKAN KARTU HD]`** langsung di dalam dialog, sehingga pengguna yang tidak menyalakan perekam layar tetap dapat langsung membuat dan membagikan gambar poster rute Full HD beresolusi tinggi ke media sosial atau menyimpannya ke memori HP dalam 1 kali klik.

- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.4` (`versionCode = 17`).

## [v1.0.4.3] - 2026-10-18

### 🎨 Desain Menu Minimalis, Peta Bersih Bebas Halangan & Berbagi Video Praktis
- **Desain Menu Minimalis & Eliminasi Tombol Duplikat (`ActivityDetailScreen`):**
  - **Peta Bersih 100% Bebas Halangan:** Menghapus tombol mengambang dari atas peta. Area peta kini sepenuhnya bersih sehingga saat pengguna menyentuh pin penanda lintasan (KM 1, KM 2, Milestone Kecepatan Maksimum, Puncak Elevasi), keterangan lencana tampil utuh dan jelas tanpa terhalang tombol apa pun.
  - **Menu Aksi Ramping Dua Tombol:** Mengganti deretan 3 tombol bertumpuk yang memadati layar dengan satu bilah aksi elegan sejajar: `[▶ PUTAR RUTE]` dan `[📤 BAGIKAN]`. Ekspor GPX disematkan rapi pada ikon AppBar atas.
- **Minimalisasi Panel Kontrol & Lembar Berbagi (`RouteReplayScreen`):**
  - Menyederhanakan kontrol pemutar bawah: Menghapus ikon duplikat pelacakan kamera dan berbagi yang sebelumnya berdesakan di tengah, menyisakan tombol pemutar utama yang lega, responsif, dan mudah ditekan.
  - Lembar aksi berbagi video dibuat ramping dan fokus pada 2 opsi utama (Rekam Video Flyover & Bagikan Kartu Foto HD) ditambah tombol cepat berbagi video dari Galeri.
- **Panduan & Alur Berbagi Video Rekaman:**
  - Menambahkan dialog persiapan interaktif sebelum memutar rute untuk memberikan panduan jelas mengenai perekaman layar menggunakan *Screen Recorder* bawaan ponsel.
  - Dialog otomatis saat animasi selesai dengan tombol langsung *"BAGIKAN DARI GALERI"* yang membuka pemilih video dan meneruskannya ke WhatsApp, Instagram Reels, TikTok, atau penyimpanan file.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.3` (`versionCode = 16`).

## [v1.0.4.2] - 2026-10-18

### 🚀 Optimasi Performa & Pre-Buffering Peta (60 FPS di Semua HP)
- **Layanan Pre-caching Peta Sinematik (`MapPrecacheService`):**
  - Mengimplementasikan kalkulasi koordinat tile matematis $(x, y)$ pada zoom level lintasan dan mengunduh serta mendekode seluruh potongan peta rute ke dalam *in-memory cache* Flutter sebelum animasi diputar.
  - Mengeliminasi 100% beban koneksi jaringan dan *CPU image decoding* selama animasi berjalan, sehingga pemutaran flyover rute dan perekaman video berjalan di **60 FPS super mulus** tanpa *lag* bahkan di ponsel berspesifikasi rendah / HP lemot.
- **HUD Indikator Proses Pre-Buffering Interaktif:**
  - Menampilkan panel mengambang elegan *"Menyiapkan Peta Rute"* dengan bilah progres real-time (`LinearProgressIndicator`) dan metrik jumlah tile terunduh.
  - Tombol *"Lewati & Langsung Putar"* untuk pengguna yang ingin langsung menonton tanpa menunggu.
  - *Safety Timeout* (3.5 detik) yang otomatis memulai pemutaran jika jaringan internet lambat atau dalam mode *offline*.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.4.2` (`versionCode = 15`) untuk kelancaran auto-update.

## [v1.0.4.1] - 2026-10-18

### 🚀 Pembaruan Utama (Major Feature Update)
- **Rilis Minor Patch `v1.0.4.1` (Penyempurnaan Jalur Pembaruan):**
  - Menaikkan versi aplikasi menjadi `1.0.4.1` dengan `versionCode = 14` pada konfigurasi Gradle Android untuk mengatasi kendala pemasangan pembaruan dari rilis `1.0.4` dan memastikan auto-updater mendeteksi serta memasang berkas paket APK baru secara mulus.
- **Pemutar Rute Animasi Flyover Sinematik & Fitur Berbagi Video Sosial:**
  - Menghadirkan pemutaran animasi rute dinamis (*dynamic route flyover*) di layar `RouteReplayScreen` untuk menonton kembali aktivitas lari & gowes secara visual dan sinematik.
  - **Fitur Baru: Mode Rekam Layar Bersih (*Clean Screen Record Mode*):**
    - Menyediakan tombol cepat untuk menyembunyikan seluruh tombol antarmuka (header bar, scrubber, tombol navigasi) dan memutar rute dari awal secara bersih.
    - Menampilkan *HUD Telemetry Capsule* minimalis melayang berisi metrik aktif (Jarak, Kecepatan/Pace, Elevasi, Waktu) untuk rekaman video sinematik Full HD 60 FPS bebas gangguan tombol.
    - Ketuk layar kapan saja untuk mengembalikan kontrol antarmuka.
  - **Fitur Baru: Lembar Aksi Bagikan Video & Panduan Rekam Layar:**
    - Tombol aksi *"Rekam & Bagikan Video"* di header atas dan baris kontrol bawah.
    - Modal interaktif dengan opsi: **Mulai Mode Rekam Bersih**, **Bagikan Berkas Video dari Galeri** langsung ke WhatsApp, Instagram Reels, TikTok, atau YouTube Shorts, serta pintasan **Bagikan Kartu Ringkasan (Foto & Peta HD)**.
    - Panduan praktis 3 langkah merekam layar menggunakan *Screen Recorder* bawaan ponsel Android.
- **Peningkatan Kelancaran Rendering Peta (Bebas Kotak Hitam / Putih):**
  - **Kamera Throttling (Stabilisasi Request):** Membatasi pergerakan kamera otomatis agar tidak membanjiri request tile OSM (kamera diperbarui setiap interval stabil atau saat delta jarak >= 25 meter), mengeliminasi masalah *rate-limiting* dan pembatalan koneksi tile.
  - **Peningkatan Buffering & Transisi Halus:** Mengaktifkan `panBuffer: 2`, `keepBuffer: 6`, dan efek transisi lembut `TileDisplay.fadeIn(150ms)` dengan latar belakang solid gelap `AppColors.darkBackground` sehingga tampilan peta terasa mulus tanpa kedipan kotak hitam/putih.
  - Penyesuaian `initialZoom: 16.0` untuk sudut pandang rute yang lebih luas dan efisien dalam konsumsi data internet.
- **Penegasan Identitas Orisinal Velora:**
  - Membersihkan seluruh referensi brand eksternal di seluruh antarmuka dan basis kode aplikasi demi menjaga orisinalitas branding dan integritas produk Velora.
  - Label tombol ekspor rute distandarkan menjadi *"EKSPOR BERKAS GPX STANDAR"*.
- **Penyempurnaan Pemasang Paket APK Mandiri (In-App APK Installer):**
  - Mengaktifkan skema penandatanganan ganda `enableV1Signing = true` (JAR signing) dan `enableV2Signing = true` (APK Signature v2) untuk kompatibilitas penuh di seluruh varian Android (Xiaomi/MIUI, Samsung One UI, ColorOS, dsb).
  - Menambahkan deteksi otomatis izin pemasangan aplikasi tidak dikenal (`canRequestPackageInstalls()`) dengan pengalihan langsung ke Pengaturan sistem (`ACTION_MANAGE_UNKNOWN_APP_SOURCES`).
  - Memperluas pemetaan direktori penyimpanan `file_paths.xml` (cache, files, external files).

### 🧪 Penjaminan Kualitas & Pengujian Otomatis
- Menambahkan dan menyempurnakan `test/route_replay_test.dart` yang memverifikasi HUD statistik, tombol play/pause, pengubah kecepatan (1x-8x), toggle kamera auto-follow, lembar aksi bagikan video, dan aktivasi mode rekam bersih.
- Seluruh **66 pengujian otomatis** pada suite Velora lulus 100% dan analisis kode `flutter analyze` menghasilkan **0 issues**.

---

## [v1.0.3.6] - 2026-10-18

### 🚀 Fitur Baru & Peningkatan
- **Kustomisasi Nama Profil Atlet (Edit Nama Offline):**
  - Mengimplementasikan layanan lokal persisten `UserProfileService` berbasis `SharedPreferences` untuk menyimpan dan membaca nama atlet pengguna.
  - Memperbarui layar *Profil Atlet & Prestasi* (`ProfileRecordsScreen`) dengan antarmuka edit nama interaktif (ikon pensil dan dialog modal) lengkap dengan validasi teks (maksimal 28 karakter).
  - Nama profil tersimpan langsung secara offline dan ditampilkan secara dinamis di *header banner* profil atlet serta konfirmasi notifikasi *SnackBar*.
  - Mengintegrasikan nama atlet kustom ke dalam kartu berbagi media sosial (`SocialShareCard`) sehingga nama pengguna otomatis tertera berdampingan dengan tanggal aktivitas (contoh: `"Budi • Minggu, 18 Oktober 2026 • 08:30"`).

- **Penambahan Metrik MAX SPEED pada Kartu Media Sosial:**
  - Menampilkan metrik **MAX SPEED** (`session.maxSpeedKmh.toStringAsFixed(1) km/h`) pada baris statistik sekunder di kartu berbagi media sosial (`SocialShareCard`).
  - Baris statistik kini menyajikan 4 metrik lengkap: **DURASI** | **AVG SPEED / PACE** | **MAX SPEED** | **ELEVASI**, diatur dengan *divider* vertikal tipis dan tata letak berskala otomatis (*auto-scaled*) tanpa *layout overflow*.

- **Penandaan Lintasan Peta Langsung & Analisis Split (*On-Track Milestones & KM Splits*):**
  - Mengimplementasikan `TrackAnalysisService` untuk mengekstrak titik-titik penting di sepanjang lintasan GPS:
    - **KM Split Pins:** Menampilkan pin penanda bernomor (`1`, `2`, `3`...) langsung di atas garis lintasan rute pada setiap kelipatan 1.000 meter.
    - **Fastest KM:** Kilometer dengan catatan waktu tercepat otomatis dihiasi dengan lingkaran emas menyala (*Electric Amber*) dan lencana `⚡ TERCEPAT`.
    - **Max Speed Pin (⚡):** Menandai titik geografis persis saat kecepatan puncak tercapai.
    - **Puncak Ketinggian Pin (▲):** Menandai puncak elevasi maksimum rute.
    - **Pin Start (🟢) & Finish (🏁):** Menandai titik awal dan garis akhir lintasan rute.
    - **Sorotan Segmen 1K Tercepat:** Menyorot potongan lintasan 1 km tercepat dengan garis ganda neon emas menyala pada peta.
  - Menghadirkan interaktivitas sentuh: Mengetuk pin penanda di peta langsung memunculkan kartu mengambang (*bottom tooltip*) interaktif berisi rincian waktu, kecepatan split, pace, dan elevasi.
  - Menambahkan tombol kontrol mengambang (*floating toggle button*) di peta untuk menyalakan/mematikan penanda rute sesuai preferensi pengguna.
  - Menambahkan bagian baru **"SPLIT KILOMETER & REKOR LINTASAN"** di layar rincian aktivitas (`ActivityDetailScreen`) dengan tombol *toggle* sorotan segmen 1K.

### 🧪 Penjaminan Kualitas & Pengujian Otomatis
- **Peningkatan Suite Pengujian Unit & Widget:**
  - Menambahkan berkas pengujian baru `test/user_profile_test.dart` untuk menguji penyimpanan persisten `UserProfileService` dan skenario interaksi dialog edit nama pada `ProfileRecordsScreen`.
  - Menambahkan berkas pengujian baru `test/track_milestone_test.dart` untuk menguji ekstraksi split kilometer, penentuan KM tercepat, segmen tercepat, dan perenderan pin penanda lintasan pada `LiveMapView`.
  - Memperbarui `test/social_share_test.dart` untuk menguji kemunculan metrik `MAX SPEED` dan perenderan nama atlet kustom pada `SocialShareCard`.
  - Seluruh **63 pengujian unit & widget** lolos 100% dan 0 peringatan *linting* (`flutter analyze`).

---

## [v1.0.3.5] - 2026-10-17

### 🐛 Perbaikan Bug & Alur Pengguna (Hotfix Tombol Selesai & Reset Status)
- **Reset Otomatis Status Selesai ke Siap Mulai (*Clean State Reset*):**
  - Mengatasi kendala di mana setelah menekan *"Selesai"* $\to$ *"Simpan & Selesai"*, saat pengguna menekan tombol kembali (*Back*) dari layar rincian aktivitas, tombol kontrol di layar pelacakan utama masih menampilkan *"LANJUT"* dan mempertahankan data lama alih-alih menampilkan tombol *"MULAI LATIHAN"* dari awal (0.00 km).
  - Di `TrackingProvider.stopAndSaveSession()`: status pelacakan kini otomatis di-reset menjadi `TrackingStatus.idle` dan `_resetState()` dieksekusi segera setelah data sesi berhasil disimpan ke SQLite lokal.
  - Memperbarui widget `ControlButtons` agar kondisi `TrackingStatus.completed` maupun `TrackingStatus.idle` sama-sama menampilkan tombol utama *"MULAI LATIHAN"* dan pemilih jenis olahraga (*LARI* / *SEPEDA*).
  - Menghubungkan reload otomatis `HistoryProvider.loadActivities()` dan `AchievementProvider.loadAchievements()` saat sesi disimpan sehingga riwayat dan trofi langsung terbarui tanpa *refresh* manual.
- **Peningkatan Suite Pengujian Unit (*Test-First Verification*):**
  - Menambahkan berkas pengujian baru `test/session_completion_test.dart` yang menguji status kontrol tombol pada kondisi *idle*, *completed*, *tracking*, dan *paused*. Total **54 pengujian unit & widget** lolos 100%.

---

## [v1.0.3.4] - 2026-10-17

### 🐛 Perbaikan Bug & Optimasi Visual (Hotfix Latar Belakang Peta Share)
- **Perbaikan Matriks Warna Mode Gelap Peta (Eliminasi Zero-Clamping):**
  - Mengidentifikasi akar masalah visual di mana latar belakang peta OpenStreetMap tampak hilang/gelap total (*solid black*) saat dibagikan. Formula matriks warna lama (`-0.2, -0.7, -0.1, 0, 235`) membalikkan warna pastel OSM dan menjepit (*clamp*) semua fitur geografis (daratan `#F2EFE9` dan jalan raya `#FFFFFF`) ke nilai RGB `0, 0, 0` (hitam pekat) sehingga jalan dan daratan tidak dapat dibedakan.
  - Memperbarui matriks warna ke skema kontras tinggi ala *midnight slate*:
    - **Daratan:** Slate gelap elegan (`#293250`).
    - **Jalanan:** Garis jalan terang terlihat jelas (`#2F395D`).
    - **Tepian Jalan:** Batas kontras presisi (`#192241`).
    - **Perairan:** Biru laut *deep navy* (`#09244A`).
    - **Taman & Vegetasi:** Hijau pinus alami (`#18302F`).
- **Penyesuaian Gradasi Vignette Kartu Berbagi:**
  - Menghilangkan tutupan bayangan hitam pekat di bagian tengah kartu pada mode peta, memungkinkan 100% detail grafis peta OSM dan garis lintasan rute terlihat transparan dan jelas tanpa terhalang bayangan tebal.
- **Rendering Instan Tile Peta (*Instantaneous Tile Display*):**
  - Mengaktifkan `TileDisplay.instantaneous()` pada `TileLayer` peta share maupun live map, menghilangkan jeda animasi *fade-in* (100ms) saat tile berhasil diunduh.
- **Penyelarasan Waktu Tangkap Snapshot (*Capture Settling Delay*):**
  - Menyesuaikan durasi penundaan rendering di `SocialShareService.capturePng` menjadi 250ms sebelum *RepaintBoundary* diekstrak, memastikan dekoder bitmap raster tile telah terlukis sepenuhnya ke kanvas sebelum citra PNG dihasilkan.
- **Ekspor Kartu Beresolusi Tinggi Full HD 1080p+ (Anti-Blur / Anti-Pecah):**
  - Mengatasi kendala gambar tampak buram (*blur/pixelated*) saat diposting ke Instagram Stories atau WhatsApp Status. Sebelumnya, rasio piksel tetap (`pixelRatio = 2.0`) pada kartu pratinjau (lebar ~310dp) hanya menghasilkan citra berukuran ~620x1108 px sehingga buram saat di-stretch ke resolusi standar cerita ponsel (1080x1920 px).
  - Mengimplementasikan skala adaptif `(1080.0 / boundaryWidth).clamp(3.0, 4.5)` pada `SocialShareService.capturePng` guna menjamin lebar citra PNG hasil tangkapan **selalu minimal 1080 px (1080 x 1920 Full HD)**.
  - Mengaktifkan `retinaMode: true` pada `TileLayer` peta share untuk merender *tile* OpenStreetMap pada tingkat ketajaman 2x lebih rapat (*high-density retina*), menjadikan nama jalan, kontur rute, dan teks sangat tajam tanpa blur.
- **Peningkatan Suite Pengujian Unit (*Test-First Verification*):**
  - Menambahkan pengujian matematis validasi matriks warna `SocialShareCard.darkMatrix` untuk menjamin tidak adanya pemotongan ke nilai nol (*zero clamping*).
  - Menambahkan pengujian verifikasi resolusi citra PNG bahwa `capturePng` menghasilkan lebar $\ge 1080\text{ px}$ dan tinggi $\ge 1900\text{ px}$ (Full HD 9:16).
  - Seluruh **50 pengujian unit & widget** lolos 100%.

---

## [v1.0.3.3] - 2026-10-17

### 🚀 Fitur Baru & Peningkatan
- **Tombol Berbagi Khusus ke WhatsApp Story & Instagram Story:**
  - Menyediakan 3 tombol aksi langsung di layar pratinjau kartu media sosial:
    1. **WhatsApp (Status & Chat):** Tombol hijau resmi (`#25D366`) yang membuka langsung pemilih kontak dan "Status Saya" (*My Status*) di aplikasi WhatsApp dengan gambar kartu terlampir.
    2. **IG Story (Instagram Stories):** Tombol gradasi magenta (`#E1306C`) yang mengintegrasikan Intent resmi Meta (`com.instagram.share.ADD_TO_STORY`) untuk memuat kartu 9:16 langsung ke komposer cerita Instagram.
    3. **Lainnya:** Tombol *outline* elegan untuk membuka lembar berbagi sistem Android (*system share sheet*) ke aplikasi lain (Telegram, Twitter/X, Facebook, dsb).
  - Menambahkan deklarasi `<queries>` untuk paket `com.whatsapp` dan `com.instagram.android` di `AndroidManifest.xml` guna kompatibilitas penuh dengan Android 11+ (API 30+).

### 🐛 Perbaikan Bug Kritis & Penjaminan Kualitas (Hotfix)
- **Eliminasi LateInitializationError pada Mode Rilis Android:**
  - Mengidentifikasi akar masalah di mana properti `RenderRepaintBoundary.debugNeedsPaint` pada Flutter Engine diinisialisasi bertipe `late` di dalam blok `assert()`. Pada kompilasi rilis (`flutter build apk --release`), blok `assert` dihapus sehingga pemanggilan properti tersebut memicu `LateInitializationError: Field 'result' has not been initialized`.
  - Menghapus ketergantungan pada properti `debugNeedsPaint` dan menggantikannya dengan penundaan frame asynchronous yang 100% aman dieksekusi di lingkungan produksi.
- **Pencegahan RenderFlex Layout Overflow:**
  - Menambahkan `FittedBox` dengan `BoxFit.scaleDown` pada angka jarak besar (`68px`) dan baris metrik sekunder (`DURASI`, `PACE/SPEED`, `ELEVASI`) di `SocialShareCard`, menjamin tampilan kartu tidak pernah terpotong (*overflow*) pada ponsel berbagai ukuran layar atau skala font besar.
- **Pengujian Otomatis Menyeluruh (*Test-First Verification*):**
  - Membuat berkas pengujian baru `test/social_share_test.dart` untuk memverifikasi penangkapan snapshot PNG, header ajaib format citra (`0x89 0x50 0x4E 0x47`), dan penyimpanan berkas lokal.
  - Seluruh **46 pengujian unit dan widget** lolos 100% dan analisis kode bersih (**0 issues**).

---

## [v1.0.3.2] - 2026-10-17

### 🐛 Perbaikan Bug Minor (Hotfix)
- **Perbaikan Pemrosesan Ekspor Gambar Kartu (Social Share):** Memperbaiki kendala munculnya pesan peringatan *"Batal atau gagal memproses gambar kartu"* saat menekan tombol *BAGIKAN (IG / WA)* di layar pratinjau kartu media sosial:
  - **Sinkronisasi Frame Pipeline Flutter:** Menggunakan `WidgetsBinding.instance.endOfFrame` sebelum mengakses `RenderRepaintBoundary`, menghilangkan konflik ras (*race condition*) antara pembaruan status tombol (`_isSharing = true`) dan proses ekstraksi citra bitmap.
  - **Pemeriksaan Status Pohon Render (*Attachment Check*):** Menambahkan verifikasi `boundary.attached` dan penundaan adaptif jika `currentContext` sedang dalam fase mounting atau layout ulang.
  - **Penanganan Status `debugNeedsPaint`:** Menambahkan mekanisme penungguan hingga 10 frame secara aman jika pohon render masih berstatus *dirty* atau membutuhkan proses cat ulang.
  - **Toleransi Kegagalan Rasterisasi Peta (*3x Retry Loop*):** Menambahkan penanganan galat dan pengulangan hingga 3 kali percobaan pada `boundary.toImage()` untuk menjamin *tile* OpenStreetMap dan garis lintasan rute ter-rasterisasi sempurna tanpa *AssertionError*.
  - **Pembersihan Logika Status Berbagi (*Share Sheet Integration*):** Menghilangkan deteksi kegagalan palsu (*false negative*) pada platform Android ketika lembar berbagi (*ACTION_SEND*) dibuka atau dialihkan ke aplikasi target (WhatsApp / Instagram).
  - **Penyempurnaan Pesan Notifikasi UI:** Mengganti pesan ambigu *"Batal atau gagal memproses gambar kartu"* dengan notifikasi kesalahan spesifik berlatar belakang merah neon hanya jika terjadi pengecualian (*exception*) riil.

---

## [v1.0.3.1] - 2026-10-17

### 🐛 Perbaikan Bug Minor (Hotfix)
- **Perbaikan Freeze & Crash pada Fitur Bagikan Riwayat:** Memperbaiki kendala aplikasi membeku dan keluar saat menekan tombol share pada riwayat. Masalah ini diatasi dengan:
  - Pembatasan tingkat zoom kamera peta (`maxZoom: 17.0`, `minZoom: 4.0`) guna mencegah kalkulasi zoom tak hingga (`double.infinity`) pada sesi dengan sedikit titik koordinat atau pergerakan statis.
  - Fallback otomatis ke latar belakang minimalis/foto saat sesi memiliki kurang dari 2 titik GPS.
  - Penanganan kesalahan pembukaan kartu share dengan blok *try-catch* dan pesan interaktif yang aman.
  - Optimasi resolusi snapshot kartu (menggunakan *pixelRatio* 2.0 yang lebih efisien memori) serta sinkronisasi penundaan render sebelum ekstraksi *RepaintBoundary*.

---

## [v1.0.3] - 2026-10-17

### 🚀 Fitur Baru & Peningkatan (Latest Release)
- **Statistik Sepanjang Masa (All-Time Lifetime Stats):** Menampilkan rekor seumur hidup untuk Bersepeda & Lari secara terpisah (Tanjakan Tertinggi / *Biggest Climb*, Jarak Terjauh / *Longest Ride*, Kecepatan Puncak / *Top Speed*, Kecepatan Rata-Rata Terbaik, Pace Terbaik, serta akumulasi total kilometer, waktu, elevasi, dan sesi).
- **Pencapaian Terbaik (Best Efforts):** Ekstraksi rekor waktu tercepat pada jarak patokan standar (1K, 5K, 10K, Half Marathon 21.1K, 40K Time Trial) dengan algoritma sliding window GPS dan estimasi segmen.
- **Lemari Trofi Digital (Trophy Case & Badges):** 11 lencana prestasi offline (Gran Fondo 100km, Half Fondo 50km, Century Rider 160.9km, Speed Demon >30km/h, 5K/10K/Half-Marathon Finisher, Climbing Legend >=1000m, King of the Hill >=500m, Early Bird, Night Owl, Consistent Athlete) dengan kartu berdesain emas bercahaya dan progress bar.
- **Deteksi Waktu Aktivitas Cerdas (Time-of-Day Activity Naming):** Otomatis menamai kegiatan berdasarkan jam mulai secara akurat dengan standar teks bersih murni tanpa simbol gender (`♂` / `‍♂`) maupun emoji, serta menggunakan istilah baku **"Bersepeda"** (bukan *"Gowes"*):
  - `04:00 – 10:59`: *"Bersepeda Pagi"* / *"Lari Pagi"*
  - `11:00 – 14:59`: *"Bersepeda Siang Hari"* / *"Lari Siang Hari"*
  - `15:00 – 18:29`: *"Bersepeda Sore Hari"* / *"Lari Sore Hari"*
  - `18:30 – 23:59`: *"Bersepeda Malam Hari"* / *"Lari Malam Hari"*
  - `00:00 – 03:59`: *"Bersepeda Subuh"* / *"Lari Subuh"*
  - Prioritas catatan kustom: jika pengguna mengisi catatan khusus saat menyimpan sesi, catatan tersebut otomatis menjadi judul utama aktivitas.
- **Tab Baru "Profil & Rekor":** Menambahkan tab ketiga di bilah navigasi utama untuk mengakses profil atlet, rekor, dan trofi.

---

## [v1.0.2] - 2026-10-17

### 🚀 Fitur Baru & Peningkatan (Latest Release)
- **Pintasan Kontrol Notifikasi Status Bar & Lockscreen:** Tombol aksi kontrol cepat (`JEDA`, `LANJUT`, dan `SELESAI`) kini selalu tampil aktif dan dapat ditekan langsung dari bilah notifikasi maupun layar kunci ponsel saat aplikasi di-minimize.
- **Izin Notifikasi Runtime Android 13+ (POST_NOTIFICATIONS) & Saluran Notifikasi Prioritas Tinggi:** Memperbarui konfigurasi saluran notifikasi ke `HIGH` importance (`velora_tracking_channel_v2`) dengan visibilitas publik serta menambahkan dialog perizinan notifikasi otomatis saat aplikasi dibuka maupun saat sesi pelacakan dimulai.
- **Sinkronisasi Durasi Real-Time Notifikasi:** Notifikasi foreground kini memperbarui waktu berjalan setiap 2 detik secara hening (*onlyAlertOnce*) tanpa getaran atau bunyi berulang.
- **Kartu Berbagi Media Sosial (Default Map Background):** Menampilkan latar belakang peta OpenStreetMap Dark Mode secara otomatis dengan zoom presisi pada rute aktivitas, garis polyline oranye menyala, serta penanda Start & Finish. Pengguna juga dapat memilih foto pribadi atau mode minimalis.
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
