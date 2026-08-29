package com.mezgeb.vault

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.media.ExifInterface
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.text.SimpleDateFormat
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    private var pendingPickResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mezgeb/picker").setMethodCallHandler { call, result ->
            when (call.method) {
                "pickPhotos" -> launchPicker(result, "image/*")
                "pickFiles" -> launchPicker(result, "*/*")
                "deleteOriginal" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) runCatching { contentResolver.delete(Uri.parse(uriString), null, null) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchPicker(result: MethodChannel.Result, mimeType: String) {
        if (hasPendingOperation()) {
            result.error("picker_busy", "A picker or camera is already open.", null)
            return
        }
        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        startActivityForResult(intent, PICK_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            PICK_REQUEST -> handlePhotoPickResult(resultCode, data)
        }
    }

    private fun handlePhotoPickResult(resultCode: Int, data: Intent?) {
        val result = pendingPickResult ?: return
        pendingPickResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (index in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(index).uri)
            }
        } ?: data.data?.let { uris.add(it) }

        val files = uris.mapNotNull { uri ->
            runCatching {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                pickedFileMap(uri, displayName(uri), contentResolver.getType(uri))
            }.getOrNull()
        }
        result.success(files)
    }

    private fun pickedFileMap(uri: Uri, name: String, mimeType: String?): Map<String, Any?> {
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: error("Could not read selected image.")
        val capturedAtMillis = mediaStoreDateTaken(uri) ?: exifDateTaken(bytes)
        return mapOf(
            "name" to name,
            "mimeType" to (mimeType ?: "image/jpeg"),
            "uri" to uri.toString(),
            "capturedAtMillis" to capturedAtMillis,
            "bytes" to bytes
        )
    }

    private fun mediaStoreDateTaken(uri: Uri): Long? {
        val projection = arrayOf(MediaStore.Images.Media.DATE_TAKEN)
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, projection, null, null, null)
            val index = cursor?.getColumnIndex(MediaStore.Images.Media.DATE_TAKEN) ?: -1
            if (cursor != null && cursor.moveToFirst() && index >= 0 && !cursor.isNull(index)) {
                cursor.getLong(index).takeIf { it > 0L }
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } finally {
            cursor?.close()
        }
    }

    private fun exifDateTaken(bytes: ByteArray): Long? {
        return try {
            val exif = ExifInterface(ByteArrayInputStream(bytes))
            val raw = exif.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)
                ?: exif.getAttribute(ExifInterface.TAG_DATETIME_DIGITIZED)
                ?: exif.getAttribute(ExifInterface.TAG_DATETIME)
            if (raw.isNullOrBlank()) return null
            val parser = SimpleDateFormat("yyyy:MM:dd HH:mm:ss", Locale.US)
            parser.parse(raw)?.time?.takeIf { it > 0L }
        } catch (_: Exception) {
            null
        }
    }

    private fun displayName(uri: Uri): String {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, null, null, null, null)
            val nameIndex = cursor?.getColumnIndex(OpenableColumns.DISPLAY_NAME) ?: -1
            if (cursor != null && cursor.moveToFirst() && nameIndex >= 0) {
                cursor.getString(nameIndex)
            } else {
                uri.lastPathSegment ?: "Imported file"
            }
        } finally {
            cursor?.close()
        }
    }

    private fun hasPendingOperation(): Boolean {
        return pendingPickResult != null
    }

    private companion object {
        const val PICK_REQUEST = 8124
    }
}
