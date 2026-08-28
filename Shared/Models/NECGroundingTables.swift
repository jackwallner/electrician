import Foundation

/// Grounding and bonding conductor sizing: Table 250.66 and Table 250.122.
///
/// Same legal posture as the rest of `NECTables`: these are the numbers, which
/// are facts, and the article numbers, which are citations. No code text.
///
/// These two tables are here because they are the highest-yield pages in the
/// most-failed article on the exam, and because candidates confuse them with
/// each other more than they confuse anything else in the book. One is sized
/// from the SERVICE conductor, the other from the OVERCURRENT DEVICE, and
/// picking the wrong table is the single named mistake this content exists to
/// trap.
extension NECTables {

    // MARK: - Grounding electrode conductor, Table 250.66

    /// One row of Table 250.66, expressed the way the table reads: the largest
    /// ungrounded service conductor (or equivalent for parallel sets), in
    /// circular mils, and the electrode conductor it calls for.
    struct GECRow: Sendable {
        /// Upper bound of the service-conductor band, in circular mils.
        let serviceUpTo: Double
        let copper: String
        let aluminum: String
    }

    /// The copper-service rows. Bands are read as "up to and including".
    static let gecCopperService: [GECRow] = [
        // 2 AWG and smaller
        GECRow(serviceUpTo: 66360, copper: "8 AWG", aluminum: "6 AWG"),
        // 1 or 1/0
        GECRow(serviceUpTo: 105600, copper: "6 AWG", aluminum: "4 AWG"),
        // 2/0 or 3/0
        GECRow(serviceUpTo: 167800, copper: "4 AWG", aluminum: "2 AWG"),
        // over 3/0 through 350 kcmil
        GECRow(serviceUpTo: 350000, copper: "2 AWG", aluminum: "1/0 AWG"),
        // over 350 through 600 kcmil
        GECRow(serviceUpTo: 600000, copper: "1/0 AWG", aluminum: "3/0 AWG"),
        // over 600 through 1100 kcmil
        GECRow(serviceUpTo: 1_100_000, copper: "2/0 AWG", aluminum: "4/0 AWG"),
        // over 1100 kcmil
        GECRow(serviceUpTo: .greatestFiniteMagnitude, copper: "3/0 AWG", aluminum: "250 kcmil"),
    ]

    /// The aluminum-service rows. The bands are NOT the copper bands: an
    /// aluminum service is larger for the same load, so the table shifts, and
    /// reading the copper column for an aluminum service is a real exam trap.
    static let gecAluminumService: [GECRow] = [
        // 1/0 and smaller
        GECRow(serviceUpTo: 105600, copper: "8 AWG", aluminum: "6 AWG"),
        // 2/0 or 3/0
        GECRow(serviceUpTo: 167800, copper: "6 AWG", aluminum: "4 AWG"),
        // 4/0 or 250 kcmil
        GECRow(serviceUpTo: 250000, copper: "4 AWG", aluminum: "2 AWG"),
        // over 250 through 500 kcmil
        GECRow(serviceUpTo: 500000, copper: "2 AWG", aluminum: "1/0 AWG"),
        // over 500 through 900 kcmil
        GECRow(serviceUpTo: 900000, copper: "1/0 AWG", aluminum: "3/0 AWG"),
        // over 900 through 1750 kcmil
        GECRow(serviceUpTo: 1_750_000, copper: "2/0 AWG", aluminum: "4/0 AWG"),
        // over 1750 kcmil
        GECRow(serviceUpTo: .greatestFiniteMagnitude, copper: "3/0 AWG", aluminum: "250 kcmil"),
    ]

    /// Circular mils for every size these tables can name, including the ones
    /// too large to appear in the ampacity table this app drills.
    static let circularMilsExtended: [String: Double] = {
        var mils = circularMils
        mils["600 kcmil"] = 600_000
        mils["700 kcmil"] = 700_000
        mils["750 kcmil"] = 750_000
        mils["800 kcmil"] = 800_000
        mils["900 kcmil"] = 900_000
        mils["1000 kcmil"] = 1_000_000
        mils["1100 kcmil"] = 1_100_000
        mils["1200 kcmil"] = 1_200_000
        mils["1750 kcmil"] = 1_750_000
        return mils
    }()

    /// The grounding electrode conductor for a service, from Table 250.66.
    ///
    /// - Parameters:
    ///   - serviceSize: the largest ungrounded service conductor.
    ///   - serviceMaterial: which column of the table to read down.
    ///   - gecMaterial: the metal the electrode conductor itself will be.
    ///   - parallelSets: sets in parallel. The table is read on the EQUIVALENT
    ///     area of the whole set, not on one conductor of it, which is the
    ///     other way this table is commonly misread.
    static func groundingElectrodeConductor(
        serviceSize: String,
        serviceMaterial: ConductorMaterial,
        gecMaterial: ConductorMaterial,
        parallelSets: Int = 1
    ) -> String? {
        guard let one = circularMilsExtended[serviceSize], parallelSets >= 1 else { return nil }
        let equivalent = one * Double(parallelSets)
        let rows = serviceMaterial == .copper ? gecCopperService : gecAluminumService
        guard let row = rows.first(where: { equivalent <= $0.serviceUpTo + 0.5 }) else { return nil }
        return gecMaterial == .copper ? row.copper : row.aluminum
    }

    /// The ceilings that override the table when the electrode is one of the
    /// three that cannot use more. 250.66(A), (B) and (C): a rod, pipe or
    /// plate electrode never needs more than 6 AWG copper, a concrete-encased
    /// electrode never more than 4 AWG copper, and a ground ring never more
    /// than the size of the ring conductor itself (2 AWG minimum).
    ///
    /// This is the part candidates skip: they read the table, get 2/0, and miss
    /// that the run to the rod stops at 6 AWG.
    enum ElectrodeType: String, CaseIterable, Identifiable, Sendable {
        case rodPipePlate
        case concreteEncased
        case groundRing
        case waterPipe

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .rodPipePlate: return "Rod, pipe or plate"
            case .concreteEncased: return "Concrete-encased"
            case .groundRing: return "Ground ring"
            case .waterPipe: return "Metal water pipe"
            }
        }

        /// The largest copper conductor this electrode can require, or nil when
        /// the table governs with no ceiling.
        var copperCeiling: String? {
            switch self {
            case .rodPipePlate: return "6 AWG"
            case .concreteEncased: return "4 AWG"
            case .groundRing: return "2 AWG"
            case .waterPipe: return nil
            }
        }

        var citation: String {
            switch self {
            case .rodPipePlate: return "250.66(A)"
            case .concreteEncased: return "250.66(B)"
            case .groundRing: return "250.66(C)"
            case .waterPipe: return "250.66"
            }
        }
    }

    /// The GEC after the electrode ceiling is applied. Returns the table value
    /// and the value actually required, so an explanation can show both.
    static func groundingElectrodeConductor(
        serviceSize: String,
        serviceMaterial: ConductorMaterial,
        electrode: ElectrodeType
    ) -> (fromTable: String, required: String)? {
        guard let table = groundingElectrodeConductor(
            serviceSize: serviceSize,
            serviceMaterial: serviceMaterial,
            gecMaterial: .copper
        ) else { return nil }
        guard let ceiling = electrode.copperCeiling,
              let ceilingMils = circularMilsExtended[ceiling],
              let tableMils = circularMilsExtended[table],
              tableMils > ceilingMils
        else { return (table, table) }
        return (table, ceiling)
    }

    // MARK: - Equipment grounding conductor, Table 250.122

    /// Table 250.122, keyed by the rating of the overcurrent device ahead of
    /// the circuit. Read UP to the next row when a rating falls between two:
    /// the table is a set of "not exceeding" bands, not a lookup of exact
    /// breaker sizes, and treating a 45 A breaker as unlisted is the second
    /// most common way this table is misread.
    ///
    /// The 30 A and 40 A rows people remember from an older book are gone; a
    /// 30 A circuit reads the 60 A row and takes 10 AWG copper.
    static let egcRows: [(ocpdUpTo: Int, copper: String, aluminum: String)] = [
        (15, "14 AWG", "12 AWG"),
        (20, "12 AWG", "10 AWG"),
        (60, "10 AWG", "8 AWG"),
        (100, "8 AWG", "6 AWG"),
        (200, "6 AWG", "4 AWG"),
        (300, "4 AWG", "2 AWG"),
        (400, "3 AWG", "1 AWG"),
        (500, "2 AWG", "1/0 AWG"),
        (600, "1 AWG", "2/0 AWG"),
        (800, "1/0 AWG", "3/0 AWG"),
        (1000, "2/0 AWG", "4/0 AWG"),
        (1200, "3/0 AWG", "250 kcmil"),
        (1600, "4/0 AWG", "350 kcmil"),
        (2000, "250 kcmil", "400 kcmil"),
        (2500, "350 kcmil", "600 kcmil"),
        (3000, "400 kcmil", "600 kcmil"),
        (4000, "500 kcmil", "750 kcmil"),
        (5000, "700 kcmil", "1200 kcmil"),
        (6000, "800 kcmil", "1200 kcmil"),
    ]

    /// The equipment grounding conductor for a circuit protected at `ocpd`.
    static func equipmentGroundingConductor(ocpd: Int, material: ConductorMaterial) -> String? {
        guard let row = egcRows.first(where: { ocpd <= $0.ocpdUpTo }) else { return nil }
        return material == .copper ? row.copper : row.aluminum
    }

    /// The EGC row a rating lands in, for an explanation that can say "45 A
    /// reads the 60 A row" instead of just naming a wire size.
    static func equipmentGroundingRow(ocpd: Int) -> Int? {
        egcRows.first(where: { ocpd <= $0.ocpdUpTo })?.ocpdUpTo
    }

    // MARK: - Bonding

    /// The main and system bonding jumper for a service, 250.28(D)(1): the
    /// same as a grounding electrode conductor from Table 250.66 while the
    /// service conductors are 1100 kcmil copper or smaller, and 12.5% of the
    /// service area above that.
    ///
    /// Returned as circular mils rather than a size, because above the table
    /// the answer is an area a candidate then rounds up to a real conductor.
    static func mainBondingJumperMils(serviceMils: Double, serviceMaterial: ConductorMaterial) -> Double? {
        let tableLimit: Double = serviceMaterial == .copper ? 1_100_000 : 1_750_000
        if serviceMils <= tableLimit {
            let rows = serviceMaterial == .copper ? gecCopperService : gecAluminumService
            guard let row = rows.first(where: { serviceMils <= $0.serviceUpTo + 0.5 }) else { return nil }
            let size = serviceMaterial == .copper ? row.copper : row.aluminum
            return circularMilsExtended[size]
        }
        return serviceMils * 0.125
    }
}
