# Product Requirement Document (PRD) & Spesifikasi Arsitektur Teknis
## Velora: Run & Ride (Mode Lokal)
**Package ID:** `online.nurmancloud.velora`  
**Versi:** 1.0.0  
**Status:** Architecture & Requirements Freeze  
**Author:** Agent Analisis (Systems & Requirements Analyst)

---

## 1. Pendahuluan & Visi Produk
**Velora: Run & Ride** adalah aplikasi pelacak kebugaran dan rute GPS mandiri (*standalone*) berbasis Flutter untuk platform Android. Aplikasi ini beroperasi 100% secara lokal (*offline-first*), tanpa bergantung pada server *backend*, API eksternal berbayar, atau keharusan login akun. 

Fokus utama Velora adalah:
- **Privasi Maksimal:** Data koordinat dan catatan kesehatan pengguna tersimpan aman di penyimpanan internal SQLite perangkat.
- **Presisi & Efisiensi Energi:** Algoritma GPS adaptif dengan *noise filtering*, pemicu otomatis *Auto-Pause*, dan algoritma kompresi koordinat *Douglas-Peucker*.
- **Peta Bebas Biaya & Terbuka:** Menggunakan OpenStreetMap (OSM) melalui *tile layer* standar dan CartoDB dark/light tile layer.
- **Viralitas Sosial:** Fitur *RepaintBoundary Social Sharing* yang menghasilkan gambar *watermark* beresolusi tinggi untuk Instagram Story dan status WhatsApp.

---

## 2. Batasan Lingkungan & Sistem (*System Constraints*)
1. **Target Platform:** Android SDK 24 (Android 7.0 Nougat) s/d SDK 35 (Android 15+).
2. **Konektivitas Internet:** Hanya dibutuhkan saat mengambil *tile* peta OpenStreetMap secara daring jika belum tersimpan di *cache*. Seluruh fungsi pencatatan, kalkulasi metrik, database SQLite, dan ekspor gambar berjalan 100% *offline*.
3. **Penyimpanan:** SQLite lokal dengan enkapsulasi direktori aplikasi internal (`getDatabasesPath()`).
4. **Izin Sistem (Permissions):**
   - `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`: Akurasi titik GPS tinggi.
   - `ACCESS_BACKGROUND_LOCATION` & `FOREGROUND_SERVICE_LOCATION`: Merekam saat layar terkunci / aplikasi di latar belakang.
   - `POST_NOTIFICATIONS`: Menampilkan status durasi & jarak pada notification tray Android 13+.
   - `CAMERA` & `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`: Mengambil atau memilih foto latar untuk diekspor ke media sosial.

---

## 3. Pemodelan Algoritma Matematis

### 3.1. Kalkulasi Jarak Rute (Formula Haversine)
Perhitungan jarak antar dua titik koordinat $(\phi_1, \lambda_1)$ dan $(\phi_2, \lambda_2)$ dihitung menggunakan rumus *Haversine* dengan radius rata-rata bumi $R = 6.371.000\text{ meter}$:

$$\Delta \phi = \phi_2 - \phi_1$$
$$\Delta \lambda = \lambda_2 - \lambda_1$$
$$a = \sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1) \cdot \cos(\phi_2) \cdot \sin^2\left(\frac{\Delta \lambda}{2}\right)$$
$$c = 2 \cdot \text{atan2}\left(\sqrt{a}, \sqrt{1-a}\right)$$
$$d = R \cdot c$$

**Filter Noise & GPS Drift:**
- Titik koordinat baru hanya dihitung jika:
  1. $Akurasi \le 25.0\text{ meter}$.
  2. Jarak perpindahan $d \ge 2.0\text{ meter}$ dari titik valid terakhir (mencegah *jitter* saat diam).
  3. Perubahan kecepatan realistis: kecepatan $< 60\text{ km/jam}$ untuk lari, dan $< 120\text{ km/jam}$ untuk bersepeda.

### 3.2. Mesin Logika Auto-Pause
- **Tujuan:** Mencegah degradasi pace dan penambahan durasi kosong saat pengguna berhenti (di lampu merah, menyeberang, istirahat).
- **Parameter Ambang Batas (*Threshold*):**
  - Kecepatan ambang batas ($V_{pause}$): $2.0\text{ km/jam}$ ($0.556\text{ m/s}$).
  - Jendela Waktu Konfirmasi ($T_{confirm}$): $3.0\text{ detik}$.
- **FSM (Finite State Machine):**
  - **State `RUNNING`:** Kecepatan GPS $\ge 2.0\text{ km/jam}$. Stopwatch durasi aktif berjalan.
  - **Kondisi Menuju `AUTO_PAUSED`:** Kecepatan GPS $< 2.0\text{ km/jam}$ berturut-turut selama $\ge 3\text{ detik}$. Stopwatch durasi aktif berhenti sementara. Notifikasi visual dan getar (haptic) diaktifkan.
  - **Kondisi Menuju `RESUMED`:** Kecepatan terdeteksi $\ge 2.5\text{ km/jam}$ atau perpindahan jarak $> 5\text{ meter}$. Stopwatch aktif kembali berjalan.

### 3.3. Algoritma Penyederhanaan Rute (Ramer-Douglas-Peucker)
- **Tujuan:** Mengurangi beban komputasi rendering *polyline* dan memperkecil ukuran payload saat menyimpan ratusan ribu titik koordinat rute panjang (misal: rute sepeda 50-100 km).
- **Parameter Toleransi ($\epsilon$):** $\epsilon = 0.00003$ derajat ($\approx 3\text{ meter}$).
- Titik-titik di antara dua ujung segmen yang jarak tegak lurusnya $< \epsilon$ dieliminasi tanpa mengubah bentuk lengkungan rute secara signifikan.

### 3.4. Metrik Olahraga: Pace vs Kecepatan
- **Mode Bersepeda (Ride):**
  - Metrik Utama: Kecepatan Instan & Rata-rata ($v = \frac{d_{total}}{t_{aktif}}$) dalam satuan $\text{km/jam}$.
- **Mode Lari (Run):**
  - Metrik Utama: Pace Instan & Pace Rata-rata ($Pace = \frac{t_{aktif}}{d_{total}}$) dalam satuan $\text{menit:detik / km}$.
  - Format output: Contoh: $5'24''\text{ /km}$.

---

## 4. Desain Skema Database Lokal (SQLite)
Nama Database: `velora_local.db`  
Versi Skema: 1

### 4.1. Tabel `aktivitas` (Sesi Latihan)
Menyimpan ringkasan sesi latihan olahraga.
```sql
CREATE TABLE aktivitas (
    id TEXT PRIMARY KEY,               -- UUID v4 unik
    jenis_olahraga TEXT NOT NULL,      -- 'run' | 'ride'
    waktu_mulai INTEGER NOT NULL,      -- Timestamp Unix epoch (ms)
    waktu_selesai INTEGER NOT NULL,    -- Timestamp Unix epoch (ms)
    total_durasi_detik INTEGER NOT NULL,-- Durasi aktif bersih (tidak termasuk pause)
    total_jarak_meter REAL NOT NULL,   -- Jarak total dalam meter
    kecepatan_rata_rata REAL NOT NULL, -- Kecepatan rata-rata (km/jam)
    kecepatan_maksimal REAL NOT NULL,  -- Kecepatan puncak (km/jam)
    pace_rata_rata REAL NOT NULL,      -- Pace rata-rata (detik per km)
    elevasi_positif REAL DEFAULT 0.0,  -- Total tanjakan dalam meter
    catatan TEXT,                      -- Catatan opsional dari pengguna
    foto_path TEXT                     -- Path lokal foto share (opsional)
);
```

### 4.2. Tabel `titik_koordinat`
Menyimpan deretan titik koordinat GPS yang membentuk rute perjalanan.
```sql
CREATE TABLE titik_koordinat (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    aktivitas_id TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    elevasi REAL DEFAULT 0.0,
    kecepatan REAL DEFAULT 0.0,        -- Kecepatan instan pada titik ini (m/s)
    akurasi REAL DEFAULT 0.0,          -- Akurasi GPS (meter)
    timestamp INTEGER NOT NULL,        -- Timestamp Unix epoch (ms)
    is_auto_paused INTEGER DEFAULT 0,  -- 1 jika titik ini berada saat auto-pause
    FOREIGN KEY (aktivitas_id) REFERENCES aktivitas (id) ON DELETE CASCADE
);

CREATE INDEX idx_titik_aktivitas ON titik_koordinat (aktivitas_id);
```

---

## 5. Alur Fitur Social Media Sharing
1. Pengguna menyelesaikan sesi latihan atau membuka riwayat sesi sebelumnya.
2. Pengguna menekan tombol **"Bagikan / Share"**.
3. Pengguna memilih format gaya berbagi (Clean Minimalis ala Strava, Peta Rute OSM, Foto Pengguna, atau Klasik).
4. Layar menampilkan pratinjau komposit *watermark*:
   - Aspek rasio 9:16 ideal untuk Instagram Story & status WhatsApp.
   - Pilihan latar belakang: Hitam pekat (*pure black* `#000000`), Peta OSM, atau Foto Pengguna.
5. Komponen dirender via `RepaintBoundary` menjadi citra PNG resolusi tinggi Full HD (1080x1920).
6. File disimpan sementara di direktori *cache*, kemudian memicu *native share sheet* (`share_plus`) atau integrasi langsung ke WhatsApp dan Instagram Story.

### 5.2. Spesifikasi Teknis Format Clean Minimalis (Strava Style)
- **Tujuan:** Menghadirkan template visual yang sangat bersih (*distraction-free*) dengan fokus pada metrik inti performa atlet dan siluet rute, terinspirasi dari format visual populer Strava.
- **Hierarki Konten (Vertical Stacking):**
  1. **Metrik 1 (Distance):** Label `Distance`, nilai `XX.XX km` dalam tipografi ultra-bold putih.
  2. **Metrik 2 (Pace / Speed):**
     - Sesi Lari (*Run*): Label `Pace`, nilai `M:SS /km` via algoritma `formatCleanPace` ($mins = pace \div 60$, $secs = pace \pmod{60}$).
     - Sesi Bersepeda (*Ride*): Label `Speed`, nilai `XX.X km/h`.
  3. **Metrik 3 (Time):** Label `Time`, nilai `XXm XXs` (jika $< 1\text{ jam}$) atau `Xh XXm XXs` (jika $\ge 1\text{ jam}$) via algoritma `formatCleanDuration`.
  4. **Siluet Rute GPS:** Miniatur rute polyline vektor dengan warna oranye Strava/Velora (`#FC5200`), garis melengkung halus tanpa marker titik awal/akhir (*markerless clean path*).
  5. **Branding Aplikasi:** Teks kapital murni **`VELORA`** berwarna putih tebal (*FontWeight.w900*) dengan *wide tracking* (letter spacing 4.5).
- **Penanganan Kondisi Batas (*Edge Cases*):**
  - Pace $\le 0$ atau $> 3600\text{ s/km}$: Menampilkan placeholder `--:-- /km`.
  - Durasi $\le 0$: Menampilkan `0m 0s`.
  - Jumlah koordinat $< 2$: Siluet rute disembunyikan secara anggun (*graceful fallback*) tanpa merusak perataan vertikal spacer.
