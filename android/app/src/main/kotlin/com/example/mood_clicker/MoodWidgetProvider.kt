package com.example.mood_clicker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home screen widget. The Flutter app writes the snapshot (day, mood, count, link, face_png) with
 * the home_widget package and asks for a redraw. A snapshot of an earlier day shows an empty widget,
 * so the widget never claims taps from yesterday after midnight.
 */
class MoodWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val fresh = widgetData.getString("day", null) == today
        val count = if (fresh) widgetData.getInt("count", 0) else 0
        val link = if (fresh) widgetData.getString("link", null) else null
        val facePath = if (fresh) widgetData.getString("face_png", null) else null
        val face = facePath?.let { BitmapFactory.decodeFile(it) }

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.mood_widget)
            views.setTextViewText(R.id.widget_count, count.toString())
            if (face != null) {
                views.setImageViewBitmap(R.id.widget_face, face)
                views.setViewVisibility(R.id.widget_face, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_face, View.GONE)
            }
            val target = Uri.parse(link ?: "moodclicker://tap")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, target),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
