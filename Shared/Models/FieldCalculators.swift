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
    }

    /// Any two of V, I, R, P determine the other two. Zero or a single input
    /// is not a circuit.
    static func ohmsLaw(volts: Double?, amps: Double?, ohms: Double?, watts: Double?) -> OhmsLawResult? {
        func valid(_ value: Double?) -> Double? {
            guard let value, value > 0, value.isFinite else { return nil }
            return value
        }
        let v = valid(volts)
        let i = valid(amps)
        let r = valid(ohms)
        let p = valid(watts)

        switch (v, i, r, p) {
        case let (v?, i?, _, _):
            return OhmsLawResult(volts: v, amps: i, ohms: v / i, watts: v * i)
        case let (v?, _, r?, _):
            return OhmsLawResult(volts: v, amps: v / r, ohms: r, watts: v * v / r)
        case let (_, i?, r?, _):
            return OhmsLawResult(volts: i * r, amps: i, ohms: r, watts: i * i * r)
        case let (v?, _, _, p?):
            let i = p / v
            return OhmsLawResult(volts: v, amps: i, ohms: v / i, watts: p)
        case let (_, i?, _, p?):
            let v = p / i
            return OhmsLawResult(volts: v, amps: i, ohms: v / i, watts: p)
        case let (_, _, r?, p?):
            let v = sqrt(p * r)
            return OhmsLawResult(volts: v, amps: v / r, ohms: r, watts: p)
        default:
            return nil
        }
    }
}
