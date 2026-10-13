package com.menemlabs.zaadalthakir.reminders

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ReminderDueTest {
    private val hour = 60 * 60 * 1000L

    private fun entry(day: Int, minuteOfDay: Int, titleId: Int) =
        PlannedReminder(2026, 10, day, minuteOfDay, titleId, "t$titleId", "")

    private fun at(day: Int, minuteOfDay: Int): Long = entry(day, minuteOfDay, 0).atMillis()

    init {
        TimeZone.setDefault(TimeZone.getTimeZone("Africa/Cairo"))
        Calendar.getInstance()
    }

    @Test
    fun anAlarmHeldBackByDozeStillShowsTheMissedMorningReminder() {
        val morning = entry(14, 6 * 60, 1)
        val tomorrow = entry(15, 6 * 60, 1)

        val shown = ReminderDue.toShow(listOf(morning, tomorrow), at(14, 8 * 60), staleMs = null)

        assertEquals(listOf(morning), shown)
    }

    @Test
    fun aLateAlarmShowsOnlyTheLatestEntryOfEachSection() {
        val yesterday = entry(13, 22 * 60, 18)
        val today = entry(14, 6 * 60, 1)
        val tonight = entry(14, 1 * 60, 18)

        val shown = ReminderDue.toShow(listOf(yesterday, tonight, today), at(14, 7 * 60), staleMs = null)

        assertEquals(setOf(tonight, today), shown.toSet())
    }

    @Test
    fun afterABootAReminderDueWithinTheHourIsShown() {
        val morning = entry(14, 6 * 60, 1)

        val shown = ReminderDue.toShow(listOf(morning), at(14, 6 * 60 + 5), staleMs = hour)

        assertEquals(listOf(morning), shown)
    }

    @Test
    fun afterABootAReminderMoreThanAnHourOverdueIsDropped() {
        val morning = entry(14, 6 * 60, 1)

        val shown = ReminderDue.toShow(listOf(morning), at(14, 7 * 60 + 1), staleMs = hour)

        assertEquals(emptyList<PlannedReminder>(), shown)
    }

    @Test
    fun aReminderStillInTheFutureIsNotShown() {
        val shown = ReminderDue.toShow(listOf(entry(14, 6 * 60, 1)), at(14, 5 * 60), staleMs = null)

        assertEquals(emptyList<PlannedReminder>(), shown)
    }
}
