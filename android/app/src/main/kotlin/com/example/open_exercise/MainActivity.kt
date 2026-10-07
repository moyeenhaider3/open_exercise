package com.example.open_exercise

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val safChannelName = "com.openexercise/backup_saf"
    private val safPickRequestCode = 9182
    private var pendingSafResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, safChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> {
                    if (pendingSafResult != null) {
                        result.error("cancelled", "Another pick request is active", null)
                        return@setMethodCallHandler
                    }
                    pendingSafResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                            )
                        }
                        startActivityForResult(intent, safPickRequestCode)
                    } catch (e: Exception) {
                        pendingSafResult = null
                        result.error("intent_failed", e.message, null)
                    }
                }
                "writeFile" -> {
                    val uriString = call.argument<String>("uri")
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")
                    if (uriString == null || fileName == null || content == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val treeUri = Uri.parse(uriString)
                        val dir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                        if (dir == null || !dir.canWrite()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        var targetFile = dir.findFile(fileName)
                        if (targetFile == null) {
                            targetFile = dir.createFile("application/json", fileName)
                        }
                        if (targetFile == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        applicationContext.contentResolver.openOutputStream(targetFile.uri, "wt")?.use { os: OutputStream ->
                            os.write(content.toByteArray(Charsets.UTF_8))
                            os.flush()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isFolderAccessible" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val treeUri = Uri.parse(uriString)
                        val dir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                        val accessible = dir != null && dir.exists() && dir.canWrite()
                        result.success(accessible)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == safPickRequestCode) {
            val res = pendingSafResult
            pendingSafResult = null
            if (res == null) return

            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                res.success(null)
                return
            }

            try {
                val uri = data.data!!
                val takeFlags = (data.flags
                    and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
                try {
                    contentResolver.takePersistableUriPermission(uri, takeFlags)
                } catch (pe: Exception) {
                    android.util.Log.e("BackupSaf", "takePersistableUriPermission failed", pe)
                }
                val doc = DocumentFile.fromTreeUri(applicationContext, uri)
                val name = doc?.name ?: "Backups"
                android.util.Log.i("BackupSaf", "Picked tree URI: $uri, name: $name")
                res.success(mapOf("uri" to uri.toString(), "name" to name))
            } catch (e: Exception) {
                android.util.Log.e("BackupSaf", "onActivityResult failed", e)
                res.success(null)
            }
        }
    }
}
