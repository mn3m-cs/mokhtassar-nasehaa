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

    /**
     * What an old list still owes when a new one replaces it: entries already
     * due and not yet shown, newer than [staleMs], for sections the new list
     * still reminds of. A section the reader just turned off is not shown.
     */
    fun owedBeforeReplacing(
        old: List<PlannedReminder>,
        new: List<PlannedReminder>,
        nowMillis: Long,
        staleMs: Long,
    ): List<PlannedReminder> = toShow(old, nowMillis, staleMs)
        .filter { due -> new.any { it.titleId == due.titleId } }
}
