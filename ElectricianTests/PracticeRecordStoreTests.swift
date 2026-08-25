import XCTest
@testable import Electrician

@MainActor
final class PracticeRecordStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: PracticeRecordStore!

    // The async overrides are deliberate. XCTest's synchronous setUp/tearDown
    // are nonisolated, so overriding them from a @MainActor test case is an
    // isolation mismatch Swift 6 rejects; the async pair inherits the class's
    // isolation, which is what the main-actor store fixtures below need.
    override func setUp() async throws {
        try await super.setUp()
        defaults = UserDefaults(suiteName: "PracticeRecordStoreTests")!
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        store = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        try await super.tearDown()
    }

    private let room = "basics-room"

    func testRecordsAccuracy() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.record(itemID: "q1", roomID: room, correct: false)
        let record = store.records["q1"]
        XCTAssertEqual(record?.attempts, 2)
        XCTAssertEqual(record?.correct, 1)
        XCTAssertEqual(record?.accuracy, 0.5)
    }

    /// A missed item goes into the queue; two clean answers retire it. Without
    /// the second condition an item would either nag forever or vanish on the
    /// first lucky guess.
    func testMissedItemEntersAndLeavesTheQueue() {
        store.record(itemID: "q1", roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue(), ["q1"])

        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertEqual(store.reviewQueue(), [], "One correct answer schedules it a day out")

        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertFalse(store.records["q1"]!.needsReview, "Two in a row retires it")
    }

    func testQueueRanksWorstFirst() {
        // q1: 1 of 3. q2: 2 of 3. Both due, q1 should lead.
        for correct in [false, false, false] {
            store.record(itemID: "q1", roomID: room, correct: correct)
        }
        store.record(itemID: "q2", roomID: room, correct: true)
        store.record(itemID: "q2", roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue().first, "q1")
    }

    /// Generated items mint a new id per question. They must roll up onto one
    /// per-skill row and must never enter the review queue, or the queue would
    /// fill with questions that can never be shown again.
    func testGeneratedItemsCollapseAndStayOutOfTheQueue() {
        let prefix = PracticeSkill.ampacity.itemPrefix
        store.record(itemID: prefix + "a", roomID: room, correct: false)
        store.record(itemID: prefix + "b", roomID: room, correct: true)

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records[PracticeSkill.ampacity.rawValue]?.attempts, 2)
        XCTAssertTrue(store.reviewQueue().isEmpty)
        XCTAssertEqual(store.dueCount, 0)
    }

    func testOneOffDailyItemContributesToStatsWithoutEnteringReview() {
        store.record(itemID: "code-minute-rollup", roomID: "calc-room", correct: false, isReviewable: false)

        XCTAssertEqual(store.records["code-minute-rollup"]?.attempts, 1)
        XCTAssertTrue(store.reviewQueue().isEmpty)
        XCTAssertEqual(store.dueCount, 0)
    }

    func testRoomStatsAggregate() {
        store.record(itemID: "q1", roomID: "basics-room", correct: true)
        store.record(itemID: "q2", roomID: "basics-room", correct: false)
        store.record(itemID: "q3", roomID: "conductors-room", correct: true)

        let stats = store.roomStats()
        XCTAssertEqual(stats.count, 2)
        let basics = stats.first { $0.id == "basics-room" }
        XCTAssertEqual(basics?.attempts, 2)
        XCTAssertEqual(basics?.accuracy, 0.5)
        XCTAssertEqual(store.overallAccuracy, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testChallengeScoreKeepsTheBest() {
        store.recordChallengeScore(12)
        store.recordChallengeScore(7)
        XCTAssertEqual(store.bestChallengeScore, 12)
    }

    func testPersistsAcrossInstances() {
        store.record(itemID: "q1", roomID: room, correct: true)
        let reloaded = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(reloaded.records["q1"]?.attempts, 1)
    }

    func testResetClearsEverything() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.recordChallengeScore(9)
        store.resetAll()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(store.bestChallengeScore, 0)
        XCTAssertTrue(PracticeRecordStore(defaults: defaults).records.isEmpty)
    }

    // MARK: - Mistake patterns

    private var derateFrom75: MistakePattern { CandidateMistake.derateFrom75 }

    func testRecordingAMistakeMakesItOutstanding() {
        store.recordMistake(derateFrom75)
        XCTAssertEqual(store.outstandingMistakeCount, 1)
        XCTAssertEqual(store.outstandingMistakes().first, derateFrom75)
    }

    /// Two right answers, two patterns worked off. A single lucky pick must not
    /// clear a habit the reader repeated four times.
    func testResolvingWorksAMistakeOffOneAtATime() {
        store.recordMistake(derateFrom75)
        store.recordMistake(derateFrom75)
        XCTAssertEqual(store.outstandingMistakeCount, 2)

        store.resolveMistake(derateFrom75.id)
        XCTAssertEqual(store.outstandingMistakeCount, 1)

        store.resolveMistake(derateFrom75.id)
        XCTAssertEqual(store.outstandingMistakeCount, 0)
        XCTAssertTrue(store.outstandingMistakes().isEmpty)
    }

    func testResolvingAnUntrackedMistakeIsHarmless() {
        store.resolveMistake("never-recorded")
        XCTAssertEqual(store.outstandingMistakeCount, 0)
    }

    /// One bad afternoon on derating must not crowd every other pattern out of
    /// targeted practice for a week.
    func testOutstandingMistakesAreCapped() {
        for _ in 0..<20 { store.recordMistake(derateFrom75) }
        XCTAssertEqual(store.outstandingMistakeCount, PracticeRecordStore.maxOutstandingPerPattern)
    }

    func testWorstMistakeLeadsTheQueue() {
        store.recordMistake(CandidateMistake.ignoredBundling)
        for _ in 0..<3 { store.recordMistake(derateFrom75) }
        XCTAssertEqual(store.outstandingMistakes().first, derateFrom75)
    }

    func testMistakesPersistAcrossLaunches() {
        store.recordMistake(derateFrom75)
        let reloaded = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(reloaded.outstandingMistakes().first, derateFrom75)
    }

    /// The stored summary is refreshed on every miss, so improving the wording
    /// of a mistake in a later release reaches people who already banked it.
    func testRecordingRefreshesTheStoredSummary() {
        let stale = MistakePattern(id: derateFrom75.id, skill: derateFrom75.skill, summary: "old wording")
        store.recordMistake(stale)
        store.recordMistake(derateFrom75)
        XCTAssertEqual(store.outstandingMistakes().first?.summary, derateFrom75.summary)
    }

    func testResetClearsMistakes() {
        store.recordMistake(derateFrom75)
        store.resetAll()
        XCTAssertEqual(store.outstandingMistakeCount, 0)
    }

    /// The Home badge counts both halves: authored questions the scheduler owes
    /// the reader, and generated mistake patterns it can build a problem for.
    func testFixableCountCoversBothHalves() {
        store.record(itemID: "q-fix", roomID: room, correct: false)
        store.recordMistake(derateFrom75)
        XCTAssertEqual(store.fixableCount, store.dueCount + 1)
        XCTAssertGreaterThan(store.fixableCount, 1)
    }

    /// Generated rows collapse per skill; the stats screen reads them by title.
    func testSkillStatsReportGeneratedRows() {
        store.record(itemID: PracticeSkill.ampacity.itemPrefix + "abc", roomID: "conductors-room", correct: true)
        store.record(itemID: PracticeSkill.ampacity.itemPrefix + "def", roomID: "conductors-room", correct: false)
        let stats = store.skillStats()
        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats.first?.name, PracticeSkill.ampacity.title)
        XCTAssertEqual(stats.first?.attempts, 2)
        XCTAssertEqual(stats.first?.correct, 1)
    }
}

final class WhatsNewTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WhatsNewTests")!
        defaults.removePersistentDomain(forName: "WhatsNewTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WhatsNewTests")
        super.tearDown()
    }

    func testNeverShownBeforeOnboarding() {
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: false, defaults: defaults))
    }

    /// Someone updating from a build that predates the feature has no stored
    /// marker at all. That is exactly who the sheet is for, once there is a
    /// release to show them.
    ///
    /// At 1.0 there is nothing to announce, so `releases` is empty and the
    /// correct behaviour is to stay silent. Asserting on `currentRelease`
    /// rather than hardcoding either answer means this test starts enforcing
    /// the real contract the moment 1.1 adds a release, instead of being a
    /// false green that has to be remembered later.
    func testShownToAnUpgraderWithNoMarker() {
        let shouldShow = WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults)
        if WhatsNew.currentRelease == nil {
            XCTAssertFalse(shouldShow, "No release for \(WhatsNew.currentVersion); the sheet must stay closed")
        } else {
            XCTAssertTrue(shouldShow, "An upgrader with no marker should see \(WhatsNew.currentVersion) notes")
        }
    }

    func testShownOnlyOnce() {
        WhatsNew.markSeen(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    func testFreshInstallBaselineSuppressesIt() {
        WhatsNew.markCurrentAsBaseline(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    /// 1.0 has no previous version to have updated from, so `releases` is
    /// legitimately empty. This checks the shape of whatever IS there, and
    /// starts enforcing the real contract as soon as 1.1 adds a release.
    func testReleaseNotesAreWellFormed() throws {
        let versions = WhatsNew.releases.map(\.version)
        XCTAssertEqual(Set(versions).count, versions.count, "duplicate release versions")

        for release in WhatsNew.releases {
            XCTAssertFalse(release.headline.isEmpty, release.version)
            XCTAssertFalse(release.items.isEmpty, release.version)
            XCTAssertEqual(Set(release.items.map(\.id)).count, release.items.count, release.version)
            for item in release.items {
                XCTAssertFalse(item.title.isEmpty)
                XCTAssertFalse(item.body.isEmpty)
                XCTAssertFalse(item.body.contains("—"), "No em dashes in copy")
            }
        }

        if let release = WhatsNew.currentRelease {
            XCTAssertEqual(release.version, WhatsNew.currentVersion)
        }
    }
}
