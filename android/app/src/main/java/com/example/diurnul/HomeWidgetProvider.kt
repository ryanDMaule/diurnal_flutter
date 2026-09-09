package com.example.diurnul

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider as HomeWidgetBaseProvider

class HomeWidgetProvider : DiurnusWidgetProvider(WidgetComposition.SMALL)

class MediumWidgetProvider : DiurnusWidgetProvider(WidgetComposition.MEDIUM)

class LargeWidgetProvider : DiurnusWidgetProvider(WidgetComposition.LARGE)

class MarkWidgetProvider : DiurnusWidgetProvider(WidgetComposition.MARK)

class BrandWidgetProvider : DiurnusWidgetProvider(WidgetComposition.BRAND)

abstract class DiurnusWidgetProvider(
    private val composition: WidgetComposition,
) : HomeWidgetBaseProvider() {
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshScheduler.schedulePeriodic(context)
        if (composition.requiresPublication) {
            enqueueRefreshWhenCacheIsEmpty(context)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        if (!DiurnusWidgetProviders.hasInstalledWidgets(context)) {
            WidgetRefreshScheduler.cancelPeriodic(context)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        WidgetRefreshScheduler.schedulePeriodic(context)
        if (composition.requiresPublication && !CachedPublication.from(widgetData).isUsable) {
            WidgetRefreshScheduler.enqueueManualRefresh(context)
        }
        appWidgetIds.forEach { widgetId ->
            WidgetRenderer.update(
                context,
                appWidgetManager,
                widgetData,
                widgetId,
                composition,
            )
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        WidgetRenderer.update(
            context,
            appWidgetManager,
            HomeWidgetPlugin.getData(context),
            appWidgetId,
            composition,
        )
    }

    private fun enqueueRefreshWhenCacheIsEmpty(context: Context) {
        if (!CachedPublication.from(HomeWidgetPlugin.getData(context)).isUsable) {
            WidgetRefreshScheduler.enqueueManualRefresh(context)
        }
    }
}

internal object WidgetRenderer {
    fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetData: SharedPreferences,
        widgetId: Int,
        composition: WidgetComposition,
    ) {
        val publication = CachedPublication.from(widgetData)
        val editionId = widgetData.getString(WidgetCacheKeys.EDITION, null)
        val interfaceColorId = widgetData.getString(WidgetCacheKeys.INTERFACE_COLOR, null)
        val style = WidgetStyle.resolve(editionId, interfaceColorId)
        val views = RemoteViews(context.packageName, composition.layoutResource)

        when (composition) {
            WidgetComposition.SMALL -> {
                setWord(views, publication, style, composition)
                setOptionalText(views, R.id.widget_type, publication.type.uppercase())
                views.setTextColor(R.id.widget_type, style.mutedTextColor)
            }

            WidgetComposition.MEDIUM -> {
                setWord(views, publication, style, composition)
                views.setTextViewText(R.id.widget_definition, publication.definition)
                views.setTextColor(R.id.widget_definition, style.secondaryTextColor)
            }

            WidgetComposition.LARGE -> {
                setWord(views, publication, style, composition)
                setOptionalText(views, R.id.widget_type, publication.type.uppercase())
                setOptionalText(views, R.id.widget_phonetic, publication.phonetic)
                views.setTextViewText(R.id.widget_definition, publication.definition)
                setOptionalText(
                    views,
                    R.id.widget_sequence,
                    publication.sequence.takeIf { it.isNotBlank() }?.let { "#$it" }.orEmpty(),
                )
                views.setTextColor(R.id.widget_type, style.mutedTextColor)
                views.setTextColor(R.id.widget_phonetic, style.mutedTextColor)
                views.setTextColor(R.id.widget_definition, style.secondaryTextColor)
                views.setTextColor(R.id.widget_sequence, style.secondaryTextColor)
            }

            WidgetComposition.MARK -> {
                views.setTextColor(R.id.widget_brand_name, style.primaryTextColor)
                views.setInt(R.id.widget_mark, "setColorFilter", style.accentColor)
            }

            WidgetComposition.BRAND -> {
                views.setTextColor(R.id.widget_brand_name, style.primaryTextColor)
                views.setTextColor(R.id.widget_brand_tagline, style.secondaryTextColor)
                views.setInt(R.id.widget_mark, "setColorFilter", style.accentColor)
            }
        }

        val showTexture = editionId == WidgetStyle.EVERGREEN.id &&
            widgetData.getBoolean(WidgetCacheKeys.TEXTURE_ENABLED, true)
        views.setImageViewResource(R.id.widget_background, style.backgroundResource ?: 0)
        views.setInt(R.id.widget_background, "setBackgroundColor", style.backgroundColor)
        if (showTexture) {
            val usesPaper = interfaceColorId == "paper"
            views.setImageViewResource(
                R.id.widget_texture,
                if (usesPaper) R.drawable.widget_texture_paper else R.drawable.widget_texture_leather,
            )
            views.setInt(R.id.widget_texture, "setImageAlpha", if (usesPaper) 26 else 15)
            views.setViewVisibility(R.id.widget_texture, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_texture, View.GONE)
        }
        views.setInt(R.id.widget_overlay, "setBackgroundColor", style.overlayColor)
        views.setViewVisibility(R.id.widget_overlay, View.VISIBLE)

        val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun setOptionalText(views: RemoteViews, viewId: Int, value: String) {
        views.setTextViewText(viewId, value)
        views.setViewVisibility(viewId, if (value.isBlank()) View.GONE else View.VISIBLE)
    }

    private fun setWord(
        views: RemoteViews,
        publication: CachedPublication,
        style: WidgetStyle,
        composition: WidgetComposition,
    ) {
        views.setTextViewText(R.id.widget_word, publication.word)
        views.setTextColor(R.id.widget_word, style.primaryTextColor)
        views.setTextViewTextSize(
            R.id.widget_word,
            TypedValue.COMPLEX_UNIT_SP,
            composition.wordSizeFor(publication.word),
        )
    }
}

internal object DiurnusWidgetProviders {
    val registrations = listOf(
        WidgetProviderRegistration(HomeWidgetProvider::class.java, HomeWidgetProvider()),
        WidgetProviderRegistration(MediumWidgetProvider::class.java, MediumWidgetProvider()),
        WidgetProviderRegistration(LargeWidgetProvider::class.java, LargeWidgetProvider()),
        WidgetProviderRegistration(MarkWidgetProvider::class.java, MarkWidgetProvider()),
        WidgetProviderRegistration(BrandWidgetProvider::class.java, BrandWidgetProvider()),
    )

    fun hasInstalledWidgets(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        return registrations.any { registration ->
            manager.getAppWidgetIds(registration.componentName(context)).isNotEmpty()
        }
    }
}

internal data class WidgetProviderRegistration(
    val providerClass: Class<*>,
    val provider: DiurnusWidgetProvider,
) {
    fun componentName(context: Context) = android.content.ComponentName(context, providerClass)
}

enum class WidgetComposition(val layoutResource: Int) {
    SMALL(R.layout.widget_layout),
    MEDIUM(R.layout.widget_layout_medium),
    LARGE(R.layout.widget_layout_large),
    MARK(R.layout.widget_layout_mark),
    BRAND(R.layout.widget_layout_brand);

    val requiresPublication: Boolean get() = this != MARK && this != BRAND

    fun wordSizeFor(word: String): Float {
        val length = word.trim().length
        return when (this) {
            SMALL -> when {
                length >= 16 -> 20f
                length >= 13 -> 23f
                length >= 10 -> 26f
                else -> 30f
            }
            MEDIUM -> when {
                length >= 20 -> 23f
                length >= 15 -> 25f
                else -> 28f
            }
            LARGE -> when {
                length >= 22 -> 25f
                length >= 17 -> 29f
                else -> 34f
            }
            MARK -> 0f
            BRAND -> 0f
        }
    }
}

internal object WidgetCacheKeys {
    const val WORD = "word"
    const val TYPE = "type"
    const val PHONETIC = "phonetic"
    const val DEFINITION = "definition"
    const val SEQUENCE = "sequence"
    const val EDITION = "edition"
    const val INTERFACE_COLOR = "interfaceColor"
    const val TEXTURE_ENABLED = "textureEnabled"
}

internal data class CachedPublication(
    val word: String,
    val type: String,
    val phonetic: String,
    val definition: String,
    val sequence: String,
) {
    val isUsable: Boolean get() = word.isNotBlank() && definition.isNotBlank()

    companion object {
        fun from(widgetData: SharedPreferences) = CachedPublication(
            word = widgetData.getString(WidgetCacheKeys.WORD, null).orEmpty().trim(),
            type = widgetData.getString(WidgetCacheKeys.TYPE, null).orEmpty().trim(),
            phonetic = widgetData.getString(WidgetCacheKeys.PHONETIC, null).orEmpty().trim(),
            definition = widgetData.getString(WidgetCacheKeys.DEFINITION, null).orEmpty().trim(),
            sequence = widgetData.getString(WidgetCacheKeys.SEQUENCE, null).orEmpty().trim(),
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
    val accentColor: Int,
) {
    LIBRARY(
        "library",
        R.drawable.widget_background_library,
        0xFF000000.toInt(),
        0x7A000000,
        0xFFF3EBDD.toInt(),
        0xFFE6DED1.toInt(),
        0xFFD8CDBD.toInt(),
        0xFFC49A52.toInt(),
    ),
    ATRIUM(
        "atrium",
        R.drawable.widget_background_atrium,
        0xFF000000.toInt(),
        0x4DFFF2DD,
        0xFF302B27.toInt(),
        0xFF5C5048.toInt(),
        0xFF786C65.toInt(),
        0xFFB85C5C.toInt(),
    ),
    ARCHIVE(
        "archive",
        R.drawable.widget_background_archive,
        0xFF000000.toInt(),
        0x665A321C,
        0xFFEFE3D2.toInt(),
        0xFFC7B7A3.toInt(),
        0xFF9F8F7F.toInt(),
        0xFFA97842.toInt(),
    ),
    GALLERY(
        "gallery",
        R.drawable.widget_background_gallery,
        0xFF000000.toInt(),
        0x383B3C20,
        0xFFF0E9D8.toInt(),
        0xFFC9C3AC.toInt(),
        0xFFA2A08E.toInt(),
        0xFFD8C66A.toInt(),
    ),
    MIDNIGHT(
        "midnight",
        R.drawable.widget_background_midnight,
        0xFF000000.toInt(),
        0x5207111F,
        0xFFE2E7ED.toInt(),
        0xFFB5C0CA.toInt(),
        0xFF87939F.toInt(),
        0xFF6F8FAF.toInt(),
    ),
    EVERGREEN(
        "evergreen",
        null,
        0xFF032C23.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFCFC7B8.toInt(),
        0xFF9AA89F.toInt(),
        0xFFC8A363.toInt(),
    ),
    THEME_CHARCOAL(
        "theme:charcoal",
        null,
        0xFF211F1C.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFC9C0B4.toInt(),
        0xFF625C54.toInt(),
        0xFFC5A063.toInt(),
    ),
    THEME_NAVY(
        "theme:navy",
        null,
        0xFF0B1724.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFB9C2CA.toInt(),
        0xFF43515E.toInt(),
        0xFFC5A063.toInt(),
    ),
    THEME_OXBLOOD(
        "theme:oxblood",
        null,
        0xFF351519.toInt(),
        0x00000000,
        0xFFF3EBDD.toInt(),
        0xFFCDB9B5.toInt(),
        0xFF755056.toInt(),
        0xFFC5A063.toInt(),
    ),
    THEME_PAPER(
        "theme:paper",
        null,
        0xFFF1EBDD.toInt(),
        0x00000000,
        0xFF282722.toInt(),
        0xFF665F56.toInt(),
        0xFFC9BEA8.toInt(),
        0xFF8C682F.toInt(),
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
