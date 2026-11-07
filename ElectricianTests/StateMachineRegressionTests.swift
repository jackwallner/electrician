import Combine
import SwiftUI
import UIKit
import XCTest
@testable import Electrician

/// Regression tests for the state machine audit of 2026-11-06 and its review
/// (`project-docs/audits/state-machines-2026-11-06-fixes.md`).
@MainActor
final class StateMachineRegressionTests: XCTestCase {

    private var suite: UserDefaults!
    private var suiteName = ""
    private var window: UIWindow?

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "sm.regression.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)!
        SubscriptionService.shared.setLocalOverride(isPro: false)
        SubscriptionService.shared.setEntitlementKnownForTesting(true)
        _ = AppRouter.shared.consumePendingDestination()
    }

    override func tearDown() async throws {
        window?.isHidden = true
        window = nil
        SubscriptionService.shared.setLocalOverride(isPro: false)
        SubscriptionService.shared.setEntitlementKnownForTesting(true)
        _ = AppRouter.shared.consumePendingDestination()
        suite.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    private func mountHome(settings: AppSettings) -> UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        let root = HomeView()
            .environmentObject(ProgressStore.shared)
            .environmentObject(SubscriptionService.shared)
            .environmentObject(settings)
            .environmentObject(AppRouter.shared)
            .environmentObject(CandidateProfile.shared)
        let w = UIWindow(windowScene: scene)
        w.rootViewController = UIHostingController(rootView: root)
        w.makeKeyAndVisible()
        window = w
        return w
    }

    private func spin(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    // MARK: B1 - lapsed while the app was closed

    /// From the audit's repro: a member whose entitlement resolves false at
    /// launch (false to false, so no change fires) must lose the warm-up reminder.
    func testB1_lapsedMemberLaunchClearsWarmUpReminder() async {
        suite.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: suite)
        XCTAssertTrue(settings.examWarmUpReminderEnabled, "precondition: reminder persisted on")
        XCTAssertFalse(SubscriptionService.shared.isPro, "precondition: not entitled")
        let w = mountHome(settings: settings)
        XCTAssertNotNil(w?.rootViewController?.view.window, "precondition: Home is mounted")
        await spin(1.5)
        XCTAssertFalse(SubscriptionService.shared.isPro, "precondition: still not entitled")
        XCTAssertFalse(settings.examWarmUpReminderEnabled)
        XCTAssertFalse(suite.bool(forKey: "settings.gameNightReminderEnabled"))
    }

    /// The same clearing must not hit a paying member whose cached answer is
    /// stale: RevenueCat reports a live subscription as inactive from a cache
    /// more than a few days old, then the fetch says entitled.
    func testB1_staleCacheDoesNotClearPayingMembersReminder() async {
        SubscriptionService.shared.setEntitlementKnownForTesting(false)
        suite.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: suite)
        let w = mountHome(settings: settings)
        XCTAssertNotNil(w?.rootViewController?.view.window, "precondition: Home is mounted")
        await spin(0.5)
        let fourDaysAgo = Date().addingTimeInterval(-4 * 86_400)
        SubscriptionService.shared.applyEntitlement(false, requestedAt: fourDaysAgo)
        await spin(0.5)
        XCTAssertFalse(SubscriptionService.shared.entitlementKnown)
        XCTAssertTrue(settings.examWarmUpReminderEnabled, "a stale cache is not an answer")
        SubscriptionService.shared.applyEntitlement(true, requestedAt: Date())
        await spin(0.5)
        XCTAssertTrue(SubscriptionService.shared.isPro)
        XCTAssertTrue(settings.examWarmUpReminderEnabled)
    }

    func testB1_onlyFreshNegativeAnswersCount() {
        let now = Date()
        XCTAssertTrue(SubscriptionService.isCurrentAnswer(entitled: false, requestedAt: now, now: now))
        XCTAssertFalse(SubscriptionService.isCurrentAnswer(
            entitled: false, requestedAt: now.addingTimeInterval(-4 * 86_400), now: now))
        XCTAssertTrue(SubscriptionService.isCurrentAnswer(
            entitled: true, requestedAt: now.addingTimeInterval(-4 * 86_400), now: now))
    }

    // MARK: B2 - reminder denial in onboarding

    func testB2_laterGrantClearsDenialWarning() {
        let settings = AppSettings(defaults: suite)
        settings.handleReminderAuthorization(granted: false)
        XCTAssertTrue(settings.reminderPermissionDenied, "precondition")
        XCTAssertFalse(settings.reminderEnabled, "precondition")
        settings.handleReminderAuthorization(granted: true)
        XCTAssertFalse(settings.reminderPermissionDenied)
    }

    /// "Turn them on there and we will schedule it": coming back with
    /// permission turns the reminder the user asked for back on.
    func testB2_returningWithPermissionTurnsReminderBackOn() {
        let settings = AppSettings(defaults: suite)
        settings.handleReminderAuthorization(granted: false)
        settings.resumeDailyReminder(authorized: false)
        XCTAssertFalse(settings.reminderEnabled, "still off while iOS refuses")
        settings.resumeDailyReminder(authorized: true)
        XCTAssertTrue(settings.reminderEnabled)
        XCTAssertTrue(suite.bool(forKey: "settings.reminderEnabled"))
    }

    func testB2_noRemindersEndsWarningAndRetry() {
        let settings = AppSettings(defaults: suite)
        settings.handleReminderAuthorization(granted: false)
        settings.declineReminders()
        XCTAssertFalse(settings.reminderPermissionDenied)
        settings.resumeDailyReminder(authorized: true)
        XCTAssertFalse(settings.reminderEnabled, "a declined reminder is not switched back on")
    }

    func testB2_noRetryWithoutAnEarlierRefusal() {
        let settings = AppSettings(defaults: suite)
        settings.resumeDailyReminder(authorized: true)
        XCTAssertFalse(settings.reminderEnabled)
    }

    // MARK: B3 - flashcard Undo

    /// The store calls FlashcardDrillView makes for a plain card: Again, Undo,
    /// Knew it. Only the final answer may count.
    func testB3_undoneMissLeavesNoTrace() {
        let records = PracticeRecordStore(defaults: suite)
        let progress = ProgressStore(defaults: suite)
        let id = "basics-chapters"
        let room = "basics-room"
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)

        let before = records.snapshot(itemID: id)
        let wasSeen = progress.seenItems.contains(id)
        let wasMissed = progress.missedItems.contains(id)
        progress.recordItem(id: id, correct: false)
        records.record(itemID: id, roomID: room, correct: false, now: t0)
        XCTAssertEqual(records.records[id]?.attempts, 1, "precondition: Again recorded")

        progress.restoreItem(id: id, wasSeen: wasSeen, wasMissed: wasMissed)
        records.restore(itemID: id, to: before)

        progress.recordItem(id: id, correct: true)
        records.record(itemID: id, roomID: room, correct: true, now: t0.addingTimeInterval(30))

        let r = records.records[id]!
        XCTAssertEqual(r.attempts, 1)
        XCTAssertEqual(r.correct, 1)
        XCTAssertFalse(r.needsReview)
        XCTAssertFalse(progress.missedItems.contains(id))
        XCTAssertEqual(records.roomStats().first { $0.id == room }?.correct, 1)
        // Persisted, not just in memory.
        XCTAssertEqual(PracticeRecordStore(defaults: suite).records[id]?.attempts, 1)
        XCTAssertFalse(ProgressStore(defaults: suite).missedItems.contains(id))
    }

    /// Undo puts back a card's earlier history, not an empty row.
    func testB3_undoRestoresEarlierHistory() {
        let records = PracticeRecordStore(defaults: suite)
        let progress = ProgressStore(defaults: suite)
        let id = "basics-chapters"
        progress.recordItem(id: id, correct: false)
        records.record(itemID: id, roomID: "basics-room", correct: false)
        let before = records.snapshot(itemID: id)

        progress.recordItem(id: id, correct: true)
        records.record(itemID: id, roomID: "basics-room", correct: true)
        progress.restoreItem(id: id, wasSeen: true, wasMissed: true)
        records.restore(itemID: id, to: before)

        XCTAssertEqual(records.records[id]?.attempts, 1)
        XCTAssertEqual(records.records[id]?.correct, 0)
        XCTAssertTrue(progress.missedItems.contains(id))
    }

    // MARK: B4 - Exam Target Cancel

    func testB4_cancelRestoresExamDate() {
        let exam = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        suite.set(exam, forKey: "candidate.examDate")
        let profile = CandidateProfile(defaults: suite)
        let opened = profile.snapshot()
        profile.examDate = nil
        profile.dailyGoal = 40
        profile.restore(opened)
        XCTAssertEqual(profile.examDate, exam)
        let reloaded = CandidateProfile(defaults: suite)
        XCTAssertEqual(reloaded.examDate, exam)
        XCTAssertEqual(reloaded.dailyGoal, 15)
    }

    /// An install that predates the edition picker has no `candidate.edition`
    /// key, which resolves to this app's edition. Cancel must leave it absent.
    func testB4_cancelLeavesAbsentEditionKeyAbsent() {
        let profile = CandidateProfile(defaults: suite)
        XCTAssertNil(suite.object(forKey: "candidate.edition"), "precondition: legacy install")
        let opened = profile.snapshot()
        profile.edition = .unsure
        profile.restore(opened)
        XCTAssertEqual(CandidateProfile(defaults: suite).edition, .nec2023)
        XCTAssertEqual(profile.snapshot(), opened)
    }

    // MARK: B5 - Home across midnight

    func testB5_dayClockPublishesWhenTheDayTurns() async {
        let center = NotificationCenter()
        let evening = Calendar.current.date(bySettingHour: 23, minute: 50, second: 0, of: Date())!
        var current = evening
        let clock = DayClock(center: center, now: { current })
        let changed = expectation(description: "today changed")
        let watch = clock.$today.dropFirst().sink { _ in changed.fulfill() }

        current = evening.addingTimeInterval(5 * 60)
        center.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        await spin(0.3)
        XCTAssertEqual(clock.today, Calendar.current.startOfDay(for: evening), "same day: no redraw")

        current = evening.addingTimeInterval(20 * 60)
        center.post(name: .NSCalendarDayChanged, object: nil)
        await fulfillment(of: [changed], timeout: 2)
        XCTAssertEqual(clock.today, Calendar.current.startOfDay(for: current))
        watch.cancel()
    }

    // MARK: B7 - trial attribution

    func testB7_ineligibleBuyerDidNotStartTrial() {
        XCTAssertFalse(SubscriptionService.purchaseStartsTrial(offersFreeTrial: true, eligible: false))
        XCTAssertTrue(SubscriptionService.purchaseStartsTrial(offersFreeTrial: true, eligible: true))
        XCTAssertTrue(SubscriptionService.purchaseStartsTrial(offersFreeTrial: true, eligible: nil))
        XCTAssertFalse(SubscriptionService.purchaseStartsTrial(offersFreeTrial: false, eligible: true))
    }
}
