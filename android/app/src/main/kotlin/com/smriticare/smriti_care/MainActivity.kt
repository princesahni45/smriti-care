package com.smriticare.smriti_care

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smriticare.smriti_care/step_permission"
    private val PERMISSION_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkActivityPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.ACTIVITY_RECOGNITION
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        // Pre-Android 10 does not require runtime permission for activity recognition
                        result.success(true)
                    }
                }
                "requestActivityPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.ACTIVITY_RECOGNITION
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.ACTIVITY_RECOGNITION),
                                PERMISSION_REQUEST_CODE
                            )
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}
