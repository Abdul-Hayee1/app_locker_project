package com.example.app_locker

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AppDetectionAccessibilityService : AccessibilityService() {

    private val openedApps = mutableSetOf<String>()
    private var currentForegroundApp: String? = null
    private val ignoredPackages = setOf(
        "com.android.systemui",
        "com.google.android.googlequicksearchbox",
        "com.example.app_locker",
        "com.transsion.XOSLauncher",
        "com.sec.android.app.launcher", // Samsung Launcher
        "com.google.android.apps.nexuslauncher",
        "com.android.launcher3" // Pixel Launcher
    )

    override fun onServiceConnected() {
        Log.d("AppDetectionAccessibilityService", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
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
}
