import Foundation

/// The dwelling-unit service calculation, generated.
///
/// This is the longest question on a journeyman paper and the one candidates
/// most often skip. It is worth doing anyway, and worth generating rather than
/// authoring, for the same reason the derating shape is: there are eight steps,
/// each step has its own way to go wrong, and a candidate needs to walk the
/// whole sequence enough times that the order stops being something they
/// reconstruct under time pressure.
///
/// Every distractor here is a whole step done wrong, not a slip of arithmetic.
extension CandidateMistake {
    static let loadForgotLightingDemand = MistakePattern(
        id: "load-forgot-lighting-demand",
        skill: PracticeSkill.dwellingLoad.rawValue,
        summary: "You carried the general lighting at 100%. Only the first 3000 VA stays whole; the rest of it up to 120,000 VA comes in at 35%. That demand factor is most of the difference between a 200 A service and a 400 A one."
    )
    static let loadForgotSmallAppliance = MistakePattern(
        id: "load-forgot-small-appliance",
        skill: PracticeSkill.dwellingLoad.rawValue,
        summary: "You left out the small-appliance and laundry circuits. A dwelling carries two 1500 VA small-appliance circuits and a 1500 VA laundry circuit, and they go INSIDE the general lighting total before the demand factor, not after it."
    )
    static let loadUsedRangeNameplate = MistakePattern(
        id: "load-used-range-nameplate",
        skill: PracticeSkill.dwellingLoad.rawValue,
        summary: "You used the range nameplate. A household range has its own demand table: one range not over 12 kW is taken at 8 kW, however big the nameplate says it is."
    )
    static let loadAddedHeatAndCooling = MistakePattern(
        id: "load-added-heat-and-cooling",
        skill: PracticeSkill.dwellingLoad.rawValue,
        summary: "You added the heating and the air conditioning together. 220.60 calls them noncoincident: they cannot run at once, so only the larger of the two goes into the calculation."
    )
    static let loadForgotApplianceDemand = MistakePattern(
        id: "load-forgot-appliance-demand",
        skill: PracticeSkill.dwellingLoad.rawValue,
        summary: "You carried the fastened-in-place appliances at 100%. Four or more of them on the same service come in at 75% under 220.53, and the range, dryer, heating and air conditioning are not part of that count."
    )
}

extension CalcGenerator {

    // MARK: - Dwelling service, standard method

    static func dwellingLoadProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        var padRNG: RandomNumberGenerator = SeededGenerator(seed: rng.next())

        let area = Double([1500, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 3400, 3800]
            .randomElement(using: &rng)!)
        let rangeKW = [8.0, 10.0, 12.0, 14.0, 16.0].randomElement(using: &rng)!
        let dryerNameplate = [4000.0, 4500.0, 5000.0, 5500.0, 6000.0, 7200.0].randomElement(using: &rng)!
        let waterHeater = [3500.0, 4500.0, 5500.0].randomElement(using: &rng)!
        let dishwasher = [1000.0, 1200.0, 1400.0].randomElement(using: &rng)!
        let disposal = [700.0, 900.0, 1000.0].randomElement(using: &rng)!
        let compactor = [800.0, 1000.0].randomElement(using: &rng)!
        let coolingVA = [4000.0, 5000.0, 6000.0, 7000.0].randomElement(using: &rng)!
        let heatingVA = [9000.0, 10000.0, 12000.0, 15000.0].randomElement(using: &rng)!

        // 1 to 3: general lighting, plus the circuits that live inside it.
        let lighting = area * NECTables.dwellingLightingVAPerSqFt
        let circuits = NECTables.smallApplianceCircuitVA * Double(NECTables.minimumSmallApplianceCircuits)
            + NECTables.laundryCircuitVA
        let generalTotal = lighting + circuits
        let generalDemand = NECTables.generalLightingDemand(totalVA: generalTotal)

        // 4: the range, off its own table.
        let rangeVA = (NECTables.rangeDemandKW(count: 1, eachKW: rangeKW) ?? 8) * 1000
        // 5: the dryer, at the greater of nameplate and 5000 VA.
        let dryerVA = max(dryerNameplate, NECTables.minimumDryerVA)
        // 6: four fastened-in-place appliances, so 220.53 applies.
        let appliances = [waterHeater, dishwasher, disposal, compactor]
        let applianceTotal = appliances.reduce(0, +)
        let applianceDemand = NECTables.fastenedApplianceDemand(totalVA: applianceTotal, count: appliances.count)
        // 7: heat against cooling, larger only.
        let climate = NECTables.noncoincident(coolingVA, heatingVA)

        let total = generalDemand + rangeVA + dryerVA + applianceDemand + climate
        let amps = NECTables.serviceAmps(va: total)
        guard let rating = NECTables.dwellingServiceRating(amps: amps) else {
            return ampacityProblem(using: &rng)
        }

        // Each alternative total is one whole step done the common wrong way.
        let noLightingDemandVA = generalTotal + rangeVA + dryerVA + applianceDemand + climate
        let noCircuitsVA = NECTables.generalLightingDemand(totalVA: lighting)
            + rangeVA + dryerVA + applianceDemand + climate
        let rangeAtNameplateVA = generalDemand + rangeKW * 1000 + dryerVA + applianceDemand + climate
        let bothClimateVA = generalDemand + rangeVA + dryerVA + applianceDemand + coolingVA + heatingVA
        let appliancesWholeVA = generalDemand + rangeVA + dryerVA + applianceTotal + climate

        // Half the problems ask for the calculated load, half for the service
        // size, and that is not variety for its own sake.
        //
        // The service-size form quantises: the standard ratings near a house
        // service are 25 A apart, which is 6000 VA, so a mistake worth less
        // than that lands on the same answer and cannot be offered. Skipping
        // the 220.53 appliance discount is exactly such a mistake, worth 25% of
        // maybe 8000 VA, so in the service form it is almost never a distinct
        // choice and the trap could never be set. Asking for the volt-amperes
        // separates every one of the five. Both forms are questions a real
        // paper asks, so the fix costs nothing.
        let asksForService = Bool.random(using: &rng)

        let answerValue: Double = asksForService ? Double(rating) : total.rounded()
        let alternatives: [Double] = [
            noLightingDemandVA, bothClimateVA, rangeAtNameplateVA, appliancesWholeVA, noCircuitsVA,
        ].map { asksForService
            ? Double(NECTables.dwellingServiceRating(amps: NECTables.serviceAmps(va: $0)) ?? rating)
            : $0.rounded()
        }

        // Five named mistakes and three distractor slots, so the order they are
        // offered in decides which ones a candidate ever gets to make. A fixed
        // order means the last two are effectively unreachable, and a mistake
        // the generator never sets a trap for is a mistake Fix My Mistakes can
        // never re-trap: `testTargetedPracticeSetsTheRequestedTrap` catches
        // exactly that. Shuffling from the problem's own stream keeps the whole
        // scenario reproducible while giving every mistake a fair share.
        let order = Array(alternatives.indices).shuffled(using: &rng)

        let format: (Double) -> String = { value in
            asksForService ? "\(Int(value)) A" : "\(Int(value).groupedText) VA"
        }
        let choices = uniqueChoices(
            from: [answerValue] + order.map { alternatives[$0] },
            answer: answerValue,
            using: &rng,
            pad: { value in
                guard asksForService else {
                    // Neighbouring totals, far enough apart to be legible as
                    // different answers rather than as rounding noise.
                    let step = Double(Int.random(in: 2...9, using: &padRNG)) * 500
                    return (value + (Bool.random(using: &padRNG) ? step : -step)).rounded()
                }
                let index = NECTables.standardOCPD.firstIndex { Double($0) >= value } ?? 0
                let offset = Int.random(in: 1...2, using: &padRNG) * (Bool.random(using: &padRNG) ? 1 : -1)
                let clamped = min(max(index + offset, 0), NECTables.standardOCPD.count - 1)
                return Double(max(NECTables.minimumDwellingServiceAmps, NECTables.standardOCPD[clamped]))
            },
            format: format
        )

        var steps = [
            "General lighting and general-use receptacles: \(Int(area)) ft² × 3 VA = \(Int(lighting).groupedText) VA.",
            "Add the circuits that belong inside that total: two small-appliance circuits at 1500 VA and one laundry circuit at 1500 VA, so \(Int(lighting).groupedText) + \(Int(circuits).groupedText) = \(Int(generalTotal).groupedText) VA.",
            "Apply the demand factor to that subtotal only: the first 3000 VA at 100%, the remaining \(Int(generalTotal - 3000).groupedText) VA at 35%, giving \(Int(generalDemand.rounded()).groupedText) VA.",
            "The range has its own table. \(rangeKW.factorText) kW\(rangeKW > 12 ? ", which is over 12 kW, so column C's 8 kW rises 5% per kW above 12" : " is not over 12 kW, so column C reads 8 kW flat"): \(Int(rangeVA).groupedText) VA.",
            "The dryer is the greater of its nameplate and 5000 VA: \(Int(dryerNameplate).groupedText) against 5000, so \(Int(dryerVA).groupedText) VA.",
            "Four fastened-in-place appliances (\(Int(waterHeater)) + \(Int(dishwasher)) + \(Int(disposal)) + \(Int(compactor)) = \(Int(applianceTotal).groupedText) VA) reach the four-appliance threshold, so 220.53 takes them at 75%: \(Int(applianceDemand.rounded()).groupedText) VA.",
            "Heat and air conditioning cannot run together, so 220.60 counts only the larger: \(Int(climate).groupedText) VA.",
            "Total \(Int(generalDemand.rounded()).groupedText) + \(Int(rangeVA).groupedText) + \(Int(dryerVA).groupedText) + \(Int(applianceDemand.rounded()).groupedText) + \(Int(climate).groupedText) = \(Int(total.rounded()).groupedText) VA.",
        ]
        if asksForService {
            steps.append("\(Int(total.rounded()).groupedText) VA ÷ 240 V = \(amps.roundedAmpsText) A, and the smallest standard rating that carries it is \(rating) A.")
        }

        let mistakes = mistakeMap(answerLabel: format(answerValue), choices: choices.labels, [
            (format(alternatives[0]), CandidateMistake.loadForgotLightingDemand),
            (format(alternatives[1]), CandidateMistake.loadAddedHeatAndCooling),
            (format(alternatives[2]), CandidateMistake.loadUsedRangeNameplate),
            (format(alternatives[3]), CandidateMistake.loadForgotApplianceDemand),
            (format(alternatives[4]), CandidateMistake.loadForgotSmallAppliance),
        ])

        return CalcScenario(
            id: "gen-dwellingLoad-\(UUID().uuidString)",
            situation: asksForService
                ? "Standard method, single-family dwelling on a 120/240 V single-phase service. What is the minimum standard service rating?"
                : "Standard method, single-family dwelling on a 120/240 V single-phase service. What is the calculated load?",
            givens: [
                Given("Floor area", "\(Int(area))", unit: "ft²"),
                Given("Range", rangeKW.factorText, unit: "kW"),
                Given("Dryer", "\(Int(dryerNameplate))", unit: "VA"),
                Given("Water heater", "\(Int(waterHeater))", unit: "VA"),
                Given("Dishwasher", "\(Int(dishwasher))", unit: "VA"),
                Given("Disposal", "\(Int(disposal))", unit: "VA"),
                Given("Compactor", "\(Int(compactor))", unit: "VA"),
                Given("Air conditioning", "\(Int(coolingVA))", unit: "VA"),
                Given("Electric heat", "\(Int(heatingVA))", unit: "VA"),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "220.41, Table 220.45, 220.52, 220.53, 220.54, Table 220.55, 220.60, 230.79(C)",
            mistakes: mistakes
        )
    }
}
