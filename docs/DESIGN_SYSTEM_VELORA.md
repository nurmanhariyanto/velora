# Panduan Sistem Desain & Visual Identity: Velora
## UI/UX & Graphic Specifications
**Aplikasi:** Velora: Run & Ride  
**Author:** Agent Desain (UI/UX Designer)

---

## 1. Identitas Visual & Filosofi Logo
Logo **Velora** melambangkan pergerakan, ketangkasan, dan arah yang tak henti ke depan (*Forward Momentum*).
- **Simbol:** Panah ganda bersudut tajam membentuk huruf alfabetik **'V'** (*Double Chevron V*).
- **Warna Ikonik (Signature Color):** *Velora Neon Orange* (`#FF6B00`) dipadu gradien api (*Electric Amber* `#FFA000` ke `#FF3D00`).
- **Tagline:** `RUN & RIDE` (dibuat dalam tipografi tebal sans-serif dengan spasi huruf lebar / *wide tracking*).

### Palet Warna Utama
| Nama Warna | Kode HEX | Peran Desain |
|---|---|---|
| **Velora Orange** | `#FF6B00` | Aksen tombol aksi utama, logo, mini-polyline rute sharing |
| **Electric Amber** | `#FF9100` | Gradasi highlight, status aktif / bergerak |
| **Neon Cyan / Blue** | `#00E5FF` | Garis polyline GPS langsung (*real-time track*) di peta |
| **Deep Charcoal** | `#121418` | Latar belakang tema gelap (*Dark Mode Background*) |
| **Card Surface** | `#1C2026` | Permukaan panel statistik dan kartu riwayat |
| **Surface Border** | `#2C333E` | Garis tepi halus komponen dan pemisah |
| **Text Primary** | `#FFFFFF` | Angka metrik utama, judul layar |
| **Text Secondary** | `#9EACB9` | Label satuan (km, min/km, km/h, elev) |
| **Success Green** | `#00E676` | Titik awal (*Start Marker*), status *Resumed* |
| **Warning Yellow** | `#FFD600` | Indikator *Auto-Pause* aktif |
| **Danger Red** | `#FF1744` | Titik henti (*Stop/Finish Marker*), tombol akhiri sesi |

---

## 2. Tipografi
Menggunakan font keluarga Modern Sans (Roboto / System Default sans-serif):
- **Display Metrik Utama:** Ukuran 48sp - 64sp, Weight: *Bold (w800)*, Angka berkarakter tabular untuk mencegah teks bergeser saat angka bertambah cepat.
- **Header Layar & Judul:** Ukuran 20sp - 24sp, Weight: *Semi-Bold (w600)*.
- **Label Metrik & Sub-teks:** Ukuran 11sp - 13sp, Weight: *Medium (w500)*, Uppercase dengan letter spacing 1.2px.
- **Body & Waktu:** Ukuran 14sp - 16sp, Weight: *Regular (w400)*.

---

## 3. Komponen Layar & Tata Letak

### 3.1. Layar Pelacakan Utama (*Live Tracking Screen*)
- **Peta Layar Penuh (OpenStreetMap):**
  - Menggunakan *tile layer* OSM standar dengan filter kecerahan / *dark tint* kontras tinggi agar garis neon terlihat menyala.
  - Kamera peta secara cerdas melakukan *re-centering* dan rotasi berdasarkan arah mata angin / heading pengguna.
  - Titik posisi saat ini ditandai dengan lingkaran biru berdenyut (*pulse animation*) dan panah arah.
  - Garis lintasan (*Polyline*): Warna `#00E5FF`, ketebalan `6.0px` - `8.0px`, dengan *capping* membulat.
- **Floating Map Controls (Atas/Kanan):**
  - Tombol Pusat GPS (*Recenter*): Mengarahkan kamera kembali ke koordinat pengguna saat ini.
  - Tombol Pilihan Mode: Saklar instan antara mode **Lari (Run)** dan **Bersepeda (Ride)**.
  - Tombol Ganti Lapisan Peta (*Tile Switcher*): Pilihan antara OpenStreetMap Standard dan CartoDB Dark/Voyager.
- **Banner Status Cerdas:**
  - Menampilkan badge lonjong saat status berubah: `● AUTO-PAUSED` (warna kuning menyala) atau `● RECORDING` (warna hijau cerah).
- **Bottom-Sheet Panel Statistik Ergonomis:**
  - Panel dengan sudut melengkung 28px di bagian bawah, memberikan akses satu tangan yang nyaman.
  - Grid metrik:
    - Baris 1: **Durasi Aktif** (00:23:45) & **Total Jarak** (4.82 km).
    - Baris 2: **Pace Rata-rata** (5'12" /km) / **Kecepatan** (24.5 km/h) & **Elevasi** (+42 m).
  - Tombol Kontrol Besar:
    - Tombol bulat berukuran 72px di tengah: **Start / Pause / Resume**.
    - Tombol sekunder: **Selesai / Stop** dengan konfirmasi dialog agar tidak tertekan tanpa sengaja.

### 3.2. Layar Riwayat Aktivitas (*History Screen*)
- Daftar kartu aktivitas dikelompokkan berdasarkan tanggal.
- Setiap kartu menyajikan:
  - Ikon olahraga (sepatu lari atau sepeda).
  - Ringkasan 4 metrik penting (jarak, durasi, pace/kecepatan, tanggal/jam).
  - Miniatur sketsa rute atau pintasan cepat untuk membuka rincian dan berbagi.

### 3.3. Template Desain Social Share (Instagram Story / WA)
Rasio kanvas: **9:16 (1080 x 1920 px)**.
- **Latar Belakang:** Foto jepretan pengguna dari kamera atau galeri, dengan gradasi *vignette* hitam halus (opacity 60% di atas dan 75% di bawah).
- **Bagian Atas (Header):**
  - Badge jenis olahraga (misal: "VELORA MORNING RUN").
  - Tanggal latihan (contoh: "17 Oktober 2026, 06:15 WIB").
- **Bagian Tengah-Atas (Statistik Sorotan):**
  - Angka jarak spektakuler (contoh: `10.25` dengan label satuan `KILOMETER`).
  - Baris statistik sekunder: Durasi `00:54:12` | Pace `5'17" /KM` | Elevasi `+84M`.
  - Teks menggunakan efek bayangan tebal (*strong drop shadow*) agar terbaca jelas di atas foto apapun.
- **Bagian Tengah (Mini Polyline):**
  - Bentuk rute hasil pelacakan digambar dengan garis tebal oranye Velora (`#FF6B00`) di atas kanvas semi-transparan.
  - Titik awal hijau neon dan titik akhir merah.
- **Bagian Bawah (Footer & Branding):**
  - Ikon panah ganda Velora dan teks **VELORA : RUN & RIDE**.
  - Garis aksen oranye penegas identitas aplikasi.
