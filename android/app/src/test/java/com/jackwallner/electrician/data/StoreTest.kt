package com.jackwallner.electrician

import com.jackwallner.electrician.content.DrillLibrary
import com.jackwallner.electrician.content.CandidateMistake
import com.jackwallner.electrician.content.CodeMinuteContent
import com.jackwallner.electrician.content.PracticeSkill
import com.jackwallner.electrician.data.AppClock
import com.jackwallner.electrician.data.ConversionDiagnostics
import com.jackwallner.electrician.data.InMemoryStore
import com.jackwallner.electrician.data.CodeMinuteStore
import com.jackwallner.electrician.data.MasteryLevel
import com.jackwallner.electrician.data.PracticeRecordStore
import com.jackwallner.electrician.data.ProgressStore
import com.jackwallner.electrician.data.ReviewPromptTracker
import com.jackwallner.electrician.data.WhatsNewTracker
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ports of the iOS store tests: the logic that was hand-translated rather than exported. */
class StoreTest {
    private val defaults = InMemoryStore()
    private val clock = AppClock(Clock.fixed(Instant.parse("2026-09-30T12:00:00Z"), ZoneOffset.UTC))
    private val room = "basics-room"

    private fun advanceDays(days: Long) {
        clock.clock = Clock.offset(clock.clock, java.time.Duration.ofDays(days))
    }

    @Test
    fun streakCountsConsecutiveDaysAndResetsOnAGap() {
        val store = ProgressStore(defaults, clock)
        store.recordSession("meet-tiles")
        store.recordSession("meet-tiles")
        assertEquals(1, store.streakCount)
        assertEquals(2, store.completions("meet-tiles"))
        advanceDays(1)
        store.recordSession("navigation-quiz")
        assertEquals(2, store.streakCount)
        advanceDays(3)
        store.recordSession("navigation-quiz")
        assertEquals(1, store.streakCount)
    }

    @Test
    fun seenAndMissedPersistAndUndoRestoresThem() {
        val store = ProgressStore(defaults, clock)
        store.recordItem("q1", correct = false)
        store.recordItem("other", correct = true)
        val snapshot = store.snapshotItem("missed")
        store.recordItem("missed", correct = false)
        store.recordItem("q1", correct = true)
        val reloaded = ProgressStore(defaults, clock)
        assertTrue("q1" in reloaded.seenItems)
        assertFalse("A correct answer clears the miss", "q1" in reloaded.missedItems)
        reloaded.restoreItem(snapshot)
        val again = ProgressStore(defaults, clock)
        assertFalse("missed" in again.seenItems)
    }

    @Test
    fun resetKeepsOnboardingAndTheQuickSessionRestsForTheDay() {
        val store = ProgressStore(defaults, clock)
        store.setOnboarded(true)
        store.recordSession("a")
        store.markQuickSessionCompleted()
        assertTrue(store.quickSessionCompletedToday())
        advanceDays(1)
        assertFalse(store.quickSessionCompletedToday())
        store.resetAll()
        assertEquals(0, store.streakCount)
        assertTrue("Reset must not re-trigger onboarding", ProgressStore(defaults, clock).hasOnboarded)
    }

    @Test
    fun undoThenReanswerDoesNotCreateMastery() {
        val store = PracticeRecordStore(defaults, clock)
        val snapshot = store.snapshotAnswer("q1")
        store.record("q1", room, correct = true)
        store.restoreAnswer(snapshot)
        assertNull(PracticeRecordStore(defaults, clock).records["q1"])
        store.record("q1", room, correct = true)
        assertEquals(1, store.records["q1"]!!.streak)
        assertFalse(store.records["q1"]!!.isKnown(clock.millis()))
    }

    @Test
    fun missedItemEntersAndLeavesTheQueueWorstFirst() {
        val store = PracticeRecordStore(defaults, clock)
        store.record("q1", room, correct = false)
        assertEquals(listOf("q1"), store.reviewQueue())
        store.record("q1", room, correct = true)
        assertEquals("One correct answer schedules it a day out", emptyList<String>(), store.reviewQueue())
        store.record("q1", room, correct = true)
        assertFalse("Two in a row retires it", store.records["q1"]!!.needsReview)

        repeat(3) { store.record("q2", room, correct = false) }
        store.record("q3", room, correct = true)
        store.record("q3", room, correct = false)
        assertEquals("q2", store.reviewQueue().first())
    }

    @Test
    fun generatedItemsCollapseAndOneOffsStayOutOfReview() {
        val store = PracticeRecordStore(defaults, clock)
        val prefix = PracticeSkill.ampacity.itemPrefix
        store.record(prefix + "a", room, correct = false)
        store.record(prefix + "b", room, correct = true)
        store.record("code-minute-rollup", "calc-room", correct = false, isReviewable = false)
        assertEquals(2, store.records[PracticeSkill.ampacity.raw]!!.attempts)
        assertEquals(0, store.dueCount())
        store.record("q1", room, correct = false)
        store.record("calc-ampacity-1", "calc-room", correct = false)
        assertEquals(2, store.dueCount())
        assertEquals(listOf("q1"), store.reviewQueue(presentable = setOf("q1")))
    }

    @Test
    fun masteryLevelsAndStaleness() {
        assertEquals(MasteryLevel.UNTOUCHED, MasteryLevel.level(0, 10))
        assertEquals(MasteryLevel.LEARNING, MasteryLevel.level(3, 10))
        assertEquals(MasteryLevel.SOLID, MasteryLevel.level(4, 10))
        assertEquals(MasteryLevel.SHARP, MasteryLevel.level(9, 10))

        val store = PracticeRecordStore(defaults, clock)
        val tileRoom = DrillLibrary.room(room)!!
        val id = PracticeRecordStore.trackableItemIDs(tileRoom, isMember = false).first()
        store.record(id, room, correct = true)
        store.record(id, room, correct = true)
        assertEquals(1, store.mastery(tileRoom, isMember = false).known)
        advanceDays(10)
        assertEquals("A full interval past due goes rusty", 0, store.mastery(tileRoom, isMember = false).known)
    }

    @Test
    fun legacyMigrationSeedsEngagementOnlyOnce() {
        val store = PracticeRecordStore(defaults, clock)
        val ids = PracticeRecordStore.trackableItemIDs(DrillLibrary.room(room)!!, true).take(2)
        store.migrateLegacyProgress(seen = ids.toSet() + "gone", missed = setOf(ids[0]))
        assertEquals(2, store.records.size)
        assertEquals(0, store.records[ids[0]]!!.streak)
        assertEquals(1, store.records[ids[1]]!!.streak)
        store.resetAll()
        store.migrateLegacyProgress(seen = ids.toSet(), missed = emptySet())
        assertTrue(store.records.isEmpty())
    }

    @Test
    fun codeMinuteKeepsOnlyTheFirstAttempt() {
        val store = CodeMinuteStore(defaults, clock)
        val challenge = CodeMinuteContent.challenge(LocalDate.of(2026, 9, 30))
        val first = store.record(challenge, listOf(true, true, false, false, true))
        store.record(challenge, List(5) { true })
        assertEquals(3, CodeMinuteStore(defaults, clock).result(LocalDate.of(2026, 9, 30))!!.score)
        assertEquals("Sep 30", first.shortDate)
        assertTrue(first.shareText.startsWith("Code Minute Sep 30: 3/5"))
        assertEquals(1, store.completedThisWeek())
    }

    @Test
    fun reviewCardWaitsForTheSecondLaunchAndHonoursCooldowns() {
        val tracker = ReviewPromptTracker(defaults, clock)
        tracker.recordAppLaunch()
        tracker.recordPositiveMoment()
        assertFalse("never in the first session", tracker.shouldShowAfterPositiveMoment())
        tracker.recordAppLaunch()
        assertTrue(tracker.shouldShowAfterPositiveMoment())
        tracker.markStoreCardRequested()
        assertFalse(tracker.shouldShowAfterPositiveMoment())
        advanceDays(29)
        assertFalse(tracker.shouldShowAfterPositiveMoment())
        advanceDays(2)
        assertTrue(tracker.shouldShowAfterPositiveMoment())
        tracker.markOpenedWriteReview()
        advanceDays(400)
        assertFalse("A terminal outcome retires it", tracker.shouldShowAfterPositiveMoment())
    }

    @Test
    fun conversionAttributesStayEmptyUntilAPitchAndFreezeAtConversion() {
        val diagnostics = ConversionDiagnostics(defaults, clock)
        diagnostics.recordAppOpen()
        assertTrue(diagnostics.subscriberAttributes.isEmpty())
        diagnostics.recordPitchView("electrician_onboarding_trial")
        diagnostics.recordPitchView("electrician_home_sheet")
        diagnostics.recordConversion("monthly", startedTrial = true, offeringId = "default")
        diagnostics.recordConversion("yearly", startedTrial = false, offeringId = null)
        val attributes = diagnostics.subscriberAttributes
        assertEquals("2", attributes["pitch_views_total"])
        assertEquals("1", attributes["pitch_views_onboarding_trial"])
        assertEquals("home_sheet", attributes["converted_surface"])
        assertEquals("monthly", attributes["converted_plan"])
        assertEquals("true", attributes["converted_with_trial"])
        assertEquals("1", attributes["opens_before_first_pitch"])
    }

    @Test
    fun whatsNewNeverShowsOnAFreshInstall() {
        val tracker = WhatsNewTracker(defaults, "1.0.3")
        assertFalse(tracker.shouldPresent(hasOnboarded = false))
        tracker.markCurrentAsBaseline()
        assertFalse(tracker.shouldPresent(hasOnboarded = true))
        assertFalse("No notes at or below this version", WhatsNewTracker(InMemoryStore(), "0.9").shouldPresent(hasOnboarded = true))
    }

    /** iOS ships no release notes yet, so nothing presents until a release earns them. */
    @Test
    fun noReleaseNotesMeansNothingPresents() {
        assertNull(WhatsNewTracker(defaults, "1.0.3").currentRelease)
        assertFalse(WhatsNewTracker(defaults, "1.0.3").shouldPresent(hasOnboarded = true))
        assertTrue(WhatsNewTracker.isOlder("1.4.1", "1.4.10"))
    }

    @Test
    fun namedMistakesTallyCapAndWorkOffOneAtATime() {
        val store = PracticeRecordStore(defaults, clock)
        repeat(7) { store.recordMistake(CandidateMistake.derateFrom75) }
        store.recordMistake(CandidateMistake.ignoredSmallConductorCap)
        assertEquals(PracticeRecordStore.MAX_OUTSTANDING_PER_PATTERN + 1, store.outstandingMistakeCount)
        assertEquals(CandidateMistake.derateFrom75, store.outstandingMistakes().first())
        val reloaded = PracticeRecordStore(defaults, clock)
        assertEquals(6, reloaded.outstandingMistakeCount)
        reloaded.resolveMistake(CandidateMistake.ignoredSmallConductorCap.id)
        assertEquals(listOf(CandidateMistake.derateFrom75), reloaded.outstandingMistakes())
        reloaded.resetAll()
        assertEquals(0, PracticeRecordStore(defaults, clock).outstandingMistakeCount)
    }

    @Test
    fun tourPracticeDoesNotUnlockHomeExtras() {
        val progress = ProgressStore(defaults, clock)
        progress.recordSession("tour")
        progress.sessionsAtOnboarding = progress.totalSessions
        assertFalse(progress.hasPracticedSinceOnboarding)
        progress.recordSession("meet-the-code")
        assertTrue(progress.hasPracticedSinceOnboarding)
        progress.resetAll()
        assertEquals(0, progress.sessionsAtOnboarding)
    }
}
