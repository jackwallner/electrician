import Foundation

/// Article 220: the dwelling-unit service and feeder calculation.
///
/// This is the biggest single block of exam points the app did not previously
/// cover. A journeyman paper almost always carries at least one full dwelling
/// calculation, and it is worth several ordinary questions because it takes
/// several minutes. It is also the shape candidates most often abandon, because
/// it is the only question on the paper that has eight steps rather than three.
///
/// Numbers and article references only, as everywhere else here. The article
/// numbering below is the 2023 arrangement, where Article 220 was reorganised
/// and several sections moved: general lighting is 220.41 and the general
/// lighting demand table is 220.45, where a 2020 book puts them at 220.12 and
/// 220.42. The VALUES did not change, so both citations are given wherever a
/// candidate on an older cycle would otherwise be sent to the wrong page.
extension NECTables {

    // MARK: - Unit loads

    /// Dwelling-unit general lighting and general-use receptacle load, in
    /// volt-amperes per square foot of floor area computed from the outside
    /// dimensions. 220.41 (220.12 in a 2020 book).
    static let dwellingLightingVAPerSqFt = 3.0

    /// Each 20 A small-appliance branch circuit, 220.52(A). A dwelling has at
    /// least two, and the calculation counts circuits, not receptacles.
    static let smallApplianceCircuitVA = 1500.0
    static let minimumSmallApplianceCircuits = 2

    /// The laundry branch circuit, 220.52(B).
    static let laundryCircuitVA = 1500.0

    /// 220.54: an electric clothes dryer is 5000 VA or the nameplate, whichever
    /// is larger. The "whichever is larger" is the half people drop.
    static let minimumDryerVA = 5000.0

    /// Citation strings, kept in one place so a renumbering between cycles is a
    /// one-line change rather than a hunt through the content files.
    enum LoadCitation {
        static let generalLighting = "220.41 (220.12 in 2020)"
        static let lightingDemand = "Table 220.45 (Table 220.42 in 2020)"
        static let smallAppliance = "220.52"
        static let applianceDemand = "220.53"
        static let dryer = "220.54"
        static let range = "Table 220.55"
        static let heatingVsCooling = "220.60"
        static let optionalMethod = "220.82"
        static let neutral = "220.61"
    }

    // MARK: - General lighting demand, Table 220.45

    /// The demand bands applied to the general lighting, small-appliance and
    /// laundry total for a dwelling. First 3000 VA at 100%, the next block to
    /// 120,000 VA at 35%, anything above that at 25%.
    ///
    /// Only these three loads go through this table. Dropping the dryer or the
    /// range into it, or forgetting the small-appliance and laundry circuits
    /// are inside it rather than added after, are the two named mistakes this
    /// content traps.
    static func generalLightingDemand(totalVA: Double) -> Double {
        var remaining = totalVA
        var demand = 0.0

        let firstBand = min(remaining, 3000)
        demand += firstBand
        remaining -= firstBand

        let secondBand = min(remaining, 117_000)
        demand += secondBand * 0.35
        remaining -= secondBand

        demand += remaining * 0.25
        return demand
    }

    // MARK: - Ranges, Table 220.55

    /// Column C of Table 220.55, the maximum demand for household electric
    /// ranges over 1.75 kW, keyed by the number of appliances. Values in kW.
    ///
    /// This covers the case the exam asks about: ranges each rated not over
    /// 12 kW. A range over 12 kW raises the column C figure by 5% per kW (or
    /// major fraction) above 12, which `rangeDemandKW` applies.
    static let rangeColumnC: [Int: Double] = [
        1: 8, 2: 11, 3: 14, 4: 17, 5: 20, 6: 21, 7: 22, 8: 23, 9: 24, 10: 25,
        11: 26, 12: 27, 13: 28, 14: 29, 15: 30, 16: 31, 17: 32, 18: 33,
        19: 34, 20: 35, 21: 36, 22: 37, 23: 38, 24: 39, 25: 40,
    ]

    /// Demand for a group of identical household ranges, in kW.
    ///
    /// - Parameters:
    ///   - count: how many ranges.
    ///   - eachKW: the nameplate rating of one range.
    static func rangeDemandKW(count: Int, eachKW: Double) -> Double? {
        guard count >= 1, let base = rangeColumnC[count] else { return nil }
        guard eachKW > 12 else { return base }
        // 5% increase per kW or major fraction above 12 kW.
        let over = eachKW - 12
        let steps = (over - over.rounded(.down)) >= 0.5
            ? over.rounded(.down) + 1
            : over.rounded(.down)
        return base * (1 + 0.05 * max(0, steps))
    }

    // MARK: - Fastened-in-place appliances, 220.53

    /// Four or more fastened-in-place appliances on the same feeder or service,
    /// other than the ranges, dryers, space heating and air conditioning that
    /// have their own rules, may be taken at 75%.
    ///
    /// "Four or more" is a count of appliances, not of circuits, and the
    /// excluded categories are the trap: a candidate who counts the range and
    /// the dryer into this group reaches four early and discounts loads that
    /// should have stayed at 100%.
    static func fastenedApplianceDemand(totalVA: Double, count: Int) -> Double {
        count >= 4 ? totalVA * 0.75 : totalVA
    }

    // MARK: - Heating against cooling, 220.60

    /// Noncoincident loads: where two loads cannot run at the same time, only
    /// the larger goes into the calculation. Electric heat and air conditioning
    /// are the pair the exam always uses.
    static func noncoincident(_ a: Double, _ b: Double) -> Double { max(a, b) }

    // MARK: - Service size

    /// The service or feeder current for a computed volt-ampere load.
    static func serviceAmps(va: Double, volts: Double = 240, phase: Phase = .single) -> Double {
        switch phase {
        case .single: return va / volts
        case .three: return va / (volts * 1.732)
        }
    }

    /// Dwelling services have their own floor: 230.79(C) puts a one-family
    /// dwelling's service disconnect at 100 A minimum, so a small house that
    /// calculates to 71 A is still a 100 A service.
    static let minimumDwellingServiceAmps = 100

    /// The service rating for a computed load, honouring the dwelling minimum.
    static func dwellingServiceRating(amps: Double) -> Int? {
        guard let standard = nextStandardOCPD(atLeast: amps) else { return nil }
        return max(standard, minimumDwellingServiceAmps)
    }

    // MARK: - Optional method, 220.82

    /// The optional calculation for a one-family dwelling served by a single
    /// 120/240 V set of 100 A or larger conductors: the general loads take
    /// the first 10 kVA at 100% and the remainder at 40%, then the heating or
    /// air-conditioning load is added separately at its own percentage.
    ///
    /// It usually produces a smaller service than the standard method, which is
    /// exactly why an exam question naming the optional method and then being
    /// answered with the standard one is a wrong answer rather than a
    /// conservative one.
    static func optionalMethodGeneralLoad(totalVA: Double) -> Double {
        let first = min(totalVA, 10_000)
        return first + max(0, totalVA - 10_000) * 0.40
    }

    /// 220.82(C), the largest of the six air-conditioning and heating cases the
    /// exam actually uses. Central air conditioning at 100%, or electric space
    /// heat at 65% for fewer than four separately controlled units and 40% for
    /// four or more.
    static func optionalMethodHVAC(coolingVA: Double, heatingVA: Double, heatingUnits: Int) -> Double {
        let heatFactor = heatingUnits >= 4 ? 0.40 : 0.65
        return max(coolingVA, heatingVA * heatFactor)
    }
}
