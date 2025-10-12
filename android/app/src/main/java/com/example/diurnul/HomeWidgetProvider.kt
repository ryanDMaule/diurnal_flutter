package com.example.diurnul

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.appwidget.AppWidgetManager
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val word = widgetData.getString("word", "Loading...") ?: "Loading..."
            val definition = widgetData.getString("definition", "Fetching definition...") ?: "Fetching definition..."

            views.setTextViewText(R.id.widget_word, word)
            views.setTextViewText(R.id.widget_definition, definition)

            // Tap opens main Flutter activity
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_word, launchIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
