import XCTest

/// The flashcard deck throws a card off on Knew it, Again and Next. A second tap
/// that lands while the card is still in flight has to be ignored: it used to
/// grade and discard the NEXT card as well, one the reader had not seen.
@MainActor
final class FlashcardDeckUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testDoubleTappingKnewItClearsOneCardNotTwo() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.electrician")
        // The DEBUG route walker lands straight in the first deck, and the
        // seeded candidate keeps onboarding and the paywall out of the way.
        app.launchArguments = [
            "-DuoSeed", "-DuoTour", "-DuoTourFirst", "1", "-DuoTourStep", "600",
            "-DuoRoutes", "drill-meet-the-code", "-electrician.suppressWhatsNew",
        ]
        app.launch()

        let progress = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", " reviewed")).firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 45), "The deck never opened")
        let total = progress.label.components(separatedBy: " of ").last?.components(separatedBy: " ").first ?? "?"
        XCTAssertEqual(progress.label, "0 of \(total) reviewed")

        // The first card has no self-test, so a tap turns it over and shows
        // the grading buttons.
        let card = app.buttons["How the book is arranged"]
        if card.waitForExistence(timeout: 10) {
            card.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        }
        let knewIt = app.buttons["Knew it"]
        XCTAssertTrue(knewIt.waitForExistence(timeout: 10), "The card never turned over")

        knewIt.doubleTap()

        // Let the throw finish, then count what the deck says it cleared.
        let oneCleared = NSPredicate(format: "label == %@", "1 of \(total) reviewed")
        let settled = XCTNSPredicateExpectation(predicate: oneCleared, object: progress)
        let result = XCTWaiter().wait(for: [settled], timeout: 8)
        XCTAssertEqual(result, .completed, "A double tap on Knew it left the deck reading \(progress.label)")
        XCTAssertEqual(progress.label, "1 of \(total) reviewed")
    }
}
