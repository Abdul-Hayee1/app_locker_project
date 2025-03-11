/*
package com.example.app_locker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AppLaunchReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_PACKAGE_ADDED || intent.action == Intent.ACTION_PACKAGE_REPLACED) {
            val packageName = intent.data?.schemeSpecificPart
            if (packageName != null && isAppLocked(context, packageName)) {
                // Show lock screen
                showLockScreen(context)
            }
        }
    }

    private fun isAppLocked(context: Context, packageName: String): Boolean {
        // Retrieve the locked apps list from SharedPreferences
        val sharedPreferences = context.getSharedPreferences("AppLockerPrefs", Context.MODE_PRIVATE)
        val lockedApps = sharedPreferences.getStringSet("locked_apps", emptySet())
        return lockedApps?.contains(packageName) ?: false
    }

    private fun showLockScreen(context: Context) {
        val lockIntent = Intent(context, LockScreenActivity::class.java)
        lockIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(lockIntent)
    }
}
*/