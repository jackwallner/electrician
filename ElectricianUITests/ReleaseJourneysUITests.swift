import XCTest

@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test1FirstRunToTrialAndHome() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        QA.launch(app, arguments: ["-electrician.suppressWhatsNew"])
        checkpoint("open-book", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("what-fails", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("walk-in-ready", button: "Set up my exam", in: app)
        tap("Set up my exam", in: app)
        choose(containing: "Journeyman", in: app)
        checkpoint("track", button: "Continue", in: app)
        tap("Continue", in: app)
        choose(containing: "Alabama", in: app)
        checkpoint("jurisdiction", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("edition", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("exam-date", button: "Skip", in: app)
        tap("Skip", in: app)
        choose(containing: "Sitting the exam soon", in: app)
        checkpoint("experience", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("focus", button: "Skip", in: app)
        tap("Skip", in: app)
        checkpoint("reminder", button: "Skip", in: app)
        tap("Skip", in: app)
        checkpoint("plan", button: "Looks right", in: app)
        tap("Looks right", in: app)
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap("Get Started", in: app)
        home("first-home", in: app)
    }

    func test2HomeToolsUpgradeSettingsAndReturn() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        QA.launch(app, arguments: ["-DuoSeed", "-electrician.suppressWhatsNew"])
        home("home", in: app)
        let tools = reveal(app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "Field tools")).firstMatch, in: app)
        tools.tap()
        QA.checkpoint(app, "field-tools")
        app.navigationBars.buttons.firstMatch.tap()
        home("home-after-tools", in: app)
        let upgrade = reveal(app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "Get Electrician+")).firstMatch, in: app)
        upgrade.tap()
        XCTAssertTrue(app.buttons["Restore"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "upgrade", paywall: true)
        tap("Close", in: app)
        home("home-after-upgrade", in: app)
        tap("Settings", in: app)
        checkpoint("settings", button: "Done", in: app)
        tap("Done", in: app)
        home("home-after-settings", in: app)
        QA.interrupt(app)
        home("home-after-background", in: app)
        QA.relaunch(app)
        home("home-after-relaunch", in: app)
    }

    private func tap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        button.tap()
    }

    private func choose(containing text: String, in app: XCUIApplication) {
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        reveal(row, in: app).tap()
    }

    /// Scrolls until the element is on screen, for rows below the fold.
    @discardableResult
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < 8 {
            app.swipeUp()
            tries += 1
        }
        XCTAssertTrue(element.isHittable)
        return element
    }

    private func checkpoint(_ name: String, button label: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons[label].firstMatch.waitForExistence(timeout: 15))
        QA.checkpoint(app, name)
    }

    private func home(_ name: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Settings"].firstMatch.waitForExistence(timeout: 20))
        QA.checkpoint(app, name)
    }
}
