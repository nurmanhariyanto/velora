package online.nurmancloud.velora

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val INSTALLER_CHANNEL = "online.nurmancloud.velora/app_installer"
    private val SHARE_CHANNEL = "online.nurmancloud.velora/social_share"
    private val MEDIA_CHANNEL = "online.nurmancloud.velora/media_store"
    private val WAKELOCK_CHANNEL = "online.nurmancloud.velora/wakelock"
    private var renderWakeLock: android.os.PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel untuk Menjaga Layar Tetap Aktif Saat Proses Render Video Berjalan
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "keepScreenOn" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    this.runOnUiThread {
                        try {
                            if (enable) {
                                window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                                if (renderWakeLock == null) {
                                    val pm = getSystemService(android.content.Context.POWER_SERVICE) as? android.os.PowerManager
                                    renderWakeLock = pm?.newWakeLock(
                                        android.os.PowerManager.PARTIAL_WAKE_LOCK,
                                        "velora:render_cpu_wakelock"
                                    )?.apply {
                                        setReferenceCounted(false)
                                    }
                                }
                                renderWakeLock?.acquire(10 * 60 * 1000L) // Maksimal 10 menit batas waktu aman
                            } else {
                                window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                                if (renderWakeLock?.isHeld == true) {
                                    renderWakeLock?.release()
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WAKELOCK_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Channel untuk Pemasangan Pembaruan APK Mandiri
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    val file = File(filePath)
                    if (file.exists()) {
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                                if (!context.packageManager.canRequestPackageInstalls()) {
                                    val settingsIntent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                        data = Uri.parse("package:${context.packageName}")
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    context.startActivity(settingsIntent)
                                    result.success(false)
                                    return@setMethodCallHandler
                                }
                            }
                            val uri: Uri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "filePath is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Channel untuk Menyimpan Video Langsung ke Galeri Resmi Ponsel (Android MediaStore)
        // dan Menduplikasi ke Direktori Publik Download/Velora
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveVideoToGallery") {
                val filePath = call.argument<String>("filePath")
                val title = call.argument<String>("title") ?: "velora_flyover"

                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "filePath bernilai null", null)
                    return@setMethodCallHandler
                }

                val sourceFile = File(filePath)
                if (!sourceFile.exists() || sourceFile.length() == 0L) {
                    result.error("FILE_NOT_FOUND", "Berkas video tidak ditemukan atau kosong: $filePath", null)
                    return@setMethodCallHandler
                }

                try {
                    val timestamp = System.currentTimeMillis()
                    val cleanTitle = if (title.endsWith(".mp4", ignoreCase = true)) {
                        title.substring(0, title.length - 4)
                    } else {
                        title
                    }
                    val displayName = if (cleanTitle.contains(Regex("\\d{10,}"))) {
                        "$cleanTitle.mp4"
                    } else {
                        "${cleanTitle}_$timestamp.mp4"
                    }

                    val resolver = context.contentResolver
                    var itemUri: Uri? = null

                    // 1. Simpan ke MediaStore Galeri Video Resmi (Movies/Velora)
                    val contentValues = android.content.ContentValues().apply {
                        put(android.provider.MediaStore.Video.Media.DISPLAY_NAME, displayName)
                        put(android.provider.MediaStore.Video.Media.TITLE, cleanTitle)
                        put(android.provider.MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                        put(android.provider.MediaStore.Video.Media.DATE_ADDED, timestamp / 1000)
                        put(android.provider.MediaStore.Video.Media.DATE_MODIFIED, timestamp / 1000)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                            put(android.provider.MediaStore.Video.Media.RELATIVE_PATH, android.os.Environment.DIRECTORY_MOVIES + "/Velora")
                            put(android.provider.MediaStore.Video.Media.IS_PENDING, 1)
                        } else {
                            val dir = File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MOVIES), "Velora")
                            if (!dir.exists()) dir.mkdirs()
                            put(android.provider.MediaStore.Video.Media.DATA, File(dir, displayName).absolutePath)
                        }
                    }

                    val collection = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        android.provider.MediaStore.Video.Media.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL_PRIMARY)
                    } else {
                        android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    }

                    itemUri = resolver.insert(collection, contentValues)
                    if (itemUri == null) {
                        result.error("INSERT_FAILED", "Gagal membuat entri video di MediaStore", null)
                        return@setMethodCallHandler
                    }

                    try {
                        resolver.openOutputStream(itemUri)?.use { outStream ->
                            sourceFile.inputStream().use { inStream ->
                                inStream.copyTo(outStream)
                            }
                        }
                    } catch (streamErr: Exception) {
                        try { resolver.delete(itemUri, null, null) } catch (_: Exception) {}
                        throw streamErr
                    }

                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        contentValues.clear()
                        contentValues.put(android.provider.MediaStore.Video.Media.IS_PENDING, 0)
                        resolver.update(itemUri, contentValues, null, null)
                    }

                    // Pindai file pada Android versi lama
                    if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.Q) {
                        val moviesDir = File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MOVIES), "Velora")
                        val moviesPath = File(moviesDir, displayName).absolutePath
                        android.media.MediaScannerConnection.scanFile(
                            context,
                            arrayOf(moviesPath),
                            arrayOf("video/mp4"),
                            null
                        )
                    }

                    // 2. Salin juga ke direktori publik Download/Velora sebagai cadangan mandiri
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                            val downloadValues = android.content.ContentValues().apply {
                                put(android.provider.MediaStore.Downloads.DISPLAY_NAME, displayName)
                                put(android.provider.MediaStore.Downloads.TITLE, cleanTitle)
                                put(android.provider.MediaStore.Downloads.MIME_TYPE, "video/mp4")
                                put(android.provider.MediaStore.Downloads.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS + "/Velora")
                                put(android.provider.MediaStore.Downloads.IS_PENDING, 1)
                            }
                            val downloadCollection = android.provider.MediaStore.Downloads.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            val downloadUri = resolver.insert(downloadCollection, downloadValues)
                            if (downloadUri != null) {
                                resolver.openOutputStream(downloadUri)?.use { dOut ->
                                    sourceFile.inputStream().use { dIn ->
                                        dIn.copyTo(dOut)
                                    }
                                }
                                downloadValues.clear()
                                downloadValues.put(android.provider.MediaStore.Downloads.IS_PENDING, 0)
                                resolver.update(downloadUri, downloadValues, null, null)
                            }
                        } else {
                            val downloadDir = File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS), "Velora")
                            if (!downloadDir.exists()) downloadDir.mkdirs()
                            val destDownloadFile = File(downloadDir, displayName)
                            sourceFile.inputStream().use { input ->
                                destDownloadFile.outputStream().use { output ->
                                    input.copyTo(output)
                                }
                            }
                            android.media.MediaScannerConnection.scanFile(
                                context,
                                arrayOf(destDownloadFile.absolutePath),
                                arrayOf("video/mp4"),
                                null
                            )
                        }
                    } catch (downloadErr: Exception) {
                        android.util.Log.w("VeloraMediaStore", "Info salin ke direktori Download/Velora: ${downloadErr.message}")
                    }

                    result.success(itemUri.toString())
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", "Gagal menyimpan video ke galeri: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Channel untuk Berbagi Langsung ke WhatsApp & Instagram Story
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            val filePath = call.argument<String>("filePath")
            val text = call.argument<String>("text") ?: ""

            if (filePath == null) {
                result.error("INVALID_ARGUMENT", "filePath bernilai null", null)
                return@setMethodCallHandler
            }

            val file = File(filePath)
            if (!file.exists() || file.length() == 0L) {
                result.error("FILE_NOT_FOUND", "Berkas tidak ditemukan atau kosong: $filePath", null)
                return@setMethodCallHandler
            }

            val uri: Uri = try {
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    file
                )
            } catch (uriErr: Exception) {
                result.error("FILE_PROVIDER_ERROR", "Gagal membuat URI berkas: ${uriErr.message}", null)
                return@setMethodCallHandler
            }

            val mimeType = if (filePath.endsWith(".mp4", ignoreCase = true)) "video/mp4" else "image/png"

            when (call.method) {
                "shareToWhatsApp" -> {
                    try {
                        val pm = context.packageManager
                        val waPackages = listOf("com.whatsapp", "com.whatsapp.w4b")
                        var targetPackage: String? = null
                        for (pkg in waPackages) {
                            try {
                                pm.getPackageInfo(pkg, 0)
                                targetPackage = pkg
                                break
                            } catch (_: Exception) {}
                        }

                        // 1. Coba kirim langsung ke aplikasi WhatsApp
                        if (targetPackage != null) {
                            try {
                                context.grantUriPermission(targetPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                val intent = Intent(Intent.ACTION_SEND).apply {
                                    type = mimeType
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    if (text.isNotEmpty()) {
                                        putExtra(Intent.EXTRA_TEXT, text)
                                    }
                                    clipData = android.content.ClipData.newRawUri("", uri)
                                    setPackage(targetPackage)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                                result.success(true)
                                return@setMethodCallHandler
                            } catch (directErr: Exception) {
                                android.util.Log.w("VeloraShare", "Kirim langsung WhatsApp gagal, beralih ke chooser: ${directErr.message}")
                            }
                        }

                        // 2. Fallback: buka pemilih aplikasi sistem (System Chooser)
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = mimeType
                            putExtra(Intent.EXTRA_STREAM, uri)
                            if (text.isNotEmpty()) {
                                putExtra(Intent.EXTRA_TEXT, text)
                            }
                            clipData = android.content.ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(sendIntent, "Bagikan via WhatsApp").apply {
                            clipData = android.content.ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", "Gagal membagikan ke WhatsApp: ${e.message}", null)
                    }
                }
                "shareToInstagramStory" -> {
                    try {
                        val pm = context.packageManager
                        var isIgInstalled = false
                        try {
                            pm.getPackageInfo("com.instagram.android", 0)
                            isIgInstalled = true
                        } catch (_: Exception) {}

                        if (isIgInstalled) {
                            context.grantUriPermission("com.instagram.android", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                            // 1. Coba Intent Resmi Meta untuk Instagram Stories
                            try {
                                val storyIntent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                                    setDataAndType(uri, mimeType)
                                    putExtra("source_application", context.packageName)
                                    putExtra("interactive_asset_uri", uri)
                                    clipData = android.content.ClipData.newRawUri("", uri)
                                    setPackage("com.instagram.android")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                if (storyIntent.resolveActivity(pm) != null) {
                                    context.startActivity(storyIntent)
                                    result.success(true)
                                    return@setMethodCallHandler
                                }
                            } catch (metaErr: Exception) {
                                android.util.Log.w("VeloraShare", "Meta Stories Intent gagal, coba ACTION_SEND: ${metaErr.message}")
                            }

                            // 2. Fallback: kirim langsung via Intent.ACTION_SEND ke paket Instagram
                            try {
                                val igIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = mimeType
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    clipData = android.content.ClipData.newRawUri("", uri)
                                    setPackage("com.instagram.android")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                if (igIntent.resolveActivity(pm) != null) {
                                    context.startActivity(igIntent)
                                    result.success(true)
                                    return@setMethodCallHandler
                                }
                            } catch (igSendErr: Exception) {
                                android.util.Log.w("VeloraShare", "Instagram ACTION_SEND gagal, beralih ke chooser: ${igSendErr.message}")
                            }
                        }

                        // 3. Fallback umum: pemilih aplikasi sistem
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = mimeType
                            putExtra(Intent.EXTRA_STREAM, uri)
                            clipData = android.content.ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(sendIntent, "Bagikan ke Instagram").apply {
                            clipData = android.content.ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", "Gagal membagikan ke Instagram: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        try {
            if (renderWakeLock?.isHeld == true) {
                renderWakeLock?.release()
            }
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
