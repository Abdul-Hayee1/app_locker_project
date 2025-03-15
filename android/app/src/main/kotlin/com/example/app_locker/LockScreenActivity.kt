package com.example.app_locker

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class LockScreenActivity : AppCompatActivity() {

    private var volumeButtonPressedTime: Long = 0
    private var unlockDuration: Long = 3L // Default duration (3 seconds)
    private val handler = Handler(Looper.getMainLooper())

    // Static flag to track unlock state
    companion object {
        var isUnlocked = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isUnlocked = false

        // Get the duration from the intent (in seconds)
        unlockDuration = intent.getLongExtra("duration", 3L) // Duration in seconds

        // Set the activity to full-screen
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        setContentView(R.layout.activity_lock_screen)
    }

    // Prevent the back button from closing the activity
    override fun onBackPressed() {
        // Do nothing (disable back button)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Reset the unlock flag when the activity is destroyed
        isUnlocked = false
    }

    // Handle volume button press
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN -> {
                if (event?.action == KeyEvent.ACTION_DOWN) {
                    volumeButtonPressedTime = System.currentTimeMillis()
                    handler.postDelayed(volumeButtonHoldRunnable, unlockDuration * 1000) // Convert to milliseconds
                }
                true // Consume the event
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    // Handle volume button release
    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN -> {
                handler.removeCallbacks(volumeButtonHoldRunnable)
                true // Consume the event
            }
            else -> super.onKeyUp(keyCode, event)
        }
    }

    // Runnable to check if the volume button is held for the specified duration
    private val volumeButtonHoldRunnable = Runnable {
        unlockApp()
    }

    // Unlock the app and finish the activity
    private fun unlockApp() {
        isUnlocked = true // Set the unlock flag
        Toast.makeText(this, "App Unlocked", Toast.LENGTH_SHORT).show()
        finish()
    }
}