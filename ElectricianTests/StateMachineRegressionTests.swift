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

    // MARK: R1 - cold launch from the warm-up notification

    /// A notification tap that arrives before RevenueCat answers is held, not
    /// turned into a paywall for a member, and released once the answer lands.
    func testR1_notificationTapWaitsForEntitlement() async {
        SubscriptionService.shared.setEntitlementKnownForTesting(false)
        AppRouter.shared.route(to: .examWarmUpSession)
        let settings = AppSettings(defaults: suite)
        let w = mountHome(settings: settings)
        XCTAssertNotNil(w?.rootViewController?.view.window, "precondition: Home is mounted")
        await spin(1.0)
        XCTAssertEqual(AppRouter.shared.pendingDestination, .examWarmUpSession,
                       "the tap must wait for RevenueCat instead of opening the paywall")
        SubscriptionService.shared.applyEntitlement(true, requestedAt: Date())
        await spin(1.0)
        XCTAssertNil(AppRouter.shared.pendingDestination, "the member's tap is delivered")
    }
}
