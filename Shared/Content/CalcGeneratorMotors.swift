import Foundation

/// Motor circuits, generated.
///
/// Article 430 is the one place in the code where the nameplate is not the
/// number you calculate from, and that reversal is the whole exam question.
/// Conductors and short-circuit protection come off Table 430.248 or 430.250;
/// only the overload device comes off the nameplate. A candidate who has spent
/// six months sizing branch circuits from the actual load walks into that
/// backwards, every time, which is why both shapes below offer the nameplate
/// answer as a distractor and name it.
///
/// The second reversal is rounding. Everywhere else in the book the protective
/// device goes to the largest standard rating at or BELOW the calculated value.
/// 430.52(C)(1) Exception 1 goes the other way: where the percentage does not
/// land on a standard rating, you go up. Bringing the 240.6 habit here is the
/// second named mistake.
extension CandidateMistake {
    static let motorUsedNameplateForConductors = MistakePattern(
        id: "motor-nameplate-for-conductors",
        skill: PracticeSkill.motorConductor.rawValue,
        summary: "You sized from the nameplate current. Branch-circuit conductors come off the full-load current in Table 430.248 or 430.250, whatever the nameplate says. The nameplate is only used for the overload device."
    )
    static let motorForgot125 = MistakePattern(
        id: "motor-forgot-125",
        skill: PracticeSkill.motorConductor.rawValue,
        summary: "You used the full-load current straight. 430.22 puts branch-circuit conductors for a single continuous-duty motor at 125% of it."
    )
    static let motorWrongVoltageRow = MistakePattern(
        id: "motor-wrong-voltage-row",
        skill: PracticeSkill.motorConductor.rawValue,
        summary: "You read the wrong voltage column. The same horsepower draws roughly half the current at twice the voltage, so picking the wrong column is a 2x error, not a rounding one."
    )

    static let motorRoundedOCPDDown = MistakePattern(
        id: "motor-rounded-ocpd-down",
        skill: PracticeSkill.motorProtection.rawValue,
        summary: "You rounded down to the next standard rating. Motor branch-circuit protection is the exception: 430.52(C)(1) Exception 1 lets you go UP to the next standard size when the percentage does not land on one, because the device has to survive starting current."
    )
    static let motorWrongDevicePercent = MistakePattern(
        id: "motor-wrong-device-percent",
        skill: PracticeSkill.motorProtection.rawValue,
        summary: "You used another device's percentage. Table 430.52 gives each type its own ceiling: 300% for a nontime-delay fuse, 175% for a dual-element fuse, 250% for an inverse-time breaker, 800% for an instantaneous-trip breaker."
    )
    static let motorUsedOverloadPercent = MistakePattern(
        id: "motor-used-overload-percent",
        skill: PracticeSkill.motorProtection.rawValue,
        summary: "That is an overload calculation, not short-circuit protection. The two are separate devices with separate rules: overload runs at 115% or 125% of the NAMEPLATE, while the branch-circuit device runs at the Table 430.52 percentage of the TABLE current."
    )
}

extension CalcGenerator {

    /// A motor drawn from the tables, with a nameplate current that is
    /// deliberately close to but not equal to the table value.
    ///
    /// The gap is the point. A nameplate that matched the table would make
    /// "used the nameplate" indistinguishable from the right answer, and the
    /// whole shape would stop teaching the one thing it exists to teach.
    private struct GeneratedMotor {
        let rating: NECTables.MotorRating
        let supply: NECTables.MotorSupply
        let tableFLC: Double
        let nameplateFLA: Double
    }

    private static func rollMotor(using rng: inout RandomNumberGenerator) -> GeneratedMotor? {
        let supply = NECTables.MotorSupply.allCases.randomElement(using: &rng)!
        let ratings = NECTables.motorRatings(for: supply)
        guard let rating = ratings.randomElement(using: &rng),
              let flc = NECTables.motorFLC(hp: rating.label, supply: supply)
        else { return nil }
        // Between 8% and 22% off the table value, either way, rounded to a
        // tenth the way a nameplate prints it.
        let drift = Double.random(in: 0.08...0.22, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
        let nameplate = ((flc * (1 + drift)) * 10).rounded() / 10
        guard nameplate > 0, abs(nameplate - flc) > 0.05 else { return nil }
        return GeneratedMotor(rating: rating, supply: supply, tableFLC: flc, nameplateFLA: nameplate)
    }

    // MARK: - Branch-circuit conductors, 430.22

    static func motorConductorProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        var padRNG: RandomNumberGenerator = SeededGenerator(seed: rng.next())
        guard let motor = rollMotor(using: &rng) else { return ampacityProblem(using: &rng) }

        let answer = motor.tableFLC * NECTables.motorConductorFactor
        let fromNameplate = motor.nameplateFLA * NECTables.motorConductorFactor
        let forgot125 = motor.tableFLC
        // The other column of the same table row, which is what a misread of
        // the voltage produces.
        let otherSupply = NECTables.MotorSupply.allCases.first {
            $0 != motor.supply && $0.phase == motor.supply.phase
                && NECTables.motorFLC(hp: motor.rating.label, supply: $0) != nil
        }
        let wrongRow = otherSupply
            .flatMap { NECTables.motorFLC(hp: motor.rating.label, supply: $0) }
            .map { $0 * NECTables.motorConductorFactor } ?? answer

        let format: (Double) -> String = { "\($0.roundedAmpsText) A" }
        let choices = uniqueChoices(
            from: [answer, fromNameplate, forgot125, wrongRow],
            answer: answer,
            using: &rng,
            pad: { $0 * Double.random(in: 0.75...1.3, using: &padRNG) },
            format: format
        )

        let steps = [
            "The nameplate is not the number here. Branch-circuit conductors for a single motor are sized from the full-load current in Table \(motor.supply.phase == .single ? "430.248" : "430.250"), which for a \(motor.rating.label) motor at \(motor.supply.displayName) is \(motor.tableFLC.factorText) A.",
            "430.22 puts the conductors at 125% of that: \(motor.tableFLC.factorText) × 1.25 = \(answer.roundedAmpsText) A.",
            "That \(answer.roundedAmpsText) A is the minimum ampacity the conductors must have after any correction and adjustment, which is then read back into Table 310.16.",
            "The nameplate \(motor.nameplateFLA.factorText) A is still used, but only for the separate overload device under 430.32.",
        ]

        let mistakes = mistakeMap(answerLabel: format(answer), choices: choices.labels, [
            (format(fromNameplate), CandidateMistake.motorUsedNameplateForConductors),
            (format(forgot125), CandidateMistake.motorForgot125),
            (format(wrongRow), CandidateMistake.motorWrongVoltageRow),
        ])

        return CalcScenario(
            id: "gen-motorConductor-\(UUID().uuidString)",
            situation: "What minimum ampacity must the branch-circuit conductors for this single continuous-duty motor have?",
            givens: [
                Given("Motor", motor.rating.label),
                Given("Supply", motor.supply.displayName),
                Given("Nameplate", motor.nameplateFLA.factorText, unit: "A"),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "430.22, \(motor.supply.citation), 430.6(A)(1)",
            mistakes: mistakes
        )
    }

    // MARK: - Branch-circuit short-circuit protection, 430.52

    static func motorProtectionProblem(using rng: inout RandomNumberGenerator) -> CalcScenario {
        var padRNG: RandomNumberGenerator = SeededGenerator(seed: rng.next())
        guard let motor = rollMotor(using: &rng) else { return ocpdProblem(using: &rng) }
        let protection = NECTables.MotorProtection.allCases.randomElement(using: &rng)!

        let calculated = motor.tableFLC * protection.percent
        guard let answer = NECTables.motorBranchOCPD(flc: motor.tableFLC, protection: protection),
              let roundedDown = NECTables.nextStandardOCPD(atMost: calculated)
        else { return ocpdProblem(using: &rng) }

        let otherDevice = NECTables.MotorProtection.allCases.first { $0 != protection }!
        let wrongPercent = NECTables.motorBranchOCPD(flc: motor.tableFLC, protection: otherDevice) ?? answer
        let overloadNumber = NECTables.nextStandardOCPD(
            atLeast: NECTables.motorOverloadTrip(nameplateFLA: motor.nameplateFLA, serviceFactor: 1.15, tempRiseC: nil)
        ) ?? answer

        let format: (Double) -> String = { "\(Int($0)) A" }
        let choices = uniqueChoices(
            from: [Double(answer), Double(roundedDown), Double(wrongPercent), Double(overloadNumber)],
            answer: Double(answer),
            using: &rng,
            pad: { value in
                let index = NECTables.standardOCPD.firstIndex { Double($0) >= value } ?? 0
                let offset = Int.random(in: 1...3, using: &padRNG) * (Bool.random(using: &padRNG) ? 1 : -1)
                let clamped = min(max(index + offset, 0), NECTables.standardOCPD.count - 1)
                return Double(NECTables.standardOCPD[clamped])
            },
            format: format
        )

        var steps = [
            "Short-circuit and ground-fault protection is sized from the TABLE full-load current, not the nameplate: \(motor.rating.label) at \(motor.supply.displayName) is \(motor.tableFLC.factorText) A in Table \(motor.supply.phase == .single ? "430.248" : "430.250").",
            "Table 430.52 allows a \(protection.displayName.lowercased()) up to \(protection.percentLabel) of that: \(motor.tableFLC.factorText) × \(protection.percent.factorText) = \(calculated.roundedAmpsText) A.",
        ]
        if Double(answer) > calculated {
            steps.append("\(calculated.roundedAmpsText) A is not a standard rating. This is the one calculation in the book that rounds UP: 430.52(C)(1) Exception 1 permits the next standard size, so \(answer) A.")
        } else {
            steps.append("\(calculated.roundedAmpsText) A is itself a standard rating in 240.6(A), so \(answer) A is the answer with no rounding needed.")
        }
        steps.append("This device does not protect against overload. That is a separate device sized from the nameplate \(motor.nameplateFLA.factorText) A under 430.32.")

        let mistakes = mistakeMap(answerLabel: format(Double(answer)), choices: choices.labels, [
            (format(Double(roundedDown)), CandidateMistake.motorRoundedOCPDDown),
            (format(Double(wrongPercent)), CandidateMistake.motorWrongDevicePercent),
            (format(Double(overloadNumber)), CandidateMistake.motorUsedOverloadPercent),
        ])

        return CalcScenario(
            id: "gen-motorProtection-\(UUID().uuidString)",
            situation: "What is the largest standard device permitted for branch-circuit short-circuit and ground-fault protection of this motor?",
            givens: [
                Given("Motor", motor.rating.label),
                Given("Supply", motor.supply.displayName),
                Given("Nameplate", motor.nameplateFLA.factorText, unit: "A"),
                Given("Device", protection.displayName),
            ],
            choices: choices.labels,
            answerIndex: choices.answerIndex,
            steps: steps,
            citation: "430.52, Table 430.52, 430.52(C)(1) Ex. 1, 240.6(A)",
            mistakes: mistakes
        )
    }
}
