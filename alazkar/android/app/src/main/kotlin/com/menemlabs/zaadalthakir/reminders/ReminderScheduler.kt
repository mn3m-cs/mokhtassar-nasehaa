package com.menemlabs.zaadalthakir.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object ReminderScheduler {
    private const val WINDOW_MS = 15 * 60 * 1000L

    /** Drops what has passed and keeps one alarm for the earliest entry. */
    fun scheduleNext(context: Context) {
        val now = System.currentTimeMillis()
        val upcoming = ReminderStore.load(context)
            .filter { it.atMillis() > now }
            .sortedBy { it.atMillis() }
        ReminderStore.save(context, upcoming)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val alarm = alarmIntent(context)
        alarmManager.cancel(alarm)
        val next = upcoming.firstOrNull() ?: return
        alarmManager.setWindow(AlarmManager.RTC_WAKEUP, next.atMillis(), WINDOW_MS, alarm)
    }

    private fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
