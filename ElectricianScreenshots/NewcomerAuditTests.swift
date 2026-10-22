import XCTest

/// Persona audit: a first-time user who does not know the terminology and
/// wants one useful result immediately. Walks a truly fresh install (no seeded
/// defaults) from the first onboarding page to a finished first answer, and
/// records a screenshot and the element tree per step.
///
/// Never hard-fails on a missing element: it logs what it could not find in a
/// `problems` attachment so one run explains the whole flow.
@MainActor
final class NewcomerAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var log: [String] = []
    private var tapCount = 0

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // Fresh install: no onboarding bypass. Only the localized store-less
        // environment differs from a real first launch.
        app.launch()
    }

    func testFirstRunToFirstAnswer() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()

        // Value pages: how many taps before anything is asked, and is there a way out?
        capture("01_open_book")
        note("page1 buttons: \(labels(app.buttons))")
        note("page1 has Skip: \(app.buttons["Skip"].exists)")
        tapPrimary("Continue")
        capture("02_what_fails")
        tapPrimary("Continue")
        capture("03_walk_in_ready")
        note("page3 primary: \(labels(app.buttons))")
        tapPrimary("Set up my exam")

        // Track
        capture("04_track")
        attachTree("track")
        tapPrimary("Continue")

        // Jurisdiction: Continue must be disabled until a state is chosen.
        capture("05_jurisdiction")
        let cont = app.buttons["Continue"].firstMatch
        note("jurisdiction Continue enabled before pick: \(cont.exists && cont.isEnabled)")
        let georgia = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Georgia'")).firstMatch
        if georgia.waitForExistence(timeout: 4) {
            georgia.tap()
            settle()
        } else {
            problems("could not find Georgia row")
        }
        capture("06_jurisdiction_picked")
        attachTree("jurisdiction")
        tapPrimary("Continue")

        capture("07_edition")
        tapPrimary("Continue")
        capture("08_exam_date")
        note("exam date has Skip: \(app.buttons["Skip"].exists)")
        tapPrimary("Continue")

        // Experience is required.
        capture("09_experience")
        let c2 = app.buttons["Continue"].firstMatch
        note("experience Continue enabled before pick: \(c2.exists && c2.isEnabled)")
        let justStarting = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Just starting'")).firstMatch
        if justStarting.waitForExistence(timeout: 4) { justStarting.tap(); settle() }
        capture("10_experience_picked")
        tapPrimary("Continue")

        capture("11_focus")
        tapPrimary("Continue")
        capture("12_reminder")
        let skip = app.buttons["Skip"].firstMatch
        if skip.exists { skip.tap(); settle() } else { problems("no Skip on reminder") }

        capture("13_plan")
        attachTree("plan")
        tapPrimary("Looks right")

        capture("14_trial")
        attachTree("trial")
        let free = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Get Started'")).firstMatch
        if free.waitForExistence(timeout: 4) { free.tap(); settle(2.5) } else { problems("no free way in on trial") }
        note("taps from launch to Home: \(tapCount)")

        // Home
        dismissWhatsNew()
        capture("15_home_first")
        attachTree("home")
        app.swipeUp()
        settle()
        capture("16_home_scrolled")
        app.swipeDown()
        settle()

        // The first useful result: the Home "Get Started" card, then one answer.
        let start = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Get Started'")).firstMatch
        if start.waitForExistence(timeout: 5) {
            start.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
        } else { problems("no Get Started card on Home") }
        capture("17_first_question")
        attachTree("question")

        let row = app.buttons["choice.0"].firstMatch
        if row.waitForExistence(timeout: 6) {
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            capture("18_first_answer")
            app.swipeUp()
            settle()
            capture("19_first_answer_scrolled")
            attachTree("answered")
        } else { problems("no choice rows") }

        // Back out mid-session: does it ask, and what is lost?
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists { back.tap(); settle() }
        capture("20_after_back")

        // Settings and a paid room, for the subscription surface.
        let gear = app.buttons["Settings"].firstMatch
        if gear.waitForExistence(timeout: 3) { gear.tap(); settle(); capture("21_settings") }
        attachTree("settings")
        let done = app.buttons["Done"].firstMatch
        if done.exists { done.tap(); settle() }

        flush()
    }

    // MARK: - Helpers

    private func tapPrimary(_ label: String) {
        let button = app.buttons[label].firstMatch
        guard button.waitForExistence(timeout: 6) else {
            problems("missing primary: \(label); have \(labels(app.buttons))")
            return
        }
        button.tap()
        tapCount += 1
        settle()
    }

    private func labels(_ query: XCUIElementQuery) -> String {
        query.allElementsBoundByIndex.prefix(14).map(\.label).joined(separator: " | ")
    }

    private func dismissWhatsNew() {
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    private var problemLog: [String] = []
    private func problems(_ text: String) { problemLog.append(text); log.append("PROBLEM: \(text)") }
    private func note(_ text: String) { log.append(text) }

    private func settle(_ seconds: TimeInterval = 1.4) { Thread.sleep(forTimeInterval: seconds) }

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

    private func flush() {
        let notes = XCTAttachment(string: log.joined(separator: "\n"))
        notes.name = "newcomer_log"
        notes.lifetime = .keepAlways
        add(notes)
    }
}
