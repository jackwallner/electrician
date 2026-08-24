import XCTest
@testable import Electrician

/// The safety net for every drill in the library.
///
/// This matters more here than it did in the card apps it was ported from. A
/// wrong tile in a teaching hand is embarrassing. A wrong ampacity is a refund,
/// a one-star review from a professional, and a candidate who walks into a
/// licensing exam with a number we taught them. So these tests check the
/// arithmetic, not just the shape.
final class ContentValidityTests: XCTestCase {

    private var allDrills: [Drill] {
        DrillLibrary.rooms.flatMap(\.drills)
    }

    private var allQuiz: [QuizQuestion] {
        allDrills.flatMap { drill -> [QuizQuestion] in
            if case .quiz(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allArticleMatch: [ArticleMatchQuestion] {
        allDrills.flatMap { drill -> [ArticleMatchQuestion] in
            if case .articleMatch(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allCalc: [CalcScenario] {
        allDrills.flatMap { drill -> [CalcScenario] in
            if case .calc(let scenarios) = drill.kind { return scenarios }
            return []
        }
    }

    private var allFlashcards: [Flashcard] {
        allDrills.flatMap { drill -> [Flashcard] in
            if case .flashcards(let cards) = drill.kind { return cards }
            return []
        }
    }

    // MARK: - Structure

    func testEveryItemIDIsUnique() {
        var ids: [String] = []
        ids += allQuiz.map(\.id)
        ids += allArticleMatch.map(\.id)
        ids += allCalc.map(\.id)
        ids += allFlashcards.map(\.id)
        ids += HowToPlayContent.pages.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate item ids: \(duplicates(in: ids))")
    }

    func testEveryRoomIDIsUniqueAndDrillsResolveBackToTheirRoom() {
        let roomIDs = DrillLibrary.rooms.map(\.id)
        XCTAssertEqual(Set(roomIDs).count, roomIDs.count)
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                XCTAssertEqual(
                    DrillLibrary.roomID(forDrillID: drill.id), room.id,
                    "\(drill.id) does not resolve back to \(room.id)"
                )
            }
        }
    }

    func testEveryGeneratedSkillPointsAtARealRoom() {
        let roomIDs = Set(DrillLibrary.rooms.map(\.id))
        for skill in PracticeSkill.allCases {
            XCTAssertTrue(
                roomIDs.contains(skill.roomID),
                "\(skill.rawValue) reports room \(skill.roomID), which does not exist"
            )
        }
    }

    func testAnswerIndicesAreInRange() {
        for question in allQuiz {
            XCTAssertTrue(question.choices.indices.contains(question.answerIndex), question.id)
            XCTAssertGreaterThanOrEqual(question.choices.count, 2, question.id)
        }
        for scenario in allCalc {
            XCTAssertTrue(scenario.choices.indices.contains(scenario.answerIndex), scenario.id)
            XCTAssertGreaterThanOrEqual(scenario.choices.count, 2, scenario.id)
        }
        for question in allArticleMatch {
            XCTAssertTrue(question.choices.contains(question.answer), question.id)
        }
    }

    func testNoDuplicateChoicesWithinAnItem() {
        for question in allQuiz {
            XCTAssertEqual(Set(question.choices).count, question.choices.count,
                           "\(question.id) repeats a choice, which makes a right answer look wrong")
        }
        for scenario in allCalc {
            XCTAssertEqual(Set(scenario.choices).count, scenario.choices.count, scenario.id)
        }
        for question in allArticleMatch {
            XCTAssertEqual(Set(question.choices).count, question.choices.count, question.id)
        }
    }

    // MARK: - Copy rules

    /// Global house style. Also a legal tell: em dashes are how copied text
    /// usually arrives.
    func testNoEmDashesInPlayerFacingCopy() {
        for text in allPlayerFacingCopy() {
            XCTAssertFalse(text.contains("—"), "Em dash in: \(text.prefix(70))")
        }
    }

    /// Nothing may survive from the app this shell was ported from.
    ///
    /// Matched on word boundaries, not substrings: "rack" as a substring hits
    /// "bracket" and "tile" hits nothing useful, and a check that cries wolf
    /// gets deleted the first time it blocks a real change.
    func testNoStaleTermsFromTheSourceApp() {
        let banned = ["mahj", "mahjong", "tile", "tiles", "rack", "racks",
                      "charleston", "joker", "jokers", "bam", "crak", "nmjl",
                      "flower", "pung", "kong"]
        for text in allPlayerFacingCopy() {
            let words = text.lowercased().split(whereSeparator: { !$0.isLetter })
            for word in words where banned.contains(String(word)) {
                XCTFail("Stale term \"\(word)\" in: \(text.prefix(70))")
            }
        }
    }

    /// Every teaching item points somewhere the reader can verify it. This is
    /// the habit the exam rewards, and it is also the legal posture: we cite
    /// the code, we never reproduce it.
    func testEveryQuizAndCalcCitesAnArticle() {
        for question in allQuiz {
            XCTAssertNotNil(question.citation, "\(question.id) has no citation")
            XCTAssertFalse(question.citation?.isEmpty ?? true, question.id)
        }
        for scenario in allCalc {
            XCTAssertFalse(scenario.citation.isEmpty, scenario.id)
        }
    }

    // MARK: - The numbers

    /// Every authored calculation is recomputed from the same tables the
    /// generator uses. An authored answer can never drift from a generated one.
    func testAuthoredAmpacityExampleRecomputes() throws {
        let scenario = try XCTUnwrap(allCalc.first { $0.id == "calc-ampacity-1" })
        let base = try XCTUnwrap(NECTables.ampacity(size: "6 AWG", material: .copper, column: .c90))
        let correction = try XCTUnwrap(NECTables.ambientCorrection(celsius: 45, column: .c90))
        let adjustment = NECTables.adjustmentFactor(currentCarrying: 6)
        let terminal = try XCTUnwrap(NECTables.ampacity(size: "6 AWG", material: .copper, column: .c75))

        let derated = Double(base) * correction * adjustment
        let answer = min(derated, Double(terminal))

        XCTAssertEqual(answer, 52.2, accuracy: 0.05)
        XCTAssertEqual(scenario.choices[scenario.answerIndex], "52.2 A")
    }

    func testAuthoredOCPDExampleRecomputes() throws {
        let scenario = try XCTUnwrap(allCalc.first { $0.id == "calc-ocpd-1" })
        let table = try XCTUnwrap(NECTables.ampacity(size: "12 AWG", material: .copper, column: .c75))
        let ceiling = try XCTUnwrap(NECTables.smallConductorCeiling(size: "12 AWG", material: .copper))
        XCTAssertEqual(table, 25, "table value")
        XCTAssertEqual(ceiling, 20, "240.4(D) cap")

        let answer = try XCTUnwrap(NECTables.nextStandardOCPD(atMost: Double(min(table, ceiling))))
        XCTAssertEqual(answer, 20)
        XCTAssertEqual(scenario.choices[scenario.answerIndex], "20 A")
    }

    func testAuthoredConduitFillExampleRecomputes() throws {
        let scenario = try XCTUnwrap(allCalc.first { $0.id == "calc-conduitfill-1" })
        let area = try XCTUnwrap(NECTables.thhnArea["10 AWG"])
        let bundle = area * 9
        let percent = NECTables.fillPercent(conductorCount: 9)
        XCTAssertEqual(percent, 0.40)

        let smallest = try XCTUnwrap(NECTables.emtTradeSizes.first { trade in
            (NECTables.emtArea[trade] ?? 0) * percent >= bundle
        })
        XCTAssertEqual(smallest, "3/4\"")
        XCTAssertEqual(scenario.choices[scenario.answerIndex], "3/4\"")
    }

    func testAuthoredBoxFillExampleRecomputes() throws {
        let scenario = try XCTUnwrap(allCalc.first { $0.id == "calc-boxfill-1" })
        let volume = try XCTUnwrap(NECTables.conductorVolume["12 AWG"])
        // 6 conductors + 1 for all grounds + 1 for clamps + 2 for the yoke.
        let allowances = 6 + 1 + 1 + 2
        XCTAssertEqual(Double(allowances) * volume, 22.5, accuracy: 0.001)
        XCTAssertEqual(scenario.choices[scenario.answerIndex], "22.5 in³")
    }

    func testAuthoredVoltageDropExampleRecomputes() throws {
        let scenario = try XCTUnwrap(allCalc.first { $0.id == "calc-vdrop-1" })
        let cm = try XCTUnwrap(NECTables.circularMils["10 AWG"])
        let drop = Phase.single.voltageDropFactor * ConductorMaterial.copper.voltageDropK * 16 * 100 / cm
        XCTAssertEqual(drop, 3.977, accuracy: 0.01)
        XCTAssertEqual(scenario.choices[scenario.answerIndex], "4.0 V")
    }

    /// Ampacity has to increase with conductor size and with temperature
    /// column, in both materials. A transcription slip in the table breaks this
    /// before it breaks any single question.
    func testAmpacityTablesAreMonotonic() {
        for material in ConductorMaterial.allCases {
            for column in TemperatureRating.allCases {
                let values = NECTables.conductorSizes.compactMap {
                    NECTables.ampacity(size: $0, material: material, column: column)
                }
                XCTAssertEqual(values, values.sorted(),
                               "\(material) \(column.displayName) is not monotonic in size")
            }
            for size in NECTables.conductorSizes {
                let sixty = NECTables.ampacity(size: size, material: material, column: .c60)
                let seventyFive = NECTables.ampacity(size: size, material: material, column: .c75)
                let ninety = NECTables.ampacity(size: size, material: material, column: .c90)
                guard let sixty, let seventyFive, let ninety else { continue }
                XCTAssertLessThan(sixty, seventyFive, "\(material) \(size)")
                XCTAssertLessThan(seventyFive, ninety, "\(material) \(size)")
            }
        }
    }

    /// Copper always beats aluminum of the same size. If it ever does not, a
    /// row was pasted into the wrong table.
    func testCopperOutperformsAluminum() {
        for size in NECTables.conductorSizes {
            guard let copper = NECTables.ampacity(size: size, material: .copper, column: .c75),
                  let aluminum = NECTables.ampacity(size: size, material: .aluminum, column: .c75)
            else { continue }
            XCTAssertGreaterThan(copper, aluminum, size)
        }
    }

    func testCorrectionAndAdjustmentFactorsNeverExceedOne() {
        for celsius in 26...60 {
            for column in TemperatureRating.allCases {
                guard let factor = NECTables.ambientCorrection(celsius: celsius, column: column) else { continue }
                XCTAssertGreaterThan(factor, 0, "\(celsius)°C \(column.displayName)")
                XCTAssertLessThanOrEqual(factor, 1.0, "\(celsius)°C \(column.displayName)")
            }
        }
        for count in 1...60 {
            let factor = NECTables.adjustmentFactor(currentCarrying: count)
            XCTAssertGreaterThan(factor, 0, "\(count) conductors")
            XCTAssertLessThanOrEqual(factor, 1.0, "\(count) conductors")
        }
        XCTAssertEqual(NECTables.adjustmentFactor(currentCarrying: 3), 1.0)
        XCTAssertEqual(NECTables.adjustmentFactor(currentCarrying: 4), 0.80)
    }

    func testStandardOCPDListIsSortedAndRoundsBothWays() {
        XCTAssertEqual(NECTables.standardOCPD, NECTables.standardOCPD.sorted())
        XCTAssertEqual(NECTables.nextStandardOCPD(atLeast: 88), 90)
        XCTAssertEqual(NECTables.nextStandardOCPD(atMost: 88), 80)
        // An exact hit must not jump a size in either direction.
        XCTAssertEqual(NECTables.nextStandardOCPD(atLeast: 100), 100)
        XCTAssertEqual(NECTables.nextStandardOCPD(atMost: 100), 100)
    }

    // MARK: - The generator

    /// The generated stream is the paid tier. Every problem it emits has to be
    /// answerable and internally consistent, forever, without a human reading
    /// them. This is that check.
    func testGeneratorProducesValidProblems() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 42)
        let makers: [(String, (inout RandomNumberGenerator) -> CalcScenario)] = [
            ("ampacity", CalcGenerator.ampacityProblem),
            ("ocpd", CalcGenerator.ocpdProblem),
            ("conduit fill", CalcGenerator.conduitFillProblem),
            ("box fill", CalcGenerator.boxFillProblem),
            ("voltage drop", CalcGenerator.voltageDropProblem),
        ]

        for (name, make) in makers {
            for iteration in 0..<400 {
                let scenario = make(&rng)
                let context = "\(name) #\(iteration)"

                XCTAssertTrue(scenario.choices.indices.contains(scenario.answerIndex), context)
                XCTAssertGreaterThanOrEqual(scenario.choices.count, 2,
                                            "\(context) collapsed to one choice")
                XCTAssertEqual(Set(scenario.choices).count, scenario.choices.count,
                               "\(context) shows the same value twice")
                XCTAssertFalse(scenario.steps.isEmpty, context)
                XCTAssertFalse(scenario.citation.isEmpty, context)
                XCTAssertFalse(scenario.givens.isEmpty, context)
                for step in scenario.steps {
                    XCTAssertFalse(step.contains("—"), "Em dash in \(context)")
                }
                // No answer may be a placeholder or a zero: those are what a
                // missing table row looks like from the outside.
                let answer = scenario.choices[scenario.answerIndex]
                XCTAssertFalse(answer.hasPrefix("0 "), "\(context) answered zero")
                XCTAssertFalse(answer.contains("nan"), context)
            }
        }
    }

    /// The generator must never emit a derated ampacity above the termination
    /// limit. That is the exact mistake the drill exists to teach, so shipping
    /// it would be worse than shipping nothing.
    func testGeneratedAmpacityNeverExceedsTerminationLimit() throws {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 7)
        for _ in 0..<300 {
            let scenario = CalcGenerator.ampacityProblem(using: &rng)
            let sizeGiven = try XCTUnwrap(scenario.givens.first { $0.label == "Conductor" })
            let size = String(sizeGiven.value.split(separator: " ").prefix(2).joined(separator: " "))
            let materialGiven = try XCTUnwrap(scenario.givens.first { $0.label == "Material" })
            let material: ConductorMaterial = materialGiven.value == "Copper" ? .copper : .aluminum
            let terminal = try XCTUnwrap(NECTables.ampacity(size: size, material: material, column: .c75))

            let answer = scenario.choices[scenario.answerIndex]
            let value = Double(answer.replacingOccurrences(of: " A", with: "")) ?? .infinity
            XCTAssertLessThanOrEqual(value, Double(terminal) + 0.5,
                                     "\(size) \(material) answered \(answer) over a \(terminal) A termination")
        }
    }

    /// The generator must never contradict 240.4(D).
    func testGeneratedOCPDRespectsSmallConductorCap() throws {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 99)
        for _ in 0..<300 {
            let scenario = CalcGenerator.ocpdProblem(using: &rng)
            let sizeGiven = try XCTUnwrap(scenario.givens.first { $0.label == "Conductor" })
            let size = String(sizeGiven.value.split(separator: " ").prefix(2).joined(separator: " "))
            let materialGiven = try XCTUnwrap(scenario.givens.first { $0.label == "Material" })
            let material: ConductorMaterial = materialGiven.value == "Copper" ? .copper : .aluminum

            guard let cap = NECTables.smallConductorCeiling(size: size, material: material) else { continue }
            let answer = scenario.choices[scenario.answerIndex]
            let value = Int(answer.replacingOccurrences(of: " A", with: "")) ?? .max
            XCTAssertLessThanOrEqual(value, cap, "\(size) \(material) answered \(answer) over a \(cap) A cap")
        }
    }

    /// Conduit fill must actually fit, and the size below it must not.
    func testGeneratedConduitFillIsTheSmallestThatWorks() throws {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 1234)
        for _ in 0..<300 {
            let scenario = CalcGenerator.conduitFillProblem(using: &rng)
            let sizeGiven = try XCTUnwrap(scenario.givens.first { $0.label == "Conductor" })
            let size = String(sizeGiven.value.split(separator: " ").prefix(2).joined(separator: " "))
            let countGiven = try XCTUnwrap(scenario.givens.first { $0.label == "Quantity" })
            let count = try XCTUnwrap(Int(countGiven.value))

            let bundle = try XCTUnwrap(NECTables.thhnArea[size]) * Double(count)
            let percent = NECTables.fillPercent(conductorCount: count)
            let answer = scenario.choices[scenario.answerIndex]
            let allowance = try XCTUnwrap(NECTables.emtArea[answer]) * percent
            XCTAssertGreaterThanOrEqual(allowance, bundle, "\(count) × \(size) does not fit \(answer)")

            if let index = NECTables.emtTradeSizes.firstIndex(of: answer), index > 0 {
                let smaller = NECTables.emtTradeSizes[index - 1]
                let smallerAllowance = try XCTUnwrap(NECTables.emtArea[smaller]) * percent
                XCTAssertLessThan(smallerAllowance, bundle,
                                  "\(count) × \(size) would have fit \(smaller); \(answer) is oversized")
            }
        }
    }

    // MARK: - Free / paid split

    func testFreeRoomsExistAndPaidContentIsActuallyLocked() {
        XCTAssertTrue(DrillLibrary.rooms.contains { $0.isFree },
                      "Every room is paid; a new reader would see a wall")
        XCTAssertTrue(DrillLibrary.rooms.contains { !$0.isFree || $0.plusDrillCount > 0 },
                      "Nothing is locked; there is nothing to sell")
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                XCTAssertFalse(room.isLocked(drill, isMember: true),
                               "\(drill.id) stays locked for a member")
            }
        }
    }

    func testEverySessionPoolItemIsAnswerable() {
        for includePro in [false, true] {
            for item in SessionBuilder.choicePool(includePro: includePro) {
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex), item.id)
                XCTAssertGreaterThanOrEqual(item.choices.count, 2, item.id)
                XCTAssertFalse(item.prompt.isEmpty, item.id)
            }
        }
    }

    // MARK: - Helpers

    private func allPlayerFacingCopy() -> [String] {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy += [room.name, room.tagline]
            copy += room.drills.flatMap { [$0.title, $0.subtitle] }
        }
        copy += allQuiz.flatMap { [$0.prompt, $0.explanation] + $0.choices }
        copy += allArticleMatch.flatMap { [$0.scenario, $0.explanation] }
        copy += allCalc.flatMap { [$0.situation, $0.citation] + $0.choices + $0.steps }
        copy += allFlashcards.flatMap { card -> [String] in
            [card.frontTitle, card.backTitle, card.backBody]
                + [card.frontSubtitle, card.citation].compactMap { $0 }
                + (card.choice?.options ?? [])
        }
        copy += HowToPlayContent.pages.flatMap { page in
            [page.title, page.body] + [page.tip].compactMap { $0 }
        }
        copy += CodeArticle.allCases.flatMap { [$0.displayName, $0.shortName, $0.howToSpot, $0.citation] }
        copy += PracticeSkill.allCases.flatMap { [$0.title, $0.subtitle] }
        return copy
    }

    private func duplicates(in ids: [String]) -> [String] {
        Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.map(\.key).sorted()
    }
}
