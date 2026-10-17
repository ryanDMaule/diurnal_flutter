package com.mauleapplications.diurnus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetStyleTest {
    @Test
    fun evergreenUsesStableIdAndSolidForestBackground() {
        val style = WidgetStyle.resolve("evergreen", "evergreen")

        assertSame(WidgetStyle.EVERGREEN, style)
        assertNull(style.landscapeBackgroundResource)
        assertNull(style.portraitBackgroundResource)
        assertEquals(0xFF032C23.toInt(), style.backgroundColor)
        assertEquals(0x00000000, style.largeOverlayColor)
    }

    @Test
    fun invalidIdStillFallsBackToLibrary() {
        assertSame(WidgetStyle.LIBRARY, WidgetStyle.resolve("unknown", null))
        assertSame(WidgetStyle.LIBRARY, WidgetStyle.resolve(null, null))
    }

    @Test
    fun photographicEditionsRemainImageBacked() {
        val photographic = listOf(
            WidgetStyle.LIBRARY,
            WidgetStyle.ATRIUM,
            WidgetStyle.FOUNDRY,
            WidgetStyle.ASCENT,
            WidgetStyle.HEARTH,
            WidgetStyle.REVERIE,
            WidgetStyle.MONOLITH,
            WidgetStyle.OAK,
            WidgetStyle.GILDED,
            WidgetStyle.PALINDROME,
            WidgetStyle.MIDNIGHT,
        )

        assertTrue(photographic.all { it.landscapeBackgroundResource != null })
        assertTrue(photographic.all { it.portraitBackgroundResource != null })
    }
}
