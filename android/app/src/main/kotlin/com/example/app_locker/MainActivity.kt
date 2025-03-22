package com.example.app_locker

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.os.Build
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.net.Uri

class MainActivity : FlutterActivity() {
    private val SERVICE_CHANNEL = "com.example.app_locker/service"
    private val ACCESSIBILITY_CHANNEL = "com.example.app_locker/accessibility"
    private val EVENT_CHANNEL = "com.example.app_locker/events"
    private val CHANNEL = "com.example.app_locker/native"
    private val NOTIFICATION_CHANNEL = "com.example.app_locker/notification"

    var eventSink: EventChannel.EventSink? = null

    companion object {
        var instance: MainActivity? = null
        private const val REQUEST_CODE_OVERLAY_PERMISSION = 1001
        private const val REQUEST_CODE_NOTIFICATION_PERMISSION = 1002
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }
    
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_CODE_NOTIFICATION_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // Notification permission granted, start the service
                    startService(Intent(this, AppDetectionService::class.java))
                } else {
                    // Notification permission denied
                    println("Notification permission denied")
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Service Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    if (areNotificationPermissionsGranted()) {
                        startService(Intent(this, AppDetectionService::class.java))
                        result.success("Service started")
                    } else {
                        result.error("PERMISSION_DENIED", "Notification permissions are not granted", null)
                    }
                }
                "stopService" -> {
                    stopService(Intent(this, AppDetectionService::class.java))
                    result.success("Service stopped")
                }
                "showLockScreen" -> {
                    val durationInSeconds = call.argument<Int>("duration") ?: 3
                    val packageName = call.argument<String>("packageName") ?: ""

                    val intent = Intent(this, LockScreenActivity::class.java).apply {
                        putExtra("duration", durationInSeconds.toLong())
                        putExtra("packageName", packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    startActivity(intent)
                    result.success("Lock screen shown")
                }
                else -> result.notImplemented()
            }
        }

        // Notification Permission Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "areNotificationPermissionsGranted" -> {
                    result.success(areNotificationPermissionsGranted())
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success("Notification permission requested")
                }
                else -> result.notImplemented()
            }
        }

        // Accessibility Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAccessibilityServicePermission" -> {
                    requestAccessibilityServicePermission()
                    result.success("Accessibility settings opened")
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun areNotificationPermissionsGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Notification permissions are not required below Android 13
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE_NOTIFICATION_PERMISSION)
        }
    }

    private fun saveLockList(lockList: List<Map<String, Any>>) {
        val sharedPreferences = getSharedPreferences("AppLockerPrefs", Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()

        // Convert the lock list to JSON and save it
        val gson = Gson()
        val lockListJson = gson.toJson(lockList)
        editor.putString("lockList", lockListJson)
        editor.apply()
    }

    private fun requestAccessibilityServicePermission() {
        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(this)
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "${applicationContext.packageName}/${AppDetectionAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            applicationContext.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(serviceName) == true
    }
}