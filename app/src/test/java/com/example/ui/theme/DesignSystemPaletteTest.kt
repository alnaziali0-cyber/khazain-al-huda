package com.example.ui.theme

import androidx.compose.ui.graphics.Color
import org.junit.Assert.assertEquals
import org.junit.Test

/** Guards the central palette against accidental drift from the approved Khazain surfaces. */
class DesignSystemPaletteTest {

    @Test
    fun `light palette matches the approved calm surfaces`() {
        assertEquals(Color(0xFFEAF3F0), CalmAlabasterBg)
        assertEquals(Color(0xFFE4EFED), SoftSageSurfaceVariant)
        assertEquals(Color.White, PureGlassWhite)
        assertEquals(Color(0xFF172D2B), InkDarkText)
        assertEquals(Color(0xFF637875), MutedSlateText)
        assertEquals(Color(0xFFD6E2DE), SubtleGlassBorderLight)
    }

    @Test
    fun `dark palette uses charcoal rather than blue gray or pure black`() {
        assertEquals(Color(0xFF101312), AppSoftBlackBackground)
        assertEquals(Color(0xFF1B211E), NightGlassSurface)
        assertEquals(Color(0xFF202824), NightSurfaceVariant)
        assertEquals(Color(0xFF171D1A), NightInputSurface)
        assertEquals(Color(0xFF2B3530), SubtleGlassBorderDark)
        assertEquals(Color(0xFF4D9A8C), TurquoisePrimaryDark)
        assertEquals(Color(0xFF8BC8B8), TurquoiseSecondaryDark)
        assertEquals(Color(0xFFC6A15B), NightGoldAccent)
    }
}
