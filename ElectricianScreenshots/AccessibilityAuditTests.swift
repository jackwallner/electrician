import XCTest

/// Persona audit capture: a reader on a large Dynamic Type size. Walks first
/// run, the core drills, the paywall and Settings and attaches a screenshot
/// and the element tree for each, plus a record of anything off screen.
///
/// Never fails on a missing element (see `ScreenshotTests` for why); it
/// records `problems` instead. Reduce Motion cannot be toggled from a UI test
/// on a simulator, so motion findings are source-only.
///
/// Run: gh-sim test --scheme Screenshots --only ElectricianScreenshots/AccessibilityAuditTests
@MainActor
final class AccessibilityAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    private static let ax3 = "UICTContentSizeCategoryAccessibilityXL"
    private static let ax5 = "UICTContentSizeCategoryAccessibilityXXXL"

    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() {
        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    // MARK: - Launch

    private func launch(size: String, setUp extra: [String]) {
        app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", size] + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
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
        "-progress.streakCount", "6",
        "-progress.totalSessions", "24",
    ]

    // MARK: - First run

    func testFirstRunOnboardingAX3() { walkOnboarding(size: Self.ax3, prefix: "ob_ax3") }

    func testFirstRunOnboardingAX5() { walkOnboarding(size: Self.ax5, prefix: "ob_ax5") }

    private func walkOnboarding(size: String, prefix: String) {
        launch(size: size, setUp: [])
        for step in 0..<16 {
            capture("\(prefix)_\(String(format: "%02d", step))")
            if step == 0 || step == 9 || step == 11 { attachTree("\(prefix)_\(step)") }
            noteOffscreenControls(context: "\(prefix)_\(step)")
            // Setup gates: a state and an experience level have to be chosen.
            let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Georgia'")).firstMatch
            if row.exists, row.isHittable {
                row.tap(); settle(0.8)
            }
            let primary = app.buttons.matching(NSPredicate(
                format: "label IN {'Continue','Set up my exam','Looks right'}")).firstMatch
            if primary.exists, !primary.isEnabled {
                // Pick the first selectable row inside the scroll view.
                let rows = app.scrollViews.buttons
                if rows.count > 0 { rows.element(boundBy: 0).tap(); settle(0.8) }
            }
            if primary.exists, primary.isEnabled {
                primary.tap()
                settle(1.2)
                continue
            }
            // Trial step (or unknown): stop and record why.
            problems.append("\(prefix): no enabled primary at step \(step)")
            attachTree("\(prefix)_stuck_\(step)")
            break
        }
    }

    // MARK: - Core loop

    func testHomeAndDrillsAX3() {
        launch(size: Self.ax3, setUp: Self.seeded + ["-subscription.localProOverride", "YES"])
        capture("home_ax3_top")
        attachTree("home_ax3")
        noteOffscreenControls(context: "home")
        app.swipeUp(); settle(0.8)
        capture("home_ax3_mid")
        app.swipeUp(); settle(0.8)
        capture("home_ax3_low")
        app.swipeDown(); app.swipeDown(); app.swipeDown(); settle(0.8)

        if open("Get Started") {
            capture("quick_q1")
            attachTree("quick_q1")
            tapChoice(0)
            capture("quick_q1_answered")
            scrollDown()
            capture("quick_q1_answered_scrolled")
            attachTree("quick_q1_answered")
        }
    }

    func testRoomAndCalcDrillAX3() {
        launch(size: Self.ax3, setUp: Self.seeded + ["-subscription.localProOverride", "YES"])
        if open("Code Basics") {
            capture("room_basics_ax3")
            if open("Know the Articles") {
                capture("flash_front_ax3")
                attachTree("flash_front")
                // Flip: tap the card centre.
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
                settle(1.0)
                capture("flash_back_ax3")
                attachTree("flash_back")
            }
        }
        back()
        back()
        if app.buttons["Settings"].firstMatch.exists == false { back() }
        app.swipeUp(); settle(0.8)
        if open("Worked Calculations") {
            app.swipeUp(); settle(0.8)
            if open("The Five Shapes") {
                capture("calc_q_ax3")
                attachTree("calc_q")
                tapChoice(0)
                capture("calc_answered_ax3")
                scrollDown()
                capture("calc_answered_scrolled_ax3")
            }
        }
    }

    // MARK: - Free user: paywall and Settings

    func testPaywallAndSettingsAX3() {
        launch(size: Self.ax3, setUp: Self.seeded)
        app.swipeUp(); settle(0.8)
        if open("Worked Calculations") {
            capture("locked_room_ax3")
            attachTree("locked_room")
            app.swipeUp(); settle(0.8)
            if open("The Five Shapes") {
                capture("paywall_ax3_top")
                attachTree("paywall")
                noteOffscreenControls(context: "paywall")
                app.swipeUp(); settle(0.8)
                capture("paywall_ax3_scrolled")
            }
        }
        launch(size: Self.ax3, setUp: Self.seeded)
        app.buttons["Settings"].firstMatch.tap(); settle()
        capture("settings_ax3_top")
        attachTree("settings")
        app.swipeUp(); settle(0.8)
        capture("settings_ax3_mid")
        app.swipeUp(); settle(0.8)
        capture("settings_ax3_low")
    }

    func testFieldToolsAX3() {
        launch(size: Self.ax3, setUp: Self.seeded + ["-subscription.localProOverride", "YES"])
        app.swipeUp(); app.swipeUp(); settle(0.8)
        if open("Field tools") {
            capture("tools_list_ax3")
            if open("Voltage drop") {
                capture("vdrop_ax3")
                let fields = app.textFields
                if fields.count > 0 {
                    let field = fields.element(boundBy: 0)
                    field.tap()
                    field.typeText("125.5")
                    settle(0.8)
                    capture("vdrop_typed_ax3")
                    attachTree("vdrop_typed")
                    noteOffscreenControls(context: "vdrop")
                } else {
                    problems.append("vdrop: no text field")
                }
            }
        }
    }

    // MARK: - Helpers

    private func noteOffscreenControls(context: String) {
        let screen = app.frame
        for button in app.buttons.allElementsBoundByIndex where button.exists && !button.label.isEmpty {
            let f = button.frame
            if f.height > 0, f.height < 44 || f.width < 44 {
                problems.append("\(context): small target '\(button.label)' \(Int(f.width))x\(Int(f.height))")
            }
            if f.maxY > screen.maxY + 1 || f.maxX > screen.maxX + 1 {
                problems.append("\(context): '\(button.label)' extends off screen \(f)")
            }
        }
    }

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
        problems.append("could not open: \(label)")
        return false
    }

    private func back() {
        let b = app.navigationBars.buttons.element(boundBy: 0)
        if b.exists, b.identifier != "gearshape" { b.tap(); settle(0.8) }
    }

    private func scrollDown() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        start.press(forDuration: 0.1, thenDragTo: end)
        settle()
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
