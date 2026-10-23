import XCTest
@testable import Electrician

/// A question's four answers have to clear the Next button on short viewports.
/// What has to hold: the Duo's panes and folded display and an iPhone SE get the
/// compact setting, every larger iPhone keeps the layout it had, and compact
/// only ever tightens.
final class QuestionDensityTests: XCTestCase {
    func testShortViewportsAreCompact() {
        // Scroll viewport heights measured from the Duo captures (a pane of the
        // unfolded inner display, then the folded outer one) and an iPhone SE.
        XCTAssertEqual(QuestionDensity.forViewport(height: 434), .compact)
        XCTAssertEqual(QuestionDensity.forViewport(height: 444), .compact)
        XCTAssertEqual(QuestionDensity.forViewport(height: 480), .compact)
    }

    func testTallViewportsKeepTheRegularLayout() {
        XCTAssertEqual(QuestionDensity.forViewport(height: QuestionDensity.compactBelowHeight), .regular)
        XCTAssertEqual(QuestionDensity.forViewport(height: 620), .regular)
        XCTAssertEqual(QuestionDensity.forViewport(height: 700), .regular)
    }

    func testBeforeFirstLayoutStaysRegular() {
        XCTAssertEqual(QuestionDensity.forViewport(height: 0), .regular)
    }

    func testCompactOnlyTightens() {
        let regular = QuestionDensity.regular
        let compact = QuestionDensity.compact
        XCTAssertLessThan(compact.stackSpacing, regular.stackSpacing)
        XCTAssertLessThan(compact.givensScale, regular.givensScale)
        XCTAssertLessThan(compact.choiceSpacing, regular.choiceSpacing)
        XCTAssertLessThan(compact.choiceVerticalPadding, regular.choiceVerticalPadding)
        // Four answers, three gaps, two of each spacing around the givens:
        // enough to lift the fourth answer of the derating problem (17 pt short
        // in a Duo pane, 32 pt folded) clear of the Next button.
        let saved = 4 * 2 * (regular.choiceVerticalPadding - compact.choiceVerticalPadding)
            + 3 * (regular.choiceSpacing - compact.choiceSpacing)
            + 2 * (regular.stackSpacing - compact.stackSpacing)
        XCTAssertGreaterThanOrEqual(saved, 32)
    }
}
