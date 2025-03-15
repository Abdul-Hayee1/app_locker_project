package com.example.app_locker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AppDetectionService : Service() {

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(1, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAppUsageMonitoring()
        return START_STICKY
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
        val stopIntent = Intent(this, StopServiceReceiver::class.java)
        val stopPendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, "app_locker_channel")
            .setContentTitle("App Locker")
            .setContentText("Monitoring app usage...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .addAction(
                R.drawable.stop_icon,
                "Stop",
                stopPendingIntent
            )
            .build()
    }

    private fun startAppUsageMonitoring() {
        val intent = Intent(this, AppDetectionAccessibilityService::class.java)
        startService(intent)
        Log.d("AppDetectionService", "AccessibilityService started for app usage monitoring")
    }
}