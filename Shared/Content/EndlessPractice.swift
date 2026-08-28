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
    // Added after the first release. Raw values are persisted inside generated
    // item ids and inside `MistakePattern.skill`, so they are keys: renaming
    // one resets that skill's tally and orphans its mistake patterns.
    case egcSizing
    case gecSizing
    case motorConductor
    case motorProtection
    case dwellingLoad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ampacity: return "Derate the Conductor"
        case .overcurrent: return "Size the Breaker"
        case .conduitFill: return "Fill the Pipe"
        case .boxFill: return "Fill the Box"
        case .voltageDrop: return "Drop the Voltage"
        case .egcSizing: return "Size the Ground"
        case .gecSizing: return "Reach the Electrode"
        case .motorConductor: return "Feed the Motor"
        case .motorProtection: return "Protect the Motor"
        case .dwellingLoad: return "Size the Service"
        }
    }

    var subtitle: String {
        switch self {
        case .ampacity: return "Heat and bundling, unlimited reps"
        case .overcurrent: return "Where 240.4(D) beats the table"
        case .conduitFill: return "Smallest raceway that works"
        case .boxFill: return "Counting allowances, not wires"
        case .voltageDrop: return "The field calculation, drilled"
        case .egcSizing: return "Table 250.122, read from the breaker"
        case .gecSizing: return "Table 250.66, and the rod's own ceiling"
        case .motorConductor: return "Table current, never the nameplate"
        case .motorProtection: return "The one place you round up"
        case .dwellingLoad: return "The full dwelling calculation"
        }
    }

    var icon: String {
        switch self {
        case .ampacity: return "thermometer.medium"
        case .overcurrent: return "bolt.shield.fill"
        case .conduitFill: return "cylinder.fill"
        case .boxFill: return "shippingbox.fill"
        case .voltageDrop: return "chart.line.downtrend.xyaxis"
        case .egcSizing: return "leaf.fill"
        case .gecSizing: return "arrow.down.to.line"
        case .motorConductor: return "fan.fill"
        case .motorProtection: return "gearshape.2.fill"
        case .dwellingLoad: return "house.fill"
        }
    }

    /// The room this skill practises, for the stats breakdown.
    var roomID: String {
        switch self {
        case .ampacity, .overcurrent: return "conductors-room"
        case .conduitFill, .boxFill, .voltageDrop: return "calc-room"
        case .egcSizing, .gecSizing, .motorConductor, .motorProtection: return "grounding-room"
        case .dwellingLoad: return "loads-room"
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
        return (0..<count).map { _ in item(for: skill, using: &rng) }
    }

    /// A mixed batch across every skill, for the timed challenge.
    static func mixedItems(count: Int) -> [QuickItem] {
        let skills = PracticeSkill.allCases
        let perSkill = max(1, count / skills.count + 1)
        return skills.flatMap { items(for: $0, count: perSkill) }.shuffled().prefix(count).map { $0 }
    }

    /// Adapts a generated scenario into the session runner's shape.
    ///
    /// The worked steps stay a LIST. They used to be joined into one paragraph
    /// here, which quietly threw away the thing the authored Worked
    /// Calculations room does best: a miss is almost never bad arithmetic, it
    /// is one skipped step, and a paragraph hides which one. The generator is
    /// the paid tier, so it gets the better explanation, not the worse one.
    static func item(from scenario: CalcScenario, skill: PracticeSkill, sourceLabel: String = "Endless Practice") -> QuickItem {
        QuickItem(
            id: skill.itemPrefix + UUID().uuidString,
            prompt: scenario.situation,
            givens: scenario.givens,
            choices: scenario.choices,
            answerIndex: scenario.answerIndex,
            explanation: scenario.steps.first ?? "",
            steps: scenario.steps,
            citation: scenario.citation,
            sourceLabel: sourceLabel,
            roomID: skill.roomID,
            isReviewable: false,
            mistakes: scenario.mistakes
        )
    }

    /// One freshly generated problem for a skill.
    static func item(for skill: PracticeSkill, using rng: inout RandomNumberGenerator, sourceLabel: String = "Endless Practice") -> QuickItem {
        item(from: scenario(for: skill, using: &rng), skill: skill, sourceLabel: sourceLabel)
    }

    static func scenario(for skill: PracticeSkill, using rng: inout RandomNumberGenerator) -> CalcScenario {
        switch skill {
        case .ampacity: return CalcGenerator.ampacityProblem(using: &rng)
        case .overcurrent: return CalcGenerator.ocpdProblem(using: &rng)
        case .conduitFill: return CalcGenerator.conduitFillProblem(using: &rng)
        case .boxFill: return CalcGenerator.boxFillProblem(using: &rng)
        case .voltageDrop: return CalcGenerator.voltageDropProblem(using: &rng)
        case .egcSizing: return CalcGenerator.egcProblem(using: &rng)
        case .gecSizing: return CalcGenerator.gecProblem(using: &rng)
        case .motorConductor: return CalcGenerator.motorConductorProblem(using: &rng)
        case .motorProtection: return CalcGenerator.motorProtectionProblem(using: &rng)
        case .dwellingLoad: return CalcGenerator.dwellingLoadProblem(using: &rng)
        }
    }

    /// Problems that set the traps this candidate keeps walking into.
    ///
    /// This is what makes "your misses come back" honest for generated
    /// practice. A generated question is a one-off: its id will never be seen
    /// again, so scheduling the ITEM for review is meaningless. The MISTAKE is
    /// not a one-off. So instead of replaying a question whose answer they now
    /// remember, this mints a new problem of the right shape and keeps it only
    /// if the same named trap is actually one of its distractors.
    ///
    /// Rejection is bounded. A shape whose trap does not apply to the inputs it
    /// happens to roll (a conductor with no 240.4(D) cap cannot punish missing
    /// 240.4(D)) falls back to an untargeted problem of the same skill rather
    /// than returning nothing, because a short Fix My Mistakes session is worse
    /// than a slightly less pointed one.
    static func targetedItems(for patterns: [MistakePattern], count: Int) -> [QuickItem] {
        guard !patterns.isEmpty, count > 0 else { return [] }
        var rng: RandomNumberGenerator = SystemRandomNumberGenerator()
        var items: [QuickItem] = []

        for index in 0..<count {
            let pattern = patterns[index % patterns.count]
            guard let skill = PracticeSkill(rawValue: pattern.skill) else { continue }

            var made: QuickItem?
            for _ in 0..<24 {
                let candidate = scenario(for: skill, using: &rng)
                guard candidate.mistakes.values.contains(pattern) else { continue }
                made = item(from: candidate, skill: skill, sourceLabel: "Targeted Practice")
                break
            }
            items.append(made ?? item(for: skill, using: &rng, sourceLabel: "Targeted Practice"))
        }
        return items
    }
}
