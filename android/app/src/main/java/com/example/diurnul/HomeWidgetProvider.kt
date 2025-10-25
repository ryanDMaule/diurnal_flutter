package com.example.diurnul

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import android.util.Log


class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d("HomeWidgetProvider", "WOOHOOO onUpdate() called from AlarmManager")

        // --- your existing update logic ---
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val word = widgetData.getString("word", "Loading...") ?: "Loading..."
            val definition = widgetData.getString("definition", "Fetching definition...") ?: "Fetching definition..."

            views.setTextViewText(R.id.widget_word, word)
            views.setTextViewText(R.id.widget_definition, definition)

            // Tap to open main Flutter activity
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_word, launchIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // --- NEW: schedule a daily refresh ---
        scheduleDailyUpdate(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleDailyUpdate(context)
    }

    /**
     * Sets up a repeating alarm that will trigger the widget to refresh every day
     * a few seconds after midnight.
     */
    private fun scheduleDailyUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, HomeWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // For testing — trigger every 1 minute
        val triggerTime = System.currentTimeMillis() + 60 * 1000L
        val interval = 60 * 1000L // 1 minute interval for testing

        // --- Uncomment for production daily updates ---
        // val triggerTime = System.currentTimeMillis() + AlarmManager.INTERVAL_DAY
        // val interval = AlarmManager.INTERVAL_DAY // 24 hours
        // ------------------------------------------------

        // Use inexact repeating alarm — no special permissions required
        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            triggerTime,
            interval,
            pendingIntent
        )

        // Log each time this is scheduled (for debugging)
        android.util.Log.d("HomeWidgetProvider", "Widget update scheduled every ${interval / 1000} seconds.")
    }


    
}
