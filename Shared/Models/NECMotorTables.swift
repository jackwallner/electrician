import Foundation

/// Motor full-load current and the percentages that size a motor circuit:
/// Tables 430.248 and 430.250, and the rules in 430.22, 430.32, 430.52,
/// 430.24 and 430.62.
///
/// Article 430 is the one place in the book where the nameplate is NOT the
/// number you calculate from. Conductors and short-circuit protection come off
/// the table; only the overload device comes off the nameplate. That reversal
/// is the whole content of this file, and it is what the exam tests.
extension NECTables {

    // MARK: - Full-load current

    enum MotorSupply: String, CaseIterable, Identifiable, Sendable {
        case single115
        case single230
        case three208
        case three230
        case three460

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .single115: return "115V 1Ø"
            case .single230: return "230V 1Ø"
            case .three208: return "208V 3Ø"
            case .three230: return "230V 3Ø"
            case .three460: return "460V 3Ø"
            }
        }

        var volts: Int {
            switch self {
            case .single115: return 115
            case .single230: return 230
            case .three208: return 208
            case .three230: return 230
            case .three460: return 460
            }
        }

        var phase: Phase {
            switch self {
            case .single115, .single230: return .single
            case .three208, .three230, .three460: return .three
            }
        }

        /// Single-phase motors are Table 430.248; three-phase squirrel-cage and
        /// wound-rotor motors are Table 430.250. Naming the right table is half
        /// the question on the exam.
        var citation: String {
            phase == .single ? "430.248" : "430.250"
        }
    }

    /// Horsepower as it is written on a nameplate, paired with the value used
    /// to sort and look up. Fractional sizes are real motors and real exam
    /// questions, so they are not rounded away.
    struct MotorRating: Hashable, Sendable {
        let label: String
        let hp: Double
    }

    static let motorRatings: [MotorRating] = [
        MotorRating(label: "1/6 hp", hp: 1.0 / 6),
        MotorRating(label: "1/4 hp", hp: 0.25),
        MotorRating(label: "1/3 hp", hp: 1.0 / 3),
        MotorRating(label: "1/2 hp", hp: 0.5),
        MotorRating(label: "3/4 hp", hp: 0.75),
        MotorRating(label: "1 hp", hp: 1),
        MotorRating(label: "1-1/2 hp", hp: 1.5),
        MotorRating(label: "2 hp", hp: 2),
        MotorRating(label: "3 hp", hp: 3),
        MotorRating(label: "5 hp", hp: 5),
        MotorRating(label: "7-1/2 hp", hp: 7.5),
        MotorRating(label: "10 hp", hp: 10),
        MotorRating(label: "15 hp", hp: 15),
        MotorRating(label: "20 hp", hp: 20),
        MotorRating(label: "25 hp", hp: 25),
        MotorRating(label: "30 hp", hp: 30),
        MotorRating(label: "40 hp", hp: 40),
        MotorRating(label: "50 hp", hp: 50),
        MotorRating(label: "60 hp", hp: 60),
        MotorRating(label: "75 hp", hp: 75),
        MotorRating(label: "100 hp", hp: 100),
    ]

    /// Table 430.248, single-phase alternating-current motors, in amperes.
    static let singlePhaseFLC: [String: [MotorSupply: Double]] = [
        "1/6 hp": [.single115: 4.4, .single230: 2.2],
        "1/4 hp": [.single115: 5.8, .single230: 2.9],
        "1/3 hp": [.single115: 7.2, .single230: 3.6],
        "1/2 hp": [.single115: 9.8, .single230: 4.9],
        "3/4 hp": [.single115: 13.8, .single230: 6.9],
        "1 hp": [.single115: 16, .single230: 8],
        "1-1/2 hp": [.single115: 20, .single230: 10],
        "2 hp": [.single115: 24, .single230: 12],
        "3 hp": [.single115: 34, .single230: 17],
        "5 hp": [.single115: 56, .single230: 28],
        "7-1/2 hp": [.single115: 80, .single230: 40],
        "10 hp": [.single115: 100, .single230: 50],
    ]

    /// Table 430.250, three-phase squirrel-cage induction motors, in amperes.
    static let threePhaseFLC: [String: [MotorSupply: Double]] = [
        "1/2 hp": [.three208: 2.4, .three230: 2.2, .three460: 1.1],
        "3/4 hp": [.three208: 3.5, .three230: 3.2, .three460: 1.6],
        "1 hp": [.three208: 4.6, .three230: 4.2, .three460: 2.1],
        "1-1/2 hp": [.three208: 6.6, .three230: 6.0, .three460: 3.0],
        "2 hp": [.three208: 7.5, .three230: 6.8, .three460: 3.4],
        "3 hp": [.three208: 10.6, .three230: 9.6, .three460: 4.8],
        "5 hp": [.three208: 16.7, .three230: 15.2, .three460: 7.6],
        "7-1/2 hp": [.three208: 24.2, .three230: 22, .three460: 11],
        "10 hp": [.three208: 30.8, .three230: 28, .three460: 14],
        "15 hp": [.three208: 46.2, .three230: 42, .three460: 21],
        "20 hp": [.three208: 59.4, .three230: 54, .three460: 27],
        "25 hp": [.three208: 74.8, .three230: 68, .three460: 34],
        "30 hp": [.three208: 88, .three230: 80, .three460: 40],
        "40 hp": [.three208: 114, .three230: 104, .three460: 52],
        "50 hp": [.three208: 143, .three230: 130, .three460: 65],
        "60 hp": [.three208: 169, .three230: 154, .three460: 77],
        "75 hp": [.three208: 211, .three230: 192, .three460: 96],
        "100 hp": [.three208: 273, .three230: 248, .three460: 124],
    ]

    /// Full-load current from the table. Nil for a combination the tables do
    /// not carry, which is itself a correct answer to teach.
    static func motorFLC(hp label: String, supply: MotorSupply) -> Double? {
        switch supply.phase {
        case .single: return singlePhaseFLC[label]?[supply]
        case .three: return threePhaseFLC[label]?[supply]
        }
    }

    /// Every horsepower this supply has a table value for, in order.
    static func motorRatings(for supply: MotorSupply) -> [MotorRating] {
        motorRatings.filter { motorFLC(hp: $0.label, supply: supply) != nil }
    }

    // MARK: - Sizing the circuit

    /// 430.22: branch-circuit conductors for a single continuous-duty motor
    /// carry 125% of the table full-load current. Not 125% of the nameplate.
    static let motorConductorFactor = 1.25

    /// The device types 430.52 gives different ceilings to. Percentages are of
    /// the TABLE full-load current, and they are maximums, not targets: 430.52
    /// lets the next standard size up be used when the calculated value does
    /// not correspond to a standard rating.
    enum MotorProtection: String, CaseIterable, Identifiable, Sendable {
        case nonTimeDelayFuse
        case dualElementFuse
        case instantaneousTrip
        case inverseTimeBreaker

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .nonTimeDelayFuse: return "Nontime-delay fuse"
            case .dualElementFuse: return "Dual-element (time-delay) fuse"
            case .instantaneousTrip: return "Instantaneous-trip breaker"
            case .inverseTimeBreaker: return "Inverse-time breaker"
            }
        }

        /// Maximum percentage of table FLC, for a squirrel-cage motor other
        /// than a Design B energy-efficient one.
        var percent: Double {
            switch self {
            case .nonTimeDelayFuse: return 3.00
            case .dualElementFuse: return 1.75
            case .instantaneousTrip: return 8.00
            case .inverseTimeBreaker: return 2.50
            }
        }

        var percentLabel: String { "\(Int(percent * 100))%" }
    }

    /// The largest standard device allowed ahead of one motor.
    ///
    /// 430.52(C)(1) Exception 1 is the part that makes this different from
    /// every other overcurrent calculation in the book: where the percentage
    /// does not land on a standard rating, you go UP to the next standard size,
    /// not down. A candidate who applies the 240.6 "next size down" habit here
    /// gets every motor question wrong.
    static func motorBranchOCPD(flc: Double, protection: MotorProtection) -> Int? {
        let calculated = flc * protection.percent
        if let exact = standardOCPD.first(where: { abs(Double($0) - calculated) < 0.0001 }) {
            return exact
        }
        return nextStandardOCPD(atLeast: calculated)
    }

    /// 430.32(A)(1): the separate overload device, which IS sized from the
    /// nameplate. 125% for a motor with a service factor of 1.15 or more or a
    /// temperature rise of 40°C or less, 115% for everything else.
    static func motorOverloadTrip(nameplateFLA: Double, serviceFactor: Double, tempRiseC: Double?) -> Double {
        let generous = serviceFactor >= 1.15 || (tempRiseC.map { $0 <= 40 } ?? false)
        return nameplateFLA * (generous ? 1.25 : 1.15)
    }

    /// 430.24: feeder conductors for a group of motors carry 125% of the
    /// largest motor's full-load current plus 100% of the rest.
    static func motorFeederAmpacity(flcs: [Double]) -> Double? {
        guard let largest = flcs.max() else { return nil }
        return largest * motorConductorFactor + (flcs.reduce(0, +) - largest)
    }

    /// 430.62: the feeder overcurrent device is the LARGEST branch-circuit
    /// device in the group plus the full-load currents of the other motors.
    /// Note which quantities each side of that sum uses: it is one device
    /// rating plus a set of currents, never a sum of device ratings.
    static func motorFeederOCPD(largestBranchOCPD: Int, otherFLCs: [Double]) -> Int? {
        let calculated = Double(largestBranchOCPD) + otherFLCs.reduce(0, +)
        return nextStandardOCPD(atMost: calculated)
    }
}
