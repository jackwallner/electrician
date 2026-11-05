import XCTest
@testable import Electrician

/// The string catalog compiles into the app and the plural rules survive the
/// trip. English is the only language for now, so these pin the English plural
/// forms and the stored-value rules that later translations depend on.
final class LocalizationTests: XCTestCase {
    private func bundle(_ language: String) -> Bundle? {
        for host in [Bundle.main] + Bundle.allBundles {
            if let path = host.path(forResource: language, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return nil
    }

    func testEnglishShips() {
        XCTAssertNotNil(bundle("en"), "en.lproj is missing, so the catalog did not compile")
    }

    func testEnglishPluralsPickSingularAndPlural() throws {
        let en = try XCTUnwrap(bundle("en"))
        let locale = Locale(identifier: "en")
        XCTAssertEqual(String(localized: "\(1) days", bundle: en, locale: locale), "1 day")
        XCTAssertEqual(String(localized: "\(5) days", bundle: en, locale: locale), "5 days")
        XCTAssertEqual(String(localized: "\(1) days out", bundle: en, locale: locale), "1 day out")
        XCTAssertEqual(String(localized: "\(12) days out", bundle: en, locale: locale), "12 days out")
        XCTAssertEqual(String(localized: "\(1) drills finished", bundle: en, locale: locale), "1 drill finished")
        XCTAssertEqual(String(localized: "\(3) drills finished", bundle: en, locale: locale), "3 drills finished")
    }

    func testSubstitutionPluralsKeepTheirOtherArguments() throws {
        let en = try XCTUnwrap(bundle("en"))
        let locale = Locale(identifier: "en")
        XCTAssertEqual(
            String(localized: "\(1) due mistakes first, then extra work in \("Grounding & Motors").", bundle: en, locale: locale),
            "1 due mistake first, then extra work in Grounding & Motors."
        )
        XCTAssertEqual(
            String(localized: "\(4) due mistakes first, then extra work in \("Grounding & Motors").", bundle: en, locale: locale),
            "4 due mistakes first, then extra work in Grounding & Motors."
        )
    }

    func testDayAndQuestionSentencesPluralizeEachCount() throws {
        let en = try XCTUnwrap(bundle("en"))
        let locale = Locale(identifier: "en")
        let free = 150
        XCTAssertEqual(
            String(localized: "The free rooms hold \(free) questions. At \(15) a day you finish them in about \(1) days, with \(1) days still to go.", bundle: en, locale: locale),
            "The free rooms hold 150 questions. At 15 a day you finish them in about 1 day, with 1 day still to go."
        )
        XCTAssertEqual(
            String(localized: "The free rooms hold \(free) questions, about \(10) days at \(15) a day. That barely covers your \(1) days, once, with nothing left to repeat.", bundle: en, locale: locale),
            "The free rooms hold 150 questions, about 10 days at 15 a day. That barely covers your 1 day, once, with nothing left to repeat."
        )
        XCTAssertEqual(
            String(localized: "The free rooms hold \(free) questions. At \(15) a day that is about \(10) days of practice, and then you are re-reading answers you remember.", bundle: en, locale: locale),
            "The free rooms hold 150 questions. At 15 a day that is about 10 days of practice, and then you are re-reading answers you remember."
        )
        XCTAssertEqual(
            String(localized: "The free rooms hold \(free) questions. At \(15) a day that is about \(1) days, and after that you are re-reading answers you already remember. The generator is what makes the reps keep counting.", bundle: en, locale: locale),
            "The free rooms hold 150 questions. At 15 a day that is about 1 day, and after that you are re-reading answers you already remember. The generator is what makes the reps keep counting."
        )
    }

    func testGoalSuggestionKeepsGroupedNumberAndPluralizesBothCounts() throws {
        let en = try XCTUnwrap(bundle("en"))
        let locale = Locale(identifier: "en")
        for (daily, planned, expected) in [
            (1, 1, "1 question a day you will have worked roughly 1 problem"),
            (27, 621, "27 questions a day you will have worked roughly 621 problems"),
            (15, 5475, "15 questions a day you will have worked roughly 5,475 problems"),
        ] {
            let text = String(localized: "\("23 days out"). At \(daily) questions a day you will have worked roughly \(planned) problems before you sit it. \(planned.groupedText)", bundle: en, locale: locale)
            XCTAssertEqual(text, "23 days out. At \(expected) before you sit it.")
        }
    }

    func testAuthoredBoxFillChipsUseCountAwareLabels() {
        // English cannot tell a fixed key from the count-aware one, so
        // Tools/Localization/check.py also rejects a fixed unit key in source.
        let box = CalcContent.workedExamples.first { $0.id == "calc-boxfill-1" }?.givens ?? []
        XCTAssertEqual(box.first { $0.label == "Grounds" }?.unit, PluralLabel.wires(3))
        XCTAssertEqual(box.first { $0.label == "Insulated" }?.unit, PluralLabel.conductors(6))
        XCTAssertEqual(box.first { $0.label == "Devices" }?.unit, PluralLabel.yokes(1))
        XCTAssertEqual(box.first { $0.label == "Internal clamps" }?.value, "yes")
    }

    func testPluralCategoryFollowsTheLanguage() {
        XCTAssertEqual(PluralLabel.category(1), .one)
        XCTAssertEqual(PluralLabel.category(0), .other)
        XCTAssertEqual(PluralLabel.category(5), .other)
        XCTAssertEqual(PluralLabel.conductors(1), "conductor")
        XCTAssertEqual(PluralLabel.conductors(6), "conductors")
        XCTAssertEqual(PluralLabel.yokes(1), "yoke")
        XCTAssertEqual(PluralLabel.yokes(2), "yokes")
        XCTAssertEqual(PluralLabel.days(1), "day")
        XCTAssertEqual(PluralLabel.days(30), "days")
        XCTAssertEqual(PluralLabel.daysOut(1), "Day out")
        XCTAssertEqual(PluralLabel.daysOut(30), "Days out")
    }

    func testJurisdictionStoredNameStaysEnglishWhileDisplayNameIsLocalized() {
        for record in Jurisdictions.all {
            XCTAssertFalse(record.displayName.isEmpty, record.id)
            XCTAssertEqual(Jurisdictions.named(record.name)?.id, record.id, record.id)
        }
        // In English the two agree, so a saved name keeps matching and reading the same.
        XCTAssertEqual(Jurisdictions.named("Wyoming")?.displayName, "Wyoming")
        XCTAssertEqual(Jurisdictions.other.displayName, Jurisdictions.other.name)
    }

    func testWeekdayNamesComeFromTheCalendar() {
        let names = AppSettings.ExamWarmUpDay.allCases.map(\.displayName)
        XCTAssertEqual(names.count, 7)
        XCTAssertEqual(Set(names).count, 7)
        XCTAssertEqual(AppSettings.ExamWarmUpDay.sunday.displayName, Calendar.current.weekdaySymbols[0])
    }

    func testSupportEmailLabelsStayEnglish() {
        for category in ContentReport.Category.allCases {
            XCTAssertFalse(category.englishName.isEmpty)
        }
    }
}
