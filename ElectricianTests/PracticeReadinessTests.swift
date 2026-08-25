import XCTest
@testable import Electrician

final class PracticeReadinessTests: XCTestCase {
    func testNoPracticeNeedsABaseline() {
        let metrics = PracticeReadinessMetrics(
            attempts: 0,
            correct: 0,
            practicedRooms: 0,
            availableRooms: 2
        )

        XCTAssertEqual(metrics.level, .notStarted)
        XCTAssertEqual(metrics.title, "Set a baseline")
        XCTAssertEqual(metrics.coverageText, "0 of 2 rooms")
    }

    func testConsistentPracticeRequiresVolumeAccuracyAndCoverage() {
        let metrics = PracticeReadinessMetrics(
            attempts: 30,
            correct: 25,
            practicedRooms: 2,
            availableRooms: 2
        )

        XCTAssertEqual(metrics.level, .consistent)
        XCTAssertEqual(metrics.accuracyText, "83%")
    }

    func testLowAccuracyStaysInBuildingState() {
        let metrics = PracticeReadinessMetrics(
            attempts: 50,
            correct: 35,
            practicedRooms: 4,
            availableRooms: 4
        )

        XCTAssertEqual(metrics.level, .building)
    }
}
