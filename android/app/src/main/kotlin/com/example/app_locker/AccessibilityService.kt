package com.example.app_locker

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.content.Context
import android.app.ActivityManager
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

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

        val lockList = getLockList()

                        // Find the locked app in the lock list
                        val lockedApp = lockList.firstOrNull { app ->
                            app["packageName"] == packageName && app["isLocked"] == true
                        }

                        if (lockedApp != null) {
                            Log.d("AccessibilityService", "App is locked: $packageName")
                            // Get the hold duration from the locked app
                            val holdDuration = when (val duration = lockedApp["holdDuration"]) {
                                is Int -> duration.toLong() // Convert Int to Long
                                is Long -> duration // Already a Long
                                is Double -> duration.toLong() // Convert Double to Long
                                else -> 3L // Default value if the type is unexpected
                            }

                            // Show lock screen
                            val intent = Intent(this, LockScreenActivity::class.java).apply {
                                putExtra("duration", holdDuration) // Pass the hold duration
                                putExtra("packageName", packageName)
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            }
                            startActivity(intent)
                        } else {
                            Log.d("AccessibilityService", "App is not locked: $packageName")
                        }
                
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

     private fun getLockList(): List<Map<String, Any>> {
        val sharedPreferences = getSharedPreferences("AppLockerPrefs", Context.MODE_PRIVATE)
        val lockListJson = sharedPreferences.getString("lockList", "[]") ?: "[]"

        // Convert JSON back to a list of maps
        val gson = Gson()
        val type = object : TypeToken<List<Map<String, Any>>>() {}.type
        return gson.fromJson(lockListJson, type)
    }
}
