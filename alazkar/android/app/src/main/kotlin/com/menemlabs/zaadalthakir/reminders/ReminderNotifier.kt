package com.menemlabs.zaadalthakir.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.menemlabs.zaadalthakir.MainActivity
import com.menemlabs.zaadalthakir.R

object ReminderNotifier {
    const val CHANNEL_ID = "daily_reminders"
    const val EXTRA_TITLE_ID = "reminder_title_id"

    fun show(context: Context, reminder: PlannedReminder) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.reminder_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
            )
        }
        val open = Intent(context, MainActivity::class.java).apply {
            // Clears a share sheet or mail screen left above the app, so the
            // tap reaches MainActivity instead of only bringing the task forward.
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_TITLE_ID, reminder.titleId)
        }
        val content = PendingIntent.getActivity(
            context,
            reminder.titleId,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        builder.setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(reminder.title)
            .setContentIntent(content)
            .setAutoCancel(true)
        if (reminder.body.isNotEmpty()) builder.setContentText(reminder.body)
        manager.notify(reminder.titleId, builder.build())
    }
}
