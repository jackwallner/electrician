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

    // MARK: Time zone moves

    /// Runs `body` with the phone's zone set to `start`, restoring it after.
    private func inZone(_ start: String, _ body: () throws -> Void) rethrows {
        let saved = NSTimeZone.default
        defer { NSTimeZone.default = saved }
        NSTimeZone.default = TimeZone(identifier: start)!
        try body()
    }

    private func move(to zone: String) {
        NSTimeZone.default = TimeZone(identifier: zone)!
        XCTAssertEqual(Calendar.current.timeZone.identifier, zone, "precondition: the calendar follows the zone")
    }

    /// Tue 10 Nov 2026, 17:00 UTC: 12:00 in New York, 09:00 in Los Angeles.
    private let tuesdayNoonNewYork = Date(timeIntervalSince1970: 1_794_330_000)

    /// A stored New York midnight read in Los Angeles is 21:00 the day before,
    /// so a second drill on the same Tuesday counted as a new day.
    func testSameDaySessionAfterFlyingWestKeepsTheStreak() {
        inZone("America/New_York") {
            store.recordSession(drillID: "a", now: tuesdayNoonNewYork)
            move(to: "America/Los_Angeles")
            store.recordSession(drillID: "b", now: tuesdayNoonNewYork.addingTimeInterval(3600))
            XCTAssertEqual(store.streakCount, 1)
            XCTAssertEqual(store.currentStreak(now: tuesdayNoonNewYork.addingTimeInterval(3600)), 1)
        }
    }

    func testSameDaySessionAfterFlyingEastKeepsTheStreak() {
        inZone("America/Los_Angeles") {
            store.recordSession(drillID: "a", now: tuesdayNoonNewYork)
            move(to: "America/New_York")
            store.recordSession(drillID: "b", now: tuesdayNoonNewYork.addingTimeInterval(3600))
            XCTAssertEqual(store.streakCount, 1)
        }
    }

    func testNextDayAfterFlyingWestStillGrowsTheStreak() {
        inZone("America/New_York") {
            store.recordSession(drillID: "a", now: tuesdayNoonNewYork)
            move(to: "America/Los_Angeles")
            store.recordSession(drillID: "b", now: tuesdayNoonNewYork.addingTimeInterval(86_400))
            XCTAssertEqual(store.streakCount, 2)
        }
    }

    func testGetStartedStaysDoneAfterFlyingWest() {
        inZone("America/New_York") {
            store.markQuickSessionCompleted(now: tuesdayNoonNewYork)
            move(to: "America/Los_Angeles")
            XCTAssertTrue(store.quickSessionCompletedToday(now: tuesdayNoonNewYork))
            XCTAssertFalse(store.quickSessionCompletedToday(now: tuesdayNoonNewYork.addingTimeInterval(86_400)))
        }
    }

    /// Older builds stored the local midnight as a Date. Those installs keep
    /// their streak and today's Get Started, in their own zone or after a move.
    func testDaysStoredByOlderBuildsStillRead() {
        inZone("America/New_York") {
            let midnight = Calendar.current.startOfDay(for: tuesdayNoonNewYork)
            defaults.set(midnight, forKey: "progress.lastActiveDay")
            defaults.set(midnight, forKey: "progress.lastQuickSessionDay")
            defaults.set(4, forKey: "progress.streakCount")
            let legacy = ProgressStore(defaults: defaults)
            XCTAssertTrue(legacy.quickSessionCompletedToday(now: tuesdayNoonNewYork))
            move(to: "America/Los_Angeles")
            XCTAssertTrue(legacy.quickSessionCompletedToday(now: tuesdayNoonNewYork))
            XCTAssertEqual(legacy.currentStreak(now: tuesdayNoonNewYork), 4)
            legacy.recordSession(drillID: "a", now: tuesdayNoonNewYork)
            XCTAssertEqual(legacy.streakCount, 4, "Same day, so the run is unchanged")
            legacy.recordSession(drillID: "a", now: tuesdayNoonNewYork.addingTimeInterval(86_400))
            XCTAssertEqual(legacy.streakCount, 5)
        }
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
