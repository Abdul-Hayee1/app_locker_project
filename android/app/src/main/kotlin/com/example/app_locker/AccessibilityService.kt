package com.example.app_locker

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.content.Context
import android.app.ActivityManager
import android.content.Intent
import android.os.Handler
import android.os.Looper

class AppDetectionAccessibilityService : AccessibilityService() {

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

    // Handler & Runnable for delayed locking
    private val handler = Handler(Looper.getMainLooper())
    private var lockRunnable: Runnable? = null

    override fun onServiceConnected() {
        Log.d("AppDetectionAccessibilityService", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isForegroundServiceRunning()) {
            return
        }

        event?.let {
            if (it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
                val packageName = it.packageName?.toString() ?: return

                Log.d("AccessibilityService", "Detected package: $packageName")

                // Cancel previous pending lock if any
                if (lockRunnable != null) {
                    handler.removeCallbacks(lockRunnable!!)
                    lockRunnable = null
                }

                // Check if launcher or ignored app
                if (isLauncherApp(packageName) || ignoredPackages.contains(packageName)) {
                    Log.d("AccessibilityService", "Launcher detected: $packageName, skipping lock")
                    return
                }

                // App detected, post delayed lock
              lockRunnable = Runnable {
    if (!isLauncherApp(packageName) &&
        !ignoredPackages.contains(packageName) &&
        !LockScreenActivity.isUnlocked
    ) {
        Log.d("AccessibilityService", "App detected after delay: $packageName, showing lock")

        currentForegroundApp = packageName
        LockScreenActivity.isUnlocked = false

        MainActivity.instance?.sendAppUsageEvent(packageName)
    } else {
        Log.d("AccessibilityService", "Launcher or unlocked app detected after delay, not locking")
    }
}


                handler.postDelayed(lockRunnable!!, 300) // 300ms delay
            }
        }
    }

    private fun isLauncherApp(packageName: String): Boolean {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(intent, 0)
        return resolveInfo?.activityInfo?.packageName == packageName
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
