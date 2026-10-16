package com.example.diurnul

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

class WidgetRefreshWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        Log.i(LOG_TAG, "Refresh started")
        var scheduleFollowingRefresh = false
        val result = when (val fetched = WidgetPublicationFetcher.fetch()) {
            is FetchResult.Success -> {
                val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(applicationContext)
                if (!WidgetPublicationCache.write(widgetData, fetched.publication)) {
                    Log.w(LOG_TAG, "Cache commit failed; retrying")
                    Result.retry()
                } else {
                    redrawWidgets(applicationContext, widgetData)
                    Log.i(LOG_TAG, "Refresh succeeded")
                    scheduleFollowingRefresh = true
                    Result.success()
                }
            }

            is FetchResult.RetryableFailure -> {
                Log.w(LOG_TAG, "${fetched.reason}; retrying")
                Result.retry()
            }

            is FetchResult.PermanentFailure -> {
                Log.w(LOG_TAG, "${fetched.reason}; keeping cached publication")
                scheduleFollowingRefresh = true
                Result.success()
            }
        }
        if (scheduleFollowingRefresh && inputData.getBoolean(DAILY_WORK_INPUT_KEY, false)) {
            WidgetRefreshScheduler.scheduleFollowing(applicationContext)
        }
        return result
    }

    private fun redrawWidgets(context: Context, widgetData: SharedPreferences) {
        val manager = AppWidgetManager.getInstance(context)
        DiurnusWidgetProviders.registrations.forEach { registration ->
            val widgetIds = manager.getAppWidgetIds(registration.componentName(context))
            if (widgetIds.isNotEmpty()) {
                registration.provider.onUpdate(context, manager, widgetIds, widgetData)
            }
        }
    }

    companion object {
        const val LOG_TAG = "DiurnusWidgetRefresh"
        const val DAILY_WORK_INPUT_KEY = "diurnus_widget_daily_work"
    }
}

internal object WidgetRefreshScheduler {
    const val PERIODIC_WORK_NAME = "diurnus_widget_daily_refresh"
    const val MANUAL_WORK_NAME = "diurnus_widget_manual_refresh"
    private const val BACKOFF_MINUTES = 30L
    private const val PUBLICATION_MINUTE = 15
    private val networkConstraint = Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .build()

    fun schedulePeriodic(context: Context, nowMillis: Long = System.currentTimeMillis()) {
        enqueueDaily(context, nowMillis, ExistingWorkPolicy.KEEP)
    }

    fun scheduleFollowing(context: Context, nowMillis: Long = System.currentTimeMillis()) {
        enqueueDaily(context, nowMillis, ExistingWorkPolicy.APPEND_OR_REPLACE)
    }

    private fun enqueueDaily(context: Context, nowMillis: Long, policy: ExistingWorkPolicy) {
        val request = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
            .setConstraints(networkConstraint)
            .setInputData(workDataOf(WidgetRefreshWorker.DAILY_WORK_INPUT_KEY to true))
            .setInitialDelay(initialDelayMillis(nowMillis), TimeUnit.MILLISECONDS)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, BACKOFF_MINUTES, TimeUnit.MINUTES)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            PERIODIC_WORK_NAME,
            policy,
            request,
        )
    }

    fun cancelPeriodic(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_WORK_NAME)
    }

    fun enqueueManualRefresh(context: Context) {
        val request = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
            .setConstraints(networkConstraint)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, BACKOFF_MINUTES, TimeUnit.MINUTES)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            MANUAL_WORK_NAME,
            ExistingWorkPolicy.KEEP,
            request,
        )
    }

    fun initialDelayMillis(nowMillis: Long): Long {
        val london = TimeZone.getTimeZone("Europe/London")
        val nextRefresh = Calendar.getInstance(london).apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, PUBLICATION_MINUTE)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= nowMillis) add(Calendar.DAY_OF_YEAR, 1)
        }
        return (nextRefresh.timeInMillis - nowMillis).coerceAtLeast(0L)
    }
}

internal object WidgetPublicationFetcher {
    const val CURRENT_PUBLICATION_URL = "https://diurnal-api-7zz8.onrender.com/word"
    const val CONNECT_TIMEOUT_MILLIS = 60_000
    const val READ_TIMEOUT_MILLIS = 60_000

    fun fetch(): FetchResult {
        var connection: HttpURLConnection? = null
        return try {
            connection = URL(CURRENT_PUBLICATION_URL).openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = CONNECT_TIMEOUT_MILLIS
            connection.readTimeout = READ_TIMEOUT_MILLIS
            connection.setRequestProperty("Accept", "application/json")

            when (val status = connection.responseCode) {
                HttpURLConnection.HTTP_OK -> {
                    val body = connection.inputStream.bufferedReader().use { it.readText() }
                    val publication = WidgetPublication.fromJson(body)
                    if (publication == null) {
                        FetchResult.PermanentFailure("Invalid publication payload")
                    } else if (!publication.isForLondonDate()) {
                        FetchResult.RetryableFailure("Publication date is not current in Europe/London")
                    } else {
                        FetchResult.Success(publication)
                    }
                }

                HttpURLConnection.HTTP_CLIENT_TIMEOUT,
                429,
                in 500..599,
                -> FetchResult.RetryableFailure("HTTP $status")

                else -> FetchResult.PermanentFailure("HTTP $status")
            }
        } catch (error: IOException) {
            FetchResult.RetryableFailure("Network failure: ${error.javaClass.simpleName}")
        } catch (error: JSONException) {
            FetchResult.PermanentFailure("Malformed JSON")
        } finally {
            connection?.disconnect()
        }
    }
}

internal sealed interface FetchResult {
    data class Success(val publication: WidgetPublication) : FetchResult
    data class RetryableFailure(val reason: String) : FetchResult
    data class PermanentFailure(val reason: String) : FetchResult
}

internal data class WidgetPublication(
    val word: String,
    val type: String,
    val phonetic: String,
    val definition: String,
    val sequence: String,
    val publicationDate: String,
) {
    fun cacheValues(): Map<String, String> = linkedMapOf(
        WidgetCacheKeys.WORD to word,
        WidgetCacheKeys.TYPE to type,
        WidgetCacheKeys.PHONETIC to phonetic,
        WidgetCacheKeys.DEFINITION to definition,
        WidgetCacheKeys.SEQUENCE to sequence,
    )

    companion object {
        fun fromJson(json: String): WidgetPublication? {
            val data = JSONObject(json)
            val word = data.optionalString("word")
            val definition = data.optionalString("definition")
            val publicationDate = data.optionalString("publicationDate")
            if (word.isEmpty() || definition.isEmpty() ||
                !WidgetPublicationDate.isValid(publicationDate)
            ) return null
            return WidgetPublication(
                word = word,
                type = data.optionalString("type"),
                phonetic = data.optionalString("phonetic"),
                definition = definition,
                sequence = data.optInt("sequence")
                    .takeIf { it > 0 }
                    ?.toString()
                    .orEmpty(),
                publicationDate = publicationDate,
            )
        }

        private fun JSONObject.optionalString(key: String): String =
            (opt(key) as? String)?.trim().orEmpty()
    }

    fun isForLondonDate(nowMillis: Long = System.currentTimeMillis()): Boolean =
        publicationDate == WidgetPublicationDate.londonDate(nowMillis)
}

internal object WidgetPublicationDate {
    private val london = TimeZone.getTimeZone("Europe/London")

    fun londonDate(nowMillis: Long): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).apply {
            timeZone = london
        }.format(nowMillis)

    fun isValid(value: String): Boolean = try {
        SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).apply {
            isLenient = false
            timeZone = london
        }.parse(value)?.let { londonDate(it.time) == value } == true
    } catch (_: java.text.ParseException) {
        false
    }
}

internal object WidgetPublicationCache {
    fun write(widgetData: SharedPreferences, publication: WidgetPublication): Boolean {
        val editor = widgetData.edit()
        publication.cacheValues().forEach { (key, value) -> editor.putString(key, value) }
        return editor.commit()
    }
}
