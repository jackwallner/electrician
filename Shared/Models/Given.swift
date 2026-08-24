import Foundation

/// One labelled input in a code problem: the "given" line an exam question
/// puts above the question itself.
///
/// This is the electrician equivalent of a dealt tile. A question shows a small
/// row of these, the reader takes in the conditions at a glance, and then
/// answers. Keeping them structured rather than baked into prompt prose is what
/// lets the generator emit a problem and the renderer lay it out the same way
/// every time.
struct Given: Hashable, Codable, Sendable, Identifiable {
    /// What the value is. Short: this renders as a chip caption.
    let label: String
    /// The value itself, already formatted for display.
    let value: String
    /// Optional unit shown smaller after the value.
    let unit: String?

    var id: String { "\(label)|\(value)|\(unit ?? "")" }

    init(_ label: String, _ value: String, unit: String? = nil) {
        self.label = label
        self.value = value
        self.unit = unit
    }

    // Shorthand for the conditions that recur across nearly every problem.

    static func conductor(_ size: String, _ insulation: String) -> Given {
        Given("Conductor", "\(size) \(insulation)")
    }

    static func material(_ metal: ConductorMaterial) -> Given {
        Given("Material", metal.displayName)
    }

    static func ambient(_ celsius: Int) -> Given {
        Given("Ambient", "\(celsius)", unit: "°C")
    }

    static func currentCarrying(_ count: Int) -> Given {
        Given("Current-carrying", "\(count)", unit: count == 1 ? "conductor" : "conductors")
    }

    static func terminals(_ rating: TemperatureRating) -> Given {
        Given("Terminals", rating.displayName)
    }

    static func load(_ amps: Double) -> Given {
        Given("Load", amps.trimmedAmps, unit: "A")
    }

    static func length(_ feet: Int) -> Given {
        Given("One-way length", "\(feet)", unit: "ft")
    }

    static func voltage(_ volts: Int, phase: Phase) -> Given {
        Given("System", "\(volts)V \(phase.displayName)")
    }

    static func raceway(_ type: String, _ trade: String) -> Given {
        Given("Raceway", "\(trade) \(type)")
    }

    var spokenLabel: String {
        if let unit { return "\(label): \(value) \(unit)" }
        return "\(label): \(value)"
    }
}

enum ConductorMaterial: String, Codable, CaseIterable, Sendable {
    case copper
    case aluminum

    var displayName: String {
        switch self {
        case .copper: return "Copper"
        case .aluminum: return "Aluminum"
        }
    }

    /// Resistivity constant K for the voltage-drop approximation, in
    /// ohm-circular-mils per foot. These are the conventional exam values.
    var voltageDropK: Double {
        switch self {
        case .copper: return 12.9
        case .aluminum: return 21.2
        }
    }
}

enum TemperatureRating: Int, Codable, CaseIterable, Sendable, Comparable {
    case c60 = 60
    case c75 = 75
    case c90 = 90

    var displayName: String { "\(rawValue)°C" }

    static func < (lhs: TemperatureRating, rhs: TemperatureRating) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum Phase: String, Codable, CaseIterable, Sendable {
    case single
    case three

    var displayName: String {
        switch self {
        case .single: return "1Ø"
        case .three: return "3Ø"
        }
    }

    /// The multiplier in the voltage-drop formula: 2 for a single-phase
    /// circuit (out and back), √3 for a balanced three-phase circuit.
    var voltageDropFactor: Double {
        switch self {
        case .single: return 2.0
        case .three: return 1.732
        }
    }
}

extension Double {
    /// Amps without a trailing ".0", because "24 A" reads like an exam and
    /// "24.0 A" reads like a spreadsheet.
    var trimmedAmps: String {
        if self == rounded() { return String(Int(rounded())) }
        return String(format: "%.1f", self)
    }
}
