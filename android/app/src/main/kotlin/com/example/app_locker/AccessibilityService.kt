package com.example.app_locker

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.content.Context
import android.app.ActivityManager

class AppDetectionAccessibilityService : AccessibilityService() {

    private val openedApps = mutableSetOf<String>()
    private var currentForegroundApp: String? = null
    private val ignoredPackages = setOf(
        "com.android.systemui",
        "com.google.android.googlequicksearchbox",
        "com.example.app_locker",
        "com.transsion.XOSLauncher",
        "com.sec.android.app.launcher",
        "com.google.android.apps.nexuslauncher",
        "com.android.launcher3"
    )

    override fun onServiceConnected() {
        Log.d("AppDetectionAccessibilityService", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isForegroundServiceRunning()) {
            return
        }

        event?.let {
            if (it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
                val packageName = it.packageName?.toString()

                if (packageName == null || ignoredPackages.contains(packageName)) {
                    return
                }

                if (packageName == currentForegroundApp) {
                    return
                }

                if (!LockScreenActivity.isUnlocked && !openedApps.contains(packageName)) {
                    MainActivity.instance?.sendAppUsageEvent(packageName)
                    return
                }

                currentForegroundApp = packageName
                openedApps.add(packageName)
                openedApps.removeIf { it != currentForegroundApp }
            }
        }
    }

    override fun onInterrupt() {
        Log.d("AppDetectionAccessibilityService", "Service interrupted")
    }

    private fun isForegroundServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (AppDetectionService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }
}