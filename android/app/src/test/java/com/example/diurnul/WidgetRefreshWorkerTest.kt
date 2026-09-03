package com.example.diurnul

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone
import java.util.concurrent.TimeUnit

class WidgetRefreshWorkerTest {
    @Test
    fun parsesAndTrimsValidWidgetFields() {
        val publication = WidgetPublication.fromJson(
            """{"word":" Diurnal ","type":" Adjective ","phonetic":" di·ur·nal ","definition":" Active by day. "}""",
        )

        assertEquals("Diurnal", publication?.word)
        assertEquals("Adjective", publication?.type)
        assertEquals("di·ur·nal", publication?.phonetic)
        assertEquals("Active by day.", publication?.definition)
    }

    @Test
    fun optionalMetadataIsStoredAsEmptyText() {
        val publication = WidgetPublication.fromJson(
            """{"word":"Diurnal","definition":"Active by day."}""",
        )

        assertEquals("", publication?.type)
        assertEquals("", publication?.phonetic)
    }

    @Test
    fun invalidPublicationDoesNotProduceCacheValues() {
        assertNull(WidgetPublication.fromJson("""{"word":"","definition":"Definition"}"""))
        assertNull(WidgetPublication.fromJson("""{"word":"Word","definition":"  "}"""))
        assertNull(WidgetPublication.fromJson("""{"word":42,"definition":"Definition"}"""))
    }

    @Test
    fun publicationCacheValuesNeverIncludeEdition() {
        val values = WidgetPublication("Word", "Noun", "word", "Definition").cacheValues()

        assertEquals(
            setOf(
                WidgetCacheKeys.WORD,
                WidgetCacheKeys.TYPE,
                WidgetCacheKeys.PHONETIC,
                WidgetCacheKeys.DEFINITION,
            ),
            values.keys,
        )
    }

    @Test
    fun initialDelayTargetsNextLondonPublicationBoundary() {
        val london = TimeZone.getTimeZone("Europe/London")
        val now = Calendar.getInstance(london).apply {
            set(2026, Calendar.SEPTEMBER, 3, 23, 45, 0)
            set(Calendar.MILLISECOND, 0)
        }

        assertEquals(
            TimeUnit.MINUTES.toMillis(30),
            WidgetRefreshScheduler.initialDelayMillis(now.timeInMillis),
        )
    }

    @Test
    fun initialDelayUsesTodaysBoundaryWhenItHasNotPassed() {
        val london = TimeZone.getTimeZone("Europe/London")
        val now = Calendar.getInstance(london).apply {
            set(2026, Calendar.SEPTEMBER, 3, 0, 5, 0)
            set(Calendar.MILLISECOND, 0)
        }

        assertEquals(
            TimeUnit.MINUTES.toMillis(10),
            WidgetRefreshScheduler.initialDelayMillis(now.timeInMillis),
        )
    }
}
