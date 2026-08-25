import XCTest
@testable import Electrician

@MainActor
final class CandidateProfileTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        defaults = UserDefaults(suiteName: "CandidateProfileTests")!
        defaults.removePersistentDomain(forName: "CandidateProfileTests")
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: "CandidateProfileTests")
        try await super.tearDown()
    }

    func testProfileNeedsAJurisdiction() {
        let profile = CandidateProfile(defaults: defaults)
        XCTAssertFalse(profile.canCompleteSetup)

        profile.selectTrack(.master)
        XCTAssertFalse(profile.canCompleteSetup)

        profile.jurisdiction = "Colorado"
        XCTAssertTrue(profile.canCompleteSetup)
    }

    func testDefaultTrackCanCompleteSetupAfterJurisdiction() {
        let profile = CandidateProfile(defaults: defaults)
        profile.jurisdiction = "Colorado"

        XCTAssertTrue(profile.canCompleteSetup)
    }

    func testProfilePersistsTheTarget() {
        let profile = CandidateProfile(defaults: defaults)
        profile.selectTrack(.master)
        profile.jurisdiction = "Colorado"
        profile.edition = .different
        profile.completeSetup()

        let reloaded = CandidateProfile(defaults: defaults)
        XCTAssertTrue(reloaded.setupComplete)
        XCTAssertEqual(reloaded.licenseTrack, .master)
        XCTAssertEqual(reloaded.jurisdiction, "Colorado")
        XCTAssertEqual(reloaded.edition, .different)
    }

    func testTargetSummaryUsesTheSavedValues() {
        let profile = CandidateProfile(defaults: defaults)
        profile.jurisdiction = "Colorado"
        profile.completeSetup()

        XCTAssertEqual(profile.targetSummary, "Journeyman · Colorado")
    }
}
