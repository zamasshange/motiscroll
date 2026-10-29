package com.example.moti_scroll

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view ->
                view.remove()
                updateSystemUiOverlays()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            handleShare(call, result)
        }
    }

    private fun handleShare(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installedApps" ->
                result.success(
                    mapOf(
                        "instagram" to isInstalled("com.instagram.android"),
                        "facebook" to isInstalled("com.facebook.katana"),
                        "facebookLite" to isInstalled("com.facebook.lite"),
                        "whatsapp" to isInstalled("com.whatsapp"),
                        "whatsappBusiness" to isInstalled("com.whatsapp.w4b"),
                    ),
                )
            "shareInstagramStory" ->
                result.success(
                    shareStory(
                        path = call.argument<String>("path"),
                        appId = call.argument<String>("appId"),
                        action = "com.instagram.share.ADD_TO_STORY",
                        packageName = "com.instagram.android",
                        facebookAppId = false,
                    ),
                )
            "shareFacebookStory" ->
                result.success(
                    shareStory(
                        path = call.argument<String>("path"),
                        appId = call.argument<String>("appId"),
                        action = "com.facebook.stories.ADD_TO_STORY",
                        packageName = "com.facebook.katana",
                        facebookAppId = true,
                    ),
                )
            "shareWhatsApp" ->
                result.success(
                    shareWhatsApp(
                        call.argument<String>("path"),
                        call.argument<String>("caption") ?: "",
                    ),
                )
            "shareSystem" ->
                result.success(
                    shareSystem(
                        call.argument<String>("path"),
                        call.argument<String>("caption") ?: "",
                    ),
                )
            "saveImage" -> result.success(false)
            "encodeJpeg" -> result.success(encodeJpeg(call.arguments))
            "openSettings" -> {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                    },
                )
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun shareStory(
        path: String?,
        appId: String?,
        action: String,
        packageName: String,
        facebookAppId: Boolean,
    ): Boolean {
        if (path.isNullOrEmpty() || appId.isNullOrEmpty()) return false
        return try {
            val uri = fileUri(path)
            val intent =
                Intent(action).apply {
                    setDataAndType(uri, mimeOf(path))
                    setPackage(packageName)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    putExtra("source_application", appId)
                    if (facebookAppId) {
                        putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)
                    }
                    clipData = ClipData.newUri(contentResolver, "share", uri)
                }
            grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    private fun shareSystem(path: String?, caption: String): Boolean {
        if (path.isNullOrEmpty()) return false
        return try {
            val uri = fileUri(path)
            val intent =
                Intent(Intent.ACTION_SEND).apply {
                    type = mimeOf(path)
                    putExtra(Intent.EXTRA_STREAM, uri)
                    if (caption.isNotEmpty()) {
                        putExtra(Intent.EXTRA_TEXT, caption)
                    }
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    clipData = ClipData.newUri(contentResolver, "share", uri)
                }
            startActivity(Intent.createChooser(intent, null))
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    private fun shareWhatsApp(path: String?, caption: String): Boolean {
        if (path.isNullOrEmpty()) return false
        val pkg =
            when {
                isInstalled("com.whatsapp") -> "com.whatsapp"
                isInstalled("com.whatsapp.w4b") -> "com.whatsapp.w4b"
                else -> return false
            }
        return try {
            val uri = fileUri(path)
            val intent =
                Intent(Intent.ACTION_SEND).apply {
                    type = "image/*"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_TEXT, caption)
                    setPackage(pkg)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    clipData = ClipData.newUri(contentResolver, "share", uri)
                }
            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    private fun encodeJpeg(raw: Any?): ByteArray? {
        val bytes =
            when (raw) {
                is ByteArray -> raw
                else -> return null
            }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        val out = ByteArrayOutputStream()
        val ok = bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
        bitmap.recycle()
        if (!ok) return null
        return out.toByteArray()
    }

    private fun fileUri(path: String): Uri {
        return FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            File(path),
        )
    }

    private fun mimeOf(path: String): String {
        return if (path.endsWith(".jpg", ignoreCase = true) ||
            path.endsWith(".jpeg", ignoreCase = true)
        ) {
            "image/jpeg"
        } else {
            "image/png"
        }
    }

    private fun isInstalled(pkg: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 33) {
                packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(pkg, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    companion object {
        private const val CHANNEL = "motiscroll/share"
    }
}
