import Foundation
import XCTest
@testable import Electrician

/// The reviewed contract is deliberately separate from production answer keys.
/// Update it only after reviewing the changed item and its code reference.
final class QuestionBankAuditTests: XCTestCase {
    private struct Audit: Decodable {
        let edition: Int
        let items: [Item]
        let tables: Tables
    }
    private struct Item: Decodable {
        let id: String
        let mode: String
        let answer: String
        let citation: String
    }
    private struct GEC: Decodable { let serviceUpTo: Double; let copper: String }
    private struct EGC: Decodable { let ocpdUpTo: Int; let copper: String; let aluminum: String }
    private struct Tables: Decodable {
        let copperAmpacity: [String: [String: Int]]
        let aluminumAmpacity: [String: [String: Int]]
        let circularMils: [String: Double]
        let conductorVolume: [String: Double]
        let emtArea: [String: Double]
        let emtTradeSizes: [String]
        let thhnArea: [String: Double]
        let standardOCPD: [Int]
        let smallConductorLimit: [String: [String: Int]]
        let gecCopperService: [GEC]
        let gecAluminumService: [GEC]
        let egcRows: [EGC]
        let singlePhaseFLC: [String: [String: Double]]
        let threePhaseFLC: [String: [String: Double]]
        let ambient: [String: [String: Double?]]
    }

    private func audit() throws -> Audit {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "nec2023-bank-audit", withExtension: "json"))
        return try JSONDecoder().decode(Audit.self, from: Data(contentsOf: url))
    }

    private func normalized(_ value: String) -> String {
        let compact = value.lowercased().filter { !$0.isWhitespace && $0 != "," }
        let number = compact.prefix { "0123456789.+-".contains($0) }
        guard let numeric = Double(number) else { return compact }
        let unit = String(compact.dropFirst(number.count))
        if ["in.", "in", "ft"].contains(unit) {
            return "\(unit == "ft" ? numeric * 12 : numeric)in"
        }
        return "\(numeric)\(unit)"
    }

    private func check(_ id: String, choices: [String], key: Int, expected: String, citation: String?) {
        XCTAssertTrue(choices.indices.contains(key), id)
        let matches = choices.indices.filter { normalized(choices[$0]) == normalized(expected) }
        XCTAssertEqual(matches.count, 1, "\(id): expected exactly one \(expected), got \(choices)")
        XCTAssertEqual(matches.first, key, "\(id): wrong answer key")
        XCTAssertEqual(Set(choices.map(normalized)).count, choices.count, "\(id): equivalent options")
        XCTAssertFalse(citation?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true, "\(id): missing citation")
    }

    func testEveryAuthoredItemHasOneReviewedAnswerAndItsReviewedCodeCitation() throws {
        let contract = try audit()
        XCTAssertEqual(contract.edition, 2023)
        let expected = Dictionary(uniqueKeysWithValues: contract.items.map { ($0.id, $0) })
        var seen: Set<String> = []
        func validate(_ id: String, choices: [String], key: Int, citation: String?) throws {
            let item = try XCTUnwrap(expected[id], "Unreviewed item: \(id)")
            XCTAssertTrue(seen.insert(id).inserted, id)
            XCTAssertEqual(item.mode, "choice", id)
            XCTAssertEqual(citation, item.citation, id)
            check(id, choices: choices, key: key, expected: item.answer, citation: citation)
        }
        for drill in DrillLibrary.rooms.flatMap(\.drills) {
            switch drill.kind {
            case .quiz(let questions):
                for q in questions { try validate(q.id, choices: q.choices, key: q.answerIndex, citation: q.citation) }
            case .articleMatch(let questions):
                for question in questions {
                    let q = question.asQuizQuestion
                    try validate(q.id, choices: q.choices, key: q.answerIndex, citation: q.citation)
                }
            case .calc(let scenarios):
                for q in scenarios { try validate(q.id, choices: q.choices, key: q.answerIndex, citation: q.citation) }
            case .flashcards(let cards):
                for card in cards {
                    if let choice = card.choice {
                        try validate(card.id, choices: choice.options, key: choice.answerIndex, citation: card.citation)
                    } else {
                        let item = try XCTUnwrap(expected[card.id], card.id)
                        XCTAssertTrue(seen.insert(card.id).inserted, card.id)
                        XCTAssertEqual(item.mode, "reference", card.id)
                        XCTAssertEqual(card.backTitle, item.answer, card.id)
                        XCTAssertEqual(card.citation, item.citation, card.id)
                        XCTAssertFalse(item.citation.isEmpty, card.id)
                    }
                }
            }
        }
        XCTAssertEqual(seen, Set(expected.keys), "Deleted or unreviewed content")
    }

    func testEveryGeneratedShapeHasExactlyOneIndependentlyCalculatedOption() throws {
        let tables = try audit().tables
        var rng: RandomNumberGenerator = SeededGenerator(seed: 20231022)
        for skill in PracticeSkill.allCases {
            for _ in 0..<500 {
                let question = EndlessPractice.scenario(for: skill, using: &rng)
                let answer = try solve(question, skill: skill, tables: tables)
                XCTAssertEqual(question.choices.count, 4, question.id)
                check(question.id, choices: question.choices, key: question.answerIndex,
                      expected: answer, citation: question.citation)
            }
        }
    }

    private func solve(_ q: CalcScenario, skill: PracticeSkill, tables t: Tables) throws -> String {
        func given(_ label: String) throws -> String {
            try XCTUnwrap(q.givens.first { $0.label == label }?.value, "\(q.id): missing \(label)")
        }
        func number(_ label: String) throws -> Double {
            try XCTUnwrap(Double(try given(label).replacingOccurrences(of: ",", with: "")))
        }
        func format(_ value: Double, _ digits: Int, _ unit: String) -> String {
            "\(String(format: "%.*f", digits, value)) \(unit)"
        }
        func conductor() throws -> String {
            String(try given("Conductor").split(separator: " ").prefix(2).joined(separator: " "))
        }
        func motorFLC() throws -> Double {
            let supply = try given("Supply")
            let key = try XCTUnwrap(["115V 1Ø": "single115", "230V 1Ø": "single230", "208V 3Ø": "three208", "230V 3Ø": "three230", "460V 3Ø": "three460"][supply])
            let row = try given("Motor")
            return try XCTUnwrap((supply.contains("1Ø") ? t.singlePhaseFLC : t.threePhaseFLC)[row]?[key])
        }
        switch skill {
        case .ampacity, .overcurrent:
            let size = try conductor()
            let copper = try given("Material") == "Copper"
            let row = try XCTUnwrap((copper ? t.copperAmpacity : t.aluminumAmpacity)[size])
            let terminal = Double(try XCTUnwrap(row["75"]))
            if skill == .overcurrent {
                let cap = (t.smallConductorLimit[size]?[copper ? "copper" : "aluminum"]).map(Double.init) ?? terminal
                return "\(try XCTUnwrap(t.standardOCPD.last { Double($0) <= min(terminal, cap) })) A"
            }
            XCTAssertTrue(q.situation.contains("nearest 0.1 A"), q.id)
            let ambient = try given("Ambient")
            let correction = try XCTUnwrap(t.ambient[ambient]?["90"] ?? nil)
            let count = try number("Current-carrying")
            let factor = count <= 3 ? 1.0 : count <= 6 ? 0.8 : count <= 9 ? 0.7 : 0.5
            return format(min(Double(try XCTUnwrap(row["90"])) * correction * factor, terminal), 1, "A")
        case .conduitFill:
            let area = try XCTUnwrap(t.thhnArea[conductor()]) * number("Quantity")
            return try XCTUnwrap(t.emtTradeSizes.first { (t.emtArea[$0] ?? 0) * 0.4 >= area })
        case .boxFill:
            XCTAssertTrue(q.situation.contains("nearest 0.01 in³"), q.id)
            let unit = try XCTUnwrap(t.conductorVolume[conductor()])
            let grounds = try number("Grounds")
            let groundUnits = grounds > 0 ? 1 + max(0, grounds - 4) / 4 : 0
            let clamps = q.givens.contains { $0.label == "Internal clamps" } ? 1.0 : 0.0
            let units = try number("Insulated") + number("Devices") * 2 + clamps + groundUnits
            return format(units * unit, 2, "in³")
        case .voltageDrop:
            let k = try given("Material") == "Copper" ? 12.9 : 21.2
            let phase = try given("System").contains("1Ø") ? 2.0 : 1.732
            let cm = try XCTUnwrap(t.circularMils[conductor()])
            return format(try phase * k * number("Load") * number("One-way length") / cm, 1, "V")
        case .egcSizing:
            let rating = try number("Protected at")
            let row = try XCTUnwrap(t.egcRows.first { Double($0.ocpdUpTo) >= rating })
            return try given("Material") == "Copper" ? row.copper : row.aluminum
        case .gecSizing:
            let parts = try given("Service conductor").components(separatedBy: " × ")
            let sets = parts.count > 1 ? Double(parts[0])! : 1
            let area = try XCTUnwrap(t.circularMils[parts.last!]) * sets
            let rows = try given("Material") == "Copper" ? t.gecCopperService : t.gecAluminumService
            let tableSize = try XCTUnwrap(rows.first { $0.serviceUpTo >= area }?.copper)
            let cap = ["Rod, pipe or plate": "6 AWG", "Concrete-encased": "4 AWG", "Ground ring": "2 AWG"][try given("Electrode")]
            guard let cap else { return tableSize }
            return try XCTUnwrap(t.circularMils[tableSize]) > XCTUnwrap(t.circularMils[cap]) ? cap : tableSize
        case .motorConductor:
            XCTAssertTrue(q.situation.contains("nearest 0.1 A"), q.id)
            return format(try motorFLC() * 1.25, 1, "A")
        case .motorProtection:
            let device = try given("Device")
            let factor = try XCTUnwrap(["Nontime-delay fuse": 3.0, "Dual-element fuse (not Class CC)": 1.75, "Inverse-time breaker (nonadjustable)": 2.5][device])
            let fuse = device.contains("fuse")
            let ratings = fuse ? (t.standardOCPD + [1, 3, 6, 601]).sorted() : t.standardOCPD
            let calculated = try motorFLC() * factor
            let rating = try XCTUnwrap(ratings.first { Double($0) >= calculated - 0.0001 })
            return "\(fuse ? rating : max(15, rating)) A"
        case .dwellingLoad:
            XCTAssertTrue(q.situation.contains("Table 220.55 column C"), q.id)
            let general = try number("Floor area") * 3 + 4500
            let lighting = 3000 + (general - 3000) * 0.35
            let rangeKW = try number("Range")
            let range = 8000 * (1 + max(0, rangeKW - 12) * 0.05)
            let dryer = try max(5000, number("Dryer"))
            let appliances = try ["Water heater", "Dishwasher", "Disposal", "Compactor"].map(number).reduce(0, +) * 0.75
            let heating = try number("Electric heat")
            XCTAssertGreaterThan(heating, try number("Air conditioning") * 1.25, q.id)
            let total = try lighting + range + dryer + appliances + heating + number("Disposal") * 0.25
            if q.situation.contains("service rating") {
                return "\(try XCTUnwrap(t.standardOCPD.first { Double($0) >= total / 240 })) A"
            }
            return "\(Int(total.rounded())) VA"
        }
    }

    func testStoredAmpacitiesFactorsAndMotorFLCMatchReviewedTableFacts() throws {
        let t = try audit().tables
        for (material, rows) in [(ConductorMaterial.copper, t.copperAmpacity), (.aluminum, t.aluminumAmpacity)] {
            for (size, columns) in rows {
                for column in TemperatureRating.allCases {
                    XCTAssertEqual(NECTables.ampacity(size: size, material: material, column: column), columns[String(column.rawValue)], size)
                }
            }
        }
        for (celsius, columns) in t.ambient {
            for column in TemperatureRating.allCases {
                XCTAssertEqual(NECTables.ambientCorrection(celsius: Int(celsius)!, column: column), columns[String(column.rawValue)] ?? nil, celsius)
            }
        }
        for (rows, supplies) in [(t.singlePhaseFLC, [NECTables.MotorSupply.single115, .single230]),
                                  (t.threePhaseFLC, [.three208, .three230, .three460])] {
            for (hp, columns) in rows {
                for supply in supplies {
                    XCTAssertEqual(NECTables.motorFLC(hp: hp, supply: supply), columns[supply.rawValue], hp)
                }
            }
        }
    }

    func testBoundaryRulesThatPreviouslyHadWrongAnswers() throws {
        XCTAssertEqual(NECTables.standardOCPD.first, 10)
        XCTAssertEqual(NECTables.ambientCorrection(celsius: 20, column: .c90), 1.08)
        XCTAssertEqual(NECTables.ambientCorrection(celsius: 65, column: .c90), 0.65)
        XCTAssertEqual(NECTables.ambientCorrection(celsius: 85, column: .c90), 0.29)
        XCTAssertNil(NECTables.ambientCorrection(celsius: 86, column: .c90))
        for (count, expected) in [(0, 0.0), (1, 1), (4, 1), (5, 1.25), (9, 2.25)] {
            XCTAssertEqual(NECTables.groundFillAllowances(entering: count), expected)
        }
        XCTAssertEqual(NECTables.motorBranchOCPD(flc: 1.1, protection: .dualElementFuse), 3)
        XCTAssertEqual(NECTables.motorBranchOCPD(flc: 1.1, protection: .inverseTimeBreaker), 15)
        XCTAssertEqual(normalized("3 ft"), normalized("36 in."))
        XCTAssertEqual(normalized("55.0 A"), normalized("55 A"))
    }
}
