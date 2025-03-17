package com.example.app_locker

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val SERVICE_CHANNEL = "com.example.app_locker/service"
    private val ACCESSIBILITY_CHANNEL = "com.example.app_locker/accessibility"
    private val EVENT_CHANNEL = "com.example.app_locker/events"

    var eventSink: EventChannel.EventSink? = null

    companion object {
        var instance: MainActivity? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startService(Intent(this, AppDetectionService::class.java))
                    result.success("Service started")
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

    fun sendAppUsageEvent(packageName: String) {
        eventSink?.success(packageName)
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