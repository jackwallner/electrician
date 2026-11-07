import XCTest

@MainActor
final class TmpLanguageRowUITests: XCTestCase {
    func testLanguageRowGerman() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        app.launchArguments += ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE", "-DuoSeed", "-electrician.suppressWhatsNew"]
        app.launch()
        let settings = app.buttons.matching(NSPredicate(format: "identifier == 'Settings' OR label == 'Einstellungen'")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 30))
        settings.tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Sprache'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15), app.debugDescription)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "settings-language-de"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
