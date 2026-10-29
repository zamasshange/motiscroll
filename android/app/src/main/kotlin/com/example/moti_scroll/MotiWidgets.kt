package com.example.moti_scroll

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.LinearLayout
import android.widget.RemoteViews
import android.widget.ScrollView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import org.json.JSONArray
import org.json.JSONObject

private const val payloadKey = "widget_payload"

class QuoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = readPayload(widgetData)
        for (id in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(id)
            val size = quoteSize(options)
            val quote = quoteForToday(payload, size)
            val views = bindQuote(context, payload, quote, size, id)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        onUpdate(
            context,
            appWidgetManager,
            intArrayOf(appWidgetId),
            HomeWidgetPlugin.getData(context),
        )
    }
}

class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = readPayload(widgetData)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_streak)
            val stale = payload == null || payload.stale || !payload.enabled
            val count = if (stale) "—" else payload.streakCount.toString()
            val label = if (stale) {
                stringOf(payload, "openToRefresh", context.getString(R.string.openToRefresh))
            } else {
                stringOf(payload, "streakLabel", context.getString(R.string.streakLabel))
            }
            views.setTextViewText(R.id.streak_count, count)
            views.setTextViewText(R.id.streak_label, label)
            views.setContentDescription(R.id.streak_root, "$count $label")
            views.setOnClickPendingIntent(R.id.streak_root, openHome(context, id))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class SavedWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = readPayload(widgetData)
        for (id in appWidgetIds) {
            val quote = if (payload == null || payload.stale || !payload.enabled) {
                null
            } else {
                cycled(payload.saved)
            }
            val empty = stringOf(payload, "saveAQuote", context.getString(R.string.saveAQuote))
            val views = bindQuote(
                context,
                payload,
                quote,
                "medium",
                id,
                emptyMessage = empty,
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class PoolWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = readPayload(widgetData)
        for (id in appWidgetIds) {
            val choice = widgetData.getString("pool_$id", null)
            val quote = poolQuote(payload, choice)
            val empty = stringOf(payload, "choosePool", context.getString(R.string.choosePool))
            val views = bindQuote(
                context,
                payload,
                quote,
                "medium",
                id,
                emptyMessage = empty,
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class PoolWidgetConfigureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        setResult(
            RESULT_CANCELED,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
        )
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        val payload = readPayload(HomeWidgetPlugin.getData(this))
        val scroll = ScrollView(this)
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val padding = (20 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }
        val title = TextView(this).apply {
            text = stringOf(payload, "choosePool", getString(R.string.choosePool))
            textSize = 22f
            setPadding(0, 0, 0, (12 * resources.displayMetrics.density).toInt())
        }
        column.addView(title)
        val choices = listOf(
            "field:sports" to "field_sports",
            "field:business" to "field_business",
            "field:science" to "field_science",
            "field:arts" to "field_arts",
            "field:leadership" to "field_leadership",
            "field:resilience" to "field_resilience",
            "mood:startingOver" to "mood_startingOver",
            "mood:badDay" to "mood_badDay",
            "mood:needFocus" to "mood_needFocus",
            "mood:preWorkout" to "mood_preWorkout",
            "mood:examStress" to "mood_examStress",
            "mood:feelingStuck" to "mood_feelingStuck",
        )
        for ((value, key) in choices) {
            val button = TextView(this).apply {
                text = stringOf(payload, key, key)
                textSize = 18f
                val vertical = (16 * resources.displayMetrics.density).toInt()
                setPadding(0, vertical, 0, vertical)
                setOnClickListener {
                    HomeWidgetPlugin.getData(this@PoolWidgetConfigureActivity)
                        .edit()
                        .putString("pool_$widgetId", value)
                        .apply()
                    val manager = AppWidgetManager.getInstance(this@PoolWidgetConfigureActivity)
                    PoolWidgetProvider().onUpdate(
                        this@PoolWidgetConfigureActivity,
                        manager,
                        intArrayOf(widgetId),
                        HomeWidgetPlugin.getData(this@PoolWidgetConfigureActivity),
                    )
                    setResult(
                        RESULT_OK,
                        Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
                    )
                    finish()
                }
            }
            column.addView(button)
        }
        scroll.addView(column)
        setContentView(scroll)
    }
}

private class MotiPayload(
    val enabled: Boolean,
    val stale: Boolean,
    val direction: String,
    val streakCount: Int,
    val strings: JSONObject,
    val root: JSONObject,
    val saved: JSONArray,
)

private fun readPayload(data: SharedPreferences): MotiPayload? {
    val raw = data.getString(payloadKey, null) ?: return null
    return try {
        val root = JSONObject(raw)
        MotiPayload(
            enabled = root.optBoolean("widgetsEnabled", true),
            stale = isStale(root),
            direction = root.optString("direction", "ltr"),
            streakCount = root.optInt("streakCount", 0),
            strings = root.optJSONObject("localizedStrings") ?: JSONObject(),
            root = root,
            saved = root.optJSONArray("saved") ?: JSONArray(),
        )
    } catch (_: Exception) {
        null
    }
}

private fun isStale(root: JSONObject): Boolean {
    if (root.optBoolean("cleared", false)) return true
    val raw = root.optString("generatedAt")
    if (raw.isEmpty() || raw == "null") return true
    return try {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        val at = format.parse(raw) ?: return true
        Date().time - at.time > 14L * 24L * 60L * 60L * 1000L
    } catch (_: Exception) {
        true
    }
}

private fun stringOf(payload: MotiPayload?, key: String, fallback: String): String {
    val value = payload?.strings?.optString(key)
    return if (value.isNullOrEmpty()) fallback else value
}

private fun quoteSize(options: Bundle): String {
    val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
    val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
    return when {
        width >= 250 && height >= 180 -> "large"
        width >= 180 -> "medium"
        else -> "small"
    }
}

private fun quoteForToday(payload: MotiPayload?, size: String): JSONObject? {
    if (payload == null || payload.stale || !payload.enabled) return null
    val daily = payload.root.optJSONArray("daily") ?: return null
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    var day = if (daily.length() > 0) daily.optJSONObject(0) else null
    for (index in 0 until daily.length()) {
        val candidate = daily.optJSONObject(index) ?: continue
        if (candidate.optString("date") == today) {
            day = candidate
            break
        }
    }
    val quote = day?.opt(size)
    return quote as? JSONObject
}

private fun poolQuote(payload: MotiPayload?, choice: String?): JSONObject? {
    if (payload == null || payload.stale || !payload.enabled || choice.isNullOrEmpty()) return null
    val parts = choice.split(":")
    if (parts.size != 2) return null
    val group = if (parts[0] == "mood") "moodPools" else "fieldPools"
    val pools = payload.root.optJSONObject(group) ?: return null
    return cycled(pools.optJSONArray(parts[1]) ?: return null)
}

private fun cycled(items: JSONArray): JSONObject? {
    if (items.length() == 0) return null
    val slot = System.currentTimeMillis() / (5L * 60L * 60L * 1000L)
    val index = (slot % items.length()).toInt()
    return items.optJSONObject(index)
}

private fun bindQuote(
    context: Context,
    payload: MotiPayload?,
    quote: JSONObject?,
    size: String,
    widgetId: Int,
    emptyMessage: String? = null,
): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_quote)
    val direction = if (payload?.direction == "rtl") {
        View.LAYOUT_DIRECTION_RTL
    } else {
        View.LAYOUT_DIRECTION_LTR
    }
    views.setInt(R.id.widget_root, "setLayoutDirection", direction)
    val message = when {
        payload == null || payload.stale ->
            stringOf(payload, "openToRefresh", context.getString(R.string.openToRefresh))
        !payload.enabled ->
            stringOf(payload, "yourDailyQuote", context.getString(R.string.yourDailyQuote))
        quote == null ->
            emptyMessage
                ?: stringOf(payload, "openToRefresh", context.getString(R.string.openToRefresh))
        else -> null
    }
    if (message != null || quote == null) {
        views.setViewVisibility(R.id.widget_quote, View.GONE)
        views.setViewVisibility(R.id.widget_author, View.GONE)
        views.setViewVisibility(R.id.widget_source, View.GONE)
        views.setViewVisibility(R.id.widget_field, View.GONE)
        views.setViewVisibility(R.id.widget_badge, View.GONE)
        views.setViewVisibility(R.id.widget_takeaway, View.GONE)
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        views.setTextViewText(R.id.widget_empty, message ?: context.getString(R.string.openToRefresh))
        views.setContentDescription(R.id.widget_root, message)
        views.setOnClickPendingIntent(R.id.widget_root, openHome(context, widgetId))
        return views
    }
    val text = quote.optString("text")
    val author = quote.optString("authorName")
    views.setViewVisibility(R.id.widget_empty, View.GONE)
    views.setViewVisibility(R.id.widget_quote, View.VISIBLE)
    views.setViewVisibility(R.id.widget_author, View.VISIBLE)
    views.setTextViewText(R.id.widget_quote, text)
    views.setTextViewText(R.id.widget_author, author)
    val showSource = size == "medium" || size == "large"
    if (showSource && quote.optString("sourceTitle").isNotEmpty()) {
        val year = quote.opt("sourceYear")
        val source = if (year is Int) {
            "${quote.optString("sourceTitle")}, $year"
        } else {
            quote.optString("sourceTitle")
        }
        views.setViewVisibility(R.id.widget_source, View.VISIBLE)
        views.setTextViewText(R.id.widget_source, source)
    } else {
        views.setViewVisibility(R.id.widget_source, View.GONE)
    }
    val fieldKey = "field_${quote.optString("field")}"
    if (size == "large") {
        views.setViewVisibility(R.id.widget_field, View.VISIBLE)
        views.setTextViewText(R.id.widget_field, stringOf(payload, fieldKey, quote.optString("field")))
    } else {
        views.setViewVisibility(R.id.widget_field, View.GONE)
    }
    val takeaway = quote.optString("takeaway")
    if (size == "large" && takeaway.isNotEmpty()) {
        views.setViewVisibility(R.id.widget_takeaway, View.VISIBLE)
        views.setTextViewText(R.id.widget_takeaway, takeaway)
    } else {
        views.setViewVisibility(R.id.widget_takeaway, View.GONE)
    }
    if (showSource && quote.optBoolean("isTranslated")) {
        views.setViewVisibility(R.id.widget_badge, View.VISIBLE)
        views.setTextViewText(
            R.id.widget_badge,
            stringOf(payload, "translated", context.getString(R.string.translated)),
        )
    } else {
        views.setViewVisibility(R.id.widget_badge, View.GONE)
    }
    paintField(context, views, quote)
    views.setContentDescription(R.id.widget_root, "quote, by $author")
    val itemId = quote.optString("itemId")
    views.setOnClickPendingIntent(
        R.id.widget_root,
        if (itemId.isEmpty()) openHome(context, widgetId) else openItem(context, widgetId, itemId),
    )
    return views
}

private fun paintField(context: Context, views: RemoteViews, quote: JSONObject) {
    val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES
    if (!night) {
        views.setImageViewBitmap(R.id.widget_bg, null)
        return
    }
    val colors = quote.optJSONArray("colors")
    val start = parseColor(colors?.optString(0), Color.parseColor("#17191E"))
    val end = parseColor(colors?.optString(1), Color.parseColor("#3A4150"))
    views.setImageViewBitmap(R.id.widget_bg, fieldBitmap(start, end))
    views.setTextColor(R.id.widget_quote, Color.parseColor("#F4F1EA"))
    views.setTextColor(R.id.widget_author, Color.parseColor("#E07A4A"))
    views.setTextColor(R.id.widget_source, Color.parseColor("#C8C2B8"))
    views.setTextColor(R.id.widget_empty, Color.parseColor("#F4F1EA"))
}

private fun fieldBitmap(start: Int, end: Int): Bitmap {
    val width = 600
    val height = 400
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint()
    paint.shader = LinearGradient(
        0f,
        0f,
        0f,
        height.toFloat(),
        start,
        end,
        Shader.TileMode.CLAMP,
    )
    canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
    paint.shader = LinearGradient(
        0f,
        0f,
        0f,
        height.toFloat(),
        0xE6000000.toInt(),
        0xB3000000.toInt(),
        Shader.TileMode.CLAMP,
    )
    canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
    return bitmap
}

private fun parseColor(raw: String?, fallback: Int): Int {
    if (raw.isNullOrEmpty()) return fallback
    return try {
        Color.parseColor(raw)
    } catch (_: Exception) {
        fallback
    }
}

private fun openItem(context: Context, widgetId: Int, itemId: String): PendingIntent {
    return pending(context, widgetId, Uri.parse("motiscroll://item/$itemId"))
}

private fun openHome(context: Context, widgetId: Int): PendingIntent {
    return pending(context, widgetId, Uri.parse("motiscroll://home"))
}

private fun pending(context: Context, widgetId: Int, uri: Uri): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        data = uri
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    return PendingIntent.getActivity(context, widgetId, intent, flags)
}
