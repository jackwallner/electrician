import XCTest
@testable import Electrician

/// Code Minute is one shared five-question set per calendar date. The whole
/// feature rests on it being *identical* on every device without a server, so
/// determinism is the thing worth testing.
final class CodeMinuteTests: XCTestCase {

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = dayOfMonth
        components.hour = 9
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    func testChallengeIsFiveQuestions() {
        let challenge = CodeMinuteContent.challenge(for: day(2026, 8, 24))
        XCTAssertEqual(challenge.questions.count, CodeMinuteContent.questionCount)
        XCTAssertEqual(challenge.items.count, CodeMinuteContent.questionCount)
    }

    /// The property the share text depends on: same date, same five questions,
    /// same order, same answer positions.
    func testSameDayProducesAnIdenticalChallenge() {
        let first = CodeMinuteContent.challenge(for: day(2026, 8, 24))
        let second = CodeMinuteContent.challenge(for: day(2026, 8, 24))

        XCTAssertEqual(first.dayKey, second.dayKey)
        XCTAssertEqual(first.items.map(\.id), second.items.map(\.id))
        XCTAssertEqual(first.items.map(\.prompt), second.items.map(\.prompt))
        XCTAssertEqual(first.items.map(\.choices), second.items.map(\.choices))
        XCTAssertEqual(first.items.map(\.answerIndex), second.items.map(\.answerIndex))
    }

    /// Time of day must not matter, only the calendar date.
    func testTimeOfDayDoesNotChangeTheChallenge() {
        let calendar = Calendar(identifier: .gregorian)
        var morning = DateComponents()
        morning.year = 2026; morning.month = 8; morning.day = 24; morning.hour = 6
        var evening = morning
        evening.hour = 22

        let first = CodeMinuteContent.challenge(for: calendar.date(from: morning)!, calendar: calendar)
        let second = CodeMinuteContent.challenge(for: calendar.date(from: evening)!, calendar: calendar)
        XCTAssertEqual(first.items.map(\.prompt), second.items.map(\.prompt))
    }

    func testDifferentDaysProduceDifferentChallenges() {
        let first = CodeMinuteContent.challenge(for: day(2026, 8, 24))
        let second = CodeMinuteContent.challenge(for: day(2026, 8, 25))
        XCTAssertNotEqual(first.dayKey, second.dayKey)
        XCTAssertNotEqual(first.items.map(\.prompt), second.items.map(\.prompt))
    }

    func testEveryQuestionIsAnswerable() {
        for offset in 0..<60 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: day(2026, 8, 24))!
            let challenge = CodeMinuteContent.challenge(for: date)
            XCTAssertEqual(challenge.questions.count, CodeMinuteContent.questionCount,
                           "short set on \(challenge.dayKey)")
            for item in challenge.items {
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex), item.id)
                XCTAssertGreaterThanOrEqual(item.choices.count, 2, item.id)
                XCTAssertFalse(item.prompt.isEmpty, item.id)
            }
        }
    }

    /// No repeats inside one day's set. Seeing the same question twice in five
    /// reads as a bug even when both are correct.
    func testNoRepeatedQuestionsWithinADay() {
        for offset in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: day(2026, 8, 24))!
            let challenge = CodeMinuteContent.challenge(for: date)
            let prompts = challenge.items.map(\.prompt)
            XCTAssertEqual(Set(prompts).count, prompts.count, "repeat on \(challenge.dayKey)")
        }
    }

    /// Generated daily items roll into one bounded stats row rather than
    /// creating an unbounded pile of one-off records.
    func testGeneratedDailyItemsShareOneTrackingRow() {
        let challenge = CodeMinuteContent.challenge(for: day(2026, 8, 24))
        let generated = challenge.items.filter { $0.id.contains("-gen-") }
        XCTAssertFalse(generated.isEmpty)
        for item in generated {
            XCTAssertEqual(item.trackingID, "code-minute-rollup", item.id)
            XCTAssertFalse(item.isReviewable, "\(item.id) would be scheduled back into review")
        }
    }

    func testCategoriesAreCoveredAcrossASet() {
        let challenge = CodeMinuteContent.challenge(for: day(2026, 8, 24))
        let categories = Set(challenge.questions.map(\.category))
        XCTAssertGreaterThanOrEqual(categories.count, 2,
                                    "a five-question set that is all one category reads as broken")
    }

    func testDayKeyFormatIsStable() {
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertEqual(CodeMinuteContent.key(for: day(2026, 8, 24), calendar: calendar), "2026-08-24")
        XCTAssertEqual(CodeMinuteContent.key(for: day(2026, 12, 1), calendar: calendar), "2026-12-01")
    }

    /// The seeded generator itself: same seed, same stream; different seed,
    /// different stream.
    func testSeededGeneratorIsDeterministic() {
        var first = SeededGenerator(seed: 12345)
        var second = SeededGenerator(seed: 12345)
        var third = SeededGenerator(seed: 54321)

        let a = (0..<20).map { _ in first.next() }
        let b = (0..<20).map { _ in second.next() }
        let c = (0..<20).map { _ in third.next() }

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    /// The day boundary is FIXED, not local.
    ///
    /// "The same five questions for every member" is the whole feature, and
    /// `Calendar.current` broke it: two readers either side of local midnight
    /// got different sets while their share cards claimed the same date.
    func testDayBoundaryIsFixedRatherThanLocal() {
        XCTAssertEqual(CodeMinuteContent.dayCalendar.timeZone.identifier, "America/Los_Angeles")

        // 05:00 UTC on the 25th is 22:00 the previous evening in Pacific time,
        // so a reader in London opening the app before breakfast gets the same
        // challenge as a reader in California still up the night before.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let earlyUTC = utc.date(from: DateComponents(year: 2026, month: 8, day: 25, hour: 5))!
        XCTAssertEqual(CodeMinuteContent.key(for: earlyUTC), "2026-08-24")

        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let tokyoEvening = tokyo.date(from: DateComponents(year: 2026, month: 8, day: 25, hour: 17))!
        let losAngeles = CodeMinuteContent.key(for: tokyoEvening)
        XCTAssertEqual(losAngeles, CodeMinuteContent.key(for: tokyoEvening, calendar: CodeMinuteContent.dayCalendar))
    }

    /// The daily calculations keep their numbered working, the same as every
    /// other generated question.
    func testDailyGeneratedItemsCarryTheirWorking() {
        let challenge = CodeMinuteContent.challenge(for: day(2026, 8, 24))
        let generated = challenge.items.filter { $0.id.contains("-gen-") }
        XCTAssertFalse(generated.isEmpty)
        for item in generated {
            XCTAssertGreaterThan(item.steps.count, 1, item.id)
            XCTAssertNotNil(item.citation, item.id)
        }
    }
}
