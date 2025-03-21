package com.example.app_locker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.content.pm.ServiceInfo
import androidx.core.app.NotificationCompat

class AppDetectionService : Service() {

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        // Ensure notification channel is created
        createNotificationChannel()
        // If we're on Android 14 or later, ensure notification starts properly
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startForeground(1, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(1, createNotification())
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAppUsageMonitoring()
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAppUsageMonitoring()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "app_locker_channel",
                "App Locker Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "app_locker_channel")
            .setContentTitle("App Locker")
            .setContentText("Monitoring app usage...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }

    private fun startAppUsageMonitoring() {
        val intent = Intent(this, AppDetectionAccessibilityService::class.java)
        // Start the service as foreground to meet Android 14 requirements
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startService(intent)
        } else {
            startService(intent)
        }
        Log.d("AppDetectionService", "AccessibilityService started for app usage monitoring")
    }

    private fun stopAppUsageMonitoring() {
        val intent = Intent(this, AppDetectionAccessibilityService::class.java)
        stopService(intent)
        Log.d("AppDetectionService", "AccessibilityService stopped")
    }
}
