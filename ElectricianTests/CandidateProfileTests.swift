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
        profile.focusAreas = ["calc-room"]
        profile.dailyGoal = 25
        profile.completeSetup()

        let reloaded = CandidateProfile(defaults: defaults)
        XCTAssertTrue(reloaded.setupComplete)
        XCTAssertEqual(reloaded.licenseTrack, .master)
        XCTAssertEqual(reloaded.jurisdiction, "Colorado")
        XCTAssertEqual(reloaded.edition, .different)
        XCTAssertEqual(reloaded.focusAreas, ["calc-room"])
        XCTAssertEqual(reloaded.dailyGoal, 25)
    }

    // MARK: - Edition suggestion

    /// The whole point of the state table: "I'm not sure" has to resolve to a
    /// real edition, not stay unanswered.
    func testUnsureEditionResolvesFromTheJurisdiction() {
        let profile = CandidateProfile(defaults: defaults)
        profile.jurisdiction = "Texas"
        profile.edition = .unsure

        XCTAssertEqual(profile.suggestedEdition, .nec2023)
        XCTAssertEqual(profile.resolvedEdition, .nec2023)
        XCTAssertTrue(profile.editionMatchesApp)
        XCTAssertTrue(profile.editionSummary.contains("Texas"))
    }

    /// A state with no statewide adoption must not fabricate one.
    func testUnsureEditionStaysUnresolvedWhereThereIsNoStatewideAdoption() {
        let profile = CandidateProfile(defaults: defaults)
        profile.jurisdiction = "Missouri"
        profile.edition = .unsure

        XCTAssertNil(profile.suggestedEdition)
        XCTAssertNil(profile.resolvedEdition)
        XCTAssertFalse(profile.editionMatchesApp)
    }

    /// Correcting your state must never overwrite an edition you chose yourself.
    func testSelectingAJurisdictionDoesNotOverwriteAnExplicitEdition() {
        let profile = CandidateProfile(defaults: defaults)
        profile.edition = .nec2017
        profile.selectJurisdiction(Jurisdictions.named("Texas")!)

        XCTAssertEqual(profile.edition, .nec2017)
        XCTAssertEqual(profile.resolvedEdition, .nec2017)
        XCTAssertFalse(profile.editionMatchesApp)
    }

    /// Free text typed before the picker existed must not crash or match.
    func testUnknownJurisdictionTextHasNoRecord() {
        let profile = CandidateProfile(defaults: defaults)
        profile.jurisdiction = "somewhere else"

        XCTAssertNil(profile.jurisdictionRecord)
        XCTAssertTrue(profile.canCompleteSetup)
    }

    // MARK: - Exam date

    func testDailySuggestionIsClampedAtBothEnds() {
        let profile = CandidateProfile(defaults: defaults)

        profile.examDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())
        XCTAssertEqual(profile.suggestedDailyQuestions, 60)

        profile.examDate = Calendar.current.date(byAdding: .day, value: 400, to: Date())
        XCTAssertEqual(profile.suggestedDailyQuestions, 10)

        profile.examDate = nil
        XCTAssertEqual(profile.suggestedDailyQuestions, 15)
        XCTAssertNil(profile.examCountdownSummary)
    }

    func testCountdownCountsWholeDays() {
        let profile = CandidateProfile(defaults: defaults)
        profile.examDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())

        XCTAssertEqual(profile.daysUntilExam, 10)
        XCTAssertEqual(profile.examCountdownSummary, "10 days out")
    }

    func testFocusTogglesBothWays() {
        let profile = CandidateProfile(defaults: defaults)
        profile.toggleFocus("calc-room")
        XCTAssertEqual(profile.focusAreas, ["calc-room"])
        profile.toggleFocus("calc-room")
        XCTAssertTrue(profile.focusAreas.isEmpty)
    }

    func testTargetSummaryUsesTheSavedValues() {
        let profile = CandidateProfile(defaults: defaults)
        profile.jurisdiction = "Colorado"
        profile.completeSetup()

        XCTAssertEqual(profile.targetSummary, "Journeyman · Colorado")
    }
}
