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

    /// The generic card-game vocabulary the shell arrived with, which the
    /// domain-specific ban above sails straight past.
    ///
    /// "Deck cleared", "Perfect round" and "all the cards down" contain no
    /// mahjong word at all, so the original check passed them, and a journeyman
    /// candidate reading them can still tell what this app used to be. Trust in
    /// a code-reference product is the whole asset; sounding like a card game
    /// spends it for nothing.
    func testNoInheritedCardGameVocabulary() {
        // "deck" and "cards" stay legal in code and comments (the flashcard
        // deck IS a deck, and renaming the interaction would be worse than the
        // problem) but must not reach a reader.
        // "hand"/"hands" are deliberately absent: "the question hands you a
        // nameplate rating" is ordinary English, and a check that fires on it
        // gets deleted the first time it blocks a real change.
        let banned = ["deck", "decks", "lobby", "meld", "melds",
                      "shuffle", "dealt", "discard", "discards"]
        for text in allPlayerFacingCopy() {
            let words = text.lowercased().split(whereSeparator: { !$0.isLetter })
            for word in words where banned.contains(String(word)) {
                XCTFail("Inherited card-game term \"\(word)\" in: \(text.prefix(70))")
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
    /// Driven from `PracticeSkill` rather than a hand-written list of makers.
    ///
    /// The list version had to be edited by hand every time a shape was added,
    /// which means a new generator shipped untested by default. Going through
    /// `EndlessPractice.scenario` means adding a case to `PracticeSkill` opts
    /// the new shape into every invariant below automatically.
    func testGeneratorProducesValidProblems() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 42)
        let makers: [(String, (inout RandomNumberGenerator) -> CalcScenario)] =
            PracticeSkill.allCases.map { skill in
                (skill.rawValue, { EndlessPractice.scenario(for: skill, using: &$0) })
            }

        for (name, make) in makers {
            for iteration in 0..<400 {
                let scenario = make(&rng)
                let context = "\(name) #\(iteration)"

                XCTAssertTrue(scenario.choices.indices.contains(scenario.answerIndex), context)
                // Exactly four, not "at least two". A shape that degrades to
                // three changes the odds of a guess and looks unfinished, and
                // the old assertion would have shipped it silently.
                XCTAssertEqual(scenario.choices.count, 4,
                               "\(context) emitted \(scenario.choices.count) choices")
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

    // MARK: - Named mistakes

    /// Every generated distractor that a named mistake produces must be
    /// attached to that mistake.
    ///
    /// This is the invariant the whole "your misses come back" feature rests
    /// on: without it a wrong pick is just wrong, the tally learns nothing, and
    /// targeted practice has nothing to aim at.
    func testGeneratedProblemsNameTheirMistakes() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 2024)
        let makers: [(String, (inout RandomNumberGenerator) -> CalcScenario)] =
            PracticeSkill.allCases.map { skill in
                (skill.rawValue, { EndlessPractice.scenario(for: skill, using: &$0) })
            }
        var namedAtLeastOnce: Set<String> = []

        for (name, make) in makers {
            var problemsWithAMistake = 0
            for iteration in 0..<200 {
                let scenario = make(&rng)
                let context = "\(name) #\(iteration)"
                let answerLabel = scenario.choices[scenario.answerIndex]

                // The correct answer must never be labelled a mistake. This is
                // the one that would actively teach the wrong thing.
                XCTAssertNil(scenario.mistakes[answerLabel],
                             "\(context) calls its own answer a mistake")

                for (label, pattern) in scenario.mistakes {
                    XCTAssertTrue(scenario.choices.contains(label),
                                  "\(context) names a mistake for \(label), which is not a choice")
                    XCTAssertNotNil(CandidateMistake.pattern(id: pattern.id),
                                    "\(context) uses an unregistered pattern \(pattern.id)")
                    XCTAssertNotNil(PracticeSkill(rawValue: pattern.skill),
                                    "\(context) pattern \(pattern.id) points at unknown skill \(pattern.skill)")
                    XCTAssertFalse(pattern.summary.isEmpty, pattern.id)
                    XCTAssertFalse(pattern.summary.contains("—"), "Em dash in \(pattern.id)")
                    namedAtLeastOnce.insert(pattern.id)
                }
                if !scenario.mistakes.isEmpty { problemsWithAMistake += 1 }
            }
            // Collisions with the answer are legitimate and common, but a shape
            // that never names anything means the wiring is broken.
            XCTAssertGreaterThan(problemsWithAMistake, 100,
                                 "\(name) almost never names a mistake")
        }

        let unused = Set(CandidateMistake.all.map(\.id)).subtracting(namedAtLeastOnce)
        XCTAssertTrue(unused.isEmpty, "Mistake patterns no generator ever emits: \(unused.sorted())")
    }

    func testMistakePatternIDsAreUnique() {
        let ids = CandidateMistake.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate mistake pattern ids: \(duplicates(in: ids))")
    }

    /// Targeted practice has to actually target. A pattern in, a problem out
    /// that sets that same trap.
    func testTargetedPracticeSetsTheRequestedTrap() {
        for pattern in CandidateMistake.all {
            let items = EndlessPractice.targetedItems(for: [pattern], count: 4)
            XCTAssertEqual(items.count, 4, pattern.id)
            let hits = items.filter { $0.mistakes.values.contains(pattern) }.count
            // Not all four: a shape whose trap does not apply to the inputs it
            // rolled falls back to an untargeted problem of the same skill
            // rather than returning nothing. Most should still land.
            XCTAssertGreaterThan(hits, 0, "\(pattern.id) never produced a problem setting its own trap")
            for item in items {
                XCTAssertEqual(item.roomID, PracticeSkill(rawValue: pattern.skill)?.roomID, pattern.id)
                XCTAssertFalse(item.steps.isEmpty, "\(pattern.id) targeted item has no working")
            }
        }
    }

    func testTargetedPracticeIsEmptyWithoutPatterns() {
        XCTAssertTrue(EndlessPractice.targetedItems(for: [], count: 5).isEmpty)
        XCTAssertTrue(EndlessPractice.targetedItems(for: CandidateMistake.all, count: 0).isEmpty)
    }

    /// The generator documents five shapes and `PracticeSkill` declares five.
    /// The doc comment said four for a while; a test is cheaper than noticing.
    func testEveryPracticeSkillGeneratesAProblem() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 5)
        for skill in PracticeSkill.allCases {
            let scenario = EndlessPractice.scenario(for: skill, using: &rng)
            XCTAssertFalse(scenario.steps.isEmpty, skill.rawValue)
            XCTAssertEqual(scenario.choices.count, 4, skill.rawValue)
        }
    }

    /// Generated practice must keep its working as a LIST. Flattening it into a
    /// paragraph is what made the paid tier explain a miss worse than the free
    /// authored room did.
    func testGeneratedItemsKeepTheirNumberedWorking() {
        for skill in PracticeSkill.allCases {
            for item in EndlessPractice.items(for: skill, count: 5) {
                XCTAssertGreaterThan(item.steps.count, 1, "\(skill.rawValue) flattened its working")
                XCTAssertNotNil(item.citation, skill.rawValue)
                XCTAssertFalse(item.isReviewable, "\(skill.rawValue) generated item claims to be reviewable")
            }
        }
    }

    /// `prepared` shuffles choice ORDER; the mistake map is keyed by label and
    /// must survive that untouched. Keying it by index is the obvious bug.
    func testShufflingChoicesPreservesTheMistakeMapping() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 77)
        for _ in 0..<50 {
            let scenario = CalcGenerator.ampacityProblem(using: &rng)
            let item = EndlessPractice.item(from: scenario, skill: .ampacity)
            let shuffled = SessionBuilder.prepared(item)
            XCTAssertEqual(Set(shuffled.choices), Set(item.choices))
            XCTAssertEqual(shuffled.choices[shuffled.answerIndex], item.choices[item.answerIndex])
            for (label, pattern) in scenario.mistakes {
                guard let index = shuffled.choices.firstIndex(of: label) else {
                    XCTFail("lost choice \(label)")
                    continue
                }
                XCTAssertEqual(shuffled.mistake(forChoiceAt: index), pattern)
            }
            XCTAssertNil(shuffled.mistake(forChoiceAt: shuffled.answerIndex))
        }
    }

    // MARK: - Edition

    /// The edition is a promise made on every result screen and in the store
    /// description. It has to be a real, non-empty value naming a cycle.
    func testEditionIsStated() {
        XCTAssertFalse(NECTables.edition.isEmpty)
        XCTAssertTrue(NECTables.edition.contains("NEC"), NECTables.edition)
        XCTAssertFalse(NECTables.editionNote.contains("—"))
    }

    /// The coverage claim is a marketing sentence backed by two constants, so
    /// the constants have to be capable of backing it.
    ///
    /// `verifiedThrough` is what the app tells a reader has actually been
    /// checked against a book. It may never be older than the edition the app's
    /// own numbers are labelled with, because that would mean the app is
    /// quoting an edition it has not verified, and it may never be raised past
    /// the newest edition the app knows about.
    func testCoverageClaimIsSupportable() {
        XCTAssertGreaterThanOrEqual(NECTables.verifiedThrough, NECEdition.app,
                                    "the app cites an edition it has not verified")
        XCTAssertLessThanOrEqual(NECTables.stableSince, NECEdition.app)
        XCTAssertFalse(NECTables.coveredEditions.isEmpty)
        XCTAssertTrue(NECTables.coveredEditions.contains(NECEdition.app),
                      "the app's own edition is missing from its coverage")
        XCTAssertTrue(NECTables.coverageLabel.contains("NEC"), NECTables.coverageLabel)
        XCTAssertFalse(NECTables.coverageNote.contains("—"))
    }

    // MARK: - Rooms

    /// Every room claims an accent explicitly.
    ///
    /// `Room.accent` used to fall through to grounding green for any id it did
    /// not recognise, so a new room silently took the one colour in the palette
    /// that carries a meaning. There is no default now, and this is what makes
    /// forgetting one a build failure rather than a subtle wrong colour.
    func testEveryRoomClaimsAnAccent() {
        for room in DrillLibrary.rooms {
            XCTAssertNotNil(Room.accents[room.id],
                            "\(room.id) has no accent, so it would fall back to the default")
        }
        for id in Room.accents.keys {
            XCTAssertTrue(DrillLibrary.rooms.contains { $0.id == id },
                          "\(id) has an accent but is not a room any more")
        }
    }

    /// The membership pitch quotes both of these. A zero in either would put
    /// "The free rooms hold 0 questions" on the paywall.
    func testContentCountsAreQuotable() {
        XCTAssertGreaterThan(DrillLibrary.freeItemCount, 20)
        XCTAssertGreaterThan(DrillLibrary.membershipItemCount, 20)
        XCTAssertGreaterThan(DrillLibrary.membershipDrillCount, 0)
    }

    // MARK: - The tables added for grounding, motors and loads

    func testEquipmentGroundingConductorReadsTheBandAbove() {
        // Exact rows.
        XCTAssertEqual(NECTables.equipmentGroundingConductor(ocpd: 20, material: .copper), "12 AWG")
        XCTAssertEqual(NECTables.equipmentGroundingConductor(ocpd: 100, material: .copper), "8 AWG")
        XCTAssertEqual(NECTables.equipmentGroundingConductor(ocpd: 200, material: .aluminum), "4 AWG")
        // Between rows: the table is not-exceeding bands, so a 45 A device
        // reads the 60 A row. Rounding the other way is the named mistake.
        XCTAssertEqual(NECTables.equipmentGroundingRow(ocpd: 45), 60)
        XCTAssertEqual(NECTables.equipmentGroundingConductor(ocpd: 45, material: .copper), "10 AWG")
        XCTAssertEqual(NECTables.equipmentGroundingConductor(ocpd: 30, material: .copper), "10 AWG")
        XCTAssertEqual(NECTables.equipmentGroundingConductor(ocpd: 175, material: .copper), "6 AWG")
    }

    func testGroundingElectrodeConductorUsesTheRightServiceColumn() {
        // A 2/0 copper service reads the copper bands.
        XCTAssertEqual(
            NECTables.groundingElectrodeConductor(serviceSize: "2/0 AWG", serviceMaterial: .copper, gecMaterial: .copper),
            "4 AWG"
        )
        // The same size in aluminum is a smaller service and reads its own,
        // different band. If these two ever agree, the aluminum rows are wrong.
        XCTAssertEqual(
            NECTables.groundingElectrodeConductor(serviceSize: "2/0 AWG", serviceMaterial: .aluminum, gecMaterial: .copper),
            "6 AWG"
        )
        // Parallel sets are read on the equivalent area of the whole set.
        XCTAssertEqual(
            NECTables.groundingElectrodeConductor(serviceSize: "250 kcmil", serviceMaterial: .copper,
                                                  gecMaterial: .copper, parallelSets: 2),
            NECTables.groundingElectrodeConductor(serviceSize: "500 kcmil", serviceMaterial: .copper,
                                                  gecMaterial: .copper)
        )
    }

    func testElectrodeCeilingsCapTheTable() {
        // A 500 kcmil copper service calls for 1/0 from the table, and a rod
        // caps it at 6 AWG. Missing that cap is the whole point of the shape.
        let rod = NECTables.groundingElectrodeConductor(
            serviceSize: "500 kcmil", serviceMaterial: .copper, electrode: .rodPipePlate
        )
        XCTAssertEqual(rod?.fromTable, "1/0 AWG")
        XCTAssertEqual(rod?.required, "6 AWG")

        let ufer = NECTables.groundingElectrodeConductor(
            serviceSize: "500 kcmil", serviceMaterial: .copper, electrode: .concreteEncased
        )
        XCTAssertEqual(ufer?.required, "4 AWG")

        // A water pipe has no ceiling, so the table stands.
        let pipe = NECTables.groundingElectrodeConductor(
            serviceSize: "500 kcmil", serviceMaterial: .copper, electrode: .waterPipe
        )
        XCTAssertEqual(pipe?.required, "1/0 AWG")
    }

    func testMotorProtectionRoundsUpAndOverloadUsesTheNameplate() {
        // 10 hp at 460 V is 14 A. An inverse-time breaker at 250% is 35 A,
        // which IS a standard rating.
        let flc = NECTables.motorFLC(hp: "10 hp", supply: .three460)
        XCTAssertEqual(flc, 14)
        XCTAssertEqual(NECTables.motorBranchOCPD(flc: 14, protection: .inverseTimeBreaker), 35)
        // 15.2 A at 250% is 38 A, which is not. This is the one calculation in
        // the book that goes UP rather than down, so the answer is 40, not 35.
        XCTAssertEqual(NECTables.motorFLC(hp: "5 hp", supply: .three230), 15.2)
        XCTAssertEqual(NECTables.motorBranchOCPD(flc: 15.2, protection: .inverseTimeBreaker), 40)
        // Overload comes off the nameplate, and only off the nameplate.
        XCTAssertEqual(NECTables.motorOverloadTrip(nameplateFLA: 16, serviceFactor: 1.15, tempRiseC: nil), 20,
                       accuracy: 0.001)
        XCTAssertEqual(NECTables.motorOverloadTrip(nameplateFLA: 16, serviceFactor: 1.0, tempRiseC: nil), 18.4,
                       accuracy: 0.001)
    }

    func testMotorFullLoadCurrentFallsWithVoltage() {
        for rating in NECTables.motorRatings(for: .three460) {
            guard let at460 = NECTables.motorFLC(hp: rating.label, supply: .three460),
                  let at230 = NECTables.motorFLC(hp: rating.label, supply: .three230),
                  let at208 = NECTables.motorFLC(hp: rating.label, supply: .three208)
            else { continue }
            XCTAssertGreaterThan(at230, at460, "\(rating.label) 230 V should draw more than 460 V")
            XCTAssertGreaterThan(at208, at230, "\(rating.label) 208 V should draw more than 230 V")
        }
    }

    func testDwellingDemandBandsAreApplied() {
        // Below the first band nothing is discounted.
        XCTAssertEqual(NECTables.generalLightingDemand(totalVA: 2500), 2500, accuracy: 0.001)
        // 11,000 VA: 3000 whole, 8000 at 35%.
        XCTAssertEqual(NECTables.generalLightingDemand(totalVA: 11_000), 5800, accuracy: 0.001)
        // The band ends at 120,000 VA and the remainder drops to 25%.
        XCTAssertEqual(NECTables.generalLightingDemand(totalVA: 120_000),
                       3000 + 117_000 * 0.35, accuracy: 0.001)
        XCTAssertEqual(NECTables.generalLightingDemand(totalVA: 140_000),
                       3000 + 117_000 * 0.35 + 20_000 * 0.25, accuracy: 0.001)
    }

    func testRangeDemandUsesColumnCAndTheOver12Increase() {
        XCTAssertEqual(NECTables.rangeDemandKW(count: 1, eachKW: 8), 8)
        XCTAssertEqual(NECTables.rangeDemandKW(count: 1, eachKW: 12), 8)
        // 16 kW is four over, so 8 kW rises 20%.
        XCTAssertEqual(try XCTUnwrap(NECTables.rangeDemandKW(count: 1, eachKW: 16)), 9.6, accuracy: 0.001)
        XCTAssertEqual(NECTables.rangeDemandKW(count: 3, eachKW: 12), 14)
        XCTAssertEqual(try XCTUnwrap(NECTables.rangeDemandKW(count: 3, eachKW: 14)), 15.4, accuracy: 0.001)
    }

    func testApplianceDemandNeedsFour() {
        XCTAssertEqual(NECTables.fastenedApplianceDemand(totalVA: 8000, count: 3), 8000, accuracy: 0.001)
        XCTAssertEqual(NECTables.fastenedApplianceDemand(totalVA: 8000, count: 4), 6000, accuracy: 0.001)
    }

    func testDwellingServiceHasAFloor() {
        XCTAssertEqual(NECTables.dwellingServiceRating(amps: 42), 100)
        XCTAssertEqual(NECTables.dwellingServiceRating(amps: 145.1), 150)
    }

    /// The authored load examples recompute, the same way the other five
    /// authored calculations already do.
    func testAuthoredDwellingCalculationsRecompute() throws {
        let standard = try XCTUnwrap(allCalc.first { $0.id == "load-calc-standard-dwelling" })
        let result = try XCTUnwrap(FieldCalculators.dwellingLoad(
            squareFeet: 2000,
            smallApplianceCircuits: 2,
            laundryCircuits: 1,
            rangeKW: 12,
            rangeCount: 1,
            dryerNameplateVA: 5500,
            fastenedApplianceVA: [4500, 1200, 900, 1000],
            coolingVA: 5000,
            heatingVA: 10_000
        ))
        XCTAssertEqual(result.generalAfterDemand, 5625, accuracy: 0.001)
        XCTAssertEqual(result.applianceAfterDemand, 5700, accuracy: 0.001)
        XCTAssertEqual(result.totalVA, 34_825, accuracy: 0.5)
        XCTAssertEqual(result.serviceRating, 150)
        XCTAssertEqual(standard.choices[standard.answerIndex], "150 A")

        // The optional method genuinely disagrees, which is the fact the pair
        // of examples exists to demonstrate. If these ever agree, one of them
        // has been worked the other one's way.
        let optional = try XCTUnwrap(allCalc.first { $0.id == "load-calc-optional-dwelling" })
        let generalPile = 2000 * NECTables.dwellingLightingVAPerSqFt + 4500 + 12_000 + 5500 + 7600
        let optionalGeneral = NECTables.optionalMethodGeneralLoad(totalVA: generalPile)
        let hvac = NECTables.optionalMethodHVAC(coolingVA: 5000, heatingVA: 10_000, heatingUnits: 1)
        let optionalRating = try XCTUnwrap(NECTables.dwellingServiceRating(
            amps: NECTables.serviceAmps(va: optionalGeneral + hvac)
        ))
        XCTAssertEqual(optionalGeneral, 20_240, accuracy: 0.5)
        XCTAssertEqual(hvac, 6500, accuracy: 0.5)
        XCTAssertEqual(optionalRating, 125)
        XCTAssertEqual(optional.choices[optional.answerIndex], "125 A")
        XCTAssertNotEqual(optionalRating, result.serviceRating)

        let ranges = try XCTUnwrap(allCalc.first { $0.id == "load-calc-three-ranges" })
        XCTAssertEqual(ranges.choices[ranges.answerIndex], "15.4 kW")
    }

    // MARK: - Box fill and installation

    func testBoxFillCountsAllowancesNotWires() throws {
        // Six 12 AWG conductors, one yoke, clamps, three grounds. The grounds
        // are ONE allowance and the yoke is TWO, so this is ten allowances at
        // 2.25 in³, not fourteen.
        let result = try XCTUnwrap(FieldCalculators.boxFill(
            conductors: 6, conductorSize: "12 AWG", devices: 1,
            hasClamps: true, grounds: 3, groundSize: "12 AWG"
        ))
        XCTAssertEqual(result.required, 22.5, accuracy: 0.001)
        // Adding grounds does not change the answer. That is the whole rule.
        let moreGrounds = try XCTUnwrap(FieldCalculators.boxFill(
            conductors: 6, conductorSize: "12 AWG", devices: 1,
            hasClamps: true, grounds: 9, groundSize: "12 AWG"
        ))
        XCTAssertEqual(moreGrounds.required, result.required, accuracy: 0.001)
        XCTAssertNotNil(result.smallestBox)
    }

    func testBoxTableIsOrderedAndComplete() {
        let volumes = NECTables.boxSizes.map(\.cubicInches)
        XCTAssertFalse(volumes.contains { $0 <= 0 })
        XCTAssertEqual(Set(NECTables.boxSizes.map(\.name)).count, NECTables.boxSizes.count)
        // The smallest box that holds 18 in³ is the 4x1-1/4 square at exactly 18.
        XCTAssertEqual(NECTables.smallestBox(forCubicInches: 18)?.cubicInches, 18.0)
        XCTAssertNil(NECTables.smallestBox(forCubicInches: 999))
    }

    func testWorkingSpaceOnlyGradesAbove150Volts() {
        for condition in NECTables.WorkingSpaceCondition.allCases {
            XCTAssertEqual(NECTables.workingSpaceDepthFeet(voltsToGround: 120, condition: condition), 3.0)
        }
        XCTAssertEqual(NECTables.workingSpaceDepthFeet(voltsToGround: 277, condition: .one), 3.0)
        XCTAssertEqual(NECTables.workingSpaceDepthFeet(voltsToGround: 277, condition: .two), 3.5)
        XCTAssertEqual(NECTables.workingSpaceDepthFeet(voltsToGround: 277, condition: .three), 4.0)
    }

    // MARK: - Study pace

    /// The cram case is the one the flow had no answer for, so it is the one
    /// with a test. A candidate sitting the exam tomorrow must get a plan, a
    /// daily number they might actually do, and an urgent pace that Home and
    /// onboarding branch on.
    @MainActor
    func testCrammingCandidateGetsAPlan() {
        let defaults = UserDefaults(suiteName: "pace-tests")!
        defaults.removePersistentDomain(forName: "pace-tests")
        let profile = CandidateProfile(defaults: defaults)

        profile.examDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        XCTAssertEqual(profile.daysUntilExam, 1)
        XCTAssertEqual(profile.pace, .cram)
        XCTAssertTrue(profile.pace.isUrgent)
        XCTAssertFalse(profile.pace.priorities.isEmpty)
        // Not 600 questions in a day, which is what dividing a fixed total by
        // the days left used to produce.
        XCTAssertLessThanOrEqual(profile.suggestedDailyQuestions, 60)
        XCTAssertGreaterThanOrEqual(profile.suggestedDailyQuestions, 20)

        profile.examDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        XCTAssertEqual(profile.pace, .sprint)
        profile.examDate = Calendar.current.date(byAdding: .day, value: 40, to: Date())
        XCTAssertEqual(profile.pace, .build)
        profile.examDate = Calendar.current.date(byAdding: .day, value: 200, to: Date())
        XCTAssertEqual(profile.pace, .foundation)
        XCTAssertFalse(profile.pace.isUrgent)
        profile.examDate = nil
        XCTAssertEqual(profile.pace, .undated)

        // Every pace has to say something, in both fields, or the card renders
        // an empty box on the screen that asks for money.
        for pace in StudyPace.allCases {
            XCTAssertFalse(pace.title.isEmpty, pace.rawValue)
            XCTAssertFalse(pace.summary.isEmpty, pace.rawValue)
            XCTAssertFalse(pace.priorities.isEmpty, pace.rawValue)
            XCTAssertFalse(pace.summary.contains("—"), pace.rawValue)
            for line in pace.priorities {
                XCTAssertFalse(line.contains("—"), pace.rawValue)
            }
        }
        defaults.removePersistentDomain(forName: "pace-tests")
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
        copy += CandidateMistake.all.map(\.summary)
        copy += ShellCopy.all
        return copy
    }

    private func duplicates(in ids: [String]) -> [String] {
        Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.map(\.key).sorted()
    }
}
