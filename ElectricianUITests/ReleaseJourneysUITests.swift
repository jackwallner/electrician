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
        XCTAssertTrue(button("Get Started", in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap("Get Started", in: app)
        home("first-home", in: app)
    }

    func test2HomeToolsUpgradeSettingsAndReturn() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        QA.launch(app, arguments: ["-DuoSeed", "-electrician.suppressWhatsNew"])
        home("home", in: app)
        let tools = reveal(app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@", "Field tools", "Praxis-Tools")).firstMatch, in: app)
        tools.tap()
        QA.checkpoint(app, "field-tools")
        app.navigationBars.buttons.firstMatch.tap()
        home("home-after-tools", in: app)
        // The Duo seed is already an Electrician+ member, so there is no
        // upgrade to open here; test1 covers the trial page.
        tap("Settings", in: app)
        checkpoint("settings", button: "Done", in: app)
        tap("Done", in: app)
        home("home-after-settings", in: app)
        QA.interrupt(app)
        home("home-after-background", in: app)
        QA.relaunch(app)
        home("home-after-relaunch", in: app)
    }

    func testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        QA.launch(app, arguments: ["-DuoSeed", "-electrician.suppressWhatsNew"])
        home("home", in: app)
        openCodeMinute(in: app)
        QA.checkpoint(app, "code-minute")
        XCTAssertFalse(app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@", "View Today's", "Heute ansehen")).firstMatch.exists)
        tap("Start Today's Challenge", in: app)
        for question in 1...5 {
            let choice = app.buttons["choice.0"].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 15), "question \(question)")
            choice.tap()
            QA.checkpoint(app, "answered-\(question)")
            tap(question < 5 ? "Next" : "Finish", in: app)
        }
        let score = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-5]/5")).firstMatch
        XCTAssertTrue(score.waitForExistence(timeout: 15))
        let result = score.label
        QA.checkpoint(app, "code-minute-result")
        // The delayed review prompt can appear before or while scrolling.
        let notNow = app.buttons.matching(NSPredicate(format: "label IN %@", ["Not Now", "Jetzt nicht"])).firstMatch
        if notNow.waitForExistence(timeout: 5) { notNow.tap() }
        let done = reveal(button("Done", in: app), in: app)
        if notNow.waitForExistence(timeout: 2) { notNow.tap() }
        done.tap()
        assertSaved(result, in: app)
        QA.checkpoint(app, "code-minute-saved")
        QA.relaunch(app)
        home("home-after-relaunch", in: app)
        openCodeMinute(in: app)
        assertSaved(result, in: app)
        QA.checkpoint(app, "code-minute-after-relaunch")
    }

    private func openCodeMinute(in app: XCUIApplication) {
        let tile = reveal(app.buttons.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Code", "Minute")).firstMatch, in: app)
        tile.tap()
        XCTAssertTrue(app.navigationBars.matching(NSPredicate(format: "identifier IN %@", ["Code Minute", "Code-Minute"])).firstMatch.waitForExistence(timeout: 15))
    }

    private func assertSaved(_ result: String, in app: XCUIApplication) {
        let saved = app.descendants(matching: .any).containing(NSPredicate(format: "(label CONTAINS %@ OR label CONTAINS %@) AND label CONTAINS %@", "View Today's", "Heute ansehen", result)).firstMatch
        let found = saved.waitForExistence(timeout: 15)
        XCTAssertTrue(found, "today's \(result) is listed. Tree:\n\(found ? "" : app.debugDescription)")
    }

    private let german: [String: String] = [
        "Continue": "Weiter", "Set up my exam": "Meine Prüfung einrichten",
        "Skip": "Überspringen", "Sitting the exam soon": "Prüfung steht bald an",
        "Looks right": "Sieht richtig aus", "Get Started": "Los geht's",
        "Settings": "Einstellungen", "Done": "Fertig",
        "Start Today's Challenge": "Tages-Challenge starten",
        "Next": "Weiter", "Finish": "Fertig"
    ]

    private func button(_ label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier IN %@ OR label IN %@",
                                        [label, german[label] ?? label], [label, german[label] ?? label])).firstMatch
    }

    private func tap(_ label: String, in app: XCUIApplication) {
        let button = button(label, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        reveal(button, in: app).tap()
    }

    private func choose(containing text: String, in app: XCUIApplication) {
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", text, german[text] ?? text)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        reveal(row, in: app).tap()
    }

    /// Scrolls until the element is on screen, for rows below the fold.
    @discardableResult
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < 8 {
            QA.swipe(app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app, .up)
            tries += 1
        }
        XCTAssertTrue(element.isHittable)
        return element
    }

    private func checkpoint(_ name: String, button label: String, in app: XCUIApplication) {
        XCTAssertTrue(button(label, in: app).waitForExistence(timeout: 15))
        QA.checkpoint(app, name)
    }

    private func home(_ name: String, in app: XCUIApplication) {
        XCTAssertTrue(button("Settings", in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, name)
    }
}
