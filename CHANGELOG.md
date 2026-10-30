# Changelog: Velora Run & Ride

Semua perubahan dan riwayat rilis pada aplikasi **Velora** dicatat dalam dokumen ini.

## [v1.1.2] - 2026-10-31

### 🛠️ Perbaikan Modal Sensor BLE & Deteksi Nama Smartwatch

#### 📱 1. Modal Sensor BLE Fixed-Height (Anti-Amblas & Bebas Blank Grey Screen)
- Mengganti `DraggableScrollableSheet` dengan modal sheet solid berketinggian stabil (88% layar).
- Header tetap terkunci (*pinned*) di atas dengan judul "Sensor Detak Jantung (BLE)", status koneksi, dan tombol tutup `[ X ]`.
- Menghilangkan bug layar amblas / ruang abu-abu kosong saat menggulir ke bawah.

#### ⌚ 2. Integrasi Perangkat Terpasang di Ponsel (*Bonded / Paired Smartwatch*)
- Menambahkan pembacaan langsung perangkat yang sudah ter-pairing di Bluetooth HP via `FlutterBluePlus.bondedDevices`.
- Smartwatch pengguna (seperti Haylou Solar Neo 2, Garmin, Amazfit) langsung tampil di baris teratas dengan label `⭐ Smartwatch Terpasang di Ponsel (Paired)`.

#### 📡 3. Perizinan Android 12+ Anti-Sensor Nama (*neverForLocation*) & Filter Anonim
- Menambahkan atribut `android:usesPermissionFlags="neverForLocation"` pada izin `BLUETOOTH_SCAN` di `AndroidManifest.xml` agar OS Android tidak menyensor nama lokal smartwatch.
- Mengelompokkan perangkat anonim tanpa nama ke dalam menu lipat (*collapsible drawer*).

## [v1.1.1] - 2026-10-30

### ⌚ RILIS UTAMA (MAJOR): Integrasi Ekosistem Smartwatch, Sensor Detak Jantung (BLE HRM), 5 Zona HR & Pengaturan Terpadu

#### ⚙️ 1. Layar Pengaturan & Sensor Terpadu (`SettingsScreen`)
- **Pusat Pengaturan Komprehensif:**
  - Ditambahkan layar Pengaturan baru yang dapat diakses langsung melalui ikon gear di bilah atas *Profile & Records* (`ProfileRecordsScreen`) dan bilah atas layar pelacakan aktif (`TrackingScreen`).
  - Mengelompokkan pengaturan menjadi 4 bagian esensial: *Perangkat & Sensor Smartwatch*, *Profil Pengguna*, *Peta & Cache Offline*, serta *Tentang & Pembaruan*.
  - **Dialog Interaktif Pemanasan Cache Peta:** Dilengkapi progres unduhan ubin peta offline dan konfirmasi visual kesiapan data.
  - **Dialog Interaktif Periksa Pembaruan:** Memeriksa ketersediaan update langsung dari server GitHub Releases dengan indikator status verifikasi.

#### 📡 2. Pemindaian Bluetooth BLE Universal & Dukungan Smartwatch
- **Daftar Perangkat BLE Sekitar:**
  - Pemindaian terbuka tanpa filter UUID eksklusif agar jam tangan (Haylou Solar Neo 2, Amazfit, Mi Band, Garmin, Coros, Huawei) dan sensor dada langsung terdeteksi.
  - Radar pemindaian visual, jumlah perangkat, kekuatan sinyal RSSI (dBm), dan ikon cerdas (Smartwatch vs Chest Strap).
  - Deteksi otomatis Bluetooth HP dengan tombol pintasan untuk mengaktifkan Bluetooth langsung.
  - Panduan koneksi untuk jam tangan pintar dengan protokol proprietary.

#### 📥 3. Impor Aktivitas Mandiri Tanpa Bawa HP (Haylou, Garmin, Amazfit, Strava GPX)
- **Olahraga Mandiri Hanya Membawa Smartwatch:**
  - Pengguna dapat berolahraga (bersepeda, berlari, atau mendaki) hanya dengan mengenakan smartwatch tanpa perlu membawa HP.
  - Selesai berolahraga, ekspor file GPX dari aplikasi jam (Haylou Fun, Zepp, Garmin Connect) dan impor ke Velora dengan satu ketukan tombol di menu Pengaturan.
  - Velora mem-parsing seluruh rute GPS, elevasi naik, kecepatan, waktu, serta metrik detak jantung per titik (`<gpxtpx:hr>` / `<hr>`) dan menyimpannya ke database lokal SQLite.

#### 💓 4. Sensor Detak Jantung Bluetooth Low Energy (BLE GATT 0x180D) & Mode Simulasi
- **Koneksi Universal BLE Heart Rate Monitor:**
  - Mendukung pemasangan langsung dengan chest strap (Polar H10, Garmin HRM-Dual, Magene, CooSpo) dan smartwatch yang mendukung siaran detak jantung Bluetooth.
  - Membaca karakteristik standar Bluetooth SIG `0x2A37` (Heart Rate Measurement) dengan format 8-bit dan 16-bit BPM.
  - Dilengkapi fitur **Mode Simulasi Sensor HR** untuk demo dan pengujian real-time tanpa perangkat fisik.

#### 📊 5. Kalkulasi 5 Zona Detak Jantung Atlet (Z1 - Z5)
- **Visualisasi & Analisis Latihan Berbasis Zona:**
  - Menghitung ambang batas BPM berdasarkan formula $HR_{max} = 220 - \text{usia}$ (dapat dikustomisasi).
  - Klasifikasi 5 Zona:
    - **Z1 (50%-60%):** Pemulihan Santai (*Active Recovery*) - Biru Muda Cyan
    - **Z2 (60%-70%):** Daya Tahan & Bakar Lemak (*Aerobic Endurance*) - Hijau Neon
    - **Z3 (70%-80%):** Aerobik Tempo / Kardio - Kuning
    - **Z4 (80%-90%):** Ambang Batas Laktat (*Threshold*) - Oranye
    - **Z5 (90%-100%):** Maksimal VO2 Max (*Anaerobic*) - Merah Neon
  - Pada layar *ActivityDetailScreen*, sesi dengan detak jantung menyajikan kartu statistik HR rata-rata & puncak, bar distribusi multi-warna, durasi, dan persentase di setiap zona.
  - Pada layar *TrackingScreen*, live HUD menampilkan badge BPM dan zona secara real-time saat sensor terhubung.

#### 🌐 6. Ekspor GPX Standar Garmin & Strava TrackPointExtension
- **Interoperabilitas Penuh dengan Strava & Garmin Connect:**
  - File GPX yang diekspor dari Velora kini otomatis menyertakan namespace `xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"` dan tag `<gpxtpx:hr>`.
  - Saat file GPX Velora di-upload ke Strava, grafik detak jantung langsung tampil mulus dan presisi.

#### 🗄️ 7. Migrasi Skema Database SQLite (v2)
- Peningkatan versi skema database SQLite `DatabaseHelper` dari versi 1 ke versi 2 dengan penambahan kolom `detak_jantung` pada tabel `titik_koordinat` serta `avg_heart_rate` dan `max_heart_rate` pada tabel `aktivitas`, aman untuk data lama pengguna (*zero data loss*).

## [v1.0.22] - 2026-10-30

### 🚀 Peningkatan Responsivitas Kartu, Aksi Buka IG Otomatis & Hardening 5 Gaya Kartu

#### 📱 1. Tata Letak Kartu Clean & Stiker Adaptif Bebas Overflow (*Adaptive LayoutBuilder Scaling*)
- **Penskalaan Dinamis Berdasarkan Tinggi Kanvas:**
  - Komponen metrik kartu clean dan stiker transparan kini menggunakan `LayoutBuilder` yang secara adaptif menyesuaikan padding vertikal dan jarak antar blok metrik pada layar berukuran sempit.
  - Menghilangkan risiko garis belang kuning-hitam (*RenderFlex overflow*) pada rasio layar atau pratinjau compact.

#### ⚡ 2. Tombol Aksi Langsung ke Instagram (*Instant Story Launcher*)
- **Pintasan Langsung `[ BUKA IG ]` di Notifikasi Simpan:**
  - Saat pengguna menekan "SIMPAN STIKER PNG KE GALERI", notifikasi mengambang yang muncul kini dilengkapi tombol aksi cepat **`[ BUKA IG ]`**.
  - Pengguna dapat langsung melompat ke Instagram Story dengan sekali sentuh untuk segera menempelkan stiker di atas foto atau video tanpa harus mencari aplikasi Instagram secara manual.

#### 🛡️ 3. Pengerasan Logo Velora & Suite Pengujian Komprehensif 5 Gaya
- **Perlindungan Visual Logo Velora:**
  - Menambahkan pembungkus `FittedBox(fit: BoxFit.scaleDown)` pada logo Velora di kartu klasik untuk stabilitas rendering maksimal di berbagai perangkat.
- **Suite Pengujian Regresi Lengkap (191 Tests Passing):**
  - Mengintegrasikan berkas audit `test/social_share_styles_audit_test.dart` yang memvalidasi bahwa kelima gaya kartu (Clean, Transparan, Foto Saya, Peta, Klasik) merender tepat satu set metrik tanpa duplikasi widget teks.

## [v1.0.21] - 2026-10-30

### 📸 Kartu Berbagi Sosial Ala Strava & Stiker PNG Transparan untuk Instagram Story

#### 🎨 1. Redesain Visual Kartu Berbagi Clean Minimalis Persis Strava (*Strava-Style Clean Share Card*)
- **Sketsa Lintasan GPS Menjadi Grafik Hero Utama (*Hero GPS Route Silhouette*):**
  - Mengubah perataan dan ukuran rute GPS mini agar tampil besar, tebal, dan proporsional (mengisi hingga 40%+ ruang vertikal kartu).
  - Mengurangi padding margin kanvas dari 15% menjadi 5% (`paddingFraction: 0.05`), memaksimalkan bentang garis lintasan tanpa terpotong.
  - Ketebalan garis ditingkatkan menjadi 4.8px dengan warna oranye Strava menyala (`#FC5200`) dan bayangan lembut (*soft drop shadow*) untuk kontras optimal.
- **Tipografi Metrik Bersih dan Proporsional:**
  - Menggantikan teks metrik raksasa sebelumnya dengan ukuran yang rapi dan elegan ala Strava: label 14sp w600 (`Colors.white.withAlpha(220)`), nilai metrik 27sp w800.
  - Spasi vertikal antar blok metrik dirapatkan menjadi 14px terpusat di bagian atas kartu.
  - Teks identitas brand `VELORA` di bagian bawah dengan gaya font tegas 18sp w900 dan `letterSpacing: 4.5`.

#### 🪟 2. Mode Stiker PNG Transparan (*Instagram Story & Reels Transparent Sticker*)
- **Ekspor PNG 32-bit dengan Alpha Channel 100% Transparan:**
  - Penambahan opsi gaya kartu baru `ShareCardStyle.transparent`.
  - Mengosongkan warna latar belakang dan bayangan kontainer luar kartu pada saat ekspor, menghasilkan stiker PNG murni berisi metrik, rute oranye, dan teks VELORA.
  - Lapisan bayangan drop shadow pada teks putih dan rute oranye memastikan stiker tetap sangat kontras dan mudah dibaca saat ditempel di atas foto maupun video Instagram Story/Reels yang terang.
- **Pratinjau Papan Catur Transparansi (*Checkerboard Transparency Grid*):**
  - Layar pratinjau menampilkan kisi papan catur (*checkerboard pattern*) di belakang kartu saat mode Transparan dipilih, memberi visualisasi nyata bahwa latar belakang adalah transparan.
  - Kisi transparan berada di luar `RepaintBoundary` sehingga hasil simpan gambar tetap 100% transparan murni.

#### 💾 3. Simpan Langsung ke Galeri Ponsel (*Direct MediaStore Save to Pictures/Velora*)
- **Tombol Aksi "SIMPAN STIKER PNG KE GALERI":**
  - Integrasi native Android MediaStore (`saveImageToGallery`) untuk menyimpan stiker PNG langsung ke folder galeri resmi `Pictures/Velora/`.
  - Tombol aksi cepat dan tombol unduh AppBar untuk menyimpan stiker secara instan sehingga pengguna dapat langsung memilih stiker dari galeri saat membuat Instagram Story.
- **Bilah Pemilih Gaya Kapsul Horisontal yang Responsif:**
  - Baris selektor 5 gaya kartu (Clean, Transparan, Foto Saya, Peta, Klasik) dengan desain kapsul modern dan pengguliran horisontal yang mulus tanpa risiko *pixel overflow*.

## [v1.0.20] - 2026-10-29

### 🗺️ Panduan Rute GPX & Peringatan Keluar Jalur (GPX Route Breadcrumbs & Off-Course Alert)

#### 🧭 1. Panduan Rute GPX Fleksibel Berbasis Mode Manual (*Optional Route Breadcrumbs*)
- **Kendali Penuh di Tangan Pengguna (Bisa Digunakan, Bisa Tidak):**
  - Pengguna bebas memilih apakah ingin berlari/bersepeda/mendaki dengan rute panduan atau sekadar pelacakan bebas biasa tanpa rute panduan.
  - Tombol aksi mengambang khusus (`Icons.alt_route_rounded`) di sisi kanan layar peta yang menyala lembut dalam aksen indigo saat panduan rute sedang aktif.
  - Dialog pengaturan modal (`RouteGuideSheet`) yang memungkinkan pengguna menyalakan/mematikan visibilitas panduan di peta, memusatkan kamera ke rute, mengganti rute, atau menghapus panduan rute kapan pun diinginkan.

#### 📁 2. Impor Universal File GPX (.gpx) & Pemilihan dari Riwayat Latihan
- **Impor Berkas Eksternal GPX:**
  - Terintegrasi dengan sistem pemilih berkas perangkat (`FilePicker`) untuk memuat rute lintasan eksternal berformat `.gpx` atau `.xml` (Garmin, Strava, Wikiloc, AllTrails, Google Earth, dsb.).
  - Parser GPX berdaya tahan tinggi (`GpxService.parseGpx`) mengekstraksi elemen lintasan (`<trkpt>`), rute (`<rtept>`), maupun titik acuan (`<wpt>`), menghitung total jarak lintasan, serta akumulasi elevasi tanjakan.
- **Pemanfaatan Riwayat Latihan Tersimpan:**
  - Opsi instan untuk menggunakan kembali rute dari sesi latihan lari, sepeda, atau mendaki yang pernah tercatat di basis data SQLite lokal tanpa memerlukan koneksi internet.

#### 🛣️ 3. Visualisasi Elegan Rute Panduan di Atas Peta OSM (*Live Map Breadcrumbs Polyline*)
- **Lapisan Polyline Berlapis Indigo (*Subtle Indigo Dual-Layer Polyline*):**
  - Rute referensi digambar dengan gaya berlapis di bawah polyline neon GPS aktif: garis luar pendar ungu indigo (`#6366F1`) 9.0px dan garis inti tegas (`#818CF8`) 4.5px, memberikan panduan arah visual yang sangat jelas tanpa mengaburkan lintasan langsung atlet.
  - Dilengkapi pin penanda titik awal berwarna hijau (*Green Start Marker*) dan penanda titik finish berwarna merah (*Red Finish Marker*).
  - Fitur pemusatan kamera peta (*Fit Route Bounds*) untuk menampilkan bentangan penuh rute panduan dengan sekali sentuh.

#### ⚠️ 4. Deteksi Keluar Jalur Presisi Tinggi (*Cross-Track Distance & Off-Course Alert*)
- **Algoritma Jarak Segmen Lintas Rute Super Cepat ($O(N)$ Planar Projection):**
  - Algoritma perhitungan jarak terdekat ke segmen garis polyline berbasis proyeksi ekuirektangular lokal yang sangat hemat daya komputasi ($< 0.1\text{ milidetik}$ pada CPU ponsel).
  - Ambang batas keluar jalur cerdas (*Off-Course Threshold*): peringatan terpicu saat jarak pengguna ke garis rute melebihi 50 meter.
  - Ambang histeresis pemulihan (*On-Course Recovery*): peringatan otomatis nonaktif kembali saat posisi berada dalam rentang $\le 30\text{ meter}$.
  - Mekanisme anti-jitter (*Debounce Filter*): membutuhkan setidaknya 2 sinyal lokasi GPS berturut-turut di luar batas untuk menghindari alarm palsu akibat lompatan akurasi sinyal satelit.

#### 📳 5. Peringatan Haptik Getar & Banner Peringatan Melayang (*HUD Warning Banner*)
- **Banner Peringatan Melayang Berdenyut:**
  - Banner peringatan dinamis (`OffCourseBanner`) bertema amber-merah kontras tinggi di bagian atas layar dengan animasi denyut halus dan metrik jarak riil terhadap rute (cth: "PERINGATAN: KELUAR DARI JALUR • Anda berjarak 65 m dari lintasan rute").
  - Getaran haptik tegas (`HapticFeedback.heavyImpact()`) seketika saat pengguna menyimpang dari lintasan dan getaran konfirmasi saat pengguna berhasil kembali ke rute yang benar.

## [v1.0.19] - 2026-10-29

### 🥾 Mode Olahraga Mendaki (Hiking / Trekking) & Modal Badge Pemilih Olahraga

#### 🥾 1. Dukungan Penuh Cabang Olahraga Mendaki (*Hiking & Mountain Trekking*)
- **Penambahan `SportsType.hike`:**
  - Menghadirkan cabang olahraga ketiga **Mendaki (Hike / Trekking)** dengan ikon sepatu gunung (`Icons.hiking_rounded`) dan tema warna amber (`#F59E0B`).
  - Penyesuaian nama otomatis sesi latihan secara adaptif ("Mendaki Pagi Hari", "Mendaki Sore Hari", dst.) serta serialisasi ke basis data SQLite lokal.
  - Penambahan lencana rekor jarak khusus mendaki (*Best Efforts Hiking*): 1 km Trail, 3 km Trek, 5 km Mountain Trek, 10 km Summit Expedition, dan 15 km Ultra Trail.
  - Penyesuaian metrik HUD pada Video Flyover 3D dan kartu berbagi sosial (Clean Strava-Style) untuk aktivitas mendaki.

#### 🎯 2. Antarmuka Pemilih Olahraga Responsif (*Sport Selection Badge Modal*)
- **Pemicu Modal Cerdas pada Tombol 'MULAI LATIHAN':**
  - Menggantikan barisan chip statis di panel awal dengan tombol **"MULAI LATIHAN"** bersih, minimalis, dan modern.
  - Mengetuk tombol "MULAI LATIHAN" kini memunculkan *Modal Bottom Sheet* elegan berisi 3 kartu lencana olahraga:
    1. 🏃 **Lari (Run):** Aksen oranye dengan metrik utama Pace (`/km`), ritme langkah & jarak lari.
    2. 🚴 **Sepeda (Ride):** Aksen cyan neon dengan metrik utama Kecepatan (`km/h`) & jarak jelajah gowes.
    3. 🥾 **Mendaki (Hike):** Aksen amber dengan metrik utama Ketinggian (`mdpl`), elevasi lereng & tanjakan.
  - Sesi latihan langsung dimulai seketika saat salah satu lencana olahraga dipilih.

#### 📊 3. Dashboard Metrik Dinamis Khusus Aktivitas Mendaki
- **Metrik Sekunder Real-Time:**
  - Menampilkan metrik **ALTITUDE** (`mdpl`) secara langsung dari sensor ketinggian GPS.
  - Menampilkan metrik **ELEV GAIN** (`+m`) dan **PACE** (`/km`).
- **Toleransi Kecepatan Auto-Pause Menanjak:**
  - Menyesuaikan sensitivitas *Auto-Pause Detector* agar langkah pelan saat melintasi tanjakan terjal ($\ge 0.8\text{ km/jam}$) tidak memicu jeda otomatis keliru.

## [v1.0.18] - 2026-10-29

### 🚀 Pemuatan Instan Nama Jalan Putaran Pertama (Instant Road Geocoding & Early Pre-Warming)

#### ⚡ 1. Pemuatan Instan Nama Jalan di Detik Pertama (*Zero-Delay Road Transitions*)
- **Dua Tahap Resolusi Sinkron & Asinkron (*Two-Tier Fast Pass*):**
  - Mengimplementasikan evaluasi instan tahap 1 (0 ms) pada `RoadGeocodingService.detectRoadTransitions` menggunakan pencocokan memori cache dan koridor lokal offline sehingga penanda transisi jalan langsung tersedia seketika di frame pertama pemutaran rute (`onProgressUpdate`).
  - Menghilangkan kendala nama jalan yang kosong pada putaran pertama akibat balapan waktu (*race condition*) antara animasi rute (durasi 18 detik) dan *sequential HTTP requests* reverse geocoding OSM publik yang lambat (15-25 detik).
  - Melakukan *targeted upgrade* tahap 2 secara terarah hanya untuk titik jalan yang belum teridentifikasi dengan batas *timeout* ketat (1,2 detik per pemanggilan), memperbarui nama jalan secara halus (*seamless update*) tanpa menghentikan pemutaran rute.

#### 🛣️ 2. Pra-Pemuatan Nama Jalan di Detail Aktivitas (*Early Pre-Warming*)
- **Pra-Pemuatan Latar Belakang Otomatis:**
  - Memicu `RoadGeocodingService.precacheRoadTransitions` di latar belakang saat pengguna membuka halaman rincian latihan (`ActivityDetailScreen`), berjalan beriringan dengan pra-pemuatan ubin peta (*Smart Map Pre-Caching*).
  - Menjamin seluruh nama jalan di sepanjang rute latihan sudah ter-cache penuh di memori bahkan sebelum pengguna menekan tombol "PUTAR RUTE".

#### 🗺️ 3. Perluasan Koridor Jalan Populer Pontianak (*Rich Offline Corridors*)
- **Pencarian Offline Cepat 0 ms untuk Koridor Utama Pontianak:**
  - Menambahkan koridor rute olahraga Kota Baru, Pontianak Barat, dan Pontianak Selatan ke dalam basis data offline lokal: Jl. Uray Bawadi, Jl. Sutan Syahrir, Jl. Kesehatan, Jl. Harapan Jaya, Jl. Ampera, Jl. Prof. M. Yamin, dan Jl. Dr. Wahidin S.
  - Memastikan rute-rute populer di Pontianak langsung menampilkan nama jalan resmi secara akurat bahkan dalam mode offline tanpa koneksi internet.

## [v1.0.17] - 2026-10-29

### 🏔️ Optimalisasi Penanda Puncak Elevasi (Anti-Occlusion) & Desain Badge 3D Ramping Proporsional

#### 🏔️ 1. Penataan Ulang Pemberitahuan Puncak Elevasi Rute (*Anti-Occlusion Summit Banner*)
- **Pemberitahuan Puncak Ramping Tanpa Menutupi Pin Peta (*Zero Occlusion Floating Pill*):**
  - Mengubah desain banner perayaan puncak elevasi (`_buildPeakSummitBanner`) dari kotak tebal masif bertingkat dua menjadi kapsul horizontal ramping berteknologi *frosted-glass backdrop blur* (`[ 🏔️ PUNCAK ELEVASI • 53 mdpl ]`).
  - Menempatkan banner di zona aman atas (`top: padding.top + 52` pada mode normal, atau di bawah watermark pada mode rekam), menjauh dari cakrawala lintasan dan titik koordinat atlet sehingga pin 3D penanda puncak di peta tetap terlihat 100% utuh dan jelas tanpa terhalang.
  - Menyatukan penataan banner batas wilayah (`_buildRegencyBorderBanner`) dan puncak elevasi dalam kolom vertikal terpadu untuk mencegah tumpang tindih (*z-fighting*).

#### 🏷️ 2. Restrukturisasi Skala & Proporsi Badge 3D di Peta Lintasan (*Sleek 3D Badges*)
- **Penanda Puncak Gunung 3D Ramping (*3D Summit Milestone Pin*):**
  - Memperkecil dimensi penanda peta dari ukuran masif (190x84, scale 1.18) menjadi ukuran presisi dan proporsional (130x58, micro-scale 1.05 saat aktif, tiang 1.5px, ground anchor 5px), memberikan tampilan estetis dan tajam mirip pin 3D modern tanpa mendominasi tampilan jalan.
- **Penanda Ruas Jalan 3D Ramping (*3D Road Billboard Pin*):**
  - Menyesuaikan ukuran kotak penanda ruas jalan (`_buildRoadTrackPin`) dari lebar 220x76 ke 150x52 dengan tipografi dan ikon yang proporsional, mencegah penumpukan elemen di layar saat melintasi persimpangan atau ruas jalan.
- **Pita Batas Wilayah Kabupaten Ramping (*3D Regency Boundary Flag*):**
  - Memperhalus garis pita cahaya dan badge batas wilayah menjadi 130x38 dengan kontras warna yang elegan.

## [v1.0.16] - 2026-10-29

### 🎯 Sinkronisasi State Play/Pause Pemutar Rute (Route Replay) & Auto-Play Instan

#### 🎯 1. Perbaikan Desinkronisasi Tombol Play/Pause Pemutar Rute (Route Replay Screen)
- **Auto-Play Otomatis Saat Layar Dibuka (*Instant Route Replay*):**
  - Mengoreksi kendala inisialisasi di mana animasi rute (`_animController.forward()`) sebelumnya tidak terpicu saat membuka layar atau setelah pra-pemuatan ubin peta selesai akibat evaluasi kondisi `!_isPlaying` yang tidak terpenuhi saat `_isPlaying` diinisialisasi `true`.
  - Memastikan rute dengan titik koordinat $\ge 2$ (seperti berkas GPX sesi latihan) langsung berputar secara otomatis dan mulus.
- **Sinkronisasi Total Ikon Tombol dan Controller Animasi:**
  - Menghilangkan anomali tombol "II" (Pause) yang macet di mana rute tampak terhenti tetapi tombol menampilkan ikon Pause, sehingga sebelumnya memerlukan klik ganda (Pause lalu Play) untuk mulai berjalan.
  - Mengalihkan pengecekan `_togglePlayPause` ke status riil `_animController.isAnimating` yang terhubung langsung dengan engine animasi Flutter.
  - Satu ketukan pada tombol Pause ("II") kini langsung menjeda rute secara responsif.
  - Satu ketukan pada tombol Play ("▶") kini langsung melanjutkan pemutaran seketika tanpa jeda atau klik ganda.
- **Konsistensi Scrubbing Slider & Restart Rute:**
  - Memperbaiki pengembalian status pemutaran setelah pengguna menggeser (*scrubbing*) bilah linimasa rute menggunakan `_animController.forward()` yang tepat.
  - Menyempurnakan fungsi `_restartReplay` agar memutar ulang rute dari posisi awal (0.0) secara bersih dan sinkron dengan ikon kontrol.

## [v1.0.15] - 2026-10-29

### ⚡ Pemanasan Peta Cerdas (Smart Early Map Pre-Caching) & Optimalisasi Render Video Instan

#### ⚡ 1. Pemanasan Peta Otomatis Saat Aplikasi Dibuka (App Start Warm-Up)
- **Deteksi Koneksi Internet Aktif Cepat (*Instant Connectivity Check*):**
  - Mengimplementasikan `MapPrecacheService.hasInternetConnection()` untuk memeriksa kesiapan jaringan sebelum memicu permintaan data peta ke server.
  - **Jika Terhubung Internet Saat Membuka Aplikasi:** Sistem secara otomatis memanaskan ubin peta di latar belakang (*background thread*) tanpa mengganggu responsivitas antarmuka:
    1. Mengunduh ubin peta di sekitar lokasi pengguna saat ini (*current location / last known position*) agar layar pelacakan langsung siap tanpa kotak hitam (*zero black tiles*).
    2. Mengunduh dan menyimpan ubin koridor rute dari sesi latihan terbaru pengguna (`getLatestActivitiesWithCoordinates`), mencakup ubin satelit dan OpenStreetMap.
  - **Jika Tidak Ada Internet Saat Membuka Aplikasi:** Sistem secara cerdas melewati (*skip*) proses pemanasan untuk menghemat daya baterai dan kuota data seluler. Peta baru akan dimuat saat proses render nanti sesuai ketersediaan jaringan.

#### 🎬 2. Pra-Pemuatan Koridor Rute Detail & Replay (Detail & Replay Pre-Caching)
- **Pre-Cache Saat Layar Detail Dibuka:**
  - Saat pengguna membuka rincian aktivitas (`ActivityDetailScreen`), sistem langsung memulai pengunduhan ubin rute di latar belakang sehingga saat tombol `PUTAR RUTE` atau `Render Video` ditekan, seluruh ubin sudah tersimpan 100% di disk lokal.
- **Pra-Dekode GPU Koridor Rute Lengkap:**
  - Pada saat perekaman video (`RouteReplayScreen`), sistem tidak hanya melakukan pre-decode pada titik awal, tetapi memanaskan ubin di sepanjang koridor rute ke memori grafis (*GPU imageCache*), mencegah kedipan layar atau kotak hitam selama pergerakan kamera flyover.
- **Toleransi Render Mode Offline Cepat:**
  - Optimalisasi `downloadAndCacheRouteTiles`: jika perangkat berada dalam kondisi offline saat merender, sistem langsung beralih membaca seluruh ubin yang telah tersimpan di disk lokal tanpa menunggu jeda *network timeout* berulang.
- **Penyatuan Cache Ubin Peta Live Tracking:**
  - Mengintegrasikan `VeloraTileProvider` pada `LiveMapView`, memastikan peta pelacakan langsung dan pemutar rute berbagi satu direktori penyimpanan ubin lokal yang sama (`velora_tile_cache`).



## [v1.0.14] - 2026-10-27

### 🚀 Ketahanan Pembaruan Aplikasi (In-App Updater Resilience) & Aksesibilitas Penuh Video Flyover 3D

#### 🚀 1. Peningkatan Ketahanan Sistem Pembaruan In-App (Updater Engine Resilience)
- **Bypass Limit GitHub API via Raw Fallback:**
  - Mengimplementasikan fallback otomatis ke repositori publik (`raw.githubusercontent.com/.../pubspec.yaml`) jika pemanggilan GitHub API terkena batasan kuota (HTTP 403 Rate Limit), memastikan ponsel mendeteksi pembaruan secara instan tanpa terhalang pembagian IP seluler (CGNAT).
- **Penyimpanan Berkas Cache Eksternal Kompatibel Lintas OEM:**
  - Mengalihkan penyimpanan berkas APK pembaruan ke direktori cache eksternal (`getExternalCacheDirectories()`), memungkinkan aplikasi Package Installer bawaan vendor (Samsung, Xiaomi, Oppo, Vivo, Realme, dll.) membaca berkas melalui `FileProvider` tanpa kendala isolasi SELinux direktori privat.
- **Pemberian Hak Akses URI Eksplisit & Flag Intent Lengkap:**
  - Menambahkan `Intent.EXTRA_NOT_UNKNOWN_SOURCE` serta iterasi pemberian izin baca berkas `FLAG_GRANT_READ_URI_PERMISSION` ke seluruh paket installer Android untuk mencegah `SecurityException` pada Android 11+.
- **Opsi Alternatif Unduh Manual via Web Browser:**
  - Menambahkan tombol "Unduh Manual via Browser" pada `UpdateDialog` di layar utama pembaruan, saat unduhan terputus, maupun saat gagal memicu installer sistem, memberikan alternatif 100% bagi pengguna.
- **Feedback UI Real-Time & Penanganan Galat Jaringan:**
  - Memperbaiki penanganan status saat gagal menghubungi server pembaruan agar memberikan informasi koneksi yang jelas alih-alih keliru menyatakan aplikasi sudah di versi terbaru.

#### 🎥 2. Visibilitas Permanen & Peningkatan Aksesibilitas Video Flyover 3D & Putar Rute
- **Tombol Putar Rute Selalu Tampil:**
  - Tombol `PUTAR RUTE` di detail aktivitas kini selalu tampil; jika aktivitas memiliki kurang dari 2 titik GPS, sistem memberikan pesan petunjuk melayang (*floating SnackBar*) yang informatif.
- **Opsi Video Flyover Selalu Tersedia di Modal Pilihan:**
  - Opsi `Video Flyover Rute (MP4 Sinematik)` selalu ditampilkan pada modal berbagi dengan lencana status kondisi titik GPS.
- **Akses Cepat Video Flyover di Layar Berbagi Sosial:**
  - Menambahkan tombol aksi langsung video flyover pada AppBar layar pratinjau berbagi (`SharePreviewScreen`) untuk pembuatan video rute 3D sinematik dalam satu sentuhan.



## [v1.0.13] - 2026-10-27

### 📍 Pelacakan Lokasi Aktif, Suar GPS Neon Pendar & Tombol Pusatkan Lokasi Pintar

#### 📍 1. Peningkatan Titik Lokasi Peta & Tombol Pusatkan Lokasi Pintar
- **Desain Titik Lokasi Bercahaya (*Luminous Multi-Layer GPS Beacon*):**
  - Mengubah penanda lokasi saat ini menjadi suar pendar multi-lapis (halo pendar luar 44px, cincin pembatas bergaris 28px, dan titik inti neon cyan 16px dengan border putih tebal serta *center dot* presisi) yang kontras di tema gelap maupun terang.
- **Pemuatan Posisi Seketika (*Instant Zero-Latency Location*):**
  - Mengambil *last known position* dari cache sistem Android dalam hitungan milidetik saat menu pelacakan dibuka, mencegah peta terpaku di koordinat default saat inisialisasi satelit.
- **Stream Lokasi Pasif Mode Diam (*Idle State Location Stream*):**
  - Mengaktifkan stream pembaruan koordinat pasif berdaya hemat saat berada di mode diam (*idle*), sehingga titik posisi pengguna langsung mengikuti pergerakan nyata sebelum tombol "MULAI" ditekan.
- **Tombol Pusatkan Lokasi Pintar (*Smart Recenter with Auto Re-fetch*):**
  - Mengintegrasikan callback `onRecenter` pada `LiveMapView`: jika koordinat belum terkunci, aplikasi langsung memicu pencarian ulang satelit GPS, memberikan feedback status melayang (*floating SnackBar*), serta memvalidasi kesiapan hardware GPS & izin lokasi perangkat.
- **Pengujian Otomatis (148/148 Tes Lulus 100%):**
  - Penambahan rangkaian pengujian di `test/location_recenter_test.dart` untuk memvalidasi interaksi pusatkan lokasi, penanganan nilai `currentLocation == null`, serta siklus hidup stream posisi idle.

## [v1.0.12] - 2026-10-27

### 🌟 Clean Strava-Style Social Share, Typography Putih & Pembaruan Sistem Kartu

#### 🌟 1. Format Kartu Berbagi Clean Minimalis (Strava Style)
- **Latar Belakang Solid Hitam Pekat (*Pure Solid Black* `#000000`):**
  - Mengeliminasi distraksi visual untuk menghadirkan kontras maksimal pada metrik utama dan siluet rute.
- **Tiga Metrik Performa Inti Vertikal:**
  - `Distance`: Nilai jarak besar ultra-bold putih (`XX.XX km`).
  - `Pace / Speed`: Format clean lari (`M:SS /km`) via `formatCleanPace` atau kecepatan sepeda (`XX.X km/h`).
  - `Time`: Format waktu clean (`XXm XXs` atau `Xh XXm XXs`) via `formatCleanDuration`.
- **Siluet Rute Oranye Murni (*Markerless Polyline Silhouette*):**
  - Garis rute oranye menyala (`#FC5200` / `AppColors.primaryOrange`) dengan efek pendaran lembut tanpa pin titik start/finish.
- **Branding Teks VELORA Putih Tebal:**
  - Teks **`VELORA`** kapital tebal putih (*FontWeight.w900*) dengan *wide tracking* di bagian bawah kartu.
- **Pembaruan Layar Pratinjau Berbagi (`SharePreviewScreen`):**
  - Menjadikan mode `Clean` sebagai pilihan bawaan (*default*).
  - Menyediakan 4 opsi tab interaktif: `Clean`, `Peta`, `Foto Saya`, dan `Klasik`.
- **Pengujian Otomatis (132 Tes Lolos 100%):**
  - Penambahan rangkaian pengujian unit dan widget di `test/social_share_test.dart` untuk validasi snapshot Full HD dan perenderan mode lari/sepeda.

## [v1.0.11] - 2026-10-25

### 🛡️ Hepta-Layer Profile Engine, Native Android Channel & Resolusi Migrasi APK Lama

#### 🛡️ 1. Resolusi Total Masalah Profil Kembali Default Saat Pembaruan APK
- **Penanganan Bug Obfuscation R8:**
  - Memperbarui komponen penyimpanan ke versi stabil (v2.5.3) dan menambahkan aturan ProGuard Keep Rules untuk kelas Kotlin coroutines, mencegah pengecualian runtime saat build rilis.
- **Penyimpanan Terisolasi Mandiri (*Decoupled Resilience Pipeline*):**
  - Mengubah alur penyimpanan menjadi pipeline terisolasi penuh; jika salah satu lapisan mengalami kendala, penyimpanan berkas fisik dokumen dan basis data tetap dieksekusi 100%.
- **Persistensi Native OS Android (*Native Android SharedPreferences*):**
  - Mengintegrasikan lapisan ke-7 penyimpanan langsung ke API sistem operasi Android via Platform Channel dengan *synchronous disk commit*, kebal terhadap status memori dan pembaruan paket.
- **Penyimpanan Berkas Eksternal Aplikasi (`getExternalFilesDir`):**
  - Menambahkan cadangan berkas di direktori berkas eksternal aplikasi yang kebal pembaruan paket tanpa membutuhkan izin penyimpanan tambahan.
- **Rangkaian Uji Simulasi Migrasi APK Lama (100% Lulus):**
  - Menambahkan pengujian simulasi komprehensif yang memverifikasi pembacaan dan pemulihan otomatis data profil atlet dari seluruh versi aplikasi lama (v1.0.3.6 hingga v1.0.9).

## [v1.0.10] - 2026-10-24

### 👤 Mesin Permanensi Profil Multi-Lapis & Penanda Puncak Tertinggi 3D Aktif

#### 👤 1. Mesin Permanensi Profil Pengguna Kebal Pembaruan (Hexa-Layer Persistence)
- **Perlindungan Data Multi-Lapis (*Hexa-Layer Data Security*):**
  - Mengimplementasikan 6 lapis penyimpanan terpadu untuk memastikan nama profil atlet tidak pernah kembali ke nama default saat aplikasi diperbarui ke versi terbaru:
    1. **Cache Memori Utama:** Akses instan 0 ms saat aplikasi dijalankan.
    2. **Penyimpanan Preferensi Perangkat:** Sinkronisasi preferensi lokal terkelola.
    3. **Berkas Pendukung Sistem Terproteksi:** Penyimpanan berkas internal kebal pembersihan sistem operasi Android.
    4. **Berkas Dokumen Internal:** Berkas terisolasi aplikasi dengan penulisan langsung ke penyimpanan fisik (*immediate disk flush*).
    5. **Basis Data Lokal SQLite dengan Checkpoint Fisik:** Memaksa penulisan menyeluruh (*WAL Checkpoint*) sebelum pembaruan aplikasi dipasang.
    6. **Pencadangan Eksternal Mandiri:** Berkas cadangan di penyimpanan publik perangkat yang tetap aman meskipun aplikasi diinstal ulang.
- **Pemulihan Otomatis (*Self-Healing Sync*):**
  - Jika nama kustom terdeteksi pada salah satu lapisan penyimpanan, sistem secara otomatis mereplikasi dan memulihkan nama tersebut ke seluruh lapisan lainnya.
- **Persiapan Pra-Pemasangan Pembaruan (*Pre-Update Flush*):**
  - Seluruh data profil dituliskan dan dikunci ke penyimpanan permanen sebelum paket instalasi versi baru dijalankan.
- **Inisialisasi Cepat Bebas Kedip (*Zero-Flicker Preload*):**
  - Profil pengguna dimuat langsung sebelum antarmuka layar utama terbuka, menghilangkan kedipan nama default saat membuka profil maupun video riwayat.

#### 🏔️ 2. Penyempurnaan Penanda Puncak Tertinggi 3D Aktif
- **Pembersihan Penanda Titik Awal (*Start Peak Suppression*):**
  - Titik start rute dipastikan tidak pernah dianggap atau dilabeli sebagai puncak elevasi.
- **Penyaringan Lintasan Datar & Turunan:**
  - Lintasan datar atau rute turunan murni (*downhill*) tidak akan menghasilkan penanda puncak palsu; penanda puncak hanya muncul jika terdapat pendakian rute nyata.
- **Animasi 3D Aktif Saat Melintasi Puncak:**
  - Penanda puncak tidak ditampilkan sebelum dilewati, dan baru aktif menyala dengan animasi 3D (pop-up, elevasi naik, dan pendaran aura *sunset crimson*) tepat saat atlet melintasi titik puncak tertinggi.
- **Spanduk Perayaan Puncak Sinematik:**
  - Menampilkan lencana perayaan *"PUNCAK ELEVASI RUTE - Titik Tertinggi XX mdpl"* saat melintasi puncak tertinggi yang juga terekam pada video hasil ekspor.

## [v1.0.9] - 2026-10-22

### 🔒 Proteksi Layar Aktif (Wakelock Engine) & Pemulihan Render Video Tanpa Terhenti

#### 🔒 1. Proteksi Layar Tetap Aktif Saat Render Video (Wakelock Engine)
- **Pencegahan Layar Mati Otomatis (`FLAG_KEEP_SCREEN_ON`):**
  - Mengintegrasikan manajemen layar aktif tingkat sistem operasi Android (`WakelockService`) yang secara otomatis menjaga layar ponsel tetap menyala selama proses pembuatan video flyover berlangsung, sehingga sistem operasi tidak mematikan layar karena batas waktu tidur (*display timeout*).
- **Perlindungan CPU Latar Belakang (*CPU WakeLock*):**
  - Mengaktifkan `PARTIAL_WAKE_LOCK` bersamaan dengan `ForegroundService` agar prosesor perangkat tetap bekerja penuh memproses frame grafis dan penulisan berkas MP4.
- **Pelepasan Otomatis Pasca-Render:**
  - Segera setelah video selesai dibuat atau dibatalkan, proteksi layar aktif dilepas secara otomatis untuk mengembalikan batas waktu layar ponsel ke pengaturan hemat daya default pengguna.

#### 🛡️ 2. Pemulihan Permukaan Grafis Toleran Gangguan (*Fault-Tolerant Frame Capture*)
- **Penanganan Frame Tanpa Hang (*Frame Timeout Handling*):**
  - Menambahkan pembatasan waktu aman (*timeout protection*) pada `endOfFrame` dan sinkronisasi vsync sehingga proses render tidak akan pernah membeku (*freeze / hang*) jika terjadi gangguan transisi layar.
- **Toleransi Pemulihan Permukaan Grafis (*Auto-Retry toImage*):**
  - Perekaman snapshot RepaintBoundary kini dilengkapi toleransi pengulangan otomatis (*retry loop*) hingga 5 kali percobaan jika permukaan grafis (*surface*) sedang dijeda sejenak oleh sistem operasi, mencegah kegagalan ekspor prematur.
- **Penyelarasan Siklus Hidup Aplikasi (*Lifecycle Resumption*):**
  - Menyelaraskan *lifecycle observer* saat aplikasi kembali ke layar depan (*resumed*) untuk memastikan status render berlanjut secara mulus.
- **Informasi Antarmuka Relevan:**
  - Menampilkan lencana informasi non-teknis pada jendela progres ekspor: *"Layar dijaga tetap aktif agar pembuatan video selesai optimal"*.

## [v1.0.8] - 2026-10-22

### 🏔️ Simulasi Mendaki Gunung 3D (3D Dynamic Mountain Climbing Engine) & Pin Puncak Elevasi 3D

#### 🏔️ 1. Simulasi Mendaki Gunung 3D Sinematik
- **Kamera Mendongak Menatap Lereng (Dynamic Pitch & Altitude Lift):**
  - Kamera satelit 3D kini merespons kemiringan lereng tanjakan secara *real-time*. Saat atlet menempuh kontur tanjakan gunung (*grade percentage > 0%*), kamera secara dinamis mendongak menengadah menatap lereng ke atas (`+0.18 rad`) dan mengangkat sudut vertikal (`+32 px`), menghadirkan sensasi mendaki lereng gunung yang nyata dan sinematik.
- **Berkas Lintasan Oranye Api (Climb Polyline Glow Shift):**
  - Jalur rute aktif bertransisi dari kuning emas menjadi pendaran berkas oranye api menyala saat mendaki tanjakan gunung, memberikan visualisasi tenaga pendakian yang dramatis.
- **Pin Milestone Puncak Tertinggi 3D (`_buildMountainPeakPin`):**
  - Penanda titik puncak tertinggi (summit peak) kini terpasang dengan lencana 3D berwarna *sunset crimson*, lengkap dengan teks ketinggian dalam meter (`🏔️ PUNCAK XXXM`), tiang penanda 3D, dan titik suar penancap di aspal.
- **Indikator Kemiringan Tanjakan Dinamis di HUD:**
  - Panel statistik elevasi (pada tampilan normal maupun rekaman video) menampilkan persentase kemiringan lereng tanjakan secara langsung (`▲ +X.X%`) beserta aksen warna oranye saat menanjak.
- **Kalibrasi Billboard 3D Dinamis:**
  - Pin nama jalan dan pin puncak secara otomatis mengompensasi pergerakan sudut kamera mendaki gunung (`rotateX(0.70 - _currentClimbTilt)`) sehingga seluruh penanda selalu berdiri tegak lurus sempurna menghadap mata penonton.

## [v1.0.7] - 2026-10-22

### 🛣️ Animasi Kemunculan 3D Pin Jalan, Persistensi Permanen di Lintasan & Deduplikasi Tunggal

#### 🛣️ 1. Animasi 3D Kemunculan & Persistensi Permanen di Jalur
- **Animasi 3D Pop-Up Saat Memasuki Jalan:**
  - Penanda nama jalan kini muncul dengan animasi 3D hidup (`scale: 1.18`, elevasi mengambang 3D `-8px`, dan pendaran aura biru menyala) tepat saat atlet melintasi titik masuk jalan tersebut.
- **Persistensi Permanen Tanpa Hilang:**
  - Setelah dilewati oleh atlet, pin nama jalan **tidak pernah hilang** dan tetap tertancap rapi di atas aspal rute (`scale: 0.88`, `opacity: 0.88`) hingga akhir flyover perjalanan.
- **Deduplikasi Tunggal (Cukup 1 Kali Kemunculan):**
  - Mengimplementasikan sistem pelacak `seenRoadNames` sehingga setiap nama jalan yang sama hanya muncul tepat **1 kali** di sepanjang rute latihan, tanpa pengulangan atau penumpukan nama jalan yang sama.
- **Arsitektur Billboard 3D Berdiri Tegak Lurus:**
  - Menggunakan matriks counter-tilt `rotateX(0.70)` yang meniadakan kemiringan kanvas satelit sehingga pin berdiri tegak lurus sempurna (billboard 3D) menghadap kamera, lengkap dengan tiang penanda vertikal 3D, suar bercahaya, dan bayangan elips di atas aspal.
- **Multi-Source Geocoding:**
  - Integrasi cerdas OpenStreetMap Nominatim dan Photon API dengan penanganan menyeluruh untuk jalan, perumahan, pedesaan, kecamatan, dan landmark daerah.

## [v1.0.6] - 2026-10-22

### 🛣️ Penanda Nama Jalan Biru Solid di Jalur, Stabilisasi Peta Bebas Kotak Hitam & Pembaruan Sistem

#### 🛣️ 1. Penanda Nama Jalan Berwarna Biru di Atas Jalur Lintasan GPS
- **Badge Warna Biru Solid Sesuai Video Referensi (`_buildRoadTrackPin`):**
  - Mengimplementasikan badge nama ruas jalan berbentuk kotak kapsul **warna biru solid** (`Color(0xFF0284C7)` hingga `Color(0xFF0EA5E9)`) dengan teks putih tebal bersih (*bold white sans-serif*), segitiga penunjuk arah biru ke aspal lintasan, dan titik suar bercahaya (*ground beacon*) persis seperti pada video referensi 3D Map.
  - Pin membesar anggun (`scale: 1.10`) dengan pendaran cahaya biru saat atlet memasuki ruas jalan baru, lalu tetap tersemat rapi di peta (`scale: 0.90`, `opacity: 0.85`) sebagai *waypoint landmark*.
- **Pemuatan Peta Sempurna Bebas Kotak Hitam (*Zero Black Tiles Guarantee*):**
  - **Zero-Gap Corridor Pre-Caching:** `calculateRouteTiles` kini memeriksa 100% titik GPS tanpa melompati titik (*step = 1*), serta menambahkan radius tetangga 2 ubin (5x5 grid) pada Zoom 15, 16, dan 17 untuk menjamin seluruh layar rasio 9:16 terisi ubin offline tanpa sela.
  - **Pre-Decode GPU Warmup:** Sebelum proses perekaman dimulai, seluruh ubin di sekitar titik awal (KM 0) di-decode langsung ke memori tekstur GPU Flutter (`precacheImage`) dengan jeda stabilisasi 2 detik untuk menjamin kanvas telah terisi 100% gambar satelit sebelum frame pertama ditulis.
  - **Perpanjangan Jeda Frame Step:** Mengalokasikan 85 ms per frame render (dari sebelumnya 65 ms) agar GPU dan *pipeline* tekstur memiliki waktu yang melimpah untuk me-render ubin tanpa pernah memunculkan kotak hitam.
- **Deteksi Transisi Ruas Jalan Otomatis (`RoadGeocodingService`):**
  - Basis data *offline* instan jalur olahraga utama (Pontianak, Jakarta, Bandung, Surabaya, Bali) untuk waktu respons 0 ms tanpa konsumsi kuota data.
  - Dukungan *reverse geocoding* daring OpenStreetMap Nominatim level jalan (`zoom=18`) dengan *in-memory cache*.
- **Kendali Sebelum Render:**
  - Opsi "Nama Jalan di Jalur" dapat diaktifkan atau dinonaktifkan secara bebas sebelum proses render video dimulai melalui lembar opsi ekspor.

#### 📐 2. Tata Letak Proporsional & Bahasa Antarmuka Non-Teknis
- **Tata Letak Proporsional Video (`_enableSocialSafeZone`):**
  - Menyesuaikan posisi panel statistik berjalan (Jarak, Speed/Pace, Elevasi, Gain, Waktu) serta watermark agar selalu terlihat proporsional, rapi, dan tidak tertutup saat dibagikan ke media sosial.
- **Bahasa Menu Ringkas, Padat, dan Profesional:**
  - Seluruh teks opsi ekspor video telah disederhanakan dari istilah teknis menjadi bahasa fungsional yang elegan:
    - *"PENGATURAN TAMPILAN"*
    - *"Tata Letak Proporsional"* & *"Menyesuaikan posisi statistik agar selalu terlihat rapi saat dibagikan."*
    - *"Nama Jalan di Jalur"* & *"Menampilkan penanda nama jalan berwarna biru di rute."*
    - *"Ekspor Video Full HD"* (1080p jernih dan tajam) & *"Ekspor Video Ultra HD"* (4K sinematik)
    - *"Mode Rekam Layar"* & *"Bagikan Berkas Video"*

#### 🔄 3. Perbaikan Siklus Pembaruan Aplikasi Android
- **Penyelarasan `versionCode` dan `versionName`:**
  - Memperbarui konfigurasi ke `versionCode = 33` dan `versionName = "1.0.6"` pada `pubspec.yaml` dan `android/app/build.gradle.kts`.
  - Mengatasi kendala pembaruan berulang (*infinite update loop*) sehingga aplikasi langsung mengenali versi terbaru secara tepat tanpa meminta pembaruan kembali setelah dipasang.

#### 🛡️ 4. Pengujian & Kualitas Kode
- Seluruh pengujian unit dan widget (`flutter test`) berhasil lulus 100%, serta 0 isu pada `flutter analyze`.

## [v1.0.5.8] - 2026-10-20

### 🚀 Audit Menyeluruh & Perbaikan Terpadu: Tombol, Animasi, Aksi, dan Tampilan (4 Task Agents)

#### 🔘 1. Audit & Perbaikan Tombol serta Interaksi Pengguna (Task Agent 1)
- **Proteksi Anti Double-Tap (`_isActionProcessing`):** Seluruh tombol interaktif (Play/Pause, Replay, Speed 1x/2x/4x, Switch Gaya Peta, Bagikan Video) kini terlindungi dari penekanan ganda berturut-turut yang berpotensi memicu duplikasi proses atau *race condition*.
- **Feedback Visual Instan:** Setiap penekanan tombol berbagi (WhatsApp, Instagram, Aplikasi Lainnya, Kartu Ringkasan Foto) kini langsung memunculkan indikator interaktif (SnackBar dengan progress spinner) sehingga pengguna mendapatkan kepastian instan tanpa rasa hening atau keluar mendadak.
- **Peningkatan Hit-Test & Kenyamanan Sentuhan:** Memperluas area sentuhan minimum (*touch target*) pada kontrol pemutaran bawah dan tombol modal agar responsif untuk jempol pada layar ponsel berbagai ukuran.
- **Proteksi Tombol Kembali (`PopScope`):** Mencegah proses ekspor video terputus secara tidak sengaja ketika pengguna menekan tombol kembali Android, baik saat dialog penuh maupun saat diminimalkan ke latar belakang.

#### 🎬 2. Audit & Perbaikan Animasi serta Kamera Flyover (Task Agent 2)
- **Interpolasi Pergerakan Kamera Halus (60 FPS & 30 FPS Video):** Memperbaiki algoritma pergerakan kamera flyover rute agar bebas dari stutter, lonjakan koordinat (*coordinate jumping*), dan anomali nilai `NaN` atau pembagian nol pada titik koordinat berdekatan.
- **Kalkulasi Sudut Hadap Adaptif (*Bearing & Pitch*):** Orientasi kamera berputar halus mengikuti arah tikungan jalan dan tanjakan rute secara alami.
- **Penanganan Interupsi Gestur Peta:** Jika pengguna melakukan pan/zoom manual di tengah animasi, pemutaran berhenti sejenak secara mulus tanpa *glitch*, dan dapat dilanjutkan kembali dari titik terakhir.
- **Sinkronisasi Statistik Real-Time HUD:** Nilai kecepatan, elevasi, jarak tempuh, dan waktu bergerak disinkronkan secara presisi dengan posisi titik koordinat animasi saat ini menggunakan komputasi kumulatif `_cumulativeElevationGains`.
- **Transisi Halus Banner Batas Wilayah:** Pergantian banner perbatasan kabupaten/kota kini menggunakan animasi *fade in/out* yang proporsional (~2-2.5 detik) tanpa berkedip.

#### ⚙️ 3. Audit & Perbaikan Aksi serta Integrasi Sistem (Task Agent 3)
- **Adaptive Multi-Tier Hardware Encoder (4K Ultra HD -> 2K QHD -> Full HD 1080p -> HD 720p):**
  - Mengimplementasikan pipeline inisialisasi hardware video encoder bertingkat pada `VideoExportService`.
  - Membatasi dimensi terpanjang pada 3840 pixel (batas standar 4K UHD MediaCodec & batas aman alokasi GPU/OpenGL `GL_MAX_TEXTURE_SIZE`), mencegah error `IllegalArgumentException: unsupported format` atau `CodecException` pada layar rasio tinggi (19.5:9 atau 20:9).
  - Jika chipset perangkat (terutama seri midrange) tidak mendukung encoding native 4K, sistem secara otomatis beralih (*fallback*) ke 2K QHD atau Full HD 1080p tanpa pernah gagal (*zero failure rate*).
  - Menggunakan konfigurasi `ProfileLevel.any` untuk kompatibilitas mutlak di seluruh varian chipset Snapdragon, MediaTek Dimensity/Helio, dan Exynos.
- **Pemisahan Teks Notifikasi Android Foreground Service:**
  - Memperbaiki teks notifikasi saat fase unduh peta (*pre-caching*): kini menampilkan secara jelas informasi ubin peta (`Ubin X / Y • Mengunduh Citra Satelit HD`), membedakannya secara tegas dari fase perekaman frame video (`Frame A / B • Menulis ke Galeri HP`).
  - Menghilangkan anomali teks notifikasi "151/151 frame" saat pengunduhan ubin.
- **Penguatan Izin Berkas Native Android:** Penambahan izin `ClipData.newRawUri` dan dukungan paket WhatsApp Business (`com.whatsapp.w4b`) pada `MainActivity.kt`.

#### 📱 4. Audit & Perbaikan Tampilan serta Layout UI/UX (Task Agent 4)
- **Eliminasi Total `RenderFlex Overflow`:** Menata ulang tata letak HUD statistik, header action bar, watermark atlet, banner batas wilayah, dialog progres render, dan floating mini-banner agar responsif pada seluruh rasio layar (16:9, 18:9, 19.5:9, 20:9), mode landscape (800x360), serta layar sempit (lebar 320dp dan 360dp) dengan text scale factor hingga 1.5x.
- **HUD Statistik 5-Metrik Terpadu (JARAK, SPEED/PACE, ELEVASI, GAIN, WAKTU):**
  - Mengintegrasikan metrik kumulatif `GAIN` (+... M) bersama `ELEVASI` (altitude mdpl) secara terpisah dan presisi, dihitung via `_cumulativeElevationGains`.
  - Membungkus setiap kolom metrik dalam `Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: _buildHudMetricColumn(...)))` sehingga angka dan satuan terskala otomatis tanpa tumpang tindih.
  - Untuk olahraga lari (`SportsType.run`), otomatis beralih dari `SPEED (KM/H)` ke `PACE (/KM)`.
- **Isolasi Rekaman Video Bersih (`RepaintBoundary`):**
  - Mengisolasi boundary rekaman video MP4 hanya mencakup lapisan visual esensial (peta, rute atlet, watermark sinematik, banner perbatasan, dan HUD).
  - Memindahkan overlay transien (dialog pre-buffering, toast bantuan, dan floating mini-banner latar belakang) ke luar `_recordBoundaryKey` agar tidak ikut terpotong atau terekam ke dalam file video MP4 hasil ekspor.
- **Header Bar & Watermark Atlet Responsif:**
  - Menata ulang 6 tombol aksi header dengan `BoxConstraints(minWidth: 32, minHeight: 32)`, `VisualDensity.compact`, serta pembungkus `FittedBox` dan `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))` agar judul rute tidak overflow pada ponsel 360dp.
  - Watermark logo dan nama atlet pada Clean Record Mode kini dibatasi `maxWidth: screenWidth - 36` dengan `TextOverflow.ellipsis`.
- **Dialog & Bottom Sheet Anti-Overflow:**
  - Seluruh dialog modal (`_showStartRecordConfirmDialog`, `_showCleanRecordCompletedDialog`, dialog progres render, dan dialog konfirmasi keluar) kini dilengkapi `SingleChildScrollView`, `actionsOverflowDirection: VerticalDirection.down`, dan teks `overflow: TextOverflow.ellipsis`.
  - Bottom sheet opsi ekspor video dibatasi `ConstrainedBox(maxHeight: 90% screenHeight)` agar nyaman diakses pada orientasi landscape.
- **Dukungan Pembatalan Precaching Peta (`isCancelled`):** Menambahkan callback `isCancelled` pada `MapPrecacheService` agar proses pre-buffering berhenti seketika saat pengguna menekan "Lewati" atau keluar layar, menjamin kebersihan memori dan zero pending timers.
- **Pengujian Komprehensif (109 Tests Passed 100%):** Menambahkan test suite audit layout `test/route_replay_layout_audit_test.dart` menguji resolusi 320x568, 360x640, 360x800, 390x844, 800x360 landscape, text scale 1.3x-1.5x, serta seluruh alur dialog tanpa ada satu pun error atau overflow UI.

- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.8` (`versionCode = 31`).

## [v1.0.5.7] - 2026-10-20

### 📲 Perbaikan Tuntas Berbagi Video Flyover ke WhatsApp & Instagram (Bebas Force Close & Feedback Visual Instan)
- **Konfigurasi FileProvider Android Terintegrasi (`<root-path>`):**
  - Menambahkan konfigurasi `<root-path name="root" path="." />` pada `file_paths.xml` sehingga `FileProvider.getUriForFile` dapat memetakan berkas video MP4 yang tersimpan di direktori aplikasi internal (`app_flutter/velora_videos/`) ke `content://` URI resmi Android tanpa menimbulkan `IllegalArgumentException`.
- **Deklarasi Visibilitas Paket Android 11+ (`<queries>`):**
  - Mendaftarkan paket WhatsApp (`com.whatsapp`), WhatsApp Business (`com.whatsapp.w4b`), dan filter MIME type video (`video/*`) pada `<queries>` di `AndroidManifest.xml` agar `resolveActivity` dapat mendeteksi keberadaan aplikasi perpesanan dan media sosial secara akurat di Android 11 ke atas.
- **Izin Berkas Native ClipData & Dukungan WhatsApp Business:**
  - Melampirkan `ClipData.newRawUri("", uri)` serta pemanggilan eksplisit `context.grantUriPermission()` pada `MainActivity.kt` untuk memastikan aplikasi penerima (WhatsApp/Instagram) memperoleh hak baca berkas video secara aman dan legal tanpa kendala `SecurityException`.
  - Menambahkan deteksi otomatis untuk WhatsApp Business (`com.whatsapp.w4b`) jika WhatsApp standar tidak terpasang.
- **Indikator Visual & Fallback Pemilih Berbagi Sistem:**
  - Menampilkan notifikasi visual interaktif (SnackBar dengan animasi loading) saat tombol "Bagikan ke WhatsApp", "Bagikan ke Instagram", atau "Bagikan ke Aplikasi Lainnya" ditekan, memberikan kepastian langsung kepada pengguna bahwa proses berbagi sedang berjalan.
  - Menyediakan *graceful fallback* ke dialog pemilih berbagi sistem bawaan Android jika aplikasi tujuan tidak terpasang di perangkat.
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.7` (`versionCode = 30`).

## [v1.0.5.6] - 2026-10-20

### 📺 Peningkatan Ketajaman Video HD (Retina Mode Zoom 17) & Fitur Render di Latar Belakang (Non-Blocking)
- **Ketajaman Kristal HD Bebas Blur (Retina Mode Peta & Zoom 17):**
  - Mengaktifkan `retinaMode: true` pada engine peta `TileLayer`, menggandakan kerapatan piksel (*simulated retina*) dengan menempatkan 4 ubin beresolusi tinggi pada bidang yang sama (resolusi efektif 512x512).
  - Memperbarui pengunduhan ubin pada `MapPrecacheService.downloadAndCacheRouteTiles` ke **Zoom 17 HD** (ubin rute beresolusi tinggi) dan **Zoom 16** (ubin cakrawala perspektif 3D). Ubin citra satelit disimpan langsung di penyimpanan internal HP (`velora_tile_cache`).
  - Citra satelit dan jalanan kini tampil tajam, jernih, dan tidak lagi buram (*anti-blur*) saat dirender ke video 1080p maupun 4K.
  - Meningkatkan bitrate video hardware encoder ke **25 Mbps (Full HD 1080p)** dan **45 Mbps (4K Ultra HD)** menggunakan profil H.264 High Profile.
- **Ekspor Video di Latar Belakang (Bisa Sambil Melakukan Hal Lain):**
  - Menghilangkan dialog modal yang mengunci layar saat render. Menyediakan tombol **"LATAR BELAKANG"** pada dialog progres render.
  - Pengguna dapat meminimalkan proses render ke *floating banner* ramping di bagian bawah layar sehingga bebas menjelajahi peta, melihat grafik elevasi, atau mengecek metrik lintasan.
  - Terintegrasi dengan **Android Foreground Service** (`ForegroundServiceHandler.startOrUpdateRenderProgress`), menampilkan bilah progres langsung di bar notifikasi sistem Android. Pengguna dapat berpindah ke aplikasi lain (WhatsApp, Instagram, dsb.) atau mengunci layar sementara video tetap dirender di latar belakang dan disimpan otomatis ke Galeri (`Movies/Velora`).
  - Menambahkan proteksi `PopScope` agar pengguna tidak kehilangan proses render jika tidak sengaja menekan tombol kembali (*back*).
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.6` (`versionCode = 29`).

## [v1.0.5.5] - 2026-10-20

### 💾 Unduh Peta Langsung ke Penyimpanan Internal HP (VeloraTileProvider & Eliminasi Mutlak Kotak Hitam)
- **Pengunduhan Ubin Peta Langsung ke Penyimpanan Internal (Disk Storage):**
  - Mengimplementasikan `VeloraTileProvider` yang memprioritaskan pembacaan ubin citra satelit dan peta jalan langsung dari berkas lokal di memori internal HP (`velora_tile_cache`).
  - Menambahkan alur pengunduhan mandiri pada `MapPrecacheService.downloadAndCacheRouteTiles`: sebelum render video dimulai, sistem mengunduh seluruh ubin di sepanjang koridor lintasan (zoom 16 rute utama dan zoom 15 untuk horizon cakrawala perspektif 3D) dan menyimpannya sebagai berkas gambar lokal di ponsel dengan fitur *auto-retry* 3x.
  - Saat video dirender frame-by-frame, engine peta membaca 100% ubin dari penyimpanan lokal (kecepatan baca < 1 ms tanpa koneksi internet live), sehingga terbebas dari latensi jaringan, pembatasan server, atau pembuangan memori RAM.
  - Menjamin hasil video bersih sempurna, tajam, dan bebas mutlak dari kotak-kotak hitam (*zero black tiles*).
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.5` (`versionCode = 28`).

## [v1.0.5.4] - 2026-10-20

### 🚀 Perekaman Video Full Frame Tanpa Terpotong, Durasi Flyover 18 Detik Sinematik & Eliminasi Total Kotak Hitam Peta
- **Perekaman Video Full-Frame Utuh Bebas Terpotong:**
  - Menghilangkan pemotongan piksel (*cropping*) vertikal dan horizontal pada `VideoExportService`. Video MP4 kini dikodekan pada dimensi rasio layar asli perangkat secara penuh.
  - Menjamin 100% elemen antarmuka (HUD statistik kecepatan, elevasi, jarak, durasi di bagian bawah, watermark logo & nama atlet, banner batas kabupaten di bagian atas, serta seluruh area peta rute) terlihat utuh tanpa ada yang terpotong sedikitpun.
- **Peningkatan Durasi Animasi Flyover ke 18 Detik Sinematik:**
  - Menaikkan durasi animasi flyover video dari sebelumnya 8 detik (240 frame) menjadi **18 detik (540 frame pada 30 FPS)**.
  - Pergerakan kamera kini mengalir dengan ritme tenang, mulus, dan megah, sehingga lekukan rute, tanjakan, kecepatan, dan gerbang batas kabupaten dapat dinikmati dan dibaca dengan sangat jelas.
  - Banner batas wilayah kabupaten kini tampil secara proporsional (~2-2.5 detik) sepanjang video dan tidak lagi lenyap seketika.
- **Pembaruan Arsitektur Pre-Caching Peta (Bebas Kotak Hitam):**
  - Mengubah logika ekstraksi ubin pada `MapPrecacheService.calculateRouteTiles` agar mengambil ubin dasar di sepanjang 100% lintasan rute dari awal hingga akhir tanpa terpotong batas parsial.
  - Menambahkan ubin tetangga (ring-1) di sekitar koridor rute dengan kapasitas hingga 800 tile ke dalam memori RAM (500 MB cache limit).
  - Mengimplementasikan sistem unduh *concurrent worker pool* (10 antrean paralel) dengan fitur *auto-retry* dan *timeout* 45 detik, menjamin 100% ubin citra satelit rute telah tersimpan dan terdekode di RAM sebelum proses perekaman frame dimulai.
  - Menambahkan jeda pemanasan (*canvas warm-up*) 500 ms di KM 0 dan meningkatkan jeda rasterisasi per frame ke 65 ms, memastikan GPU dan engine peta merender seluruh tile tanpa ada kotak hitam (*missing black tiles*).
- **Pembaruan Versi Sistem:** Menaikkan versi Android ke `1.0.5.4` (`versionCode = 27`).

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
