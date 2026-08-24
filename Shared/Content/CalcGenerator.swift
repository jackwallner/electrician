import Foundation

/// Generates code calculations forever.
///
/// This is the reason the app has something to sell after the authored sets run
/// out. Every problem here is a pure function of its inputs with exactly one
/// correct answer, so unlike a hand-written question bank it cannot be
/// exhausted, and unlike a shuffled question bank it is not the same fifty
/// questions in a new order.
///
/// The four shapes are the four that candidates actually fail: derating a
/// conductor for heat and bundling, sizing overcurrent protection when the
/// small-conductor rule overrides the table, filling a raceway, and filling a
/// box. Each one has a worked-steps explanation, because a candidate who gets
/// the order of operations wrong gets every problem of that shape wrong.
///
/// Distractors are the other half of the job. A multiple choice question whose
/// wrong answers are random numbers teaches nothing. Every distractor below is
/// the number you land on by making a specific, common mistake, so a wrong pick
/// tells the reader which mistake they made.
enum CalcGenerator {

    // MARK: - Ampacity after correction and adjustment

    /// "What is this conductor good for here?" Ambient correction and bundling
    /// adjustment both apply, both start from the 90°C column, and the answer
    /// is then capped by the terminal rating. Getting that order wrong is the
    /// single most common derating error.
    static func ampacityProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        let sizes = ["12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG", "1/0 AWG", "3/0 AWG"]
        let size = sizes.randomElement(using: &rng)!
        let material = ConductorMaterial.allCases.randomElement(using: &rng)!
        let ambient = [35, 40, 45, 50, 55].randomElement(using: &rng)!
        let ccc = [4, 5, 6, 7, 8, 10, 12].randomElement(using: &rng)!

        let base = Double(NECTables.ampacity(size: size, material: material, column: .c90) ?? 0)
        let correction = NECTables.ambientCorrection(celsius: ambient, column: .c90) ?? 1.0
        let adjustment = NECTables.adjustmentFactor(currentCarrying: ccc)
        let derated = base * correction * adjustment

        // The 75°C terminal ceiling. Equipment terminations, not the wire, are
        // usually what actually limits the circuit.
        let terminalLimit = Double(NECTables.ampacity(size: size, material: material, column: .c75) ?? 0)
        let answer = min(derated, terminalLimit)

        // Distractors, each one a named mistake.
        let startedAt75 = terminalLimit * correction * adjustment
        let forgotBundling = min(base * correction, terminalLimit)
        let forgotTerminals = derated

        let candidates = [answer, startedAt75, forgotBundling, forgotTerminals]
        let choices = uniqueChoices(from: candidates, answer: answer,
                                    pad: { $0 * Double.random(in: 0.8...1.2, using: &rng) }) {
            "\($0.roundedAmpsText) A"
        }

        var steps = [
            "Start in the 90°C column, because that is the conductor's own rating: \(size) \(material.displayName) is \(Int(base)) A.",
            "Ambient \(ambient)°C corrects by \(correction.factorText): \(Int(base)) × \(correction.factorText) = \((base * correction).roundedAmpsText) A.",
            "\(ccc) current-carrying conductors adjust by \(adjustment.factorText): \((base * correction).roundedAmpsText) × \(adjustment.factorText) = \(derated.roundedAmpsText) A.",
        ]
        if answer < derated {
            steps.append("The 75°C termination limits it to \(Int(terminalLimit)) A, and the lower number wins, so the answer is \(answer.roundedAmpsText) A.")
        } else {
            steps.append("That is still under the \(Int(terminalLimit)) A termination limit, so the derated value stands: \(answer.roundedAmpsText) A.")
        }

        return CalcScenario(
            id: "gen-ampacity-\(UUID().uuidString)",
            situation: "Find the allowable ampacity of this conductor as installed.",
            givens: [
                .conductor(size, "THHN"),
                .material(material),
                .ambient(ambient),
                .currentCarrying(ccc),
                .terminals(.c75),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "310.16, 310.15(B)(1), 310.15(C)(1), 110.14(C)"
        )
    }

    // MARK: - Overcurrent protection sizing

    /// "What breaker goes on this?" The trap is 240.4(D): for 14, 12 and 10 AWG
    /// the small-conductor ceiling overrides whatever the ampacity table says,
    /// and candidates who learned the table first walk straight into it.
    static func ocpdProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        let sizes = ["14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG"]
        let size = sizes.randomElement(using: &rng)!
        let material: ConductorMaterial = size == "14 AWG" ? .copper
            : ConductorMaterial.allCases.randomElement(using: &rng)!

        let tableAmpacity = Double(NECTables.ampacity(size: size, material: material, column: .c75) ?? 0)
        let ceiling = NECTables.smallConductorCeiling(size: size, material: material)
        let usable = ceiling.map { min(tableAmpacity, Double($0)) } ?? tableAmpacity
        let answer = Double(NECTables.nextStandardOCPD(atMost: usable) ?? 15)

        let ignoredCeiling = Double(NECTables.nextStandardOCPD(atMost: tableAmpacity) ?? 15)
        let roundedUp = Double(NECTables.nextStandardOCPD(atLeast: usable) ?? 15)
        let usedNinety = Double(
            NECTables.nextStandardOCPD(
                atMost: Double(NECTables.ampacity(size: size, material: material, column: .c90) ?? 0)
            ) ?? 15
        )

        let choices = uniqueChoices(
            from: [answer, ignoredCeiling, roundedUp, usedNinety],
            answer: answer,
            // Not every conductor has a 240.4(D) cap, and without one the three
            // mistake-distractors can all land on the answer. Adjacent standard
            // ratings keep the question from collapsing to a coin flip.
            pad: { value in
                let index = NECTables.standardOCPD.firstIndex { Double($0) >= value } ?? 0
                let offset = Int.random(in: 1...3, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
                let clamped = min(max(index + offset, 0), NECTables.standardOCPD.count - 1)
                return Double(NECTables.standardOCPD[clamped])
            }
        ) { "\(Int($0)) A" }

        var steps = [
            "Terminations are 75°C, so read the 75°C column: \(size) \(material.displayName) is \(Int(tableAmpacity)) A.",
        ]
        if let ceiling, Double(ceiling) < tableAmpacity {
            steps.append("240.4(D) caps this size at \(ceiling) A regardless of the table. That cap is the number to protect at, not \(Int(tableAmpacity)) A.")
        }
        steps.append("The largest standard rating in 240.6(A) at or below \(Int(usable)) A is \(Int(answer)) A.")

        return CalcScenario(
            id: "gen-ocpd-\(UUID().uuidString)",
            situation: "Size the overcurrent protection for this conductor. It supplies a continuous-duty general load with no next-size-up allowance.",
            givens: [
                .conductor(size, "THWN-2"),
                .material(material),
                .terminals(.c75),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "240.4, 240.4(D), 240.6(A), 110.14(C)"
        )
    }

    // MARK: - Raceway fill

    /// "Does it fit?" Over two conductors the allowance is 40%, and the
    /// candidate mistake is using 53% or 31% out of habit.
    static func conduitFillProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        let sizes = ["12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG"]
        let size = sizes.randomElement(using: &rng)!
        let count = [4, 6, 7, 9, 12].randomElement(using: &rng)!
        let area = NECTables.thhnArea[size] ?? 0
        let bundle = area * Double(count)
        let percent = NECTables.fillPercent(conductorCount: count)

        // Smallest EMT whose 40% allowance covers the bundle.
        let answerTrade = NECTables.emtTradeSizes.first { trade in
            (NECTables.emtArea[trade] ?? 0) * percent >= bundle
        } ?? "4\""

        let oneSmaller = NECTables.emtTradeSizes
            .prefix(while: { $0 != answerTrade })
            .last ?? "1/2\""
        let oneBigger = NECTables.emtTradeSizes
            .drop(while: { $0 != answerTrade })
            .dropFirst()
            .first ?? "4\""
        // The size you get by wrongly allowing 53%.
        let usedFiftyThree = NECTables.emtTradeSizes.first { trade in
            (NECTables.emtArea[trade] ?? 0) * 0.53 >= bundle
        } ?? "4\""

        let choices = uniqueChoices(
            from: [answerTrade, oneSmaller, oneBigger, usedFiftyThree],
            answer: answerTrade,
            pad: { trade in
                let index = NECTables.emtTradeSizes.firstIndex(of: trade) ?? 0
                let offset = Int.random(in: 1...2, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
                let clamped = min(max(index + offset, 0), NECTables.emtTradeSizes.count - 1)
                return NECTables.emtTradeSizes[clamped]
            }
        ) { $0 }

        let allowance = (NECTables.emtArea[answerTrade] ?? 0) * percent

        return CalcScenario(
            id: "gen-conduitfill-\(UUID().uuidString)",
            situation: "Pick the smallest trade size of EMT that will carry these conductors.",
            givens: [
                .conductor(size, "THHN"),
                Given("Quantity", "\(count)", unit: "conductors"),
                .raceway("EMT", "?"),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: [
                "One \(size) THHN is \(area.areaText) in². \(count) of them is \(bundle.areaText) in².",
                "Over two conductors the allowance is \(Int(percent * 100))%, not 53% or 31%.",
                "\(answerTrade) EMT is \((NECTables.emtArea[answerTrade] ?? 0).areaText) in² interior, and \(Int(percent * 100))% of that is \(allowance.areaText) in².",
                "\(allowance.areaText) in² covers the \(bundle.areaText) in² bundle, and the next size down does not, so \(answerTrade) is the answer.",
            ],
            citation: "Ch. 9 Table 1, Table 4, Table 5"
        )
    }

    // MARK: - Box fill

    /// "How big does the box have to be?" The counting rules are what trip
    /// people: all the grounds together are one allowance, a yoke is two, and
    /// the conductors that only pass through still count.
    static func boxFillProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        let size = ["14 AWG", "12 AWG"].randomElement(using: &rng)!
        let volume = NECTables.conductorVolume[size] ?? 2.0
        let currentCarrying = [4, 5, 6, 7, 8].randomElement(using: &rng)!
        let devices = [1, 2].randomElement(using: &rng)!
        let hasClamp = Bool.random(using: &rng)
        let groundCount = [2, 3, 4].randomElement(using: &rng)!

        // Allowances: each insulated conductor 1, all grounds together 1,
        // clamps together 1, each yoke 2.
        let conductorUnits = currentCarrying
        let groundUnits = 1
        let clampUnits = hasClamp ? 1 : 0
        let deviceUnits = devices * 2
        let totalUnits = conductorUnits + groundUnits + clampUnits + deviceUnits
        let required = Double(totalUnits) * volume

        let countedGroundsIndividually = Double(totalUnits - 1 + groundCount) * volume
        let forgotDevices = Double(totalUnits - deviceUnits) * volume
        let countedYokeAsOne = Double(totalUnits - devices) * volume

        let choices = uniqueChoices(
            from: [required, countedGroundsIndividually, forgotDevices, countedYokeAsOne],
            answer: required,
            pad: { $0 + Double(Int.random(in: 1...4, using: &rng)) * volume }
        ) { "\($0.volumeText) in³" }

        var givens: [Given] = [
            .conductor(size, "THHN"),
            Given("Insulated", "\(currentCarrying)", unit: "conductors"),
            Given("Grounds", "\(groundCount)", unit: "wires"),
            Given("Devices", "\(devices)", unit: devices == 1 ? "yoke" : "yokes"),
        ]
        if hasClamp { givens.append(Given("Internal clamps", "yes")) }

        var steps = [
            "Each allowance for \(size) is \(volume.volumeText) in³, so this is a counting problem first and a multiplication problem second.",
            "\(currentCarrying) insulated conductors is \(currentCarrying) allowances.",
            "The \(groundCount) equipment grounds together count as ONE allowance, not \(groundCount).",
        ]
        if hasClamp { steps.append("Internal clamps count as one allowance no matter how many there are.") }
        steps.append("Each device yoke counts as two, so \(devices) yoke\(devices == 1 ? "" : "s") is \(deviceUnits).")
        steps.append("\(totalUnits) allowances × \(volume.volumeText) in³ = \(required.volumeText) in³.")

        return CalcScenario(
            id: "gen-boxfill-\(UUID().uuidString)",
            situation: "Find the minimum box volume required.",
            givens: givens,
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "314.16(B)"
        )
    }

    // MARK: - Voltage drop

    /// Not a code requirement, an informational note, and asked on every exam
    /// anyway. Kept because it is also the calculation electricians actually
    /// run in the field.
    static func voltageDropProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        let size = ["12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG"].randomElement(using: &rng)!
        let material = ConductorMaterial.allCases.randomElement(using: &rng)!
        let phase = Phase.allCases.randomElement(using: &rng)!
        let volts = phase == .single ? [120, 240].randomElement(using: &rng)!
                                     : [208, 480].randomElement(using: &rng)!
        let amps = Double([12, 16, 20, 24, 30, 40].randomElement(using: &rng)!)
        let feet = [80, 120, 150, 200, 250, 300].randomElement(using: &rng)!

        let cm = NECTables.circularMils[size] ?? 1
        let k = material.voltageDropK
        let drop = phase.voltageDropFactor * k * amps * Double(feet) / cm

        let usedWrongFactor = (phase == .single ? 1.732 : 2.0) * k * amps * Double(feet) / cm
        let forgotFactor = k * amps * Double(feet) / cm
        let usedOtherMetal = phase.voltageDropFactor
            * (material == .copper ? 21.2 : 12.9) * amps * Double(feet) / cm

        let choices = uniqueChoices(
            from: [drop, usedWrongFactor, forgotFactor, usedOtherMetal],
            answer: drop,
            pad: { $0 * Double.random(in: 0.6...1.5, using: &rng) }
        ) { "\($0.voltsText) V" }

        let percent = drop / Double(volts) * 100

        return CalcScenario(
            id: "gen-vdrop-\(UUID().uuidString)",
            situation: "Find the voltage drop on this run.",
            givens: [
                .conductor(size, "THHN"),
                .material(material),
                .voltage(volts, phase: phase),
                .load(amps),
                .length(feet),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: [
                "\(phase == .single ? "Single-phase uses 2" : "Three-phase uses 1.732") as the factor, because that is the path the current actually takes.",
                "K for \(material.displayName.lowercased()) is \(k.factorText), and \(size) is \(Int(cm)) circular mils.",
                "VD = \(phase.voltageDropFactor.factorText) × \(k.factorText) × \(amps.trimmedAmps) A × \(feet) ft ÷ \(Int(cm)) cmil = \(drop.voltsText) V.",
                "That is \(percent.voltsText)% of \(volts) V, so it is \(percent <= 3 ? "within" : "past") the 3% figure the informational note suggests for a branch circuit.",
            ],
            citation: "210.19(A) Informational Note, Ch. 9 Table 8"
        )
    }

    // MARK: - Choice assembly

    private struct Choices {
        let labels: [String]
        let answerIndex: Int
    }

    /// How many options every generated question shows.
    private static let choiceCount = 4

    /// Formats candidate values into a de-duplicated, shuffled choice list of
    /// exactly `choiceCount` options, and reports where the correct one landed.
    ///
    /// Two things are going on here, and both are load-bearing.
    ///
    /// De-duplication: two different mistakes often land on the same number,
    /// and showing that number twice makes a correct answer look wrong.
    ///
    /// Padding: de-duplication can collapse the list. A conductor with no
    /// 240.4(D) cap, for instance, makes three of the four mistake-distractors
    /// identical to the answer, which would ship a question with one option.
    /// `pad` generates further plausible neighbours from an existing value
    /// until there are enough. It gets a bounded number of attempts so a
    /// generator that cannot produce a distinct neighbour degrades to a shorter
    /// list rather than spinning forever.
    /// `pad` and `format` are non-escaping on purpose: every caller closes over
    /// its `inout` generator, and an Optional closure parameter is implicitly
    /// escaping, which the compiler rightly rejects.
    private static func uniqueChoices<T>(from candidates: [T], answer: T,
                                         pad: (T) -> T,
                                         format: (T) -> String) -> Choices {
        let answerLabel = format(answer)
        var seen: Set<String> = [answerLabel]
        var labels: [String] = [answerLabel]
        var values: [T] = [answer]

        for candidate in candidates where labels.count < choiceCount {
            let label = format(candidate)
            if seen.insert(label).inserted {
                labels.append(label)
                values.append(candidate)
            }
        }

        var attempts = 0
        while labels.count < choiceCount, attempts < 40 {
            attempts += 1
            let seed = values.randomElement() ?? answer
            let candidate = pad(seed)
            let label = format(candidate)
            if seen.insert(label).inserted {
                labels.append(label)
                values.append(candidate)
            }
        }

        labels.shuffle()
        return Choices(labels: labels, answerIndex: labels.firstIndex(of: answerLabel) ?? 0)
    }
}

// MARK: - Formatting

extension Double {
    /// Ampacity rounded the way the code rounds it: to the nearest whole amp.
    var roundedAmps: Int { Int(rounded()) }
    var roundedAmpsText: String { String(format: "%.1f", self) }

    /// A correction or adjustment factor, printed without noise.
    var factorText: String {
        if self == rounded() { return String(Int(rounded())) }
        return String(format: "%g", self)
    }

    var areaText: String { String(format: "%.2f", self) }

    /// Box volumes the way the code prints them: 20 in³, not 20.00 in³, but
    /// 22.5 in³ keeps its half.
    var volumeText: String {
        if self == rounded() { return String(Int(rounded())) }
        return String(format: "%.2f", self)
            .replacingOccurrences(of: "0$", with: "", options: .regularExpression)
    }
    var voltsText: String { String(format: "%.1f", self) }
}
