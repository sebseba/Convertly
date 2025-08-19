package com.example.convertly_mobile_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.convertly.channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        openFile(filePath)
                        result.success("File opened")
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                "openFolder" -> {
                    val folderPath = call.argument<String>("folderPath")
                    if (folderPath != null) {
                        openFolder(folderPath)
                        result.success("Folder opened")
                    } else {
                        result.error("INVALID_ARGUMENT", "Folder path is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openFile(filePath: String) {
        try {
            val file = File(filePath)
            val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.provider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, getMimeType(filePath))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Dosyayı açmak için uygulama seç"))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun openFolder(folderPath: String) {
        try {
            // Önce Android 10+ için DocumentsContract kullanmayı dene
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(
                        android.provider.DocumentsContract.buildDocumentUri(
                            "com.android.externalstorage.documents",
                            "primary:Download"
                        ),
                        android.provider.DocumentsContract.Document.MIME_TYPE_DIR
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return
                }
            }
            
            // Android 10 öncesi ve yukarıdaki çalışmazsa bu yöntemi kullan
            val downloadIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    Uri.parse("content://com.android.externalstorage.documents/document/primary%3ADownload"),
                    "vnd.android.document/directory"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            if (downloadIntent.resolveActivity(packageManager) != null) {
                startActivity(downloadIntent)
                return
            }
            
            // Eğer yukarıdakiler çalışmazsa, file:// URI ile dene
            val fileIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.fromFile(File("/storage/emulated/0/Download")), "resource/folder")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            if (fileIntent.resolveActivity(packageManager) != null) {
                startActivity(fileIntent)
                return
            }
            
            // Son çare: Genel dosya yöneticisi aç
            val fileManagerIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "*/*"
                addCategory(Intent.CATEGORY_OPENABLE)
                putExtra("android.content.extra.SHOW_ADVANCED", true)
                putExtra("android.content.extra.FANCY", true)
                putExtra("android.content.extra.SHOW_FILESIZE", true)
            }
            startActivity(Intent.createChooser(fileManagerIntent, "Download Klasörünü Açmak İçin Dosya Yöneticisi Seç"))
            
        } catch (e: Exception) {
            e.printStackTrace()
            // Hata durumunda basit dosya yöneticisi aç
            try {
                val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "*/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
                startActivity(Intent.createChooser(fallbackIntent, "Dosya Yöneticisi Seç"))
            } catch (ex: Exception) {
                ex.printStackTrace()
            }
        }
    }

    private fun getMimeType(filePath: String): String {
        val extension = filePath.substringAfterLast('.').lowercase()
        return when (extension) {
            "pdf" -> "application/pdf"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "mp4" -> "video/mp4"
            "mp3" -> "audio/mpeg"
            "txt" -> "text/plain"
            "doc", "docx" -> "application/msword"
            else -> "*/*"
        }
    }
}