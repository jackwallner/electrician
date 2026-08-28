import Foundation

/// Grounding and bonding conductor sizing, generated.
///
/// Article 250 is the most-failed section on a journeyman paper, and the reason
/// is not that the tables are hard. It is that there are two of them, they look
/// alike, and they are read from different things: Table 250.122 is read from
/// the OVERCURRENT DEVICE and sizes the equipment ground that runs with the
/// circuit, while Table 250.66 is read from the SERVICE CONDUCTOR and sizes the
/// electrode conductor that runs to the ground rod. A candidate who reaches for
/// the wrong one gets a plausible wire size and no signal that anything went
/// wrong, which is exactly the failure this shape is built to produce on
/// purpose and then name.
extension CandidateMistake {
    static let usedGECTableForEGC = MistakePattern(
        id: "egc-used-250-66",
        skill: PracticeSkill.egcSizing.rawValue,
        summary: "You sized this from Table 250.66. That table sizes the conductor to the electrode, and it is read from the service conductor. An equipment ground running with a circuit comes from Table 250.122, read from the overcurrent device."
    )
    static let egcWrongMaterialColumn = MistakePattern(
        id: "egc-wrong-material-column",
        skill: PracticeSkill.egcSizing.rawValue,
        summary: "You read the other metal's column. Aluminum needs more area than copper for the same job, so the two columns are never the same size on a row."
    )
    static let egcReadRowBelow = MistakePattern(
        id: "egc-read-row-below",
        skill: PracticeSkill.egcSizing.rawValue,
        summary: "You dropped to the row below. Table 250.122 is a set of not-exceeding bands: a rating between two rows reads the row ABOVE it, so a 45 A device takes the 60 A row."
    )
    static let egcUsedCircuitConductor = MistakePattern(
        id: "egc-used-circuit-conductor",
        skill: PracticeSkill.egcSizing.rawValue,
        summary: "That is the circuit conductor size, not the equipment ground. The ground is sized independently from the device rating and is almost always smaller."
    )

    static let usedEGCTableForGEC = MistakePattern(
        id: "gec-used-250-122",
        skill: PracticeSkill.gecSizing.rawValue,
        summary: "You sized this from Table 250.122, which is read from the overcurrent device and sizes an equipment ground. The conductor to the electrode comes from Table 250.66, read from the largest ungrounded service conductor."
    )
    static let gecIgnoredElectrodeCeiling = MistakePattern(
        id: "gec-ignored-electrode-ceiling",
        skill: PracticeSkill.gecSizing.rawValue,
        summary: "That is the table value, but the electrode caps it. A rod, pipe or plate never requires more than 6 AWG copper, a concrete-encased electrode more than 4 AWG, and a ground ring more than the ring conductor itself."
    )
    static let gecWrongServiceColumn = MistakePattern(
        id: "gec-wrong-service-column",
        skill: PracticeSkill.gecSizing.rawValue,
        summary: "You read the copper service bands for an aluminum service, or the reverse. Table 250.66 has a separate set of bands for each service metal, and they do not line up."
    )
    static let gecMissedParallelSet = MistakePattern(
        id: "gec-missed-parallel-set",
        skill: PracticeSkill.gecSizing.rawValue,
        summary: "You read the table on one conductor of the parallel set. The table is entered on the EQUIVALENT area of the whole set: two 250 kcmil in parallel is read as 500 kcmil."
    )
}

extension CalcGenerator {

    // MARK: - Equipment grounding conductor, Table 250.122

    /// "What size ground runs with this circuit?" Read from the device, never
    /// from the conductor, and never from the other grounding table.
    static func egcProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        var padRNG: RandomNumberGenerator = SeededGenerator(seed: rng.next())
        // Ratings that fall BETWEEN table rows are in this list on purpose: a
        // 45 A or 175 A device is where the not-exceeding band is tested, and a
        // list of only exact table rows would never produce that question.
        let ocpd = [15, 20, 30, 40, 45, 50, 60, 70, 90, 100, 110, 125, 150, 175, 200, 225, 300, 400]
            .randomElement(using: &rng)!
        let material = ConductorMaterial.allCases.randomElement(using: &rng)!

        guard let answer = NECTables.equipmentGroundingConductor(ocpd: ocpd, material: material),
              let band = NECTables.equipmentGroundingRow(ocpd: ocpd)
        else {
            // The table covers every rating in the list above, so this cannot
            // happen; falling back to a known-good shape beats returning a
            // half-built scenario if the list is ever edited carelessly.
            return ocpdProblem(using: &rng)
        }

        let otherMaterial: ConductorMaterial = material == .copper ? .aluminum : .copper
        let wrongColumn = NECTables.equipmentGroundingConductor(ocpd: ocpd, material: otherMaterial) ?? answer
        // The row below: what someone who rounds down instead of up lands on.
        let rowIndex = NECTables.egcRows.firstIndex { $0.ocpdUpTo == band } ?? 0
        let below = NECTables.egcRows[max(0, rowIndex - 1)]
        let rowBelow = material == .copper ? below.copper : below.aluminum
        // The 250.66 answer, i.e. what reaching for the wrong table produces.
        // Sized as if the device rating were the service ampacity, which is the
        // shape of the error.
        let asService = NECTables.conductorSizes.first {
            (NECTables.ampacity(size: $0, material: material, column: .c75) ?? 0) >= ocpd
        } ?? "4/0 AWG"
        let fromGECTable = NECTables.groundingElectrodeConductor(
            serviceSize: asService, serviceMaterial: material, gecMaterial: material
        ) ?? answer

        // Four named mistakes, three slots. Shuffled for the same reason the
        // dwelling shape shuffles: a fixed order starves the last ones, and a
        // trap that is never set cannot be re-set by Fix My Mistakes.
        let egcDistractors = [fromGECTable, wrongColumn, rowBelow, asService].shuffled(using: &rng)
        let choices = uniqueChoices(
            from: [answer] + egcDistractors,
            answer: answer,
            using: &rng,
            pad: { size in
                let all = NECTables.conductorSizes
                let index = all.firstIndex(of: size) ?? 0
                let offset = Int.random(in: 1...3, using: &padRNG) * (Bool.random(using: &padRNG) ? 1 : -1)
                return all[min(max(index + offset, 0), all.count - 1)]
            },
            format: { $0 }
        )

        var steps = [
            "The equipment grounding conductor is sized from the rating of the overcurrent device ahead of the circuit, not from the circuit conductors. That rating is \(ocpd) A.",
        ]
        if ocpd == band {
            steps.append("Table 250.122 has a row at \(band) A, so read it directly.")
        } else {
            steps.append("Table 250.122 has no \(ocpd) A row. The rows are not-exceeding bands, so \(ocpd) A reads the \(band) A row.")
        }
        steps.append("In the \(material.displayName.lowercased()) column that row calls for \(answer).")
        steps.append("Nothing about the circuit conductor size changes this. An equipment ground is sized from the device, and it only grows with the conductors when they are increased for voltage drop, under 250.122(B).")

        let mistakes = mistakeMap(answerLabel: answer, choices: choices.labels, [
            (fromGECTable, CandidateMistake.usedGECTableForEGC),
            (wrongColumn, CandidateMistake.egcWrongMaterialColumn),
            (rowBelow, CandidateMistake.egcReadRowBelow),
            (asService, CandidateMistake.egcUsedCircuitConductor),
        ])

        return CalcScenario(
            id: "gen-egcSizing-\(UUID().uuidString)",
            situation: "What is the minimum size equipment grounding conductor for this circuit?",
            givens: [
                Given("Protected at", "\(ocpd)", unit: "A"),
                .material(material),
                Given("Conductor", "Run in a raceway"),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "250.122, Table 250.122, 250.122(B)",
            mistakes: mistakes
        )
    }

    // MARK: - Grounding electrode conductor, Table 250.66

    /// "What size runs to the rod?" Read from the service conductor, then
    /// capped by whichever electrode it lands on.
    static func gecProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        var padRNG: RandomNumberGenerator = SeededGenerator(seed: rng.next())
        let serviceSizes = ["4 AWG", "2 AWG", "1/0 AWG", "2/0 AWG", "3/0 AWG", "4/0 AWG",
                            "250 kcmil", "350 kcmil", "500 kcmil"]
        let serviceSize = serviceSizes.randomElement(using: &rng)!
        let serviceMaterial = ConductorMaterial.allCases.randomElement(using: &rng)!
        let sets = [1, 1, 1, 2].randomElement(using: &rng)!
        let electrode = NECTables.ElectrodeType.allCases.randomElement(using: &rng)!

        guard let fromTable = NECTables.groundingElectrodeConductor(
            serviceSize: serviceSize, serviceMaterial: serviceMaterial,
            gecMaterial: .copper, parallelSets: sets
        ) else { return egcProblem(using: &rng) }

        // Apply the electrode ceiling by hand, because the parallel set has
        // already been folded into `fromTable`.
        var answer = fromTable
        if let ceiling = electrode.copperCeiling,
           let ceilingMils = NECTables.circularMilsExtended[ceiling],
           let tableMils = NECTables.circularMilsExtended[fromTable],
           tableMils > ceilingMils {
            answer = ceiling
        }

        let otherMaterial: ConductorMaterial = serviceMaterial == .copper ? .aluminum : .copper
        let wrongBands = NECTables.groundingElectrodeConductor(
            serviceSize: serviceSize, serviceMaterial: otherMaterial,
            gecMaterial: .copper, parallelSets: sets
        ) ?? fromTable
        let oneConductorOnly = NECTables.groundingElectrodeConductor(
            serviceSize: serviceSize, serviceMaterial: serviceMaterial,
            gecMaterial: .copper, parallelSets: 1
        ) ?? fromTable
        // What reaching for the EGC table produces: read 250.122 from the
        // breaker a service that size would carry.
        let serviceAmps = NECTables.ampacity(size: serviceSize, material: serviceMaterial, column: .c75) ?? 100
        let fromEGCTable = NECTables.equipmentGroundingConductor(
            ocpd: (NECTables.nextStandardOCPD(atMost: Double(serviceAmps * sets)) ?? 100),
            material: .copper
        ) ?? answer

        let gecDistractors = [fromEGCTable, fromTable, wrongBands, oneConductorOnly].shuffled(using: &rng)
        let choices = uniqueChoices(
            from: [answer] + gecDistractors,
            answer: answer,
            using: &rng,
            pad: { size in
                let all = NECTables.conductorSizes
                let index = all.firstIndex(of: size) ?? 0
                let offset = Int.random(in: 1...3, using: &padRNG) * (Bool.random(using: &padRNG) ? 1 : -1)
                return all[min(max(index + offset, 0), all.count - 1)]
            },
            format: { $0 }
        )

        var steps: [String] = []
        if sets > 1 {
            steps.append("Parallel sets are read on the equivalent area of the whole set, not on one conductor: \(sets) × \(serviceSize).")
        }
        steps.append("Table 250.66 is entered on the largest ungrounded SERVICE conductor, and the \(serviceMaterial.displayName.lowercased()) service bands are their own set of rows.")
        steps.append("Those bands call for \(fromTable) copper.")
        if answer != fromTable {
            steps.append("\(electrode.citation) then caps it: a \(electrode.displayName.lowercased()) electrode never requires more than \(electrode.copperCeiling ?? fromTable) copper, so the run to it is \(answer).")
        } else if let ceiling = electrode.copperCeiling {
            steps.append("\(electrode.citation) caps a \(electrode.displayName.lowercased()) electrode at \(ceiling) copper, and the table value is already at or below that, so \(answer) stands.")
        } else {
            steps.append("A metal water pipe electrode has no ceiling of its own, so the table value stands: \(answer).")
        }

        let mistakes = mistakeMap(answerLabel: answer, choices: choices.labels, [
            (fromEGCTable, CandidateMistake.usedEGCTableForGEC),
            (fromTable, CandidateMistake.gecIgnoredElectrodeCeiling),
            (wrongBands, CandidateMistake.gecWrongServiceColumn),
            (oneConductorOnly, CandidateMistake.gecMissedParallelSet),
        ])

        var givens: [Given] = [
            Given("Service conductor", sets > 1 ? "\(sets) × \(serviceSize)" : serviceSize),
            .material(serviceMaterial),
            Given("Electrode", electrode.displayName),
        ]
        givens.append(Given("Electrode conductor", "Copper"))

        return CalcScenario(
            id: "gen-gecSizing-\(UUID().uuidString)",
            situation: "What is the minimum size copper grounding electrode conductor for this service?",
            givens: givens,
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "250.66, Table 250.66, \(electrode.citation)",
            mistakes: mistakes
        )
    }
}
