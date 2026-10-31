import XCTest
@testable import Electrician

@MainActor
final class ProgressStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: ProgressStore!

    // The async overrides are deliberate. XCTest's synchronous setUp/tearDown
    // are nonisolated, so overriding them from a @MainActor test case is an
    // isolation mismatch Swift 6 rejects; the async pair inherits the class's
    // isolation, which is what the main-actor store fixtures below need.
    override func setUp() async throws {
        try await super.setUp()
        defaults = UserDefaults(suiteName: "ProgressStoreTests")
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        store = ProgressStore(defaults: defaults)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        try await super.tearDown()
    }

    func testRecordSessionIncrementsCounts() {
        store.recordSession(drillID: "meet-the-book")
        store.recordSession(drillID: "meet-the-book")
        XCTAssertEqual(store.completions(for: "meet-the-book"), 2)
        XCTAssertEqual(store.totalSessions, 2)
    }

    func testStreakStartsAtOne() {
        store.recordSession(drillID: "a")
        XCTAssertEqual(store.streakCount, 1)
    }

    func testSameDaySessionsKeepStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "b", now: day1.addingTimeInterval(3600))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testConsecutiveDaysGrowStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2)
    }

    func testGapResetsStreakToOne() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400 * 3))
        XCTAssertEqual(store.streakCount, 1)
    }

    /// `streakCount` is the length of the last run, and only the next finished
    /// drill ends it, so after a week away Home still printed the old figure as
    /// if it were live. What is shown has to be what the run is worth today.
    func testStreakReadsZeroOnceADayHasBeenMissed() {
        let calendar = Calendar.current
        let first = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_750_000_000)).addingTimeInterval(12 * 3600)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: first)! }

        store.recordSession(drillID: "a", now: day(0))
        store.recordSession(drillID: "a", now: day(1))

        XCTAssertEqual(store.currentStreak(now: day(1)), 2, "Practised today")
        XCTAssertEqual(store.currentStreak(now: day(2)), 2, "Practised yesterday, so today can still extend it")
        XCTAssertEqual(store.currentStreak(now: day(3)), 0, "A whole day missed ends the run")
        XCTAssertEqual(store.currentStreak(now: day(30)), 0)
        XCTAssertEqual(store.streakCount, 2, "The stored run is untouched; only what is shown changes")
    }

    func testNothingPractisedReadsZero() {
        XCTAssertEqual(store.currentStreak(), 0)
    }

    /// The screenshot capture seeds `progress.streakCount` with no day on
    /// record, and that seeded count has to keep showing.
    func testASeededCountWithNoDayOnRecordIsShownAsStored() {
        defaults.set(6, forKey: "progress.streakCount")
        XCTAssertEqual(ProgressStore(defaults: defaults).currentStreak(), 6)
    }

    func testRoomProgress() {
        guard let room = DrillLibrary.rooms.first else { return XCTFail("no rooms") }
        XCTAssertEqual(store.roomProgress(room), 0)
        store.recordSession(drillID: room.drills[0].id)
        XCTAssertEqual(store.roomProgress(room), 1 / Double(room.drills.count), accuracy: 0.001)
    }

    func testRecordItemTracksSeenAndMissed() {
        store.recordItem(id: "q1", correct: false)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertTrue(store.missedItems.contains("q1"))
        store.recordItem(id: "q1", correct: true)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertFalse(store.missedItems.contains("q1"), "A correct answer clears the miss")
    }

    func testItemTrackingPersists() {
        store.recordItem(id: "q1", correct: false)
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertTrue(reloaded.seenItems.contains("q1"))
        XCTAssertTrue(reloaded.missedItems.contains("q1"))
    }

    func testResetAllClearsEverythingButOnboarding() {
        store.hasOnboarded = true
        store.recordSession(drillID: "a")
        store.recordItem(id: "q1", correct: false)
        store.resetAll()
        XCTAssertEqual(store.streakCount, 0)
        XCTAssertEqual(store.totalSessions, 0)
        XCTAssertEqual(store.completions(for: "a"), 0)
        XCTAssertTrue(store.seenItems.isEmpty)
        XCTAssertTrue(store.missedItems.isEmpty)
        XCTAssertTrue(store.hasOnboarded, "Reset must not re-trigger onboarding")
    }

    // Rating-ask rules live in ReviewPromptTracker; see ReviewPromptTrackerTests.
}
