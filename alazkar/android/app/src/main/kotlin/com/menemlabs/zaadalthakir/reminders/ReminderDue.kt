package com.menemlabs.zaadalthakir.reminders

object ReminderDue {
    /**
     * The entries to post now: those already due, newer than [staleMs] when
     * given, and only the latest one per section, so a late wake-up never
     * posts the same section twice.
     */
    fun toShow(
        entries: List<PlannedReminder>,
        nowMillis: Long,
        staleMs: Long?,
    ): List<PlannedReminder> = entries
        .filter { it.atMillis() <= nowMillis }
        .filter { staleMs == null || it.atMillis() > nowMillis - staleMs }
        .groupBy { it.titleId }
        .map { (_, due) -> due.maxByOrNull { it.atMillis() }!! }
}
