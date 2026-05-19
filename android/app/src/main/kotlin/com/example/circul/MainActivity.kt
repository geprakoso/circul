package com.example.circul

import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var pendingImageChooserResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "circul/attachments"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openImageChooser" -> {
                    openImageChooser(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openImageChooser(result: MethodChannel.Result) {
        if (pendingImageChooserResult != null) {
            result.error(
                "IMAGE_CHOOSER_ACTIVE",
                "Pilihan gambar masih terbuka.",
                null
            )
            return
        }

        val fileIntent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        val chooser = Intent.createChooser(fileIntent, "Pilih gambar").apply {
            putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(cameraIntent))
        }

        try {
            pendingImageChooserResult = result
            startActivityForResult(chooser, IMAGE_CHOOSER_REQUEST_CODE)
        } catch (_: ActivityNotFoundException) {
            pendingImageChooserResult = null
            result.error(
                "NO_IMAGE_CHOOSER",
                "Tidak ada aplikasi untuk membuka file atau kamera.",
                null
            )
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != IMAGE_CHOOSER_REQUEST_CODE) return

        val result = pendingImageChooserResult ?: return
        pendingImageChooserResult = null

        if (resultCode != RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }

        try {
            result.success(extractImagePaths(data))
        } catch (_: Exception) {
            result.error(
                "IMAGE_COPY_FAILED",
                "Gagal membaca gambar yang dipilih.",
                null
            )
        }
    }

    private fun extractImagePaths(data: Intent): List<String> {
        val paths = mutableListOf<String>()
        val clipData = data.clipData

        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                copyUriToCache(clipData.getItemAt(index).uri)?.let(paths::add)
            }
        } else {
            data.data?.let { uri ->
                copyUriToCache(uri)?.let(paths::add)
            }
        }

        val bitmap = data.extras?.get("data") as? Bitmap
        if (bitmap != null) {
            saveBitmapToCache(bitmap)?.let(paths::add)
        }

        return paths
    }

    private fun copyUriToCache(uri: Uri): String? {
        val extension = when (contentResolver.getType(uri)) {
            "image/png" -> ".png"
            "image/webp" -> ".webp"
            else -> ".jpg"
        }
        val outputFile = File.createTempFile("circul_image_", extension, cacheDir)

        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outputFile).use { output ->
                input.copyTo(output)
            }
        } ?: return null

        return outputFile.absolutePath
    }

    private fun saveBitmapToCache(bitmap: Bitmap): String? {
        val outputFile = File.createTempFile("circul_camera_", ".jpg", cacheDir)
        FileOutputStream(outputFile).use { output ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 92, output)
        }
        return outputFile.absolutePath
    }

    companion object {
        private const val IMAGE_CHOOSER_REQUEST_CODE = 2048
    }
}
