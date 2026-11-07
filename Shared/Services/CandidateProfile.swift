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
        case .apprentice: return String(localized: "Apprentice")
        case .residential: return String(localized: "Residential")
        case .journeyman: return String(localized: "Journeyman")
        case .master: return String(localized: "Master")
        case .contractor: return String(localized: "Contractor")
        }
    }

    /// Short enough for a segmented control on a 375pt phone.
    var shortName: String {
        switch self {
        case .apprentice: return String(localized: "App.")
        case .residential: return String(localized: "Res.")
        case .journeyman: return String(localized: "Jrny.")
        case .master: return String(localized: "Master")
        case .contractor: return String(localized: "Contr.")
        }
    }

    var detail: String {
        switch self {
        case .apprentice:
            return String(localized: "Working toward the hours, or sitting an entrance/aptitude test")
        case .residential:
            return String(localized: "Residential wireman or limited residential licence")
        case .journeyman:
            return String(localized: "The full journeyman/electrician licence exam")
        case .master:
            return String(localized: "Master electrician, usually journeyman plus added years")
        case .contractor:
            return String(localized: "Electrical contractor, often a business-and-law paper as well")
        }
    }

    /// What the exam tends to weight for this track. Not a claim about any one
    /// state's blueprint, and worded that way.
    var emphasis: String {
        switch self {
        case .apprentice:
            return String(localized: "Expect mostly code navigation and arithmetic. Live in Code Basics first.")
        case .residential:
            return String(localized: "Branch circuits, box fill, and dwelling-unit receptacle and GFCI rules carry the most weight.")
        case .journeyman:
            return String(localized: "Ampacity and derating, overcurrent sizing, conduit and box fill, grounding and motors. That is what this app drills.")
        case .master:
            return String(localized: "Everything the journeyman paper covers, plus heavier calculation and more Chapter 2 and Chapter 3 lookup under time.")
        case .contractor:
            return String(localized: "The technical paper overlaps the master exam. The business-and-law paper is separate and this app does not cover it.")
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
        case .unsure: return String(localized: "I'm not sure")
        case .different: return String(localized: "Another edition")
        default: return edition?.displayName ?? String(localized: "Another edition")
        }
    }

    var note: String {
        switch self {
        case .unsure:
            return String(localized: "We will use your state's commonly adopted edition and tell you where it differs from this app's tables.")
        case .different:
            return String(localized: "Use this app for navigation and method practice, then verify every value against the code in force where you work.")
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
        case .new: return String(localized: "Just starting")
        case .apprentice: return String(localized: "In the apprenticeship")
        case .working: return String(localized: "Sitting the exam soon")
        case .retaking: return String(localized: "Retaking it")
        case .renewing: return String(localized: "Licensed already")
        }
    }

    var detail: String {
        switch self {
        case .new: return String(localized: "New to the code book and how the exam works")
        case .apprentice: return String(localized: "Comfortable in the field, slow in the book")
        case .working: return String(localized: "Want the articles that actually fail people")
        case .retaking: return String(localized: "Been once. Want the calculations drilled hard")
        case .renewing: return String(localized: "Keeping sharp, or working through continuing education")
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

/// What the remaining time before the exam means for how a candidate should
/// use the app. Derived, never stored: the exam date is the only fact, and a
/// stored pace would go stale every night at midnight.
enum StudyPace: String, CaseIterable, Identifiable, Sendable {
    /// Three days or fewer. Triage: calculations only, mistakes only.
    case cram
    /// Up to two weeks. Every shape once, then the ones being missed.
    case sprint
    /// Two weeks to two months. The full syllabus with room to repeat it.
    case build
    /// More than two months, or no date. Build the navigation habit first.
    case foundation
    case undated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cram: return String(localized: "Cram plan")
        case .sprint: return String(localized: "Sprint plan")
        case .build: return String(localized: "Build plan")
        case .foundation: return String(localized: "Foundation plan")
        case .undated: return String(localized: "Steady plan")
        }
    }

    /// One line, in the second person, that says what to do with the time left.
    var summary: String {
        switch self {
        case .cram:
            return String(localized: "There is no time to cover everything, so do not try. Calculations only, then the mistakes you repeat. Navigation practice is the first thing to drop.")
        case .sprint:
            return String(localized: "Enough time to see every problem shape at least twice. Work each one until you can do it without the steps, then let Fix My Mistakes chase what is left.")
        case .build:
            return String(localized: "Enough time to cover the whole syllabus and then repeat the parts that fight back. Start with navigation, because it makes everything else faster.")
        case .foundation:
            return String(localized: "Time to build the habit properly. Learn how the book is organised first; the calculations get much easier once you can find things.")
        case .undated:
            return String(localized: "No date yet, so the goal is steady reps. Set a date whenever you book it and the plan sharpens up.")
        }
    }

    /// The order to work in, when there is not time for everything. Rendered as
    /// a numbered list, so each line is one instruction.
    var priorities: [String] {
        switch self {
        case .cram:
            return [
                String(localized: "Derating, breaker sizing and conduit fill. These are the most-failed shapes and the most generatable, so they are where a day buys the most."),
                String(localized: "Fix My Mistakes, twice a day. It is the only thing here that gets more valuable the less time you have."),
                String(localized: "Skim the grounding vocabulary. Four terms, four meanings, and it is free points."),
                String(localized: "Do not start anything new the night before. Re-run the shapes you already got right."),
            ]
        case .sprint:
            return [
                String(localized: "One pass through every problem shape in Endless Practice, so nothing on the paper is unfamiliar."),
                String(localized: "Worked Calculations for anything you missed, because a miss is almost always one skipped step."),
                String(localized: "Grounding and motors: the two articles that decide the most papers."),
                String(localized: "One timed run every few days, to rehearse the clock rather than the content."),
            ]
        case .build:
            return [
                String(localized: "Code Basics first. Knowing where a question lives is worth more than knowing any single answer."),
                String(localized: "Then one room a week, all the way through."),
                String(localized: "Endless Practice daily on whichever shape you are weakest at."),
                String(localized: "Timed Challenge weekly, once the content is solid."),
            ]
        case .foundation, .undated:
            return [
                String(localized: "How the book is built, then the article families. This is the part that pays off for the rest of your career, not just the exam."),
                String(localized: "One Code Minute a day. The habit matters more than the volume right now."),
                String(localized: "Add a calculation room once navigation feels quick."),
            ]
        }
    }

    /// True where the app should be steering toward triage rather than
    /// coverage. Home, onboarding and the plan recap all branch on this.
    var isUrgent: Bool { self == .cram || self == .sprint }
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

    /// The saved state, translated for display. The stored value stays the
    /// English name so it keeps matching `Jurisdictions.named`.
    var displayJurisdiction: String {
        jurisdictionRecord?.displayName ?? trimmedJurisdiction
    }

    var targetSummary: String {
        guard setupComplete else { return String(localized: "Set your exam target") }
        return "\(licenseTrack.displayName) · \(displayJurisdiction)"
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
            return edition == .unsure ? String(localized: "\(resolved.displayName) (from \(displayJurisdiction))") : resolved.displayName
        }
        return edition == .different ? String(localized: "Another edition") : String(localized: "Edition not set")
    }

    /// The edition alone, with no "(from Georgia)" attribution.
    ///
    /// `editionSummary` names its SOURCE, which is right on a settings row
    /// where the reader is deciding whether to trust a suggestion and wrong
    /// anywhere the state is already on screen: Home's subtitle rendered
    /// "2020 NEC (from Georgia) · Georgia".
    var editionShortSummary: String {
        if let resolved = resolvedEdition { return resolved.displayName }
        return edition == .different ? String(localized: "Another edition") : String(localized: "Edition not set")
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
            return String(localized: "Set your code edition so we can tell you where this app's \(NECTables.edition) values differ from your exam.")
        }
        return resolved.driftFromApp
    }

    // MARK: - Exam date

    /// Whole days to the exam: 0 on the day itself, nil with no date or once it
    /// has gone by. It used to clamp at zero, so the day after the exam Home
    /// still read "Exam today" and kept the cram plan up every day afterwards.
    var daysUntilExam: Int? {
        guard let examDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: examDate)
        ).day
        guard let days, days >= 0 else { return nil }
        return days
    }

    var examCountdownSummary: String? {
        guard let days = daysUntilExam else { return nil }
        switch days {
        case 0: return String(localized: "Exam today")
        default: return String(localized: "\(days) days out")
        }
    }

    /// How the remaining time changes what the app should ask of a candidate.
    ///
    /// The date is not just a countdown. A candidate sitting the exam tomorrow
    /// and a candidate sitting it in four months want opposite things, and the
    /// old single formula served neither: 600 questions divided by the days
    /// left told someone with three days to do 60 a day for three days, which
    /// is 180 questions and not a plan, and it told someone with a year to do
    /// ten a day forever with no sense of build.
    var pace: StudyPace {
        guard let days = daysUntilExam else { return .undated }
        switch days {
        case ...3: return .cram
        case 4...14: return .sprint
        case 15...60: return .build
        default: return .foundation
        }
    }

    /// A daily target the pace actually supports.
    ///
    /// Cramming is capped rather than computed. Dividing a fixed total by one
    /// remaining day produces a number nobody will do, and a target nobody will
    /// do is worse than a smaller one they will: it makes the countdown card a
    /// reproach on the morning of the exam.
    var suggestedDailyQuestions: Int {
        guard let days = daysUntilExam, days > 0 else {
            return pace == .cram ? 40 : 15
        }
        switch pace {
        case .cram: return 60
        case .sprint: return min(50, max(25, Int((400.0 / Double(days)).rounded(.up))))
        case .build: return min(35, max(15, Int((600.0 / Double(days)).rounded(.up))))
        case .foundation, .undated: return 15
        }
    }

    /// What the daily target adds up to by the time the exam arrives, or nil
    /// with no upcoming date. The exam day itself counts as one day of work.
    var plannedQuestions: Int? {
        guard let days = daysUntilExam else { return nil }
        return suggestedDailyQuestions * max(days, 1)
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

    /// The fields Exam Target edits, as they stood when it opened. Its fields
    /// write through, so Cancel puts this back.
    struct Snapshot: Equatable {
        let licenseTrack: LicenseTrack
        let hasSelectedTrack: Bool
        let jurisdiction: String
        let edition: CandidateEdition
        let examDate: Date?
        let dailyGoal: Int
    }

    func snapshot() -> Snapshot {
        Snapshot(
            licenseTrack: licenseTrack,
            hasSelectedTrack: hasSelectedTrack,
            jurisdiction: jurisdiction,
            edition: edition,
            examDate: examDate,
            dailyGoal: dailyGoal
        )
    }

    /// Writes back only what changed, so an untouched key stays absent.
    func restore(_ saved: Snapshot) {
        if licenseTrack != saved.licenseTrack { licenseTrack = saved.licenseTrack }
        if hasSelectedTrack != saved.hasSelectedTrack { hasSelectedTrack = saved.hasSelectedTrack }
        if jurisdiction != saved.jurisdiction { jurisdiction = saved.jurisdiction }
        if edition != saved.edition { edition = saved.edition }
        if examDate != saved.examDate { examDate = saved.examDate }
        if dailyGoal != saved.dailyGoal { dailyGoal = saved.dailyGoal }
    }
}
