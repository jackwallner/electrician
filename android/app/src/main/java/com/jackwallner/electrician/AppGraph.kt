package com.jackwallner.electrician

import android.content.Context
import com.jackwallner.electrician.data.AlarmReminderScheduler
import com.jackwallner.electrician.data.AppClock
import com.jackwallner.electrician.data.AppSettings
import com.jackwallner.electrician.data.ConversionDiagnostics
import com.jackwallner.electrician.data.CandidateProfile
import com.jackwallner.electrician.data.CodeMinuteStore
import com.jackwallner.electrician.data.PracticeRecordStore
import com.jackwallner.electrician.data.ProgressStore
import com.jackwallner.electrician.data.ReviewPromptTracker
import com.jackwallner.electrician.data.SharedPreferencesStore
import com.jackwallner.electrician.data.SubscriptionService
import com.jackwallner.electrician.data.WhatsNewTracker
import kotlinx.coroutines.MainScope

/** Every long-lived object the screens share, built once per process. */
class AppGraph(context: Context) {
    val appContext: Context = context.applicationContext
    val scope = MainScope()
    val clock = AppClock()
    val defaults = SharedPreferencesStore(appContext)
    val settings = AppSettings(defaults, AlarmReminderScheduler(appContext))
    val progress = ProgressStore(defaults, clock)
    val records = PracticeRecordStore(defaults, clock)
    val minutes = CodeMinuteStore(defaults, clock)
    val candidate = CandidateProfile(defaults, clock)
    val review = ReviewPromptTracker(defaults, clock)
    val diagnostics = ConversionDiagnostics(defaults, clock)
    val subscriptions = SubscriptionService(appContext, defaults, diagnostics)
    val whatsNew = WhatsNewTracker(defaults, BuildConfig.VERSION_NAME)

    /** Settings' Reset Progress: every practice stat, never onboarding or purchases. */
    fun resetProgress() {
        progress.resetAll()
        records.resetAll()
        minutes.resetAll()
    }

    /**
     * A wrong pick that one named mistake produces is tallied; a right answer on
     * a problem that set an outstanding trap works that habit off by one.
     */
    fun recordMistakeOutcome(item: com.jackwallner.electrician.content.QuickItem, pick: Int, correct: Boolean) {
        if (!correct) {
            item.mistake(pick)?.let(records::recordMistake)
            return
        }
        item.mistakes.values.map { it.id }.distinct().filter { it in records.mistakes }.forEach(records::resolveMistake)
    }

    /** Fix My Mistakes: the authored questions that are due, then new problems that set the traps you repeat. */
    fun fixMyMistakesItems(isPro: Boolean): List<com.jackwallner.electrician.content.QuickItem> {
        val due = com.jackwallner.electrician.content.SessionBuilder.reviewSession(
            records.reviewQueue(presentable = com.jackwallner.electrician.content.SessionBuilder.reviewableIDs(isPro)), isPro,
        )
        val targeted = com.jackwallner.electrician.content.EndlessPractice.targetedItems(records.outstandingMistakes(), maxOf(0, 10 - due.size))
        return due + targeted
    }
}
