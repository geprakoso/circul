package com.example.circul

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
        val fileIntent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        val chooser = Intent.createChooser(fileIntent, "Pilih gambar").apply {
            putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(cameraIntent))
        }

        try {
            startActivityForResult(chooser, IMAGE_CHOOSER_REQUEST_CODE)
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error(
                "NO_IMAGE_CHOOSER",
                "Tidak ada aplikasi untuk membuka file atau kamera.",
                null
            )
        }
    }

    companion object {
        private const val IMAGE_CHOOSER_REQUEST_CODE = 2048
    }
}
