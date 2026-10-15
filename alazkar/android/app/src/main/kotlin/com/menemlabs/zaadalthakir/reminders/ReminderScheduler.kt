package com.menemlabs.zaadalthakir.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object ReminderScheduler {
    private const val WINDOW_MS = 15 * 60 * 1000L
    private const val STALE_MS = 60 * 60 * 1000L

    /**
     * Keeps a newly planned list. It starts from now, so a reminder already
     * due but not yet shown (its alarm runs late, or the app was stopped)
     * would be lost: it is shown first, see [ReminderDue.owedBeforeReplacing].
     */
    fun replace(context: Context, reminders: List<PlannedReminder>) {
        ReminderDue.owedBeforeReplacing(
            ReminderStore.load(context),
            reminders,
            System.currentTimeMillis(),
            STALE_MS,
        ).forEach { ReminderNotifier.show(context, it) }
        ReminderStore.save(context, reminders)
        scheduleNext(context)
    }

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
