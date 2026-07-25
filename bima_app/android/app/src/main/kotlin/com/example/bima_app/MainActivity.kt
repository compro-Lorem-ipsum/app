package com.example.bima_app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

// MethodChannel khusus untuk menyimpan file langsung ke folder Downloads
// publik lewat MediaStore (dipakai oleh TrackingService.exportDebugMap agar
// file HTML debug GPS bisa langsung ditemukan lewat aplikasi File Manager,
// bukan tersembunyi di folder privat aplikasi).
class MainActivity : FlutterActivity() {
    private val channelName = "bima_app/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                val mimeType = call.argument<String>("mimeType") ?: "text/html"
                if (fileName == null || content == null) {
                    result.error("BAD_ARGS", "fileName dan content wajib diisi", null)
                    return@setMethodCallHandler
                }
                try {
                    result.success(saveToDownloads(fileName, content, mimeType))
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(fileName: String, content: String, mimeType: String): String {
        val bytes = content.toByteArray(Charsets.UTF_8)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Gagal membuat entri MediaStore untuk $fileName")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Gagal membuka output stream untuk $fileName")
            return "Download/$fileName"
        }

        // Fallback untuk Android < 10 (belum ada scoped storage / MediaStore.Downloads).
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) downloadsDir.mkdirs()
        val file = File(downloadsDir, fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
