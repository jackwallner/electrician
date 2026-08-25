import Foundation

/// On-site calculators. Same tables as the exam drills, same legal posture:
/// numbers and citations, never code text. These exist so the app is still
/// useful the day after the licence arrives, which is the retention problem
/// a question bank cannot solve.
enum FieldCalculators {

    // MARK: - Ampacity

    struct AmpacityResult: Equatable {
        let tableAmps: Int
        let ambientFactor: Double
        let adjustment: Double
        let afterDerate: Double
        let terminationCap: Int
        let smallConductorCeiling: Int?
        /// min(derated, termination). This is what the conductor is good for.
        let allowable: Double
        /// min(allowable, 240.4(D) if it applies). This is the OCPD ceiling.
        let ocpdCeiling: Double
        let citation: String
    }

    /// Derate from the insulation column, then cap at the termination column,
    /// then apply 240.4(D) if the size has a small-conductor ceiling. That is
    /// the order the exam tests and the order a field check has to use.
    static func ampacity(
        size: String,
        material: ConductorMaterial,
        insulation: TemperatureRating,
        termination: TemperatureRating,
        ambientCelsius: Int,
        currentCarrying: Int
    ) -> AmpacityResult? {
        guard let table = NECTables.ampacity(size: size, material: material, column: insulation),
              let ambient = NECTables.ambientCorrection(celsius: ambientCelsius, column: insulation),
              let terminationCap = NECTables.ampacity(size: size, material: material, column: termination)
        else { return nil }

        let adjustment = NECTables.adjustmentFactor(currentCarrying: currentCarrying)
        let afterDerate = Double(table) * ambient * adjustment
        let allowable = min(afterDerate, Double(terminationCap))
        let ceiling = NECTables.smallConductorCeiling(size: size, material: material)
        let ocpdCeiling = ceiling.map { min(allowable, Double($0)) } ?? allowable

        return AmpacityResult(
            tableAmps: table,
            ambientFactor: ambient,
            adjustment: adjustment,
            afterDerate: afterDerate,
            terminationCap: terminationCap,
            smallConductorCeiling: ceiling,
            allowable: allowable,
            ocpdCeiling: ocpdCeiling,
            citation: "310.16, 310.15(B)(1), 310.15(C)(1), 110.14(C), 240.4(D)"
        )
    }

    // MARK: - Conduit fill

    struct ConduitFillResult: Equatable {
        let oneConductorArea: Double
        let bundleArea: Double
        let racewayArea: Double
        let allowedPercent: Double
        let allowedArea: Double
        let actualPercent: Double
        let fits: Bool
        let smallestFitting: String?
        let citation: String
    }

    static func conduitFill(
        conductorSize: String,
        count: Int,
        tradeSize: String
    ) -> ConduitFillResult? {
        guard count >= 1,
              let one = NECTables.thhnArea[conductorSize],
              let raceway = NECTables.emtArea[tradeSize]
        else { return nil }

        let allowedPercent = NECTables.fillPercent(conductorCount: count)
        let bundle = one * Double(count)
        let allowedArea = raceway * allowedPercent
        let smallest = NECTables.emtTradeSizes.first { trade in
            (NECTables.emtArea[trade] ?? 0) * allowedPercent + 0.0000001 >= bundle
        }

        return ConduitFillResult(
            oneConductorArea: one,
            bundleArea: bundle,
            racewayArea: raceway,
            allowedPercent: allowedPercent,
            allowedArea: allowedArea,
            actualPercent: bundle / raceway,
            fits: bundle <= allowedArea + 0.0000001,
            smallestFitting: smallest,
            citation: "Ch. 9 Table 1, Table 4, Table 5"
        )
    }

    // MARK: - Voltage drop

    struct VoltageDropResult: Equatable {
        let volts: Double
        let percent: Double
        let withinThreePercent: Bool
        let citation: String
        /// What this estimate leaves out, in the reader's own units.
        ///
        /// The formula is the resistive K/cmil approximation every exam asks
        /// for, and it is genuinely useful, but it is not a complete field
        /// sizing answer and the screen used to present it as one. Naming the
        /// omissions is the difference between a study estimate and a number
        /// someone pulls wire against.
        static let assumptions = [
            "Resistive only: reactance and power factor are not included.",
            "Conductor at its table resistance, not at operating temperature.",
            "Uncoated conductor in a non-magnetic raceway.",
            "One-way length doubled (or × 1.732) by the phase factor, not a measured circuit path.",
        ]
        /// The 3% figure is an informational note, not a general mandate, and
        /// reading it as an enforceable limit is a common exam-day error.
        static let threePercentNote = "3% is the figure the informational note suggests for a branch circuit. It is a recommendation, not a general requirement, though some jurisdictions do enforce it."
    }

    static func voltageDrop(
        size: String,
        material: ConductorMaterial,
        phase: Phase,
        systemVolts: Double,
        amps: Double,
        oneWayFeet: Double
    ) -> VoltageDropResult? {
        guard systemVolts > 0, amps > 0, oneWayFeet > 0,
              let cmil = NECTables.circularMils[size]
        else { return nil }

        let drop = phase.voltageDropFactor * material.voltageDropK * amps * oneWayFeet / cmil
        let percent = drop / systemVolts * 100
        return VoltageDropResult(
            volts: drop,
            percent: percent,
            withinThreePercent: percent <= 3.0001,
            citation: "210.19(A) Informational Note, Ch. 9 Table 8"
        )
    }

    // MARK: - Ohm's law

    struct OhmsLawResult: Equatable {
        let volts: Double
        let amps: Double
        let ohms: Double
        let watts: Double
        /// The two inputs the answer was actually computed from, e.g. "V and I".
        /// Stated because the tool no longer silently picks a pair.
        let basis: String
        /// Supplied values that do not agree with the computed circuit, named.
        /// Empty when everything the user typed is consistent.
        let conflicts: [String]

        var isConsistent: Bool { conflicts.isEmpty }
    }

    /// Any two of V, I, R, P determine the other two. Zero or a single input
    /// is not a circuit.
    ///
    /// The tool used to take the first matching pair and quietly ignore
    /// everything else, so typing 120 V, 10 A and 5 Ω returned a confident
    /// answer computed from the first two with no hint that the third value
    /// described a different circuit. For an electrician audience that is worse
    /// than an error: it looks like the app checked the work. Extra inputs are
    /// now checked against the result and reported by name.
    static func ohmsLaw(volts: Double?, amps: Double?, ohms: Double?, watts: Double?) -> OhmsLawResult? {
        func valid(_ value: Double?) -> Double? {
            guard let value, value > 0, value.isFinite else { return nil }
            return value
        }
        let v = valid(volts)
        let i = valid(amps)
        let r = valid(ohms)
        let p = valid(watts)

        let solved: (volts: Double, amps: Double, ohms: Double, watts: Double, basis: String)
        switch (v, i, r, p) {
        case let (v?, i?, _, _):
            solved = (v, i, v / i, v * i, "V and I")
        case let (v?, _, r?, _):
            solved = (v, v / r, r, v * v / r, "V and R")
        case let (_, i?, r?, _):
            solved = (i * r, i, r, i * i * r, "I and R")
        case let (v?, _, _, p?):
            solved = (v, p / v, v * v / p, p, "V and P")
        case let (_, i?, _, p?):
            solved = (p / i, i, p / (i * i), p, "I and P")
        case let (_, _, r?, p?):
            let volts = sqrt(p * r)
            solved = (volts, volts / r, r, p, "R and P")
        default:
            return nil
        }

        // 1% covers rounding and the two-decimal values people actually type
        // without waving through a genuinely different circuit.
        func disagrees(_ supplied: Double?, _ computed: Double) -> Bool {
            guard let supplied, computed > 0 else { return false }
            return abs(supplied - computed) / computed > 0.01
        }

        var conflicts: [String] = []
        if disagrees(v, solved.volts) { conflicts.append("V") }
        if disagrees(i, solved.amps) { conflicts.append("I") }
        if disagrees(r, solved.ohms) { conflicts.append("R") }
        if disagrees(p, solved.watts) { conflicts.append("P") }

        return OhmsLawResult(
            volts: solved.volts,
            amps: solved.amps,
            ohms: solved.ohms,
            watts: solved.watts,
            basis: solved.basis,
            conflicts: conflicts
        )
    }
}
