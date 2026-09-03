package com.example.diurnul

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetStyleTest {
    @Test
    fun evergreenUsesStableIdAndSolidForestBackground() {
        val style = WidgetStyle.fromId("evergreen")

        assertSame(WidgetStyle.EVERGREEN, style)
        assertNull(style.backgroundResource)
        assertEquals(0xFF032C23.toInt(), style.backgroundColor)
        assertEquals(0x00000000, style.overlayColor)
    }

    @Test
    fun invalidIdStillFallsBackToLibrary() {
        assertSame(WidgetStyle.LIBRARY, WidgetStyle.fromId("unknown"))
        assertSame(WidgetStyle.LIBRARY, WidgetStyle.fromId(null))
    }

    @Test
    fun existingEditionsRemainImageBacked() {
        val existing = listOf(
            WidgetStyle.LIBRARY,
            WidgetStyle.ATRIUM,
            WidgetStyle.ARCHIVE,
            WidgetStyle.GALLERY,
            WidgetStyle.MIDNIGHT,
        )

        assertTrue(existing.all { it.backgroundResource != null })
    }
}
