package com.example.app_locker

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class LockScreenActivity : AppCompatActivity() {

    private var volumeButtonPressedTime: Long = 0
    private var unlockDuration: Long = 3L
    private val handler = Handler(Looper.getMainLooper())

    companion object {
        var isUnlocked = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        unlockDuration = intent.getLongExtra("duration", 3L)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        setContentView(R.layout.activity_lock_screen)
    }

    override fun onBackPressed() {
        // Do nothing
    }

    override fun onDestroy() {
        super.onDestroy()
        isUnlocked = false
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN -> {
                if (event?.action == KeyEvent.ACTION_DOWN) {
                    volumeButtonPressedTime = System.currentTimeMillis()
                    handler.postDelayed(volumeButtonHoldRunnable, unlockDuration * 1000)
                }
                true
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN -> {
                handler.removeCallbacks(volumeButtonHoldRunnable)
                true
            }
            else -> super.onKeyUp(keyCode, event)
        }
    }

    private val volumeButtonHoldRunnable = Runnable {
        unlockApp()
    }

    private fun unlockApp() {
        isUnlocked = true
        Toast.makeText(this, "App Unlocked", Toast.LENGTH_SHORT).show()
        finish()
    }
}

