import XCTest
@testable import Electrician

/// The state table is user-visible advice, so it gets the same treatment as
/// the authored code content: structural invariants enforced by test, and a
/// check that it stays wired to `NECTables.edition` rather than to a literal.
final class JurisdictionTests: XCTestCase {
    func testTableCoversEveryStatePlusDCAndTheFallback() {
        // 50 states + DC + Puerto Rico + the "Not listed" sentinel.
        XCTAssertEqual(Jurisdictions.all.count, 53)
        XCTAssertNotNil(Jurisdictions.named("Wyoming"))
        XCTAssertNotNil(Jurisdictions.named("District of Columbia"))
        XCTAssertTrue(Jurisdictions.all.contains(Jurisdictions.other))
    }

    func testIdsAndNamesAreUnique() {
        XCTAssertEqual(Set(Jurisdictions.all.map(\.id)).count, Jurisdictions.all.count)
        XCTAssertEqual(Set(Jurisdictions.all.map(\.name)).count, Jurisdictions.all.count)
    }

    func testEveryRecordNamesAnAuthorityToConfirmWith() {
        // The UI promises "confirm with <authority>" on every card, so an empty
        // authority would render a sentence with a hole in it.
        for record in Jurisdictions.all {
            XCTAssertFalse(record.authority.isEmpty, "\(record.id) has no authority")
            XCTAssertFalse(record.editionLabel.isEmpty, "\(record.id) has no edition label")
            XCTAssertFalse(record.providerLabel.isEmpty, "\(record.id) has no provider label")
        }
    }

    func testNoRecordClaimsAnEditionOlderThanCandidatesCanBeSitting() {
        for record in Jurisdictions.all {
            guard let edition = record.commonEdition else { continue }
            XCTAssertGreaterThanOrEqual(edition, .nec2011, "\(record.id)")
            XCTAssertLessThanOrEqual(edition, .nec2026, "\(record.id)")
        }
    }

    func testLookupIsCaseInsensitiveAndAcceptsPostalCodes() {
        XCTAssertEqual(Jurisdictions.named("texas")?.id, "TX")
        XCTAssertEqual(Jurisdictions.named("  Texas  ")?.id, "TX")
        XCTAssertEqual(Jurisdictions.named("tx")?.id, "TX")
        XCTAssertNil(Jurisdictions.named(""))
        XCTAssertNil(Jurisdictions.named("Atlantis"))
    }

    func testSearchMatchesNameAndCode() {
        XCTAssertEqual(Jurisdictions.matching("").count, Jurisdictions.all.count)
        XCTAssertTrue(Jurisdictions.matching("caro").map(\.id).contains("NC"))
        XCTAssertEqual(Jurisdictions.matching("wy").map(\.id), ["WY"])
        XCTAssertTrue(Jurisdictions.matching("zzz").isEmpty)
    }

    /// `NECEdition.app` is derived from `NECTables.edition`. If the tables move
    /// to a new cycle and this drifts, every "matches this app" claim lies.
    func testAppEditionTracksTheTables() {
        XCTAssertTrue(NECTables.edition.hasPrefix(String(NECEdition.app.year)))
    }

    func testDriftCopyDistinguishesOlderNewerAndExact() {
        XCTAssertTrue(NECEdition.app.driftFromApp.contains("every table"))
        let older = NECEdition.allCases.first { $0 < NECEdition.app }!
        XCTAssertTrue(older.driftFromApp.contains("Older"))
        if let newer = NECEdition.allCases.first(where: { $0 > NECEdition.app }) {
            XCTAssertTrue(newer.driftFromApp.contains("Newer"))
        }
    }

    /// The three original `electrician.skillLevel` values are persisted on
    /// device and switched on by Home and the primer. Adding levels must not
    /// renumber them.
    func testOriginalExperienceLevelIDsAreUnchanged() {
        XCTAssertEqual(ExperienceLevel.new.rawValue, "new")
        XCTAssertEqual(ExperienceLevel.apprentice.rawValue, "apprentice")
        XCTAssertEqual(ExperienceLevel.working.rawValue, "working")
    }

    func testEveryExperienceLevelResolvesToARealRoom() {
        for level in ExperienceLevel.allCases {
            let room = HowToPlayContent.recommendedRoom(forSkillLevel: level.rawValue)
            XCTAssertTrue(DrillLibrary.rooms.contains { $0.id == room.id }, level.rawValue)
        }
    }

    func testFocusAreasOutrankTheExperienceDefault() {
        let room = HowToPlayContent.recommendedRoom(
            forSkillLevel: ExperienceLevel.new.rawValue,
            focusAreas: ["grounding-room"]
        )
        XCTAssertEqual(room.id, "grounding-room")
    }

    /// The two raw values that were already on device before the picker grew.
    func testPersistedEditionRawValuesAreUnchanged() {
        XCTAssertEqual(CandidateEdition.nec2023.rawValue, "nec2023")
        XCTAssertEqual(CandidateEdition.different.rawValue, "different")
        XCTAssertEqual(LicenseTrack.journeyman.rawValue, "journeyman")
        XCTAssertEqual(LicenseTrack.master.rawValue, "master")
    }
}
