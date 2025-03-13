package com.example.app_locker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        // Stop the service
        val serviceIntent = Intent(context, AppDetectionService::class.java)
        context.stopService(serviceIntent)
    }
}