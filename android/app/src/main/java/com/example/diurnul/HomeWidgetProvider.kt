package com.example.diurnul

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
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
        logDimensions(
            event = "optionsChanged",
            widgetId = appWidgetId,
            options = newOptions,
            presentation = WidgetPresentation.from(newOptions),
        )
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
        val presentation = WidgetPresentation.from(options)
        logDimensions("render", widgetId, options, presentation)
        val views = RemoteViews(context.packageName, presentation.layoutResource)

        views.setTextViewText(R.id.widget_word, publication.word)
        views.setTextViewText(R.id.widget_definition, publication.definition)
        if (presentation == WidgetPresentation.LARGE) {
            setOptionalText(views, R.id.widget_type, publication.type.uppercase())
            setOptionalText(views, R.id.widget_phonetic, publication.phonetic)
        }

        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun logDimensions(
        event: String,
        widgetId: Int,
        options: Bundle,
        presentation: WidgetPresentation,
    ) {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        val maxWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        Log.d(
            LOG_TAG,
            "$event id=$widgetId min=${minWidth}x$minHeight max=${maxWidth}x$maxHeight " +
                "presentation=${presentation.name}",
        )
    }

    private fun setOptionalText(views: RemoteViews, viewId: Int, value: String) {
        views.setTextViewText(viewId, value)
        views.setViewVisibility(viewId, if (value.isBlank()) View.GONE else View.VISIBLE)
    }

    companion object {
        private const val LOG_TAG = "DiurnusWidget"
    }
}

internal data class CachedPublication(
    val word: String,
    val type: String,
    val phonetic: String,
    val definition: String,
) {
    companion object {
        fun from(widgetData: SharedPreferences) = CachedPublication(
            word = widgetData.getString("word", null).orEmpty().trim(),
            type = widgetData.getString("type", null).orEmpty().trim(),
            phonetic = widgetData.getString("phonetic", null).orEmpty().trim(),
            definition = widgetData.getString("definition", null).orEmpty().trim(),
        )
    }
}

internal enum class WidgetPresentation(val layoutResource: Int) {
    COMPACT(R.layout.widget_layout),
    MEDIUM(R.layout.widget_layout_medium),
    LARGE(R.layout.widget_layout_large);

    companion object {
        private const val MEDIUM_MIN_WIDTH_DP = 250
        private const val RICH_MIN_HEIGHT_DP = 115

        fun from(options: Bundle): WidgetPresentation {
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            return fromDimensions(width, height)
        }

        fun fromDimensions(width: Int, height: Int): WidgetPresentation {
            return when {
                height >= RICH_MIN_HEIGHT_DP -> LARGE
                width >= MEDIUM_MIN_WIDTH_DP -> MEDIUM
                else -> COMPACT
            }
        }
    }
}
