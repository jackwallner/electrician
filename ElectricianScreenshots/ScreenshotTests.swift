import XCTest

/// Captures the App Store screenshot set from the real app, on whatever
/// destination `xcodebuild test` is pointed at. Exists because the iPad shots
/// have to be re-captured whenever a drill layout changes, and re-shooting six
/// screens by hand is how you end up shipping a stale set.
///
/// Run: scripts/capture-screenshots.sh <udid> <out-dir> [prefix]
///
/// Not part of the Electrician scheme's test action — it lives on its own
/// `Screenshots` scheme so the unit-test loop stays fast.
///
/// The test never fails on a missing element. A hard XCTFail makes Xcode spend
/// ten minutes collecting simulator diagnostics before it reports anything,
/// which turns every navigation typo into a very slow question. Instead it
/// records what it could not find and attaches the element tree, so one run
/// tells you both what you got and why the rest is missing.
@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // The `-key value` form lands in UserDefaults' argument domain, so the
        // app boots past onboarding without a debug hook in shipping code.
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-electrician.hasReadPrimer", "YES",
            "-electrician.skillLevel", "some",
            "-candidate.licenseTrack", "journeyman",
            // A real state, not "Test State": Home renders the jurisdiction
            // next to the edition, and the edition is only resolvable from a
            // jurisdiction the table actually knows.
            "-candidate.jurisdiction", "Georgia",
            "-candidate.edition", "nec2023",
            "-candidate.hasSelectedTrack", "YES",
            "-candidate.setupComplete", "YES",
            "-subscription.localProOverride", "YES",
            // Home with every counter on zero photographs as an empty app.
            // Seed an ordinary week of practice so the screenshot shows the
            // return loop the store listing claims.
            "-progress.streakCount", "6",
            "-progress.totalSessions", "24",
            "-progress.completions", Self.seededCompletions,
            "-practice.records", Self.seededRecords,
        ]
        // The What's New sheet fires on the first launch after a version bump
        // and covers Home. Marking the CURRENT version as already seen is what
        // suppresses it — any other value still counts as an upgrade — so the
        // capture script passes the real marketing version in.
        if let version = ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] {
            app.launchArguments += ["-whatsnew.lastSeenVersion", version]
        }
        app.launch()
    }

    // MARK: - Seeded state

    /// Room progress rings, as an XML plist. The argument domain runs every
    /// `-key value` through the property-list parser, and the OLD-style plist
    /// syntax has no integer type: `{"meet-the-code"=2;}` decodes to
    /// `["meet-the-code": "2"]`, which `[String: Int]` then rejects, and the
    /// rings photograph as zero.
    private static var seededCompletions: String {
        let counts = [
            ("meet-the-code", 2), ("navigation-quiz", 3), ("article-cards", 1),
            ("ampacity-cards", 2), ("ampacity-quiz", 1),
            ("workspace-cards", 2), ("install-quiz", 1),
        ]
        let body = counts
            .map { "<key>\($0.0)</key><integer>\($0.1)</integer>" }
            .joined()
        return "<plist version=\"1.0\"><dict>\(body)</dict></plist>"
    }

    /// `practice.records` is stored as JSON `Data`, and the argument domain
    /// only produces `NSData` from old-style plist hex, so the seed is encoded
    /// as `<hex>`. Sixty attempts at 83% over five rooms is what puts the
    /// readiness card into its "consistent practice" state.
    private static var seededRecords: String {
        let now = Date()
        var entries: [String] = []
        var hour = 0
        for room in ["basics-room", "conductors-room", "install-room", "calc-room", "grounding-room"] {
            for (index, correct) in [4, 3, 3].enumerated() {
                hour += 1
                let last = now.addingTimeInterval(-3600 * Double(hour)).timeIntervalSinceReferenceDate
                let due = now.addingTimeInterval(86_400 * 5).timeIntervalSinceReferenceDate
                entries.append("""
                "\(room)-\(index)":{"attempts":4,"correct":\(correct),"streak":2,\
                "lastAnswered":\(last),"dueDate":\(due),"intervalDays":5,"ease":2.5,\
                "roomID":"\(room)"}
                """)
            }
        }
        let json = "{" + entries.joined(separator: ",") + "}"
        return "<" + Data(json.utf8).map { String(format: "%02x", $0) }.joined() + ">"
    }

    func testCaptureAppStoreSet() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("05_home")
        attachTree("home")

        if open("Get Started") {
            // Capture mid-session, not on question one. The first Quick
            // Session question is the same ampacity item frame 3 uses, and two
            // carousel frames showing one question reads as a thin app.
            for _ in 0..<3 {
                tapChoice(0)
                advanceQuestion()
            }
            capture("01_quick_session")
        }
        home()

        if open("Code Basics"), open("Which Article?") {
            capture("02_article_match")
        }
        home()

        // Frame 3 has to show what a MISS looks like, so it answers wrong on
        // purpose. An unanswered question proves nothing about the feedback.
        if open("Conductors & Ampacity"), open("Ampacity Check") {
            answerIncorrectly()
            capture("03_ampacity_quiz")
        }
        home()

        // Re-launch before the paid room so a stale NavigationStack destination
        // cannot leave an earlier room in the accessibility tree.
        restartAtHome()
        app.swipeUp()
        settle()

        if open("Worked Calculations") {
            // The room header and first grid row fill the initial viewport on
            // smaller phones. The calculation drill is lower in the grid.
            app.swipeUp()
            settle()
            if open("The Five Shapes") {
                // The numbered working only exists after an answer, and it
                // renders BELOW the choices, so the capture has to scroll to
                // it or the frame promises steps it does not show.
                answerCorrectly()
                scroll(byScreenFraction: 0.34)
                capture("04_worked_calc")
            }
        }
        home()

        if open("Code Basics") {
            capture("06_basics_room")
        }

        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    /// A measured drag, because `swipeUp()` is a fling: on the worked-answer
    /// screen it throws the question off the top and lands the frame in the
    /// middle of the choice list.
    private func scroll(byScreenFraction fraction: CGFloat) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8 - fraction))
        start.press(forDuration: 0.1, thenDragTo: end)
        settle()
    }

    // MARK: - Answering

    /// Taps a choice row by its stable identifier. The label text is generated
    /// and the row order is shuffled per item, so position is the only handle.
    @discardableResult
    private func tapChoice(_ index: Int) -> Bool {
        let row = app.buttons["choice.\(index)"].firstMatch
        guard row.waitForExistence(timeout: 6) else {
            problems.append("no choice.\(index)")
            return false
        }
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle()
        return true
    }

    /// After an answer the picked row carries the result in its accessibility
    /// label, which is how the capture knows whether it got what it wanted.
    private func rowLabel(_ index: Int) -> String {
        app.buttons["choice.\(index)"].firstMatch.label
    }

    /// The advance button is "Next" in a calculation drill and "Next Question"
    /// in a quiz, so match the prefix rather than one exact label.
    @discardableResult
    private func advanceQuestion() -> Bool {
        let next = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH 'Next'"))
            .firstMatch
        guard next.exists, next.isEnabled else { return false }
        next.tap()
        settle()
        return true
    }

    /// The shuffle is seeded per item, so the test cannot know which row wins.
    /// Tap the first row; if it was not the outcome this frame needs, move to
    /// the next question and try again.
    @discardableResult
    private func answer(untilLabelContains marker: String, tries: Int = 5) -> Bool {
        for attempt in 0..<tries {
            // Rotate the row. Tapping row 0 every time can miss the answer for
            // a whole five-question drill, which is how the mechanism frame
            // ended up photographing a wrong pick.
            let row = attempt % 4
            guard tapChoice(row) else { return false }
            if rowLabel(row).contains(marker) { return true }
            guard advanceQuestion() else { break }
        }
        problems.append("never landed on: \(marker)")
        return false
    }

    @discardableResult
    private func answerCorrectly() -> Bool { answer(untilLabelContains: "Correct answer") }

    @discardableResult
    private func answerIncorrectly() -> Bool { answer(untilLabelContains: "incorrect") }

    // MARK: - Navigation

    /// The What's New sheet fires on the first launch after a version bump and
    /// covers Home completely. Pinning `whatsnew.lastSeenVersion` from the
    /// launch arguments would mean hardcoding the marketing version here and
    /// re-breaking capture on every release, so just dismiss it.
    private func dismissWhatsNew() {
        // Belt and braces for a version the script could not resolve. Dismissing
        // does not mark the release seen, so the sheet returns every time Home
        // reappears; the launch argument above is the real fix.
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    private func restartAtHome() {
        app.terminate()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
    }

    /// Taps the first hittable element whose label starts with `label`.
    /// Home's cards are NavigationLinks with stacked title + subtitle, so the
    /// accessibility label is the whole card, not just the title.
    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 6) else { continue }
            // Tap the centre of the frame rather than the element. SwiftUI
            // cards report isHittable false often enough that trusting it costs
            // a whole capture run, and a coordinate tap lands the same place.
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    /// Pops back to the root, recognising Home by its Get Started card.
    ///
    /// Do NOT just tap navigation-bar button 0 until it runs out: on Home that
    /// button is the Settings gear, so the extra tap opens Settings, and every
    /// later coordinate tap then lands on the Settings sheet while the elements
    /// underneath still answer queries. That failure looks exactly like a
    /// mislabelled drill row, which is a slow thing to debug.
    private func home() {
        for _ in 0..<4 {
            if atHome { return }
            let done = app.buttons["Done"].firstMatch
            if done.exists {
                done.tap()
                settle(0.6)
                continue
            }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    private var atHome: Bool {
        // NavigationStack keeps parts of the previous screen in the query
        // tree during a pop. The Home gear is the reliable visible root
        // marker, while a room can still expose Home's section text.
        let settings = app.buttons["Settings"].firstMatch
        return settings.exists && settings.isHittable
    }

    /// Let the push transition and any entrance animation finish before the
    /// shutter: a mid-transition frame is a blurred, half-offset screenshot.
    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capture

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
