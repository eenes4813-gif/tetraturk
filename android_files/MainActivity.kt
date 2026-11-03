package com.tetraturk.tetraturk

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private lateinit var mc: MethodChannel
    private val pid = "tt"

    private fun work(res: MethodChannel.Result, block: () -> Any?) = thread {
        try { val r = block(); runOnUiThread { res.success(r) } }
        catch (e: Exception) { runOnUiThread { res.error("E", e.message ?: "Hata", null) } }
    }

    override fun configureFlutterEngine(fe: FlutterEngine) {
        super.configureFlutterEngine(fe)
        mc = MethodChannel(fe.dartExecutor.binaryMessenger, "tetraturk/engine")
        mc.setMethodCallHandler { call, res ->
            when (call.method) {
                "init" -> work(res) {
                    YoutubeDL.getInstance().init(application); FFmpeg.getInstance().init(application); null
                }
                "info" -> work(res) {
                    val i = YoutubeDL.getInstance().getInfo(call.argument<String>("url")!!)
                    mapOf("title" to i.title, "thumbnail" to i.thumbnail, "uploader" to i.uploader, "duration" to i.duration)
                }
                "download" -> work(res) {
                    val dir = File(getExternalFilesDir(null) ?: filesDir, "dl").apply { mkdirs() }
                    val req = YoutubeDLRequest(call.argument<String>("url")!!)
                    val a = call.argument<List<String>>("args")!!
                    var i = 0
                    while (i < a.size) {
                        if (i + 1 < a.size && !a[i + 1].startsWith("-")) { req.addOption(a[i], a[i + 1]); i += 2 }
                        else { req.addOption(a[i]); i++ }
                    }
                    req.addOption("-P", dir.absolutePath)
                    YoutubeDL.getInstance().execute(req, pid) { p, eta, _ ->
                        runOnUiThread { mc.invokeMethod("progress", mapOf("p" to p.toDouble(), "eta" to eta)) }
                    }
                    publish(dir); null
                }
                "cancel" -> { YoutubeDL.getInstance().destroyProcessById(pid); res.success(null) }
                "update" -> work(res) {
                    YoutubeDL.getInstance().updateYoutubeDL(application, YoutubeDL.UpdateChannel.STABLE)?.toString() ?: "güncel"
                }
                else -> res.notImplemented()
            }
        }
    }

    /** Dosyaları herkese açık İndirilenler/TetraTurk klasörüne taşır. */
    private fun publish(dir: File) {
        if (Build.VERSION.SDK_INT < 29) return
        dir.listFiles()?.forEach { f ->
            val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(f.extension) ?: "application/octet-stream"
            val v = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, f.name)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/TetraTurk")
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, v) ?: return@forEach
            contentResolver.openOutputStream(uri)?.use { o -> f.inputStream().use { it.copyTo(o) } }
            f.delete()
        }
    }
}
