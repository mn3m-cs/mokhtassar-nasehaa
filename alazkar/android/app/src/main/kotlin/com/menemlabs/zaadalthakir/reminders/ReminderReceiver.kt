package com.menemlabs.zaadalthakir.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // The phone was on, so a late alarm was held back by power saving:
        // the missed reminder is still shown, however late.
        postDue(context, staleMs = null)
    }

    companion object {
        fun postDue(context: Context, staleMs: Long?) {
            ReminderDue.toShow(ReminderStore.load(context), System.currentTimeMillis(), staleMs)
                .forEach { ReminderNotifier.show(context, it) }
            ReminderScheduler.scheduleNext(context)
        }
    }
}
