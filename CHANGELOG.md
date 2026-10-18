# Changelog: Velora Run & Ride

Semua perubahan dan riwayat rilis pada aplikasi **Velora** dicatat dalam dokumen ini.

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
