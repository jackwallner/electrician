import XCTest

/// Flow regressions from the 2026-11-20 bug catalog
/// (`project-docs/audits/2026-11-20-bug-fixes.md`).
///
/// Named to sort after `ReleaseJourneysUITests`, whose first test needs a
/// fresh install: `-DuoSeed` here marks onboarding done. Membership and the
/// onboarding flag are forced per launch through the arguments domain, so
/// each test reads the same state whatever ran before it.
@MainActor
final class StateFixesUITests: XCTestCase {
    private let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: B1 - Exam Target pushed from Home and Practice Readiness

    func testB1_examTargetFromHomeStaysOpen() {
        launch(["-DuoSeed", "-subscription.localProOverride", "YES"])
        let card = element(app.buttons, containing: "questions a day")
        XCTAssertTrue(card.waitForExistence(timeout: 20))
        reveal(card).tap()
        assertExamTargetStaysOpen()
        app.navigationBars["Exam Target"].buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10), "Cancel returns to Home")
    }

    func testB1_examTargetFromPracticeReadinessStaysOpen() {
        launch(["-DuoSeed", "-subscription.localProOverride", "YES"] + tour("readiness"))
        let card = element(app.buttons, containing: "study set")
        XCTAssertTrue(card.waitForExistence(timeout: 20))
        reveal(card).tap()
        assertExamTargetStaysOpen()
    }

    private func assertExamTargetStaysOpen() {
        let bar = app.navigationBars["Exam Target"]
        XCTAssertTrue(bar.waitForExistence(timeout: 10))
        sleep(3)
        XCTAssertTrue(bar.exists, "Exam Target popped back")
        XCTAssertEqual(app.navigationBars.count, 1, "one navigation bar, not a stack inside a stack")
        attach("exam-target")
    }

    // MARK: B4 - Close part-way through Fix My Mistakes

    func testB4_closingFixMyMistakesPartWayIsNotAFinishedRun() {
        launch(["-DuoSeed", "-subscription.localProOverride", "YES"] + tour("fix"))
        let choice = app.buttons["choice.0"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 20))
        choice.tap()
        app.navigationBars.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10), "Close returns to Home")
        XCTAssertFalse(app.buttons["Done"].exists, "Close showed the completion screen")
        attach("after-close")
    }

    // MARK: B7 - Paywall plan cards tell VoiceOver which is selected

    func testB7_paywallPlanCardsReportTheSelectedPlan() {
        launch(["-DuoSeed", "-subscription.localProOverride", "NO"] + tour("paywall"))
        let yearly = element(app.buttons, beginningWith: "Yearly")
        let monthly = element(app.buttons, beginningWith: "Monthly")
        let lifetime = element(app.buttons, beginningWith: "Lifetime")
        XCTAssertTrue(yearly.waitForExistence(timeout: 20))
        XCTAssertTrue(yearly.isSelected)
        XCTAssertFalse(monthly.isSelected)
        XCTAssertFalse(lifetime.isSelected)
        reveal(monthly).tap()
        XCTAssertTrue(monthly.isSelected)
        XCTAssertFalse(yearly.isSelected)
    }

    // MARK: B8 - An entitled candidate is not offered the trial again

    /// The onboarding flag is forced off for the whole launch, so finishing
    /// cannot swap Home in here; what matters is that the trial never shows.
    func testB8_entitledCandidateSkipsTheTrialStep() {
        launch(["-progress.hasOnboarded", "NO", "-subscription.localProOverride", "YES"])
        walkOnboardingToPlan()
        tap("Looks right")
        sleep(3)
        XCTAssertFalse(app.buttons["Get Started"].exists, "the trial step was shown to a member")
        XCTAssertFalse(element(app.buttons, beginningWith: "Start ").exists)
        XCTAssertFalse(element(app.buttons, beginningWith: "Subscribe").exists)
    }

    // MARK: B9 - A blank voltage drop field answers nothing

    func testB9_clearedLoadHidesTheVoltageDropEstimate() {
        launch(["-DuoSeed", "-subscription.localProOverride", "YES"] + tour("tools"))
        let row = element(app.buttons, containing: "Voltage drop")
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        reveal(row).tap()
        let estimate = element(app.staticTexts, beginningWith: "3% note")
        XCTAssertTrue(estimate.waitForExistence(timeout: 10), "precondition: the default run has an estimate")
        let load = app.textFields.element(boundBy: 0)
        // The text is right-aligned: tap its trailing edge so the cursor lands
        // after "16" and the deletes clear it.
        load.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        load.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6))
        let cleared = load.value as? String ?? "?"
        XCTAssertTrue(cleared.isEmpty || cleared == "A", "precondition: Load is blank, reads \(cleared)")
        XCTAssertTrue(estimate.waitForNonExistence(timeout: 5), "a blank Load still showed an estimate")
        load.typeText("20")
        XCTAssertTrue(estimate.waitForExistence(timeout: 5), "typing a load brings the estimate back")
    }

    // MARK: B10 - The Exam Warm-Up notification over an open sheet

    func testB10_warmUpNotificationOverSettingsOpensTheSession() {
        launch(["-DuoSeed", "-subscription.localProOverride", "YES"] + tour("settings,notify", step: 6))
        let done = app.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 20), "precondition: Settings is open")
        XCTAssertTrue(done.waitForNonExistence(timeout: 20), "Settings stayed on top of the session")
        XCTAssertTrue(app.navigationBars["Exam Warm-Up"].waitForExistence(timeout: 10))
        attach("warm-up-session")
    }

    // MARK: B11 - Purchase footers scroll at accessibility sizes

    private let largestText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    func testB11_paywallFooterScrollsAtTheLargestTextSize() {
        launch(["-DuoSeed", "-subscription.localProOverride", "NO"] + largestText + tour("paywall"))
        assertFooterScrolls(app.buttons["Restore"].firstMatch, name: "paywall-ax5")
    }

    func testB11_trialFooterScrollsAtTheLargestTextSize() {
        launch(["-progress.hasOnboarded", "NO", "-subscription.localProOverride", "NO"] + largestText)
        walkOnboardingToPlan()
        tap("Looks right")
        assertFooterScrolls(app.buttons["Restore"].firstMatch, name: "trial-ax5")
    }

    /// Docked, the footer is on screen from the first frame. Scrolling with
    /// the content, it starts below the fold and is reached by scrolling.
    private func assertFooterScrolls(_ control: XCUIElement, name: String) {
        XCTAssertTrue(control.waitForExistence(timeout: 20))
        sleep(1)
        attach("\(name)-top")
        XCTAssertFalse(control.isHittable, "the footer is docked over the content")
        reveal(control, in: app.scrollViews.containing(.button, identifier: "Restore").firstMatch, tries: 20)
        attach("\(name)-bottom")
    }

    // MARK: - Helpers

    private func launch(_ arguments: [String]) {
        app.launchArguments += ["-electrician.suppressWhatsNew"] + arguments
        app.launch()
    }

    private func tour(_ routes: String, step: Int = 600) -> [String] {
        ["-DuoTour", "-DuoTourFirst", "1", "-DuoTourStep", "\(step)", "-DuoTourStepRegular", "\(step)",
         "-DuoRoutes", routes]
    }

    private func walkOnboardingToPlan() {
        tap("Continue")
        tap("Continue")
        tap("Set up my exam")
        choose("Journeyman")
        tap("Continue")
        // A state saved by an earlier run shows as a card instead of the list.
        let alabama = element(app.buttons, containing: "Alabama")
        let saved = app.buttons["Choose a different state"]
        XCTAssertTrue(alabama.waitForExistence(timeout: 15) || saved.exists)
        if !saved.exists { reveal(alabama, tries: 25).tap() }
        tap("Continue")
        tap("Continue")
        tap("Skip")
        choose("Sitting the exam soon")
        tap("Continue")
        tap("Skip")
        tap("Skip")
        XCTAssertTrue(app.buttons["Looks right"].waitForExistence(timeout: 15))
    }

    private func element(_ query: XCUIElementQuery, containing text: String) -> XCUIElement {
        query.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func element(_ query: XCUIElementQuery, beginningWith text: String) -> XCUIElement {
        query.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
    }

    private func tap(_ label: String) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), label)
        reveal(button, tries: 25).tap()
        sleep(1)  // the step transition
    }

    private func choose(_ text: String) {
        let row = element(app.buttons, containing: text)
        XCTAssertTrue(row.waitForExistence(timeout: 15), text)
        reveal(row, tries: 25).tap()
    }

    /// Scrolls until the element is on screen, for rows below the fold.
    @discardableResult
    private func reveal(_ element: XCUIElement, in container: XCUIElement? = nil, tries limit: Int = 8) -> XCUIElement {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < limit {
            let scroll = container ?? (app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch
                : app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app)
            scroll.swipeUp()
            tries += 1
        }
        // A tap while the scroll is still coasting only stops the scroll.
        if tries > 0 { sleep(2) }
        XCTAssertTrue(element.isHittable, "\(element) never came on screen")
        return element
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
