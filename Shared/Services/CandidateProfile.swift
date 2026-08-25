import Foundation

enum LicenseTrack: String, CaseIterable, Identifiable, Sendable {
    case journeyman
    case master

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .journeyman: return "Journeyman"
        case .master: return "Master"
        }
    }
}

enum CandidateEdition: String, CaseIterable, Identifiable, Sendable {
    case nec2023
    case different

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nec2023: return NECTables.edition
        case .different: return "A different edition"
        }
    }

    var note: String {
        switch self {
        case .nec2023:
            return "Matches the tables and answers in this app."
        case .different:
            return "Use this app for navigation practice, then verify every value against your code in force."
        }
    }
}

@MainActor
final class CandidateProfile: ObservableObject {
    static let shared = CandidateProfile()

    private enum Keys {
        static let licenseTrack = "candidate.licenseTrack"
        static let jurisdiction = "candidate.jurisdiction"
        static let edition = "candidate.edition"
        static let examDate = "candidate.examDate"
        static let hasSelectedTrack = "candidate.hasSelectedTrack"
        static let setupComplete = "candidate.setupComplete"
    }

    private let defaults: UserDefaults

    @Published var licenseTrack: LicenseTrack {
        didSet { defaults.set(licenseTrack.rawValue, forKey: Keys.licenseTrack) }
    }

    @Published var jurisdiction: String {
        didSet { defaults.set(jurisdiction, forKey: Keys.jurisdiction) }
    }

    @Published var edition: CandidateEdition {
        didSet { defaults.set(edition.rawValue, forKey: Keys.edition) }
    }

    @Published var examDate: Date? {
        didSet {
            if let examDate {
                defaults.set(examDate, forKey: Keys.examDate)
            } else {
                defaults.removeObject(forKey: Keys.examDate)
            }
        }
    }

    @Published private(set) var hasSelectedTrack: Bool {
        didSet { defaults.set(hasSelectedTrack, forKey: Keys.hasSelectedTrack) }
    }

    @Published private(set) var setupComplete: Bool {
        didSet { defaults.set(setupComplete, forKey: Keys.setupComplete) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        licenseTrack = LicenseTrack(rawValue: defaults.string(forKey: Keys.licenseTrack) ?? "") ?? .journeyman
        jurisdiction = defaults.string(forKey: Keys.jurisdiction) ?? ""
        edition = CandidateEdition(rawValue: defaults.string(forKey: Keys.edition) ?? "") ?? .nec2023
        examDate = defaults.object(forKey: Keys.examDate) as? Date
        hasSelectedTrack = defaults.bool(forKey: Keys.hasSelectedTrack)
        setupComplete = defaults.bool(forKey: Keys.setupComplete)
    }

    var trimmedJurisdiction: String {
        jurisdiction.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canCompleteSetup: Bool {
        // Journeyman is the visible default. Requiring a tap on an already
        // selected segmented value leaves a fresh candidate stuck on Continue.
        !trimmedJurisdiction.isEmpty
    }

    var targetSummary: String {
        guard setupComplete else { return "Set your exam target" }
        return "\(licenseTrack.displayName) · \(trimmedJurisdiction)"
    }

    var editionSummary: String {
        edition == .nec2023 ? NECTables.edition : "Different edition"
    }

    func selectTrack(_ track: LicenseTrack) {
        licenseTrack = track
        hasSelectedTrack = true
    }

    func completeSetup() {
        guard canCompleteSetup else { return }
        setupComplete = true
    }
}
