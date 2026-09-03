package com.example.diurnul

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetRefreshDebugReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetRefreshScheduler.enqueueManualRefresh(context)
    }
}
