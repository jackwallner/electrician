import Foundation

/// The installation rules an exam tests as numbers: box volumes (314.16(A)),
/// working space (110.26), minimum cover (300.5), support spacing, and the
/// termination-temperature rule in 110.14(C).
///
/// These are the questions a candidate can answer in fifteen seconds if they
/// know where the number lives and loses two minutes to if they do not, which
/// makes them the best points-per-minute on the paper. They are also the part
/// of the book a working electrician uses most after the licence arrives.
extension NECTables {

    // MARK: - Box volumes, Table 314.16(A)

    struct BoxSize: Identifiable, Hashable, Sendable {
        /// As it is ordered from a supply house.
        let name: String
        /// Interior volume in cubic inches.
        let cubicInches: Double
        var id: String { name }
    }

    /// The standard metal boxes in Table 314.16(A). A box not in the table (a
    /// nonmetallic box, an extension ring, a mud ring) carries its volume
    /// marked on it, which is itself a tested fact: the table is not the only
    /// place a volume can come from.
    static let boxSizes: [BoxSize] = [
        BoxSize(name: "3x2x2 device", cubicInches: 10.0),
        BoxSize(name: "3x2x2-1/4 device", cubicInches: 10.5),
        BoxSize(name: "3x2x2-1/2 device", cubicInches: 12.5),
        BoxSize(name: "3x2x2-3/4 device", cubicInches: 14.0),
        BoxSize(name: "3x2x3-1/2 device", cubicInches: 18.0),
        BoxSize(name: "4x2-1/8x1-1/2 device", cubicInches: 10.3),
        BoxSize(name: "4x2-1/8x1-7/8 device", cubicInches: 13.0),
        BoxSize(name: "4x2-1/8x2-1/8 device", cubicInches: 14.5),
        BoxSize(name: "4x1-1/4 round/octagonal", cubicInches: 12.5),
        BoxSize(name: "4x1-1/2 round/octagonal", cubicInches: 15.5),
        BoxSize(name: "4x2-1/8 round/octagonal", cubicInches: 21.5),
        BoxSize(name: "4x1-1/4 square", cubicInches: 18.0),
        BoxSize(name: "4x1-1/2 square", cubicInches: 21.0),
        BoxSize(name: "4x2-1/8 square", cubicInches: 30.3),
        BoxSize(name: "4-11/16x1-1/4 square", cubicInches: 25.5),
        BoxSize(name: "4-11/16x1-1/2 square", cubicInches: 29.5),
        BoxSize(name: "4-11/16x2-1/8 square", cubicInches: 42.0),
    ]

    /// The smallest listed box that holds a computed fill.
    static func smallestBox(forCubicInches required: Double) -> BoxSize? {
        boxSizes.sorted { $0.cubicInches < $1.cubicInches }
            .first { $0.cubicInches >= required - 0.0001 }
    }

    // MARK: - What counts as an allowance, 314.16(B)

    /// Every allowance 314.16(B) recognises, in the words a candidate needs to
    /// hear them in: what the thing is, and how many allowances it takes.
    ///
    /// The counts are the whole question. A box is almost never over-filled by
    /// wire; it is over-filled because a yoke counted as one instead of two, or
    /// because four grounds counted as four instead of one.
    enum BoxAllowance: String, CaseIterable, Identifiable, Sendable {
        case conductorThrough
        case conductorTerminating
        case conductorOriginating
        case allClamps
        case supportFitting
        case deviceYoke
        case allGrounds

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .conductorThrough: return "A conductor passing through"
            case .conductorTerminating: return "A conductor ending in the box"
            case .conductorOriginating: return "A pigtail made up inside the box"
            case .allClamps: return "Internal cable clamps, however many"
            case .supportFitting: return "Each fixture stud or hickey"
            case .deviceYoke: return "Each device or equipment yoke"
            case .allGrounds: return "All equipment grounds together"
            }
        }

        /// Allowances taken, each one based on the size named in `sizedBy`.
        var count: Int {
            switch self {
            case .conductorThrough, .conductorTerminating: return 1
            // A conductor that starts and ends inside the box, connected to
            // nothing leaving it, is not counted at all.
            case .conductorOriginating: return 0
            case .allClamps, .supportFitting: return 1
            case .deviceYoke: return 2
            case .allGrounds: return 1
            }
        }

        /// Which conductor size sets this allowance's volume.
        var sizedBy: String {
            switch self {
            case .conductorThrough, .conductorTerminating, .conductorOriginating:
                return "its own size"
            case .allClamps, .supportFitting:
                return "the largest conductor in the box"
            case .deviceYoke:
                return "the largest conductor connected to that device"
            case .allGrounds:
                return "the largest equipment ground in the box"
            }
        }

        var citation: String {
            switch self {
            case .conductorThrough, .conductorTerminating, .conductorOriginating: return "314.16(B)(1)"
            case .allClamps: return "314.16(B)(2)"
            case .supportFitting: return "314.16(B)(3)"
            case .deviceYoke: return "314.16(B)(4)"
            case .allGrounds: return "314.16(B)(5)"
            }
        }
    }

    // MARK: - Working space, 110.26

    /// The three conditions 110.26(A)(1) grades a working space by, in the
    /// order they appear. Depth is measured from the live parts outward.
    enum WorkingSpaceCondition: Int, CaseIterable, Identifiable, Sendable {
        /// Exposed live parts on one side, no live or grounded parts opposite.
        case one = 1
        /// Exposed live parts on one side, grounded parts opposite.
        case two = 2
        /// Exposed live parts on both sides of the working space.
        case three = 3

        var id: Int { rawValue }

        var displayName: String { "Condition \(rawValue)" }

        var detail: String {
            switch self {
            case .one: return "Live parts on one side, nothing live or grounded facing them"
            case .two: return "Live parts on one side, grounded parts on the other"
            case .three: return "Live parts on both sides of where you stand"
            }
        }
    }

    /// Minimum clear depth in feet, by nominal voltage to ground and condition.
    /// Below 151 volts every condition is the same three feet, which is why the
    /// table only starts to matter on a 277/480 system.
    static func workingSpaceDepthFeet(voltsToGround: Int, condition: WorkingSpaceCondition) -> Double {
        if voltsToGround <= 150 { return 3.0 }
        switch condition {
        case .one: return 3.0
        case .two: return 3.5
        case .three: return 4.0
        }
    }

    /// 110.26(A)(2): 30 inches, or the width of the equipment, whichever is
    /// greater, and the space has to allow a 90-degree door swing.
    static let workingSpaceWidthInches = 30.0
    /// 110.26(A)(3): 6.5 feet, or the height of the equipment where it is
    /// taller.
    static let workingSpaceHeightFeet = 6.5
    /// 110.26(C)(2): equipment rated 1200 A or more and over 6 feet wide needs
    /// an entrance at each end of the working space.
    static let twoEntranceAmpThreshold = 1200

    // MARK: - Minimum cover, Table 300.5

    /// The wiring methods Table 300.5 gives their own column to.
    enum BurialMethod: String, CaseIterable, Identifiable, Sendable {
        case directBurial
        case rigidOrIMC
        case nonmetallicRaceway
        case residentialBranch
        case lowVoltageLighting

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .directBurial: return "Direct-buried cable or conductors"
            case .rigidOrIMC: return "Rigid metal or intermediate metal conduit"
            case .nonmetallicRaceway: return "Nonmetallic raceway listed for direct burial"
            case .residentialBranch: return "Residential branch circuit, 120V, 20A, GFCI protected"
            case .lowVoltageLighting: return "Irrigation and landscape lighting, 30V or less"
            }
        }

        /// Minimum cover in inches, in the ordinary case: not under a building,
        /// a slab, or a road.
        var inches: Int {
            switch self {
            case .directBurial: return 24
            case .rigidOrIMC: return 6
            case .nonmetallicRaceway: return 18
            case .residentialBranch: return 12
            case .lowVoltageLighting: return 6
            }
        }
    }

    /// Under a street, road, alley, driveway or parking lot every column goes
    /// to the same figure, which is the exception worth memorising because it
    /// collapses the whole table into one number.
    static let coverUnderTrafficInches = 24

    // MARK: - Support spacing

    struct SupportRule: Identifiable, Sendable {
        let method: String
        /// Distance from a box or fitting the first support has to be within.
        let withinOfBoxInches: Double
        /// Maximum interval between supports along the run, in feet.
        let intervalFeet: Double
        let citation: String
        var id: String { method }
    }

    /// The support intervals the exam asks for by name. Every one is "secure
    /// within X of the box, then support every Y", and the pairs are what get
    /// mixed up: cable is measured in inches from the box and feet along the
    /// run, raceway in feet for both.
    static let supportRules: [SupportRule] = [
        SupportRule(method: "EMT", withinOfBoxInches: 36, intervalFeet: 10, citation: "358.30"),
        SupportRule(method: "Rigid metal conduit, 1/2 to 3/4 in.", withinOfBoxInches: 36, intervalFeet: 10, citation: "344.30"),
        SupportRule(method: "Rigid metal conduit, 1 in.", withinOfBoxInches: 36, intervalFeet: 12, citation: "344.30"),
        SupportRule(method: "Rigid metal conduit, 1-1/4 to 1-1/2 in.", withinOfBoxInches: 36, intervalFeet: 14, citation: "344.30"),
        SupportRule(method: "Rigid metal conduit, 2 to 2-1/2 in.", withinOfBoxInches: 36, intervalFeet: 16, citation: "344.30"),
        SupportRule(method: "Rigid metal conduit, 3 in. and larger", withinOfBoxInches: 36, intervalFeet: 20, citation: "344.30"),
        SupportRule(method: "PVC conduit, 1/2 to 1 in.", withinOfBoxInches: 36, intervalFeet: 3, citation: "352.30"),
        SupportRule(method: "PVC conduit, 1-1/4 to 2 in.", withinOfBoxInches: 36, intervalFeet: 5, citation: "352.30"),
        SupportRule(method: "PVC conduit, 2-1/2 to 3 in.", withinOfBoxInches: 36, intervalFeet: 6, citation: "352.30"),
        SupportRule(method: "Type NM cable", withinOfBoxInches: 12, intervalFeet: 4.5, citation: "334.30"),
        SupportRule(method: "Type AC cable", withinOfBoxInches: 12, intervalFeet: 4.5, citation: "320.30"),
        SupportRule(method: "Type MC cable", withinOfBoxInches: 12, intervalFeet: 6, citation: "330.30"),
    ]

    /// Total bends between pull points, for every raceway article that has the
    /// rule. Four quarter bends, and it is the same number in every one.
    static let maximumBendDegrees = 360

    // MARK: - Terminations, 110.14(C)

    /// The temperature column a termination lets you use, before any listing
    /// marked on the equipment says otherwise.
    ///
    /// This is the rule the whole derating shape hangs off: 90°C insulation
    /// exists to be derated FROM, not to be protected AT, and the number that
    /// decides which column caps the answer is the circuit rating or the
    /// conductor size, not the insulation.
    static func terminationColumn(circuitAmps: Double, conductorSize: String) -> TemperatureRating {
        let bigConductor = (circularMilsExtended[conductorSize] ?? 0) > (circularMilsExtended["1 AWG"] ?? 0)
        return (circuitAmps > 100 || bigConductor) ? .c75 : .c60
    }

    /// Continuous-load factor, 210.19(A)(1) and 210.20(A). A load expected to
    /// run three hours or more takes 125%, applied to both the conductor and
    /// the device ahead of it.
    static let continuousLoadFactor = 1.25
    static let continuousLoadHours = 3
}
