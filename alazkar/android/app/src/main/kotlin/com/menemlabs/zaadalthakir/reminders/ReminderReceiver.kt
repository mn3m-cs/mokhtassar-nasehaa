package com.menemlabs.zaadalthakir.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val now = System.currentTimeMillis()
        ReminderStore.load(context)
            .filter { it.atMillis() <= now && it.atMillis() > now - STALE_MS }
            .forEach { ReminderNotifier.show(context, it) }
        ReminderScheduler.scheduleNext(context)
    }

    companion object {
        /** A reminder more than an hour late (the phone was off) is skipped. */
        private const val STALE_MS = 60 * 60 * 1000L
    }
}
