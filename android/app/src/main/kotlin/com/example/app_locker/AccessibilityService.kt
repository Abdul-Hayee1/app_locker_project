package com.example.app_locker

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AppDetectionAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        // Configure the service
        Log.d("AppDetectionAccessibilityService", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            if (it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
                val packageName = it.packageName?.toString()
                packageName?.let { pkg ->
                    Log.d("AppDetectionAccessibilityService", "App opened: $pkg")

                    // Check if the app is unlocked and within the cooldown period
                    val currentTime = System.currentTimeMillis()
                    val cooldownPeriod = 1000L // 1 second cooldown

                    if (!LockScreenActivity.isUnlocked) {
                        // Send this information to Flutter using EventChannel
                        MainActivity.instance?.sendAppUsageEvent(pkg)
                    }
                }
            }
        }
    }

    override fun onInterrupt() {
        // Handle service interruption
        Log.d("AppDetectionAccessibilityService", "Service interrupted")
    }
}