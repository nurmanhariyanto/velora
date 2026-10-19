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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveVideoToGallery") {
                val filePath = call.argument<String>("filePath")
                val title = call.argument<String>("title") ?: "velora_flyover"

                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "filePath is null", null)
                    return@setMethodCallHandler
                }

                val sourceFile = File(filePath)
                if (!sourceFile.exists()) {
                    result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                    return@setMethodCallHandler
                }

                try {
                    val timestamp = System.currentTimeMillis()
                    val displayName = "${title}_$timestamp.mp4"
                    val resolver = context.contentResolver

                    val contentValues = android.content.ContentValues().apply {
                        put(android.provider.MediaStore.Video.Media.DISPLAY_NAME, displayName)
                        put(android.provider.MediaStore.Video.Media.TITLE, title)
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

                    val itemUri = resolver.insert(collection, contentValues)
                    if (itemUri == null) {
                        result.error("INSERT_FAILED", "Failed to create MediaStore entry", null)
                        return@setMethodCallHandler
                    }

                    resolver.openOutputStream(itemUri)?.use { outStream ->
                        sourceFile.inputStream().use { inStream ->
                            inStream.copyTo(outStream)
                        }
                    }

                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        contentValues.clear()
                        contentValues.put(android.provider.MediaStore.Video.Media.IS_PENDING, 0)
                        resolver.update(itemUri, contentValues, null, null)
                    }

                    // Panggil MediaScannerConnection agar Galeri ponsel (Google Photos, Samsung, Xiaomi) langsung menampilkan video
                    android.media.MediaScannerConnection.scanFile(
                        context,
                        arrayOf(sourceFile.absolutePath),
                        arrayOf("video/mp4"),
                        null
                    )

                    result.success(itemUri.toString())
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
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
                result.error("INVALID_ARGUMENT", "filePath is null", null)
                return@setMethodCallHandler
            }

            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                return@setMethodCallHandler
            }

            val uri: Uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            val mimeType = if (filePath.endsWith(".mp4", ignoreCase = true)) "video/mp4" else "image/png"

            when (call.method) {
                "shareToWhatsApp" -> {
                    try {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = mimeType
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_TEXT, text)
                            setPackage("com.whatsapp")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (intent.resolveActivity(context.packageManager) != null) {
                            context.startActivity(intent)
                            result.success(true)
                        } else {
                            val chooser = Intent.createChooser(
                                Intent(Intent.ACTION_SEND).apply {
                                    type = mimeType
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    putExtra(Intent.EXTRA_TEXT, text)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                },
                                "Bagikan via WhatsApp"
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(chooser)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                "shareToInstagramStory" -> {
                    try {
                        // Standard Intent Resmi Meta untuk Instagram Stories
                        val storyIntent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                            setDataAndType(uri, mimeType)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (storyIntent.resolveActivity(context.packageManager) != null) {
                            context.startActivity(storyIntent)
                            result.success(true)
                        } else {
                            // Fallback ke paket utama Instagram Android
                            val igIntent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                setPackage("com.instagram.android")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            if (igIntent.resolveActivity(context.packageManager) != null) {
                                context.startActivity(igIntent)
                                result.success(true)
                            } else {
                                val chooser = Intent.createChooser(
                                    Intent(Intent.ACTION_SEND).apply {
                                        type = mimeType
                                        putExtra(Intent.EXTRA_STREAM, uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    },
                                    "Bagikan ke Instagram Story"
                                ).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(chooser)
                                result.success(true)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
