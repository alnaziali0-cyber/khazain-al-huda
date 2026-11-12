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
    fun `dark palette uses a matte black base and lifted neutral panels`() {
        assertEquals(Color(0xFF0B0D0C), AppSoftBlackBackground)
        assertEquals(Color(0xFF151918), NightGlassSurface)
        assertEquals(Color(0xFF1D2220), NightSurfaceVariant)
        assertEquals(Color(0xFF111514), NightInputSurface)
        assertEquals(Color(0xFF303734), SubtleGlassBorderDark)
        assertEquals(Color(0xFF4D9A8C), TurquoisePrimaryDark)
        assertEquals(Color(0xFF8BC8B8), TurquoiseSecondaryDark)
        assertEquals(Color(0xFFC6A15B), NightGoldAccent)
    }
}
