import Foundation

/// The numeric reference data the drills and the generator compute against.
///
/// **Legal position, and it is the important one.** NFPA holds copyright in the
/// text of the National Electrical Code and enforces it. Nothing in this app
/// reproduces that text. What lives here are the underlying numbers, which are
/// facts, and the article numbers, which are citations. Every explanation in
/// the content files is written in original wording that teaches the concept
/// and points the reader at the article to look up in their own code book.
/// Keep that discipline: cite `310.16`, never quote it.
///
/// The same rule the fleet already applies to the NMJL card and the DSkV
/// Skatordnung applies here, for the same reason.
///
/// Values follow the 2023 cycle unless noted, which is what most states are
/// examining against while the 2026 adoptions roll out.
enum NECTables {

    // MARK: - Conductor sizes

    /// Conductor sizes in the order they run, small to large. AWG sizes are
    /// negative-indexed by convention so ordering works across the AWG/kcmil
    /// boundary without special cases.
    static let conductorSizes: [String] = [
        "14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "3 AWG",
        "2 AWG", "1 AWG", "1/0 AWG", "2/0 AWG", "3/0 AWG", "4/0 AWG",
        "250 kcmil", "300 kcmil", "350 kcmil", "400 kcmil", "500 kcmil",
    ]

    /// Circular mils per size, for voltage-drop work.
    static let circularMils: [String: Double] = [
        "14 AWG": 4110, "12 AWG": 6530, "10 AWG": 10380, "8 AWG": 16510,
        "6 AWG": 26240, "4 AWG": 41740, "3 AWG": 52620, "2 AWG": 66360,
        "1 AWG": 83690, "1/0 AWG": 105600, "2/0 AWG": 133100, "3/0 AWG": 167800,
        "4/0 AWG": 211600, "250 kcmil": 250000, "300 kcmil": 300000,
        "350 kcmil": 350000, "400 kcmil": 400000, "500 kcmil": 500000,
    ]

    // MARK: - Ampacity (310.16, conductors in raceway or cable)

    /// Allowable ampacity by size and terminal-temperature column, copper.
    static let copperAmpacity: [String: [TemperatureRating: Int]] = [
        "14 AWG": [.c60: 15, .c75: 20, .c90: 25],
        "12 AWG": [.c60: 20, .c75: 25, .c90: 30],
        "10 AWG": [.c60: 30, .c75: 35, .c90: 40],
        "8 AWG": [.c60: 40, .c75: 50, .c90: 55],
        "6 AWG": [.c60: 55, .c75: 65, .c90: 75],
        "4 AWG": [.c60: 70, .c75: 85, .c90: 95],
        "3 AWG": [.c60: 85, .c75: 100, .c90: 115],
        "2 AWG": [.c60: 95, .c75: 115, .c90: 130],
        "1 AWG": [.c60: 110, .c75: 130, .c90: 145],
        "1/0 AWG": [.c60: 125, .c75: 150, .c90: 170],
        "2/0 AWG": [.c60: 145, .c75: 175, .c90: 195],
        "3/0 AWG": [.c60: 165, .c75: 200, .c90: 225],
        "4/0 AWG": [.c60: 195, .c75: 230, .c90: 260],
        "250 kcmil": [.c60: 215, .c75: 255, .c90: 290],
        "300 kcmil": [.c60: 240, .c75: 285, .c90: 320],
        "350 kcmil": [.c60: 260, .c75: 310, .c90: 350],
        "400 kcmil": [.c60: 280, .c75: 335, .c90: 380],
        "500 kcmil": [.c60: 320, .c75: 380, .c90: 430],
    ]

    /// Aluminum and copper-clad aluminum, same table.
    static let aluminumAmpacity: [String: [TemperatureRating: Int]] = [
        "12 AWG": [.c60: 15, .c75: 20, .c90: 25],
        "10 AWG": [.c60: 25, .c75: 30, .c90: 35],
        "8 AWG": [.c60: 35, .c75: 40, .c90: 45],
        "6 AWG": [.c60: 40, .c75: 50, .c90: 55],
        "4 AWG": [.c60: 55, .c75: 65, .c90: 75],
        "3 AWG": [.c60: 65, .c75: 75, .c90: 85],
        "2 AWG": [.c60: 75, .c75: 90, .c90: 100],
        "1 AWG": [.c60: 85, .c75: 100, .c90: 115],
        "1/0 AWG": [.c60: 100, .c75: 120, .c90: 135],
        "2/0 AWG": [.c60: 115, .c75: 135, .c90: 150],
        "3/0 AWG": [.c60: 130, .c75: 155, .c90: 175],
        "4/0 AWG": [.c60: 150, .c75: 180, .c90: 205],
        "250 kcmil": [.c60: 170, .c75: 205, .c90: 230],
        "300 kcmil": [.c60: 195, .c75: 230, .c90: 260],
        "350 kcmil": [.c60: 210, .c75: 250, .c90: 280],
        "400 kcmil": [.c60: 225, .c75: 270, .c90: 305],
        "500 kcmil": [.c60: 260, .c75: 310, .c90: 350],
    ]

    static func ampacity(size: String, material: ConductorMaterial,
                         column: TemperatureRating) -> Int? {
        switch material {
        case .copper: return copperAmpacity[size]?[column]
        case .aluminum: return aluminumAmpacity[size]?[column]
        }
    }

    // MARK: - Ambient temperature correction, 310.15(B)(1)

    /// Correction factors keyed by the top of each ambient band, for the 75°C
    /// and 90°C columns. Bands run in 5°C steps from 26-30°C upward.
    private static let ambientBands: [(upTo: Int, c60: Double, c75: Double, c90: Double)] = [
        (30, 1.00, 1.00, 1.00),
        (35, 0.91, 0.94, 0.96),
        (40, 0.82, 0.88, 0.91),
        (45, 0.71, 0.82, 0.87),
        (50, 0.58, 0.75, 0.82),
        (55, 0.41, 0.67, 0.76),
        (60, 0.00, 0.58, 0.71),
    ]

    /// The ambient correction factor, or nil when the ambient is off the end of
    /// the table for that column (which is itself the right answer to teach:
    /// the conductor cannot be used there).
    static func ambientCorrection(celsius: Int, column: TemperatureRating) -> Double? {
        guard celsius > 25 else { return 1.0 }
        guard let band = ambientBands.first(where: { celsius <= $0.upTo }) else { return nil }
        let factor: Double
        switch column {
        case .c60: factor = band.c60
        case .c75: factor = band.c75
        case .c90: factor = band.c90
        }
        return factor > 0 ? factor : nil
    }

    // MARK: - Conductor adjustment, 310.15(C)(1)

    /// The bundling adjustment for more than three current-carrying conductors
    /// in a raceway or cable.
    static func adjustmentFactor(currentCarrying count: Int) -> Double {
        switch count {
        case ...3: return 1.00
        case 4...6: return 0.80
        case 7...9: return 0.70
        case 10...20: return 0.50
        case 21...30: return 0.45
        case 31...40: return 0.40
        default: return 0.35
        }
    }

    // MARK: - Overcurrent protection

    /// Standard ampere ratings for fuses and inverse-time breakers, 240.6(A).
    static let standardOCPD: [Int] = [
        15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150,
        175, 200, 225, 250, 300, 350, 400, 450, 500, 600, 700, 800, 1000,
        1200, 1600, 2000, 2500, 3000, 4000, 5000, 6000,
    ]

    /// The next standard size at or above a computed value.
    static func nextStandardOCPD(atLeast amps: Double) -> Int? {
        standardOCPD.first { Double($0) >= amps - 0.0001 }
    }

    /// The next standard size at or below a computed value.
    static func nextStandardOCPD(atMost amps: Double) -> Int? {
        standardOCPD.last { Double($0) <= amps + 0.0001 }
    }

    /// The small-conductor ceiling in 240.4(D), which overrides the ampacity
    /// table for 14, 12 and 10 AWG regardless of what the column says. This is
    /// the single most-missed rule on the licensing exam.
    static let smallConductorLimit: [String: [ConductorMaterial: Int]] = [
        "14 AWG": [.copper: 15],
        "12 AWG": [.copper: 20, .aluminum: 15],
        "10 AWG": [.copper: 30, .aluminum: 25],
    ]

    static func smallConductorCeiling(size: String, material: ConductorMaterial) -> Int? {
        smallConductorLimit[size]?[material]
    }

    // MARK: - Box fill, 314.16(B)

    /// Free space required per conductor, in cubic inches.
    static let conductorVolume: [String: Double] = [
        "18 AWG": 1.50, "16 AWG": 1.75, "14 AWG": 2.00, "12 AWG": 2.25,
        "10 AWG": 2.50, "8 AWG": 3.00, "6 AWG": 5.00,
    ]

    // MARK: - Raceway fill, Chapter 9 Table 1

    /// The percentage of a raceway's interior a conductor bundle may occupy.
    static func fillPercent(conductorCount: Int) -> Double {
        switch conductorCount {
        case 1: return 0.53
        case 2: return 0.31
        default: return 0.40
        }
    }

    /// Total interior area of common trade sizes of EMT, in square inches.
    static let emtArea: [String: Double] = [
        "1/2\"": 0.304, "3/4\"": 0.533, "1\"": 0.864, "1-1/4\"": 1.496,
        "1-1/2\"": 2.036, "2\"": 3.356, "2-1/2\"": 5.858, "3\"": 8.846,
        "3-1/2\"": 11.545, "4\"": 14.753,
    ]

    static let emtTradeSizes: [String] = [
        "1/2\"", "3/4\"", "1\"", "1-1/4\"", "1-1/2\"", "2\"", "2-1/2\"", "3\"",
        "3-1/2\"", "4\"",
    ]

    /// Approximate total cross-sectional area of one THHN/THWN-2 conductor,
    /// in square inches, Chapter 9 Table 5.
    static let thhnArea: [String: Double] = [
        "14 AWG": 0.0097, "12 AWG": 0.0133, "10 AWG": 0.0211, "8 AWG": 0.0366,
        "6 AWG": 0.0507, "4 AWG": 0.0824, "3 AWG": 0.0973, "2 AWG": 0.1158,
        "1 AWG": 0.1562, "1/0 AWG": 0.1855, "2/0 AWG": 0.2223,
        "3/0 AWG": 0.2679, "4/0 AWG": 0.3237, "250 kcmil": 0.3970,
        "300 kcmil": 0.4608, "350 kcmil": 0.5242, "400 kcmil": 0.5863,
        "500 kcmil": 0.7073,
    ]
}
