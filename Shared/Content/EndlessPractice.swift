import Foundation

/// The generated-practice catalogue. Each skill turns a procedural generator
/// into the same `QuickItem` shape the authored drills already produce, so the
/// session runner never has to know whether a question was written by hand or
/// generated a second ago.
///
/// This is the answer to the finite-content problem: an authored set is a pile
/// a candidate finishes in a weekend, a generator is a machine that keeps going
/// until they pass.
enum PracticeSkill: String, CaseIterable, Identifiable, Sendable {
    case ampacity
    case overcurrent
    case conduitFill
    case boxFill
    case voltageDrop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ampacity: return "Derate the Conductor"
        case .overcurrent: return "Size the Breaker"
        case .conduitFill: return "Fill the Pipe"
        case .boxFill: return "Fill the Box"
        case .voltageDrop: return "Drop the Voltage"
        }
    }

    var subtitle: String {
        switch self {
        case .ampacity: return "Heat and bundling, unlimited reps"
        case .overcurrent: return "Where 240.4(D) beats the table"
        case .conduitFill: return "Smallest raceway that works"
        case .boxFill: return "Counting allowances, not wires"
        case .voltageDrop: return "The field calculation, drilled"
        }
    }

    var icon: String {
        switch self {
        case .ampacity: return "thermometer.medium"
        case .overcurrent: return "bolt.shield.fill"
        case .conduitFill: return "cylinder.fill"
        case .boxFill: return "shippingbox.fill"
        case .voltageDrop: return "chart.line.downtrend.xyaxis"
        }
    }

    /// The room this skill practises, for the stats breakdown.
    var roomID: String {
        switch self {
        case .ampacity, .overcurrent: return "conductors-room"
        case .conduitFill, .boxFill, .voltageDrop: return "calc-room"
        }
    }

    /// Every generated item carries this prefix so `PracticeRecordStore` can
    /// roll an unbounded stream of one-off ids up into one row of stats.
    var itemPrefix: String { "gen-\(rawValue)-" }

    static func skill(forItemID id: String) -> PracticeSkill? {
        allCases.first { id.hasPrefix($0.itemPrefix) }
    }
}

enum EndlessPractice {

    /// A finished endless run is still a "drill" for the completion screen.
    static func drill(for skill: PracticeSkill) -> Drill {
        Drill(id: "endless-\(skill.rawValue)", title: skill.title, subtitle: skill.subtitle, kind: .quiz([]))
    }

    static let challengeDrill = Drill(
        id: "timed-challenge",
        title: "Timed Challenge",
        subtitle: "Beat the clock",
        kind: .quiz([])
    )

    static func items(for skill: PracticeSkill, count: Int) -> [QuickItem] {
        var rng: RandomNumberGenerator = SystemRandomNumberGenerator()
        return (0..<count).map { _ in
            let scenario: CalcScenario
            switch skill {
            case .ampacity: scenario = CalcGenerator.ampacityProblem(using: &rng)
            case .overcurrent: scenario = CalcGenerator.ocpdProblem(using: &rng)
            case .conduitFill: scenario = CalcGenerator.conduitFillProblem(using: &rng)
            case .boxFill: scenario = CalcGenerator.boxFillProblem(using: &rng)
            case .voltageDrop: scenario = CalcGenerator.voltageDropProblem(using: &rng)
            }
            return item(from: scenario, skill: skill)
        }
    }

    /// A mixed batch across every skill, for the timed challenge.
    static func mixedItems(count: Int) -> [QuickItem] {
        let skills = PracticeSkill.allCases
        let perSkill = max(1, count / skills.count + 1)
        return skills.flatMap { items(for: $0, count: perSkill) }.shuffled().prefix(count).map { $0 }
    }

    /// Flattens a generated scenario into the session runner's shape. The
    /// worked steps become the explanation, joined into a short paragraph:
    /// after a wrong answer the reader needs the reasoning, not just the value.
    private static func item(from scenario: CalcScenario, skill: PracticeSkill) -> QuickItem {
        QuickItem(
            id: skill.itemPrefix + UUID().uuidString,
            prompt: scenario.situation,
            givens: scenario.givens,
            choices: scenario.choices,
            answerIndex: scenario.answerIndex,
            explanation: scenario.steps.joined(separator: " ") + "\n\nLook it up: \(scenario.citation).",
            sourceLabel: "Endless Practice",
            roomID: skill.roomID,
            isReviewable: false
        )
    }
}
