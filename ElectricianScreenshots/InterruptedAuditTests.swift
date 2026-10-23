import XCTest

/// Persona audit capture: a tired, busy user who is pulled away mid-task and
/// comes back later expecting the app to remember where they were.
///
/// Each test starts a task, interrupts it (terminate and relaunch, background
/// and foreground, or leave and return), and attaches a screenshot of what the
/// user finds on return. Nothing here asserts product behaviour; the findings
/// are read from the screenshots and the `notes` attachment, so a failing
/// element lookup records a note instead of failing the run.
///
/// Launch arguments live in the argument domain and are not persisted, so a
/// relaunch repeats the same seed arguments: only state the app itself wrote to
/// UserDefaults can survive, which is exactly what is being measured.
///
/// Run: gh-sim test --scheme Screenshots --only ElectricianScreenshots/InterruptedAuditTests
@MainActor
final class InterruptedAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []

    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() {
        if !notes.isEmpty {
            let note = XCTAttachment(string: notes.joined(separator: "\n"))
            note.name = "notes"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    private static let seeded: [String] = [
        "-progress.hasOnboarded", "YES",
        "-electrician.hasReadPrimer", "YES",
        "-electrician.skillLevel", "some",
        "-candidate.licenseTrack", "journeyman",
        "-candidate.jurisdiction", "Georgia",
        "-candidate.edition", "nec2023",
        "-candidate.hasSelectedTrack", "YES",
        "-candidate.setupComplete", "YES",
        "-whatsnew.lastSeenVersion", "99.0",
        "-subscription.localProOverride", "YES",
    ]

    private func launch(_ args: [String]) {
        app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    /// Kill the app the way iOS does when it needs the memory, then reopen it.
    private func killAndRelaunch(_ args: [String]) {
        app.terminate()
        settle(1.0)
        launch(args)
    }

    // MARK: - 1. Onboarding interrupted mid-setup

    func testOnboardingKilledMidSetup() {
        launch([])
        capture("ob_01_first_page")
        // Three value pages.
        for _ in 0..<3 { tapPrimary() }
        capture("ob_02_track_step")
        tapPrimary()
        // Jurisdiction: choose Georgia.
        if tap("Georgia") {
            capture("ob_03_state_chosen")
            tapPrimary()
        }
        // Edition: choose the 2020 cycle (not the app default, not "not sure").
        if tap("NEC 2020") || tap("2020") {
            capture("ob_04_edition_2020_chosen")
        } else {
            notes.append("edition: could not tap 2020 row")
            capture("ob_04_edition_step")
        }
        tapPrimary()
        // Exam date: choose the first preset.
        let preset = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Tomorrow'")).firstMatch
        if preset.waitForExistence(timeout: 4) {
            preset.tap(); settle(0.8)
            capture("ob_05_exam_date_chosen")
        } else {
            notes.append("exam date: no 'Tomorrow' preset")
            capture("ob_05_exam_step")
        }
        tapPrimary()
        capture("ob_06_before_kill")

        // The phone call comes in, the app is evicted.
        killAndRelaunch([])
        capture("ob_07_after_relaunch")
        attachTree("ob_after_relaunch")

        // Walk forward again and see what was remembered.
        for _ in 0..<3 { tapPrimary() }
        capture("ob_08_track_after_relaunch")
        tapPrimary()
        capture("ob_09_state_after_relaunch")
        tapPrimary()
        capture("ob_10_edition_after_relaunch")
        attachTree("ob_edition_after_relaunch")
        tapPrimary()
        capture("ob_11_exam_after_relaunch")
    }

    // MARK: - 2. Get Started session killed halfway

    func testQuickSessionKilledMidRun() {
        launch(Self.seeded)
        capture("qs_01_home")
        guard open("Get Started") else { return }
        capture("qs_02_q1")
        let q1 = promptText()
        tapChoice(0)
        capture("qs_03_q1_answered")
        tapNext()
        capture("qs_04_q2")
        tapChoice(0)
        tapNext()
        capture("qs_05_q3")
        let q3 = promptText()
        notes.append("before kill: q1='\(q1)' q3='\(q3)'")

        killAndRelaunch(Self.seeded)
        capture("qs_06_after_relaunch")
        attachTree("qs_after_relaunch")
        guard open("Get Started") else { return }
        capture("qs_07_reopened")
        let again = promptText()
        notes.append("after relaunch: first question='\(again)'")
        let counter = app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]+ of [0-9]+'")).firstMatch
        notes.append("counter after relaunch: \(counter.exists ? counter.label : "none")")
    }

    // MARK: - 3. Quick session abandoned with the back button

    func testQuickSessionBackedOutMidRun() {
        launch(Self.seeded)
        guard open("Get Started") else { return }
        tapChoice(0); tapNext()
        tapChoice(0); tapNext()
        capture("qb_01_q3_before_back")
        back()
        capture("qb_02_home_after_back")
        if open("Get Started") {
            capture("qb_03_reopened")
            let counter = app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]+ of [0-9]+'")).firstMatch
            notes.append("counter after back and reopen: \(counter.exists ? counter.label : "none")")
        }
    }

    // MARK: - 4. Timed challenge backgrounded

    func testTimedChallengeBackgrounded() {
        launch(Self.seeded)
        app.swipeUp(); settle(0.8)
        guard open("Timed") else { return }
        capture("tc_01_started")
        let before = timerLabel()
        notes.append("timer at start: \(before)")
        tapChoice(0)
        settle(1.0)
        let t0 = Date()
        XCUIDevice.shared.press(.home)
        settle(30)
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: 15)
        settle(0.5)
        capture("tc_02_after_30s_away")
        let after = timerLabel()
        let away = Int(Date().timeIntervalSince(t0))
        notes.append("away about \(away)s of wall clock; timer before='\(before)' after='\(after)'")
        capture("tc_03_state_after_return")
    }

    // MARK: - 5. Field Tools input lost on leaving

    func testFieldToolsLeaveAndReturn() {
        launch(Self.seeded)
        app.swipeUp(); app.swipeUp(); settle(0.8)
        guard open("Field tools") else { return }
        guard open("Ohm") else { return }
        let volts = app.textFields.element(boundBy: 0)
        guard volts.waitForExistence(timeout: 5) else { notes.append("no volts field"); return }
        volts.tap()
        volts.clearAndType("240")
        let amps = app.textFields.element(boundBy: 1)
        amps.tap()
        amps.clearAndType("32")
        settle(0.8)
        capture("ft_01_entered_240_32")

        // Dismiss the keyboard the way a user would, then leave and return.
        let keyboardDone = app.keyboards.buttons["Done"]
        notes.append("keyboard Done button present: \(keyboardDone.exists)")
        let returnKey = app.keyboards.buttons["Return"]
        notes.append("keyboard Return button present: \(returnKey.exists)")
        back()
        capture("ft_02_back_on_list")
        if open("Ohm") {
            capture("ft_03_reopened")
            notes.append("volts after return: \(app.textFields.element(boundBy: 0).value ?? "?")")
        }

        // Then the harder interruption: kill and relaunch.
        killAndRelaunch(Self.seeded)
        app.swipeUp(); app.swipeUp(); settle(0.8)
        if open("Field tools"), open("Ohm") {
            capture("ft_04_after_kill")
            notes.append("volts after kill: \(app.textFields.element(boundBy: 0).value ?? "?")")
        }
    }

    // MARK: - 6. Flashcard deck left halfway

    func testFlashcardDeckLeftHalfway() {
        launch(Self.seeded)
        guard open("Code Basics") || open("Basics") else { return }
        capture("fc_01_room")
        guard open("Know the Articles") else { return }
        capture("fc_02_deck_start")
        for _ in 0..<2 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
            settle(1.0)
            let knew = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Knew it'")).firstMatch
            if knew.waitForExistence(timeout: 3) { knew.tap() } else { notes.append("no Knew it button") }
            settle(1.2)
        }
        capture("fc_03_after_two_cards")
        let beforeCount = reviewedLabel()
        back()
        capture("fc_04_room_after_back")
        if open("Know the Articles") {
            capture("fc_05_deck_reopened")
            notes.append("reviewed before leaving: \(beforeCount); after reopening: \(reviewedLabel())")
        }
    }

    // MARK: - 7. Endless practice left by the back button

    func testEndlessLeftByBack() {
        launch(Self.seeded)
        app.swipeUp(); settle(0.8)
        guard open("Endless") else { return }
        capture("en_01_picker")
        let first = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Ampacity'")).firstMatch
        if first.waitForExistence(timeout: 4) { first.tap(); settle() }
        capture("en_02_first_problem")
        tapChoice(0); tapNext()
        tapChoice(0); tapNext()
        capture("en_03_third_problem")
        back()
        capture("en_04_after_back")
        back()
        capture("en_05_home")
    }

    // MARK: - Helpers

    private func promptText() -> String {
        let candidates = app.staticTexts.allElementsBoundByIndex.prefix(12)
        return candidates.map(\.label).filter { $0.count > 30 }.first ?? "?"
    }

    private func timerLabel() -> String {
        app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]+s'")).firstMatch.label
    }

    private func reviewedLabel() -> String {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'reviewed'")).firstMatch.label
    }

    private func tapPrimary() {
        let primary = app.buttons.matching(NSPredicate(
            format: "label IN {'Continue','Set up my exam','Looks right','Skip'}")).firstMatch
        guard primary.waitForExistence(timeout: 4) else {
            notes.append("no primary button")
            return
        }
        if !primary.isEnabled { notes.append("primary disabled: \(primary.label)") }
        primary.tap()
        settle(1.0)
    }

    @discardableResult
    private func tap(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        let match = app.buttons.matching(predicate).firstMatch
        guard match.waitForExistence(timeout: 4) else { return false }
        match.tap()
        settle(0.8)
        return true
    }

    private func tapNext() {
        let next = app.buttons.matching(NSPredicate(format: "label IN {'Next','Finish'}")).firstMatch
        if next.waitForExistence(timeout: 4) { next.tap(); settle(1.0) } else { notes.append("no Next") }
    }

    @discardableResult
    private func tapChoice(_ index: Int) -> Bool {
        let row = app.buttons["choice.\(index)"].firstMatch
        guard row.waitForExistence(timeout: 6) else {
            notes.append("no choice.\(index)")
            return false
        }
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle()
        return true
    }

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 6) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        notes.append("could not open: \(label)")
        return false
    }

    private func back() {
        let b = app.navigationBars.buttons.element(boundBy: 0)
        if b.exists { b.tap(); settle(0.8) }
    }

    private func settle(_ seconds: TimeInterval = 1.4) {
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

private extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let current = value as? String, !current.isEmpty, current != "optional" else {
            typeText(text)
            return
        }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text)
    }
}
