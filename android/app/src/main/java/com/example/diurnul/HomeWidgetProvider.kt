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
        Log.d("HomeWidgetProvider", "✅ onUpdate() triggered")

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val word = widgetData.getString("word", "Loading...") ?: "Loading..."
            val definition =
                widgetData.getString("definition", "Fetching definition...") ?: "Fetching definition..."

            // Update text content
            views.setTextViewText(R.id.widget_word, word)
            views.setTextViewText(R.id.widget_definition, definition)

            // ✅ Add click-to-open app on entire widget
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // ✅ Schedule daily refresh (you can tune interval for testing/production)
        scheduleDailyUpdate(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleDailyUpdate(context)
    }

    /**
     * Sets up a repeating alarm to trigger widget refresh.
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

        // Every 1 minute for testing (change later)
        val triggerTime = System.currentTimeMillis() + 60 * 1000L
        val interval = 60 * 1000L

        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            triggerTime,
            interval,
            pendingIntent
        )

        Log.d("HomeWidgetProvider", "⏰ Widget update scheduled every ${interval / 1000}s")
    }
}
