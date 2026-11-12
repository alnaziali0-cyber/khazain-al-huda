package com.example.ui.screens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The hidden gesture only reveals the Firebase sign-in gate. It must not be mistaken for
 * authentication or rely on a secret embedded in the client.
 */
class DeveloperAccessControllerTest {

    @Test
    fun `the tap gesture needs the full number of taps`() {
        val now = 1_000L
        var count = 0
        var lastTap = now

        // Six quick taps are not enough.
        repeat(6) {
            assertFalse(
                DeveloperAccessController.isMultiTapGesture(count, lastTap, now)
            )
            count++
            lastTap = now
        }

        // The seventh tap completes the gesture.
        assertTrue(DeveloperAccessController.isMultiTapGesture(count, lastTap, now))
    }

    @Test
    fun `a slow tap sequence resets the counter`() {
        val start = 1_000L
        val later = start + 5_000L
        // The gap between the two taps is larger than the allowed window, so the gesture fails.
        assertFalse(DeveloperAccessController.isMultiTapGesture(6, start, later))
    }

    @Test
    fun `the hidden route reveals only the remote authentication gate`() {
        assertEquals(7, DeveloperAccessController.REQUIRED_TAPS)
        // Its public API contains only the gesture threshold and device fingerprint helper.
        val publicMethods = DeveloperAccessController::class.java.methods.map { it.name }.toSet()
        assertTrue("deviceFingerprint" in publicMethods)
        assertFalse("verifyAndUnlock" in publicMethods)
        assertFalse("isUnlocked" in publicMethods)
    }
}
