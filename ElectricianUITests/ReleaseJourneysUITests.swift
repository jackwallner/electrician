import XCTest

/// Release-gate journeys, run once per persona by `qa-gate`.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        // Past onboarding and the primer, into a plain free-tier Home with no
        // practice history, so every counter this journey reads starts at zero.
        app.launchArguments += [
            "-progress.hasOnboarded", "YES",
            "-electrician.hasReadPrimer", "YES",
            "-electrician.skillLevel", "some",
            "-candidate.licenseTrack", "journeyman",
            "-candidate.jurisdiction", "Georgia",
            "-candidate.edition", "nec2023",
            "-candidate.hasSelectedTrack", "YES",
            "-candidate.setupComplete", "YES",
        ]
        return app
    }

    /// The core loop: finish the daily Get Started session and have it counted
    /// (streak, drills done, today's card spent), still there after a cold relaunch.
    func testCoreLoopGetStartedSessionCountsAndSurvivesRelaunch() {
        let app = makeApp()
        QA.launch(app)
        dismissWhatsNew(app)
        XCTAssertTrue(app.staticTexts["Get Started"].firstMatch.waitForExistence(timeout: 15), "Home never showed Get Started")
        XCTAssertTrue(label(app, "0 day streak"), "a fresh install does not start at a 0 day streak")
        XCTAssertTrue(label(app, "0 drills done"), "a fresh install does not start at 0 drills done")
        QA.checkpoint(app, "home-fresh")

        app.staticTexts["Get Started"].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        var answered = 0
        while answered < 40 {
            let choice = app.buttons["choice.0"].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 10), "question \(answered + 1) never showed its choices")
            choice.tap()
            answered += 1
            let advance = app.buttons
                .matching(NSPredicate(format: "label BEGINSWITH 'Next' OR label BEGINSWITH 'Finish'"))
                .firstMatch
            XCTAssertTrue(advance.waitForExistence(timeout: 10), "question \(answered) was not graded")
            QA.checkpoint(app, "question-\(answered)-answered")
            let finishing = advance.label.hasPrefix("Finish")
            advance.tap()
            if finishing { break }
        }
        XCTAssertGreaterThan(answered, 1, "the session ended after \(answered) question(s)")

        XCTAssertTrue(app.staticTexts["right"].firstMatch.waitForExistence(timeout: 10), "finishing the session shows no result")
        let score = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]+/\(answered)")).firstMatch
        XCTAssertTrue(score.exists, "result screen does not show a score out of \(answered)")
        XCTAssertTrue(label(app, "1-day streak"), "result screen does not show the 1-day streak")
        QA.checkpoint(app, "result")

        app.buttons["Done"].firstMatch.tap()
        assertCounted(app, "after Done")
        QA.checkpoint(app, "home-after")

        QA.relaunch(app)
        dismissWhatsNew(app)
        assertCounted(app, "after relaunch")
        QA.checkpoint(app, "home-after-relaunch")
    }

    // MARK: - Helpers

    private func assertCounted(_ app: XCUIApplication, _ when: String) {
        XCTAssertTrue(app.staticTexts["Today's session is done"].firstMatch.waitForExistence(timeout: 15),
                      "today's session is not marked done \(when)")
        XCTAssertTrue(label(app, "1 day streak"), "streak is not 1 \(when)")
        XCTAssertTrue(label(app, "1 drills done"), "drills done is not 1 \(when)")
    }

    private func label(_ app: XCUIApplication, _ text: String) -> Bool {
        let match = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", text)).firstMatch
        return match.waitForExistence(timeout: 10)
    }

    private func dismissWhatsNew(_ app: XCUIApplication) {
        let done = app.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 3) { done.tap() }
    }
}
