import XCTest

/// Persona audit flows for an experienced, returning candidate. Runs against
/// the DEBUG `-DuoSeed` fixture (a journeyman with a month of practice and the
/// local Electrician+ override, no RevenueCat, no network).
///
/// It never fails on a missing element: it records what it could not find and
/// attaches the screenshots, so one run shows both what exists and what does
/// not. These are observation flows, not regression tests.
@MainActor
final class ExperiencedAuditUITests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        app.launchArguments += [
            "-DuoSeed", "-electrician.suppressWhatsNew",
            "-whatsnew.lastSeenVersion", "999.0",
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        sleep(2)
        dismissSheetsIfAny()
    }

    override func tearDown() {
        let attachment = XCTAttachment(string: notes.joined(separator: "\n"))
        attachment.name = "notes"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Helpers

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func note(_ text: String) { notes.append(text) }

    private func dismissSheetsIfAny() {
        for label in ["Not now", "Maybe later", "Close", "Done", "Continue"] {
            let button = app.buttons[label]
            if button.exists && app.sheets.count > 0 {
                button.tap()
            }
        }
    }

    private func element(containing text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        if button.exists { return button }
        return app.staticTexts.matching(predicate).firstMatch
    }

    @discardableResult
    private func tap(_ text: String, timeout: TimeInterval = 6) -> Bool {
        let target = element(containing: text)
        guard target.waitForExistence(timeout: timeout) else {
            note("MISSING: \(text)")
            return false
        }
        target.tap()
        return true
    }

    private func back() {
        let bar = app.navigationBars.firstMatch
        let backButton = bar.buttons.element(boundBy: 0)
        if backButton.exists { backButton.tap() } else { note("MISSING: back button") }
        sleep(1)
    }

    private func answer(_ index: Int = 0) {
        let choice = app.buttons["choice.\(index)"]
        if choice.waitForExistence(timeout: 5) { choice.tap() } else { note("MISSING: choice.\(index)") }
    }

    // MARK: - Home and the training row

    func testHomeAndTraining() {
        shot("01-home-top")
        let size = app.windows.firstMatch.frame
        note("window \(size)")
        app.swipeUp()
        sleep(1)
        shot("02-home-scrolled")
        app.swipeDown()
        // The training tiles scroll sideways; find out where Fix My Mistakes is.
        let fix = element(containing: "Fix My")
        note("Fix My Mistakes exists in hierarchy: \(fix.exists), hittable: \(fix.isHittable)")
        let tools = element(containing: "Field tools")
        note("Field tools hittable on first screen: \(tools.isHittable)")
        let endless = element(containing: "Endless")
        note("Endless tile hittable on first screen: \(endless.isHittable)")
        let timed = element(containing: "Timed")
        note("Timed tile hittable on first screen: \(timed.isHittable)")
        let swipeTarget = endless.exists ? endless : element(containing: "Code")
        if swipeTarget.exists {
            swipeTarget.swipeLeft()
            sleep(1)
            shot("03-training-row-swiped")
            let fixAfter = element(containing: "Fix My")
            note("Fix My Mistakes hittable after one swipe: \(fixAfter.isHittable)")
            swipeTarget.swipeLeft()
            sleep(1)
            shot("04-training-row-swiped-twice")
        }
    }

    // MARK: - Endless practice, the repeated core task

    func testEndlessRun() {
        guard tap("Endless") else { shot("00-no-endless"); return }
        sleep(1)
        shot("10-endless-picker")
        app.swipeUp()
        sleep(1)
        shot("11-endless-picker-scrolled")
        app.swipeDown()
        guard tap("Ampacity") else { return }
        sleep(1)
        shot("12-endless-q1")
        let started = Date()
        for n in 1...6 {
            answer(n % 4)
            sleep(1)
            if n == 1 { shot("13-endless-q1-answered") }
            if n == 2 {
                app.swipeUp()
                shot("14-endless-q2-answered-scrolled")
            }
            let next = app.buttons["Next"]
            if next.waitForExistence(timeout: 3) {
                note("Next hittable after answer \(n): \(next.isHittable)")
                next.tap()
            } else {
                note("MISSING: Next after answer \(n)")
            }
            sleep(1)
        }
        note("six answers took \(Date().timeIntervalSince(started))s including sleeps")
        shot("15-endless-q7")
        tap("Finish")
        sleep(2)
        shot("16-endless-complete")
        tap("Done")
        sleep(1)
        shot("17-after-done")
    }

    // MARK: - Timed challenge

    func testTimedChallenge() {
        guard tap("Timed") else { shot("00-no-timed"); return }
        shot("20-timed-start")
        for n in 1...5 {
            answer(0)
            sleep(1)
            let next = app.buttons["Next"]
            if next.waitForExistence(timeout: 3) { next.tap() }
            if n == 2 { shot("21-timed-mid") }
        }
        // Leave mid-run with the back button: is the score kept, is there a warning?
        back()
        sleep(1)
        shot("22-timed-left-midrun")
        note("alerts after leaving timed run: \(app.alerts.count)")
    }

    func testTimedChallengeRunsOut() {
        guard tap("Timed") else { return }
        answer(0)
        sleep(1)
        let next = app.buttons["Next"]
        if next.waitForExistence(timeout: 3) { next.tap() }
        sleep(88)
        shot("23-timed-near-end")
        sleep(8)
        shot("24-timed-complete")
        tap("Done")
        sleep(1)
        shot("25-after-timed")
    }

    // MARK: - Fix My Mistakes

    func testFixMyMistakes() {
        let endless = element(containing: "Endless")
        for _ in 0..<3 where !element(containing: "Fix My").isHittable {
            if endless.exists { endless.swipeLeft() }
        }
        shot("30-fix-tile")
        guard tap("Fix My") else { return }
        sleep(1)
        shot("31-fix-q1")
        answer(0)
        sleep(1)
        shot("32-fix-q1-answered")
        tap("Close")
        sleep(1)
        shot("33-fix-closed")
    }

    // MARK: - Field tools

    func testFieldTools() {
        app.swipeUp()
        guard tap("Field tools") else { shot("00-no-tools"); return }
        sleep(1)
        shot("40-tools-list")
        guard tap("Ampacity") else { return }
        sleep(1)
        shot("41-ampacity-defaults")
        let stepper = app.steppers.firstMatch
        if stepper.exists {
            let increment = stepper.buttons.element(boundBy: 1)
            for _ in 0..<4 { increment.tap() }
        } else { note("MISSING: stepper") }
        shot("42-ampacity-changed")
        back()
        tap("Ampacity")
        sleep(1)
        shot("43-ampacity-reopened")
        back()

        guard tap("Voltage drop") else { return }
        sleep(1)
        shot("44-vdrop")
        let fields = app.textFields
        note("voltage drop text fields: \(fields.count)")
        if fields.count > 0 {
            let load = fields.element(boundBy: 0)
            load.tap()
            sleep(1)
            shot("45-vdrop-keyboard")
            load.typeText("0")
            let done = app.buttons["Done"]
            note("Done button on keyboard toolbar: \(done.exists)")
            shot("46-vdrop-typed")
            // Is there any way to dismiss without leaving the screen?
            app.swipeDown()
            sleep(1)
            shot("47-vdrop-after-swipe")
            note("keyboard still visible after swipeDown: \(app.keyboards.count > 0)")
        }
        back()
        sleep(1)
        shot("48-after-vdrop-back")
        guard tap("Ohm") else { return }
        sleep(1)
        shot("49-ohms")
        let ohmFields = app.textFields
        note("ohms fields: \(ohmFields.count)")
        if ohmFields.count > 2 {
            ohmFields.element(boundBy: 2).tap()
            ohmFields.element(boundBy: 2).typeText("12")
            shot("50-ohms-typed")
        }
    }

    // MARK: - Progress

    func testStats() {
        guard tap("day streak") || tap("drills done") else { shot("00-no-stats"); return }
        sleep(1)
        shot("60-stats-top")
        app.swipeUp()
        sleep(1)
        shot("61-stats-scrolled")
        let weak = element(containing: "Work on")
        note("weak spot card is a button: \(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Work on'")).count > 0)")
        _ = weak
        let skill = app.staticTexts["Conduit fill"]
        note("calc skill row exists: \(skill.exists), hittable: \(skill.isHittable)")
        if skill.exists {
            skill.tap()
            sleep(1)
            shot("62-after-tapping-skill-row")
        }
        if tap("Practice these traps now") {
            sleep(1)
            shot("63-traps-practice")
        }
    }

    func testSettingsAndReadiness() {
        if tap("Practice readiness") {
            sleep(1)
            shot("70-readiness")
            app.swipeUp()
            shot("71-readiness-scrolled")
            back()
        }
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            sleep(1)
            shot("72-settings")
            app.swipeUp()
            sleep(1)
            shot("73-settings-scrolled")
        }
    }

    // MARK: - Rooms and flashcards

    func testRoomAndWorkedExamples() {
        app.swipeUp()
        sleep(1)
        guard tap("Calculation") || tap("Calc") else { shot("00-no-room"); return }
        sleep(1)
        shot("80-calc-room")
        app.swipeUp()
        shot("81-calc-room-scrolled")
    }
}
