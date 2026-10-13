package com.menemlabs.zaadalthakir.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Alarms do not survive a reboot, and a clock change moves local times. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            // A reminder due shortly before the phone came back on is still
            // shown; one more than an hour old is dropped.
            Intent.ACTION_BOOT_COMPLETED -> ReminderReceiver.postDue(context, staleMs = STALE_MS)
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED ->
                ReminderScheduler.scheduleNext(context)
        }
    }

    companion object {
        private const val STALE_MS = 60 * 60 * 1000L
    }
}
