package com.example.diurnul

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshScheduler.schedulePeriodic(context)
    }

    override fun onDisabled(context: Context) {
        WidgetRefreshScheduler.cancelPeriodic(context)
        super.onDisabled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        WidgetRefreshScheduler.schedulePeriodic(context)
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetData, widgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(
            context,
            appWidgetManager,
            HomeWidgetPlugin.getData(context),
            appWidgetId,
            newOptions,
        )
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetData: SharedPreferences,
        widgetId: Int,
        options: Bundle = appWidgetManager.getAppWidgetOptions(widgetId),
    ) {
        val publication = CachedPublication.from(widgetData)
        val style = WidgetStyle.resolve(
            widgetData.getString(WidgetCacheKeys.EDITION, null),
            widgetData.getString(WidgetCacheKeys.INTERFACE_COLOR, null),
        )
        val sizeSelection = WidgetPresentation.select(
            options,
            context.resources.configuration.orientation,
        )
        val presentation = sizeSelection.presentation
        val views = RemoteViews(context.packageName, presentation.layoutResource)

        views.setTextViewText(R.id.widget_word, publication.word)
        views.setTextViewText(R.id.widget_definition, publication.definition)
        views.setTextColor(R.id.widget_word, style.primaryTextColor)
        views.setTextColor(R.id.widget_definition, style.secondaryTextColor)
        if (presentation == WidgetPresentation.LARGE) {
            setOptionalText(views, R.id.widget_type, publication.type.uppercase())
            setOptionalText(views, R.id.widget_phonetic, publication.phonetic)
            views.setTextColor(R.id.widget_type, style.mutedTextColor)
            views.setTextColor(R.id.widget_phonetic, style.mutedTextColor)
        }
        views.setImageViewResource(R.id.widget_background, style.backgroundResource ?: 0)
        views.setInt(R.id.widget_background, "setBackgroundColor", style.backgroundColor)
        views.setInt(R.id.widget_overlay, "setBackgroundColor", style.overlayColor)

        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun setOptionalText(views: RemoteViews, viewId: Int, value: String) {
        views.setTextViewText(viewId, value)
        views.setViewVisibility(viewId, if (value.isBlank()) View.GONE else View.VISIBLE)
    }
}

internal object WidgetCacheKeys {
    const val WORD = "word"
    const val TYPE = "type"
    const val PHONETIC = "phonetic"
    const val DEFINITION = "definition"
    const val EDITION = "edition"
    const val INTERFACE_COLOR = "interfaceColor"
}

internal data class CachedPublication(
    val word: String,
    val type: String,
    val phonetic: String,
    val definition: String,
) {
    companion object {
        fun from(widgetData: SharedPreferences) = CachedPublication(
            word = widgetData.getString(WidgetCacheKeys.WORD, null).orEmpty().trim(),
            type = widgetData.getString(WidgetCacheKeys.TYPE, null).orEmpty().trim(),
            phonetic = widgetData.getString(WidgetCacheKeys.PHONETIC, null).orEmpty().trim(),
            definition = widgetData.getString(WidgetCacheKeys.DEFINITION, null).orEmpty().trim(),
        )
    }
}

internal enum class WidgetStyle(
    val id: String,
    val backgroundResource: Int?,
    val backgroundColor: Int,
    val overlayColor: Int,
    val primaryTextColor: Int,
    val secondaryTextColor: Int,
    val mutedTextColor: Int,
) {
    LIBRARY(
        "library",
        R.drawable.widget_background_library,
        0xFF000000.toInt(),
        0x7A000000,
        0xFFF3EBDD.toInt(),
        0xFFE6DED1.toInt(),
        0xFFD8CDBD.toInt(),
    ),
    ATRIUM(
        "atrium",
        R.drawable.widget_background_atrium,
        0xFF000000.toInt(),
        0x4DFFF2DD,
        0xFF302B27.toInt(),
        0xFF5C5048.toInt(),
        0xFF786C65.toInt(),
    ),
    ARCHIVE(
        "archive",
        R.drawable.widget_background_archive,
        0xFF000000.toInt(),
        0x665A321C,
        0xFFEFE3D2.toInt(),
        0xFFC7B7A3.toInt(),
        0xFF9F8F7F.toInt(),
    ),
    GALLERY(
        "gallery",
        R.drawable.widget_background_gallery,
        0xFF000000.toInt(),
        0x383B3C20,
        0xFFF0E9D8.toInt(),
        0xFFC9C3AC.toInt(),
        0xFFA2A08E.toInt(),
    ),
    MIDNIGHT(
        "midnight",
        R.drawable.widget_background_midnight,
        0xFF000000.toInt(),
        0x5207111F,
        0xFFE2E7ED.toInt(),
        0xFFB5C0CA.toInt(),
        0xFF87939F.toInt(),
    ),
    EVERGREEN(
        "evergreen",
        null,
        0xFF032C23.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFCFC7B8.toInt(),
        0xFF9AA89F.toInt(),
    ),
    THEME_CHARCOAL(
        "theme:charcoal",
        null,
        0xFF211F1C.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFC9C0B4.toInt(),
        0xFF625C54.toInt(),
    ),
    THEME_NAVY(
        "theme:navy",
        null,
        0xFF0B1724.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFB9C2CA.toInt(),
        0xFF43515E.toInt(),
    ),
    THEME_OXBLOOD(
        "theme:oxblood",
        null,
        0xFF351519.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFCDB9B5.toInt(),
        0xFF755056.toInt(),
    ),
    THEME_PAPER(
        "theme:paper",
        null,
        0xFFF1EBDD.toInt(),
        0x00000000,
        0xFF282722.toInt(),
        0xFF665F56.toInt(),
        0xFFC9BEA8.toInt(),
    );

    companion object {
        fun resolve(editionId: String?, interfaceColorId: String?): WidgetStyle {
            if (editionId == EVERGREEN.id) {
                return when (interfaceColorId) {
                    "charcoal" -> THEME_CHARCOAL
                    "navy" -> THEME_NAVY
                    "oxblood" -> THEME_OXBLOOD
                    "paper" -> THEME_PAPER
                    else -> EVERGREEN
                }
            }
            return entries.firstOrNull { it.id == editionId } ?: LIBRARY
        }
    }
}

internal enum class WidgetPresentation(val layoutResource: Int) {
    COMPACT(R.layout.widget_layout),
    MEDIUM(R.layout.widget_layout_medium),
    LARGE(R.layout.widget_layout_large);

    companion object {
        private const val MEDIUM_MIN_WIDTH_DP = 250
        private const val RICH_MIN_HEIGHT_DP = 180

        fun select(options: Bundle, orientation: Int): WidgetSizeSelection {
            val fallback = legacyCurrentSize(options, orientation)
            val hostSizes = hostProvidedSizes(options)
            val selected = hostSizes.minByOrNull { size ->
                kotlin.math.abs(size.width - fallback.width) +
                    kotlin.math.abs(size.height - fallback.height)
            } ?: fallback
            val width = selected.width.toInt()
            val height = selected.height.toInt()
            return WidgetSizeSelection(
                width = width,
                height = height,
                presentation = fromDimensions(width, height),
            )
        }

        fun fromDimensions(width: Int, height: Int): WidgetPresentation {
            return when {
                height >= RICH_MIN_HEIGHT_DP -> LARGE
                width >= MEDIUM_MIN_WIDTH_DP -> MEDIUM
                else -> COMPACT
            }
        }

        private fun legacyCurrentSize(options: Bundle, orientation: Int): SizeF {
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val maxWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
            return when (orientation) {
                Configuration.ORIENTATION_LANDSCAPE -> SizeF(maxWidth.toFloat(), minHeight.toFloat())
                Configuration.ORIENTATION_PORTRAIT -> SizeF(minWidth.toFloat(), maxHeight.toFloat())
                else -> SizeF(minWidth.toFloat(), minHeight.toFloat())
            }
        }

        @Suppress("DEPRECATION")
        private fun hostProvidedSizes(options: Bundle): List<SizeF> {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return emptyList()
            return options.getParcelableArrayList<SizeF>(
                AppWidgetManager.OPTION_APPWIDGET_SIZES,
            ).orEmpty()
        }
    }
}

internal data class WidgetSizeSelection(
    val width: Int,
    val height: Int,
    val presentation: WidgetPresentation,
)
