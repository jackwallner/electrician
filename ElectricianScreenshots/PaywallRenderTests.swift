import XCTest

/// Renders the two purchase surfaces so their real prices can be read off a
/// screenshot instead of guessed at.
///
/// This has to be a UI test. `SubscriptionService` never configures RevenueCat
/// on a simulator (a prod key there fabricates customers in the live charts),
/// so a plain `simctl launch` can only ever show the paywall's empty state, and
/// The Debug-only bridge reads display values from the bundled `.storekit`
/// catalog and wraps StoreKit products so the shipping paywall view renders
/// unmodified without creating a RevenueCat customer.
///
/// Run: scripts/capture-paywall.sh <udid> <out-dir>
///
/// Like `ScreenshotTests`, this never calls XCTFail on a missing element: a
/// failing UI test spends ten minutes collecting simulator diagnostics before
/// it tells you anything.
@MainActor
final class PaywallRenderTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    override func tearDown() {
        guard !problems.isEmpty else { return }
        let note = XCTAttachment(string: problems.joined(separator: "\n"))
        note.name = "problems"
        note.lifetime = .keepAlways
        add(note)
    }

    /// The in-app paywall, reached the way a locked room reaches it.
    func testPaywallPlanCards() {
        launch(onboarded: true)
        settle()
        dismissWhatsNew()

        // Settings' upgrade row is the stable entry point; a locked drill needs
        // three taps of room-specific navigation to reach the same sheet.
        guard tapSettingsUpgrade() else {
            problems.append("could not open the paywall")
            attachTree("paywall_missing")
            return
        }
        settle(2.5)
        capture("paywall_plans")
        attachTree("paywall")
    }

    /// The What's New sheet fires on the first launch after a version bump and
    /// covers Home, and its own upsell button matches every "Electrician+" query, so
    /// it has to go before anything else is tapped.
    private func dismissWhatsNew() {
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 4) else { return }
        done.tap()
        settle(0.8)
    }

    /// The onboarding trial step: the one-tap CTA and the disclosure under it
    /// have to name the same plan and the same price.
    func testOnboardingTrialStep() {
        launch(onboarded: false)
        settle()

        for _ in 0..<3 {
            guard tap("Continue") else { break }
            settle(0.8)
        }
        // Target setup gates Continue until a level and jurisdiction are picked.
        if !tap("Journeyman") {
            problems.append("could not pick a license track")
        }
        let jurisdiction = app.textFields.firstMatch
        if jurisdiction.waitForExistence(timeout: 4) {
            jurisdiction.tap()
            jurisdiction.typeText("Test State")
            let done = app.keyboards.buttons["Done"].firstMatch
            if done.waitForExistence(timeout: 2) {
                done.tap()
            } else {
                app.keyboards.buttons["return"].firstMatch.tap()
            }
        } else {
            problems.append("could not find jurisdiction field")
        }
        app.swipeUp()
        settle(0.6)
        if !tap("In the apprenticeship") {
            problems.append("could not pick a skill level")
        }
        settle(0.5)
        _ = tap("Continue")
        settle()

        capture("onboarding_trial")
        attachTree("onboarding_trial")
    }

    // MARK: - Helpers

    private var membershipName: String { "Electrician+" }

    private func launch(onboarded: Bool) {
        app.launchArguments = [
            "-progress.hasOnboarded", onboarded ? "YES" : "NO",
            "-electrician.hasReadPrimer", "YES",
            "-electrician.suppressWhatsNew",
            "-subscription.localProOverride", "NO",
        ]
        if onboarded {
            app.launchArguments += [
                "-electrician.skillLevel", "some",
                "-candidate.licenseTrack", "journeyman",
                "-candidate.jurisdiction", "Test State",
                "-candidate.hasSelectedTrack", "YES",
                "-candidate.setupComplete", "YES",
            ]
        }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
    }

    private func tapSettingsUpgrade() -> Bool {
        let gear = app.navigationBars.buttons.element(boundBy: 0)
        guard gear.exists else { return false }
        gear.tap()
        settle(1.0)
        let upgrade = app.buttons["Get \(membershipName)"].firstMatch
        guard upgrade.waitForExistence(timeout: 4) else { return false }
        upgrade.tap()
        return true
    }

    @discardableResult
    private func tap(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 4) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return true
        }
        return false
    }

    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attachTree(_ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree_\(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
