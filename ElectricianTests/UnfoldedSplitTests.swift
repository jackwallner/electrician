import XCTest
@testable import Electrician

/// The unfolded iPhone Duo puts Home and Your Progress either side of the fold.
/// What has to hold: phones and the folded Duo never split, the panes meet the
/// fold edges exactly when the system reports a usable fold, and nothing ever
/// gets a pane too narrow for the phone layout.
final class UnfoldedSplitTests: XCTestCase {
    func testCompactWidthNeverSplits() {
        XCTAssertNil(UnfoldedSplit.make(width: 951, isRegularWidth: false, fold: 474...477))
        XCTAssertNil(UnfoldedSplit.make(width: 466, isRegularWidth: false, fold: nil))
    }

    func testRegularWidthTooNarrowForTwoPanesStaysSingle() {
        // The unfolded Duo held in portrait: 669 pt cannot hold two 360 pt panes.
        XCTAssertNil(UnfoldedSplit.make(width: 669, isRegularWidth: true, fold: nil))
        XCTAssertNil(UnfoldedSplit.make(width: 719, isRegularWidth: true, fold: 350...369))
    }

    func testPanesMeetTheFoldEdges() {
        let split = UnfoldedSplit.make(width: 871, isRegularWidth: true, fold: 474...477)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 474, secondaryX: 477, secondaryWidth: 394))
    }

    func testZeroWidthFoldSharesOneEdge() {
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: 475.5...475.5)
        XCTAssertEqual(split?.primaryWidth, 475.5)
        XCTAssertEqual(split?.secondaryX, 475.5)
        XCTAssertEqual(split?.secondaryWidth, 475.5)
    }

    func testNoFoldSplitsEvenly() {
        let split = UnfoldedSplit.make(width: 1033, isRegularWidth: true, fold: nil)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 516, secondaryX: 516, secondaryWidth: 517))
    }

    func testFoldThatLeavesANarrowPaneFallsBackToAnEvenSplit() {
        // A fold this far off-centre would squeeze Your Progress under 360 pt.
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: 600...604)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 475, secondaryX: 475, secondaryWidth: 476))
    }

    func testEveryPaneIsAtLeastTheMinimum() {
        for width in stride(from: CGFloat(720), through: 1400, by: 37) {
            for fold in [nil, (width / 2 - 2)...(width / 2 + 2), CGFloat(100)...CGFloat(104)] {
                guard let split = UnfoldedSplit.make(width: width, isRegularWidth: true, fold: fold) else {
                    return XCTFail("\(width) should split")
                }
                XCTAssertGreaterThanOrEqual(split.primaryWidth, UnfoldedSplit.minimumPaneWidth)
                XCTAssertGreaterThanOrEqual(split.secondaryWidth, UnfoldedSplit.minimumPaneWidth)
                XCTAssertEqual(split.secondaryX + split.secondaryWidth, width, accuracy: 0.001)
            }
        }
    }

    // MARK: - Training tiles

    private let tile = CGSize(width: 128, height: 118)

    func testPhoneRowKeepsNaturalSizesInOneLine() {
        let frames = TrainingTileLayout.frames(for: Array(repeating: tile, count: 5), wrapWidth: nil)
        XCTAssertEqual(frames.map(\.minY), Array(repeating: 0, count: 5))
        XCTAssertEqual(frames.map(\.minX), [0, 138, 276, 414, 552])
        XCTAssertEqual(frames.map(\.width), Array(repeating: 128, count: 5))
    }

    func testPaneWrapsFiveTilesIntoWholeColumns() {
        // A Duo pane's training row: about 440 pt pane, less Home's margins.
        let width: CGFloat = 400
        let frames = TrainingTileLayout.frames(for: Array(repeating: tile, count: 5), wrapWidth: width)
        XCTAssertEqual(TrainingTileLayout.columns(for: width), 3)
        XCTAssertEqual(frames.map(\.minY), [0, 0, 0, 128, 128])
        for frame in frames {
            XCTAssertGreaterThanOrEqual(frame.width, TrainingTileLayout.minimumTileWidth)
            // No tile is cut off at the pane's edge (the fold).
            XCTAssertLessThanOrEqual(frame.maxX, width + 0.001)
        }
        XCTAssertEqual(frames[2].maxX, width, accuracy: 0.001)
    }

    func testColumnsNeverDropBelowOneOrUnderTheMinimumWidth() {
        XCTAssertEqual(TrainingTileLayout.columns(for: 60), 1)
        for width in stride(from: CGFloat(120), through: 900, by: 7) {
            let columns = CGFloat(TrainingTileLayout.columns(for: width))
            let tileWidth = (width - 10 * (columns - 1)) / columns
            XCTAssertGreaterThanOrEqual(tileWidth, TrainingTileLayout.minimumTileWidth - 0.001, "width \(width)")
        }
    }
}
