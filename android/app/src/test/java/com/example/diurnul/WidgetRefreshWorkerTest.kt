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
            """{"word":" Diurnal ","type":" Adjective ","phonetic":" di·ur·nal ","definition":" Active by day. ","publicationDate":"2026-10-16"}""",
        )

        assertEquals("Diurnal", publication?.word)
        assertEquals("Adjective", publication?.type)
        assertEquals("di·ur·nal", publication?.phonetic)
        assertEquals("Active by day.", publication?.definition)
    }

    @Test
    fun optionalMetadataIsStoredAsEmptyText() {
        val publication = WidgetPublication.fromJson(
            """{"word":"Diurnal","definition":"Active by day.","publicationDate":"2026-10-16"}""",
        )

        assertEquals("", publication?.type)
        assertEquals("", publication?.phonetic)
    }

    @Test
    fun invalidPublicationDoesNotProduceCacheValues() {
        assertNull(WidgetPublication.fromJson("""{"word":"","definition":"Definition","publicationDate":"2026-10-16"}"""))
        assertNull(WidgetPublication.fromJson("""{"word":"Word","definition":"  ","publicationDate":"2026-10-16"}"""))
        assertNull(WidgetPublication.fromJson("""{"word":42,"definition":"Definition","publicationDate":"2026-10-16"}"""))
        assertNull(WidgetPublication.fromJson("""{"word":"Word","definition":"Definition"}"""))
    }

    @Test
    fun publicationCacheValuesNeverIncludeEdition() {
        val values = WidgetPublication("Word", "Noun", "word", "Definition", "36", "2026-10-16").cacheValues()

        assertEquals(
            setOf(
                WidgetCacheKeys.WORD,
                WidgetCacheKeys.TYPE,
                WidgetCacheKeys.PHONETIC,
                WidgetCacheKeys.DEFINITION,
                WidgetCacheKeys.SEQUENCE,
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

    @Test
    fun nextRefreshRemainsAtLondonBoundaryWhenSummerTimeStarts() {
        val now = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(2026, Calendar.MARCH, 29, 0, 16, 0)
            set(Calendar.MILLISECOND, 0)
        }

        assertEquals(
            TimeUnit.HOURS.toMillis(22) + TimeUnit.MINUTES.toMillis(59),
            WidgetRefreshScheduler.initialDelayMillis(now.timeInMillis),
        )
    }

    @Test
    fun nextRefreshRemainsAtLondonBoundaryWhenSummerTimeEnds() {
        val now = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(2026, Calendar.OCTOBER, 24, 23, 16, 0)
            set(Calendar.MILLISECOND, 0)
        }

        assertEquals(
            TimeUnit.HOURS.toMillis(24) + TimeUnit.MINUTES.toMillis(59),
            WidgetRefreshScheduler.initialDelayMillis(now.timeInMillis),
        )
    }

    @Test
    fun publicationDateUsesLondonAcrossSummerTimeMidnight() {
        val beforeMidnight = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(2026, Calendar.OCTOBER, 15, 22, 59, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val afterMidnight = beforeMidnight.clone() as Calendar
        afterMidnight.add(Calendar.MINUTE, 1)

        assertEquals("2026-10-15", WidgetPublicationDate.londonDate(beforeMidnight.timeInMillis))
        assertEquals("2026-10-16", WidgetPublicationDate.londonDate(afterMidnight.timeInMillis))
    }

    @Test
    fun widgetPublicationRejectsAStaleLondonDate() {
        val publication = WidgetPublication("Word", "Noun", "word", "Definition", "1", "2026-10-16")
        val nextDay = Calendar.getInstance(TimeZone.getTimeZone("Europe/London")).apply {
            set(2026, Calendar.OCTOBER, 17, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }

        assertEquals(false, publication.isForLondonDate(nextDay.timeInMillis))
    }

    @Test
    fun widgetNetworkTimeoutsAllowRenderColdStart() {
        assertEquals(60_000, WidgetPublicationFetcher.CONNECT_TIMEOUT_MILLIS)
        assertEquals(60_000, WidgetPublicationFetcher.READ_TIMEOUT_MILLIS)
    }
}
