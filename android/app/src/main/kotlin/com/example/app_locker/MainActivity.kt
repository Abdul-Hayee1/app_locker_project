package com.example.app_locker

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle

class MainActivity : FlutterActivity() {
    // MethodChannel for service control
    private val SERVICE_CHANNEL = "com.example.app_locker/service"

    // MethodChannel for accessibility service
    private val ACCESSIBILITY_CHANNEL = "com.example.app_locker/accessibility"

    // EventChannel for sending app usage events to Flutter
    private val EVENT_CHANNEL = "com.example.app_locker/events"

    // EventSink to send events to Flutter
    var eventSink: EventChannel.EventSink? = null

    // Static reference to MainActivity
    companion object {
        var instance: MainActivity? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up MethodChannel for service control
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
                    // Get the duration from the Flutter call
                    val durationInSeconds = call.argument<Int>("duration") ?: 3 // Default to 3 seconds
                    // Convert to Long if needed
                    val duration = durationInSeconds.toLong()
                    // Launch the LockScreenActivity with the duration
                    val intent = Intent(this, LockScreenActivity::class.java)
                    intent.putExtra("duration", duration)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success("Lock screen shown")
                }
                else -> result.notImplemented()
            }
        }

        // Set up MethodChannel for accessibility service
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

        // Set up EventChannel for sending app usage events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    // Store the EventSink to send events later
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    // Clean up the EventSink
                    eventSink = null
                }
            }
        )
    }

    // Method to send app usage events to Flutter
    fun sendAppUsageEvent(packageName: String) {
        eventSink?.success(packageName)
    }

    // Method to request accessibility service permission
    private fun requestAccessibilityServicePermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    // Method to check if accessibility service is enabled
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "${applicationContext.packageName}/${AppDetectionAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            applicationContext.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(serviceName) == true
    }
}