package com.example.ui.screens

import android.content.Context
import java.util.Locale
import java.security.MessageDigest

/**
 * Non-secret utilities for the deliberately hidden developer entry point.
 *
 * This class intentionally contains no access code, password hash, local unlock flag, or
 * authorization decision. The gesture only reveals the Firebase sign-in gate; actual access
 * remains protected by the verified Firebase identity and Firestore Security Rules.
 */
object DeveloperAccessController {

    /** The number of taps on the version number that reveals the hidden sign-in gate. */
    const val REQUIRED_TAPS = 7

    /** The maximum interval between two consecutive taps. */
    private const val TAP_WINDOW_MILLIS = 1_500L

    /**
     * Returns true when the next tap completes the deliberate gesture. No authentication is
     * performed here; the route opened after the gesture is protected by Firebase.
     */
    fun isMultiTapGesture(currentCount: Int, lastTapMillis: Long, nowMillis: Long): Boolean {
        if (nowMillis - lastTapMillis > TAP_WINDOW_MILLIS) return false
        return currentCount + 1 >= REQUIRED_TAPS
    }

    /** A short, non-reversible fingerprint of the device used by the diagnostics panel. */
    fun deviceFingerprint(context: Context): String {
        val raw = "${context.packageName}:${android.os.Build.MANUFACTURER}:${android.os.Build.MODEL}"
        return sha256(raw).take(12).uppercase(Locale.ROOT)
    }

    private fun sha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(input.toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { byte -> "%02x".format(byte) }
    }
}
