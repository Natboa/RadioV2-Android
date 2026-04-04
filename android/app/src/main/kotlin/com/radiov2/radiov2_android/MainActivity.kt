package com.radiov2.radiov2_android

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    // Move to background instead of finishing the activity when back is pressed
    // at root. This keeps the audio foreground service alive reliably.
    override fun finish() {
        moveTaskToBack(true)
    }
}
