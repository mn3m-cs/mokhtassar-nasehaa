package com.menemlabs.zaadalthakir.reminders

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

data class PlannedReminder(
    val year: Int,
    val month: Int,
    val day: Int,
    val minuteOfDay: Int,
    val titleId: Int,
    val title: String,
    val body: String,
) {
    /** The moment in the phone's current time zone. */
    fun atMillis(): Long = Calendar.getInstance().apply {
        clear()
        set(year, month - 1, day, minuteOfDay / 60, minuteOfDay % 60, 0)
    }.timeInMillis
}

object ReminderStore {
    private const val PREFS = "reminders"
    private const val KEY = "planned"

    fun fromMaps(maps: List<Map<String, Any?>>): List<PlannedReminder> = maps.map {
        PlannedReminder(
            year = (it["year"] as Number).toInt(),
            month = (it["month"] as Number).toInt(),
            day = (it["day"] as Number).toInt(),
            minuteOfDay = (it["minuteOfDay"] as Number).toInt(),
            titleId = (it["titleId"] as Number).toInt(),
            title = it["title"] as String,
            body = it["body"] as String,
        )
    }

    fun save(context: Context, reminders: List<PlannedReminder>) {
        val array = JSONArray()
        reminders.forEach {
            array.put(
                JSONObject()
                    .put("year", it.year).put("month", it.month).put("day", it.day)
                    .put("minuteOfDay", it.minuteOfDay).put("titleId", it.titleId)
                    .put("title", it.title).put("body", it.body)
            )
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, array.toString()).commit()
    }

    /** An unreadable list reads as empty, so a receiver never crashes on it. */
    fun load(context: Context): List<PlannedReminder> {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return emptyList()
        return runCatching { parse(json) }.getOrDefault(emptyList())
    }

    private fun parse(json: String): List<PlannedReminder> {
        val array = JSONArray(json)
        return (0 until array.length()).map { index ->
            val item = array.getJSONObject(index)
            PlannedReminder(
                year = item.getInt("year"),
                month = item.getInt("month"),
                day = item.getInt("day"),
                minuteOfDay = item.getInt("minuteOfDay"),
                titleId = item.getInt("titleId"),
                title = item.getString("title"),
                body = item.getString("body"),
            )
        }
    }
}
