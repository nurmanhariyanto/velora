# Panduan Rilis, Signing Keystore, & Distribusi: Velora
**Author:** Agent DevOps & Rilis (Release Manager)  
**Package:** `online.nurmancloud.velora`

---

## 1. Pembuatan Keystore Digital (Android Release Signing)

Untuk menghasilkan file APK/AAB release yang dapat diinstal langsung di perangkat pengguna secara aman, buat Android Keystore menggunakan utilitas `keytool`:

```bash
keytool -genkey -v -keystore android/app/velora-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias velora \
  -storetype JKS
```

### Konfigurasi `key.properties`
Buat file `android/key.properties` (jangan di-commit ke repositori publik):
```properties
storePassword=PASSWORD_ANDA
keyPassword=PASSWORD_ANDA
keyAlias=velora
storeFile=velora-release-key.jks
```

### Integrasi di `android/app/build.gradle.kts`
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## 2. Perintah Kompilasi Rilis

### Kompilasi Split Per-ABI APK (Ukuran Minimal ~15-20 MB):
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./build/app/outputs/symbols
```
Hasil file output berada di `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (Mayoritas smartphone modern)
- `app-armeabi-v7a-release.apk` (Smartphone Android 32-bit lawas)
- `app-x86_64-release.apk` (Emulator dan perangkat x86_64)

### Kompilasi Android App Bundle (.aab):
```bash
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

---

## 3. Distribusi Internal (QA & Pengujian Lapangan)
1. **Pemasangan Langsung via ADB:**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```
2. **Distribusi Beta:** Unggah file APK ke Firebase App Distribution atau bagikan secara aman ke tim QA via saluran internal (Google Drive / Telegram / Local Web Server).
