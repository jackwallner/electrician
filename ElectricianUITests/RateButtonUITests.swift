import XCTest

/// The listing is live, so Settings offers Rate and the review pitch opens from it.
final class RateButtonUITests: XCTestCase {
    func testRateButtonOpensReviewPitch() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        app.launchArguments += ["-progress.hasOnboarded", "YES"]
        app.launch()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 20))
        settings.tap()

        let rate = app.buttons["Rate Electrician"]
        for _ in 0..<6 where !rate.exists { app.swipeUp() }
        XCTAssertTrue(rate.waitForExistence(timeout: 5), "Rate button is still hidden")
        rate.tap()
        XCTAssertTrue(app.buttons["Rate on the App Store"].waitForExistence(timeout: 10), "Review pitch did not offer the App Store link")
    }
}
