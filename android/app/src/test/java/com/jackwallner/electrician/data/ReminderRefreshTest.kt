package com.jackwallner.electrician

import com.jackwallner.electrician.data.AppSettings
import com.jackwallner.electrician.data.InMemoryStore
import com.jackwallner.electrician.data.ReminderScheduler
import java.time.DayOfWeek
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** iOS B3: launch and each return to the app put back what the reminder switches promise. */
class ReminderRefreshTest {
    private class Recorder : ReminderScheduler {
        val calls = mutableListOf<String>()
        override fun scheduleDaily(hour: Int, minute: Int) { calls += "daily $hour:$minute" }
        override fun cancelDaily() { calls += "cancel daily" }
        override fun scheduleGameNight(day: DayOfWeek, hour: Int, minute: Int) { calls += "warm-up $day $hour:$minute" }
        override fun cancelGameNight() { calls += "cancel warm-up" }
    }

    private val defaults = InMemoryStore()

    /** A phone restored from a backup: the switches read on and no alarm exists. */
    private fun restored(daily: Boolean, warmUp: Boolean): Pair<AppSettings, Recorder> {
        defaults.putBoolean("settings.reminderEnabled", daily)
        defaults.putBoolean("settings.gameNightReminderEnabled", warmUp)
        val scheduler = Recorder()
        return AppSettings(defaults, scheduler) to scheduler
    }

    @Test
    fun allowedNotificationsPutEveryEnabledReminderBack() {
        val (settings, scheduler) = restored(daily = true, warmUp = true)
        assertFalse(settings.refreshReminders(canNotify = true))
        assertEquals(2, scheduler.calls.size)
        assertTrue(scheduler.calls.any { it.startsWith("daily 9:0") })
        assertTrue(scheduler.calls.any { it.startsWith("warm-up") })
    }

    @Test
    fun aReminderThatCannotPostAsksForPermission() {
        val (settings, scheduler) = restored(daily = true, warmUp = false)
        assertTrue(settings.refreshReminders(canNotify = false))
        assertTrue("nothing is laid until the answer comes back", scheduler.calls.isEmpty())
        assertTrue("the switch keeps the choice while the question is open", settings.reminderEnabled)
    }

    @Test
    fun aRefusalSwitchesTheRemindersOffAndSaysWhy() {
        val (settings, scheduler) = restored(daily = true, warmUp = true)
        settings.remindersRefused()
        assertFalse(settings.reminderEnabled)
        assertFalse(settings.gameNightReminderEnabled)
        assertTrue(settings.reminderPermissionDenied)
        assertEquals(listOf("cancel daily", "cancel warm-up"), scheduler.calls)
        assertFalse("off stays off: the next launch does not ask again", settings.refreshReminders(canNotify = false))
    }

    @Test
    fun nothingSwitchedOnDoesNothing() {
        val (settings, scheduler) = restored(daily = false, warmUp = false)
        assertFalse(settings.refreshReminders(canNotify = false))
        assertFalse(settings.refreshReminders(canNotify = true))
        assertTrue(scheduler.calls.isEmpty())
        assertFalse(settings.reminderPermissionDenied)
    }
}
