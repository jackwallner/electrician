import Foundation

/// What the candidate is sitting for. `journeyman` and `master` keep their
/// original raw values because they are already persisted on device; the three
/// added cases are new spellings only.
enum LicenseTrack: String, CaseIterable, Identifiable, Sendable {
    case apprentice
    case residential
    case journeyman
    case master
    case contractor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apprentice: return "Apprentice"
        case .residential: return "Residential"
        case .journeyman: return "Journeyman"
        case .master: return "Master"
        case .contractor: return "Contractor"
        }
    }

    /// Short enough for a segmented control on a 375pt phone.
    var shortName: String {
        switch self {
        case .apprentice: return "App."
        case .residential: return "Res."
        case .journeyman: return "Jrny."
        case .master: return "Master"
        case .contractor: return "Contr."
        }
    }

    var detail: String {
        switch self {
        case .apprentice:
            return "Working toward the hours, or sitting an entrance/aptitude test"
        case .residential:
            return "Residential wireman or limited residential licence"
        case .journeyman:
            return "The full journeyman/electrician licence exam"
        case .master:
            return "Master electrician, usually journeyman plus added years"
        case .contractor:
            return "Electrical contractor, often a business-and-law paper as well"
        }
    }

    /// What the exam tends to weight for this track. Not a claim about any one
    /// state's blueprint, and worded that way.
    var emphasis: String {
        switch self {
        case .apprentice:
            return "Expect mostly code navigation and arithmetic. Live in Code Basics first."
        case .residential:
            return "Branch circuits, box fill, and dwelling-unit receptacle and GFCI rules carry the most weight."
        case .journeyman:
            return "Ampacity and derating, overcurrent sizing, conduit and box fill, grounding and motors. That is what this app drills."
        case .master:
            return "Everything the journeyman paper covers, plus heavier calculation and more Chapter 2 and Chapter 3 lookup under time."
        case .contractor:
            return "The technical paper overlaps the master exam. The business-and-law paper is separate and this app does not cover it."
        }
    }
}

/// The code edition the candidate is examined on.
///
/// `nec2023` and `different` keep their original raw values: they are already
/// written to `candidate.edition` on shipped installs and changing a raw value
/// silently forgets the setting instead of migrating it.
enum CandidateEdition: String, CaseIterable, Identifiable, Sendable {
    case unsure
    case nec2014
    case nec2017
    case nec2020
    case nec2023
    case nec2026
    case different

    var id: String { rawValue }

    /// The concrete edition, when this case names one.
    var edition: NECEdition? {
        switch self {
        case .nec2014: return .nec2014
        case .nec2017: return .nec2017
        case .nec2020: return .nec2020
        case .nec2023: return .nec2023
        case .nec2026: return .nec2026
        case .unsure, .different: return nil
        }
    }

    init(edition: NECEdition) {
        switch edition {
        case .nec2011, .nec2014: self = .nec2014
        case .nec2017: self = .nec2017
        case .nec2020: self = .nec2020
        case .nec2023: self = .nec2023
        case .nec2026: self = .nec2026
        }
    }

    var displayName: String {
        switch self {
        case .unsure: return "I'm not sure"
        case .different: return "Another edition"
        default: return edition?.displayName ?? "Another edition"
        }
    }

    var note: String {
        switch self {
        case .unsure:
            return "We will use your state's commonly adopted edition and tell you where it differs from this app's tables."
        case .different:
            return "Use this app for navigation and method practice, then verify every value against the code in force where you work."
        default:
            return edition?.driftFromApp ?? ""
        }
    }
}

/// How far along the candidate is. The three original ids are load-bearing:
/// `HowToPlayContent.recommendedRoom` and Home's primer card both switch on
/// them, and they are already written to `electrician.skillLevel`.
enum ExperienceLevel: String, CaseIterable, Identifiable, Sendable {
    case new
    case apprentice
    case working
    case retaking
    case renewing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "Just starting"
        case .apprentice: return "In the apprenticeship"
        case .working: return "Sitting the exam soon"
        case .retaking: return "Retaking it"
        case .renewing: return "Licensed already"
        }
    }

    var detail: String {
        switch self {
        case .new: return "New to the code book and how the exam works"
        case .apprentice: return "Comfortable in the field, slow in the book"
        case .working: return "Want the articles that actually fail people"
        case .retaking: return "Been once. Want the calculations drilled hard"
        case .renewing: return "Keeping sharp, or working through continuing education"
        }
    }

    var icon: String {
        switch self {
        case .new: return "book.closed.fill"
        case .apprentice: return "hammer.fill"
        case .working: return "calendar.badge.clock"
        case .retaking: return "arrow.counterclockwise"
        case .renewing: return "checkmark.seal.fill"
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
        static let focusAreas = "candidate.focusAreas"
        static let dailyGoal = "candidate.dailyGoal"
    }

    private let defaults: UserDefaults

    @Published var licenseTrack: LicenseTrack {
        didSet { defaults.set(licenseTrack.rawValue, forKey: Keys.licenseTrack) }
    }

    /// Persisted as the display name, which is what this key has always held.
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

    /// Room ids the candidate asked to prioritise. Empty means "no preference",
    /// which is a real answer and not a missing one.
    @Published var focusAreas: Set<String> {
        didSet { defaults.set(Array(focusAreas).sorted(), forKey: Keys.focusAreas) }
    }

    /// Questions a day the candidate is aiming for.
    @Published var dailyGoal: Int {
        didSet { defaults.set(dailyGoal, forKey: Keys.dailyGoal) }
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
        // Absent key resolves to the app's own edition, not to "not sure":
        // installs that predate the wider picker chose from a two-option list
        // whose default was this app's edition, and re-labelling their saved
        // answer as an unanswered question would be wrong.
        edition = CandidateEdition(rawValue: defaults.string(forKey: Keys.edition) ?? "") ?? .nec2023
        examDate = defaults.object(forKey: Keys.examDate) as? Date
        focusAreas = Set(defaults.stringArray(forKey: Keys.focusAreas) ?? [])
        dailyGoal = defaults.object(forKey: Keys.dailyGoal) as? Int ?? 15
        hasSelectedTrack = defaults.bool(forKey: Keys.hasSelectedTrack)
        setupComplete = defaults.bool(forKey: Keys.setupComplete)
    }

    var trimmedJurisdiction: String {
        jurisdiction.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The matching record, when the saved name is one this app knows.
    var jurisdictionRecord: Jurisdiction? {
        Jurisdictions.named(jurisdiction)
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

    // MARK: - Edition

    /// What the state table suggests, when it has an opinion. This is what
    /// makes "I'm not sure" a usable answer instead of a dead end.
    var suggestedEdition: NECEdition? {
        jurisdictionRecord?.commonEdition
    }

    /// The edition to reason about: the explicit choice, else the state's.
    var resolvedEdition: NECEdition? {
        edition.edition ?? (edition == .unsure ? suggestedEdition : nil)
    }

    var editionSummary: String {
        if let resolved = resolvedEdition {
            return edition == .unsure ? "\(resolved.displayName) (from \(trimmedJurisdiction))" : resolved.displayName
        }
        return edition == .different ? "Another edition" : "Edition not set"
    }

    /// True only when we know the edition AND it is the one the app's tables
    /// are built from. An unknown edition is not a match.
    var editionMatchesApp: Bool {
        resolvedEdition == NECEdition.app
    }

    /// The one line the candidate most needs on the home screen and in
    /// Settings: does this app's arithmetic land on their exam or not.
    var editionAdvice: String {
        guard let resolved = resolvedEdition else {
            return "Set your code edition so we can tell you where this app's \(NECTables.edition) values differ from your exam."
        }
        return resolved.driftFromApp
    }

    // MARK: - Exam date

    var daysUntilExam: Int? {
        guard let examDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: examDate)
        ).day
        return days.map { max(0, $0) }
    }

    var examCountdownSummary: String? {
        guard let days = daysUntilExam else { return nil }
        switch days {
        case 0: return "Exam today"
        case 1: return "1 day out"
        default: return "\(days) days out"
        }
    }

    /// A daily target that actually reaches a useful total before the date.
    /// Clamped so a candidate three days out is not told to do 200 a day and a
    /// candidate a year out is not told to do two.
    var suggestedDailyQuestions: Int {
        guard let days = daysUntilExam, days > 0 else { return 15 }
        let target = 600.0
        let raw = Int((target / Double(days)).rounded(.up))
        return min(60, max(10, raw))
    }

    // MARK: - Mutations

    func selectTrack(_ track: LicenseTrack) {
        licenseTrack = track
        hasSelectedTrack = true
    }

    /// Selecting a state never rewrites an explicit edition answer. The
    /// suggestion is applied lazily by `resolvedEdition` while the answer is
    /// still `.unsure`, so correcting your state after choosing an edition
    /// cannot silently discard the edition you chose.
    func selectJurisdiction(_ record: Jurisdiction) {
        jurisdiction = record.name
    }

    func toggleFocus(_ roomID: String) {
        if focusAreas.contains(roomID) {
            focusAreas.remove(roomID)
        } else {
            focusAreas.insert(roomID)
        }
    }

    func completeSetup() {
        guard canCompleteSetup else { return }
        setupComplete = true
    }
}
