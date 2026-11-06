// Moved out of ElectricianTests so it does not build with the app. To rerun, copy it back to
// ElectricianTests/StateMachineAuditRepro.swift and run:
//   gh-sim test --scheme Electrician --only ElectricianTests/StateMachineAuditRepro
// Recorded run 2026-11-06 (xcode 27.1, iPhone 17, iOS 27.2): 4 failed (B1-B4), 4 control tests passed.
import SwiftUI
import UIKit
import XCTest
@testable import Electrician

/// State machine audit 2026-11-06 repro suite. Failing tests are expected: each
/// failing assertion is the promised behaviour. Controls pass.
@MainActor
final class StateMachineAuditRepro: XCTestCase {

    private var suite: UserDefaults!
    private var suiteName = ""
    private var window: UIWindow?

    override func setUp() async throws {
        suiteName = "sm.audit.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)!
        SubscriptionService.shared.setLocalOverride(isPro: false)
    }

    override func tearDown() async throws {
        window?.isHidden = true
        window = nil
        SubscriptionService.shared.setLocalOverride(isPro: false)
        suite.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Host Home with injected settings

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

    // MARK: B1 - Pro lapsed while the app was closed

    /// Launch state of a lapsed member: the warm-up reminder flag is persisted
    /// true, the entitlement is not active. HomeView:189-190 is the app's own rule
    /// that a non-member has no warm-up reminder.
    func testB1_lapsedMemberLaunchLeavesWarmUpReminderOn() async {
        suite.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: suite)
        XCTAssertTrue(settings.examWarmUpReminderEnabled, "precondition: reminder persisted on")
        XCTAssertFalse(SubscriptionService.shared.isPro, "precondition: not entitled")
        let w = mountHome(settings: settings)
        XCTAssertNotNil(w?.rootViewController?.view.window, "precondition: Home is mounted")
        await spin(1.5)
        XCTAssertFalse(SubscriptionService.shared.isPro, "precondition: still not entitled")
        print("B1 recorded: examWarmUpReminderEnabled=\(settings.examWarmUpReminderEnabled) isPro=\(SubscriptionService.shared.isPro)")
        XCTAssertFalse(settings.examWarmUpReminderEnabled,
                       "a member who is no longer entitled must not keep the weekly warm-up reminder")
    }

    /// Control: the same mounted Home DOES clear the reminder on a live true to
    /// false transition, so the wiring works; it just misses the launch case.
    func testB1_control_liveLapseClearsWarmUpReminder() async {
        suite.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: suite)
        XCTAssertTrue(settings.examWarmUpReminderEnabled, "precondition")
        let w = mountHome(settings: settings)
        XCTAssertNotNil(w?.rootViewController?.view.window, "precondition: Home is mounted")
        await spin(1.0)
        SubscriptionService.shared.setLocalOverride(isPro: true)
        await spin(1.0)
        XCTAssertTrue(SubscriptionService.shared.isPro, "precondition: entitled")
        XCTAssertTrue(settings.examWarmUpReminderEnabled, "precondition: still on while entitled")
        SubscriptionService.shared.setLocalOverride(isPro: false)
        await spin(1.0)
        print("B1 control recorded: examWarmUpReminderEnabled=\(settings.examWarmUpReminderEnabled)")
        XCTAssertFalse(settings.examWarmUpReminderEnabled)
    }

    // MARK: B2 - denial flag outlives the choice that produced it

    /// Onboarding reminder step: "Remind me daily" then Don't Allow leaves
    /// reminderEnabled false and reminderPermissionDenied true (AppSettings:165-167).
    /// The user then taps "No reminders" (OnboardingView sets reminderEnabled = false).
    /// The "we will schedule it" card is shown from the flag alone.
    func testB2_denialFlagSurvivesChoosingNoReminders() {
        let settings = AppSettings(defaults: suite)
        // State the permission callback leaves behind.
        settings.reminderPermissionDenied = true
        XCTAssertFalse(settings.reminderEnabled, "precondition: toggle snapped back off")
        XCTAssertTrue(settings.reminderPermissionDenied, "precondition: denial recorded")
        // "No reminders" row.
        settings.reminderEnabled = false
        print("B2 recorded: reminderEnabled=\(settings.reminderEnabled) reminderPermissionDenied=\(settings.reminderPermissionDenied)")
        XCTAssertFalse(settings.reminderPermissionDenied,
                       "after choosing No reminders the 'turn them on and we will schedule it' card must go away")
    }

    /// Control: only the alert binding (user dismissing the alert) clears it.
    func testB2_control_flagClearsOnlyWhenAlertDismissed() {
        let settings = AppSettings(defaults: suite)
        settings.reminderPermissionDenied = true
        XCTAssertTrue(settings.reminderPermissionDenied, "precondition")
        settings.reminderPermissionDenied = false // what the alert binding does on dismiss
        XCTAssertFalse(settings.reminderPermissionDenied)
        XCTAssertFalse(suite.bool(forKey: "settings.reminderEnabled"), "denial left the persisted toggle off")
    }

    // MARK: B3 - flashcard Undo restores the deck, not the record

    /// Replays the exact store calls FlashcardDrillView makes (commit at :350-362,
    /// undo at :375-385 which makes no store call): Again, Undo, Knew it.
    func testB3_flashcardUndoLeavesPhantomMiss() {
        let records = PracticeRecordStore(defaults: suite)
        let progress = ProgressStore(defaults: suite)
        let id = "audit-card-1"
        let room = "basics-room"
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)

        progress.recordItem(id: id, correct: false)
        records.record(itemID: id, roomID: room, correct: false, now: t0)
        XCTAssertEqual(records.records[id]?.attempts, 1, "precondition: Again recorded")
        // Undo: no store call in the view.
        progress.recordItem(id: id, correct: true)
        records.record(itemID: id, roomID: room, correct: true, now: t0.addingTimeInterval(30))

        let r = records.records[id]!
        print("B3 recorded: attempts=\(r.attempts) correct=\(r.correct) streak=\(r.streak) needsReview=\(r.needsReview)")
        XCTAssertEqual(r.attempts, 1, "after Undo only the final answer should count")
        XCTAssertFalse(r.needsReview, "a card answered right after Undo should not stay on the review list")
    }

    /// Control: the same final answer without the undo detour.
    func testB3_control_singleAnswerIsClean() {
        let records = PracticeRecordStore(defaults: suite)
        let id = "audit-card-2"
        records.record(itemID: id, roomID: "basics-room", correct: true,
                       now: Date(timeIntervalSince1970: 1_800_000_000))
        let r = records.records[id]!
        XCTAssertEqual(r.attempts, 1, "precondition")
        XCTAssertEqual(r.correct, 1, "precondition")
        XCTAssertFalse(r.needsReview)
    }

    // MARK: B4 - Exam Target Cancel keeps the edits

    /// CandidateProfileView:58-61 Save = completeSetup + dismiss; Cancel (:55) =
    /// dismiss only. Fields are bound straight to the persisted model
    /// (CandidateProfileFields toggle at "I know my exam date"). Replay: the toggle
    /// binding setter, then nothing (Cancel).
    func testB4_cancelDoesNotRestoreExamDate() {
        let exam = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        suite.set(exam, forKey: "candidate.examDate")
        let profile = CandidateProfile(defaults: suite)
        XCTAssertNotNil(profile.examDate, "precondition: exam date saved")
        // Toggle "I know my exam date" off; then the user taps Cancel.
        profile.examDate = nil
        print("B4 recorded: persisted examDate after edit=\(String(describing: suite.object(forKey: "candidate.examDate")))")
        XCTAssertNotNil(CandidateProfile(defaults: suite).examDate,
                        "Cancel should leave the saved exam date as it was")
    }

    /// Control: Save semantics are the same write-through, so Cancel == Save here.
    func testB4_control_editWritesThrough() {
        let profile = CandidateProfile(defaults: suite)
        profile.dailyGoal = 40
        XCTAssertEqual(CandidateProfile(defaults: suite).dailyGoal, 40)
    }
}
