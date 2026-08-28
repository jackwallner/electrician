import Foundation

/// The NEC edition a candidate is actually examined on.
///
/// The app's authored content and `NECTables` follow one edition
/// (`NECTables.edition`). A candidate sitting an exam written against a
/// different cycle needs to be told that, in the terms of their own state,
/// before they trust a number. That is the whole reason this type exists.
enum NECEdition: Int, CaseIterable, Identifiable, Sendable, Comparable {
    case nec2011 = 2011
    case nec2014 = 2014
    case nec2017 = 2017
    case nec2020 = 2020
    case nec2023 = 2023
    case nec2026 = 2026

    var id: Int { rawValue }
    var year: Int { rawValue }
    var displayName: String { "\(rawValue) NEC" }

    static func < (lhs: NECEdition, rhs: NECEdition) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The edition this app's tables are written to, resolved from the single
    /// source of truth so the two can never drift apart silently.
    static var app: NECEdition {
        let digits = NECTables.edition.prefix(4)
        return NECEdition(rawValue: Int(digits) ?? 2023) ?? .nec2023
    }

    /// What changed between this edition and the app's, at the level a
    /// candidate needs. Deliberately about *scope of difference*, not a
    /// reproduction of either code text.
    var driftFromApp: String {
        let app = NECEdition.app
        if self == app {
            return "This is the edition every table and answer in the app is built from."
        }
        if self < app {
            return "Older than the app's \(app.displayName). Ampacity tables, the small-conductor rule and overcurrent sizing are the same in practice; GFCI and AFCI coverage, receptacle placement and the surge-protection and emergency-disconnect requirements are where the two cycles differ. Practice the calculations here and check those areas in your own book."
        }
        return "Newer than the app's \(app.displayName). Conductor ampacity and overcurrent sizing carry forward; the newer cycle expands protection and equipment-disconnect requirements. Verify those against your own book."
    }
}

/// How a state hands out the licence a candidate is studying for.
enum LicensePath: String, Sendable {
    /// The state itself licenses journeymen and masters.
    case statewide
    /// The state licenses contractors; the journeyman card comes from a city
    /// or county. This is the single most common thing candidates get wrong
    /// about their own state, so it is a first-class field, not a footnote.
    case contractorOnly
    /// No state licence at all; the city or county is the whole story.
    case local

    var summary: String {
        switch self {
        case .statewide: return "Licensed by the state"
        case .contractorOnly: return "State licenses contractors; local for journeyman"
        case .local: return "Licensed locally, not by the state"
        }
    }
}

/// One US state, district or territory, with the facts a candidate needs
/// before their first practice question.
///
/// **On accuracy.** Code adoption and exam vendors move. `commonEdition` is
/// labelled in the UI as "commonly adopted", every screen that shows one of
/// these records also shows `authority` and a confirm-with-your-board line,
/// and the candidate is asked to confirm the edition on the very next step
/// rather than having it silently applied. Treat this table as a good
/// starting suggestion that the candidate ratifies, which is exactly how it is
/// presented. Re-check it against the NFPA adoption map and the state boards
/// when `Jurisdictions.reviewed` goes stale.
struct Jurisdiction: Identifiable, Hashable, Sendable {
    /// Postal abbreviation, and the stable id. `name` is what is persisted in
    /// `CandidateProfile`, because that key already holds free text.
    let id: String
    let name: String
    /// nil when there is no statewide adoption to speak of.
    let commonEdition: NECEdition?
    let authority: String
    /// The vendor that actually delivers the exam, when there is one.
    let examProvider: String?
    let path: LicensePath

    var editionLabel: String {
        commonEdition?.displayName ?? "Adopted locally"
    }

    var providerLabel: String {
        examProvider ?? "Varies by jurisdiction"
    }
}

enum Jurisdictions {
    /// When this table was last checked. Rendered in the UI: a candidate
    /// deciding whether to trust a suggestion is entitled to know how old it is.
    static let reviewed = "August 2026"

    /// The sentinel for anyone outside the list, including candidates outside
    /// the United States. Selecting it never suppresses a step; it just means
    /// the app has nothing to suggest and says so.
    static let other = Jurisdiction(
        id: "XX",
        name: "Not listed",
        commonEdition: nil,
        authority: "Your local authority having jurisdiction",
        examProvider: nil,
        path: .local
    )

    static let all: [Jurisdiction] = [
        Jurisdiction(id: "AL", name: "Alabama", commonEdition: .nec2020,
                     authority: "Alabama Electrical Contractors Board",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "AK", name: "Alaska", commonEdition: .nec2020,
                     authority: "Dept. of Labor, Mechanical Inspection",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "AZ", name: "Arizona", commonEdition: .nec2017,
                     authority: "Registrar of Contractors",
                     examProvider: nil, path: .contractorOnly),
        Jurisdiction(id: "AR", name: "Arkansas", commonEdition: .nec2020,
                     authority: "Board of Electrical Examiners",
                     examProvider: "Prov", path: .statewide),
        Jurisdiction(id: "CA", name: "California", commonEdition: .nec2020,
                     authority: "Dept. of Industrial Relations (certification)",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "CO", name: "Colorado", commonEdition: .nec2023,
                     authority: "State Electrical Board (DORA)",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "CT", name: "Connecticut", commonEdition: .nec2020,
                     authority: "Dept. of Consumer Protection",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "DE", name: "Delaware", commonEdition: .nec2023,
                     authority: "Board of Electrical Examiners",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "DC", name: "District of Columbia", commonEdition: .nec2017,
                     authority: "Dept. of Licensing and Consumer Protection",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "FL", name: "Florida", commonEdition: .nec2020,
                     authority: "Electrical Contractors' Licensing Board",
                     examProvider: "Pearson VUE", path: .contractorOnly),
        Jurisdiction(id: "GA", name: "Georgia", commonEdition: .nec2020,
                     authority: "Construction Industry Licensing Board",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "HI", name: "Hawaii", commonEdition: .nec2017,
                     authority: "Board of Electricians and Plumbers",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "ID", name: "Idaho", commonEdition: .nec2023,
                     authority: "Division of Occupational and Professional Licenses",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "IL", name: "Illinois", commonEdition: nil,
                     authority: "City or county (Chicago has its own code)",
                     examProvider: nil, path: .local),
        Jurisdiction(id: "IN", name: "Indiana", commonEdition: .nec2011,
                     authority: "City or county",
                     examProvider: nil, path: .local),
        Jurisdiction(id: "IA", name: "Iowa", commonEdition: .nec2020,
                     authority: "Iowa Electrical Examining Board",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "KS", name: "Kansas", commonEdition: nil,
                     authority: "City or county",
                     examProvider: nil, path: .local),
        Jurisdiction(id: "KY", name: "Kentucky", commonEdition: .nec2020,
                     authority: "Dept. of Housing, Buildings and Construction",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "LA", name: "Louisiana", commonEdition: .nec2020,
                     authority: "State Licensing Board for Contractors",
                     examProvider: "Prov", path: .contractorOnly),
        Jurisdiction(id: "ME", name: "Maine", commonEdition: .nec2023,
                     authority: "Electricians' Examining Board",
                     examProvider: "Prov", path: .statewide),
        Jurisdiction(id: "MD", name: "Maryland", commonEdition: .nec2023,
                     authority: "Board of Master Electricians",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "MA", name: "Massachusetts", commonEdition: .nec2023,
                     authority: "Board of State Examiners of Electricians",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "MI", name: "Michigan", commonEdition: .nec2020,
                     authority: "LARA Electrical Administrative Board",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "MN", name: "Minnesota", commonEdition: .nec2023,
                     authority: "Dept. of Labor and Industry",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "MS", name: "Mississippi", commonEdition: .nec2020,
                     authority: "State Board of Contractors",
                     examProvider: "Prov", path: .contractorOnly),
        Jurisdiction(id: "MO", name: "Missouri", commonEdition: nil,
                     authority: "City or county",
                     examProvider: nil, path: .local),
        Jurisdiction(id: "MT", name: "Montana", commonEdition: .nec2023,
                     authority: "State Electrical Board",
                     examProvider: "Prov", path: .statewide),
        Jurisdiction(id: "NE", name: "Nebraska", commonEdition: .nec2023,
                     authority: "State Electrical Division",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "NV", name: "Nevada", commonEdition: .nec2020,
                     authority: "State Contractors Board; county journeyman cards",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "NH", name: "New Hampshire", commonEdition: .nec2023,
                     authority: "Electricians' Board",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "NJ", name: "New Jersey", commonEdition: .nec2020,
                     authority: "Board of Examiners of Electrical Contractors",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "NM", name: "New Mexico", commonEdition: .nec2023,
                     authority: "Construction Industries Division",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "NY", name: "New York", commonEdition: .nec2020,
                     authority: "City or county (New York City has its own code)",
                     examProvider: nil, path: .local),
        Jurisdiction(id: "NC", name: "North Carolina", commonEdition: .nec2023,
                     authority: "State Board of Examiners of Electrical Contractors",
                     examProvider: "State board", path: .contractorOnly),
        Jurisdiction(id: "ND", name: "North Dakota", commonEdition: .nec2023,
                     authority: "State Electrical Board",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "OH", name: "Ohio", commonEdition: .nec2023,
                     authority: "Construction Industry Licensing Board",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "OK", name: "Oklahoma", commonEdition: .nec2020,
                     authority: "Construction Industries Board",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "OR", name: "Oregon", commonEdition: .nec2023,
                     authority: "Building Codes Division",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "PA", name: "Pennsylvania", commonEdition: .nec2020,
                     authority: "City or county (UCC sets the code)",
                     examProvider: nil, path: .local),
        Jurisdiction(id: "RI", name: "Rhode Island", commonEdition: .nec2023,
                     authority: "Division of Professional Regulation",
                     examProvider: "Prov", path: .statewide),
        Jurisdiction(id: "SC", name: "South Carolina", commonEdition: .nec2023,
                     authority: "Contractor's Licensing Board",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "SD", name: "South Dakota", commonEdition: .nec2023,
                     authority: "State Electrical Commission",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "TN", name: "Tennessee", commonEdition: .nec2020,
                     authority: "Board for Licensing Contractors",
                     examProvider: "PSI", path: .contractorOnly),
        Jurisdiction(id: "TX", name: "Texas", commonEdition: .nec2023,
                     authority: "Dept. of Licensing and Regulation (TDLR)",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "UT", name: "Utah", commonEdition: .nec2023,
                     authority: "Division of Professional Licensing",
                     examProvider: "Pearson VUE", path: .statewide),
        Jurisdiction(id: "VT", name: "Vermont", commonEdition: .nec2023,
                     authority: "Electricians Licensing Board",
                     examProvider: "Prov", path: .statewide),
        Jurisdiction(id: "VA", name: "Virginia", commonEdition: .nec2023,
                     authority: "Dept. of Professional and Occupational Regulation",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "WA", name: "Washington", commonEdition: .nec2023,
                     authority: "Dept. of Labor and Industries",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "WV", name: "West Virginia", commonEdition: .nec2023,
                     authority: "State Fire Marshal",
                     examProvider: "Prov", path: .statewide),
        Jurisdiction(id: "WI", name: "Wisconsin", commonEdition: .nec2023,
                     authority: "Dept. of Safety and Professional Services",
                     examProvider: "PSI", path: .statewide),
        Jurisdiction(id: "WY", name: "Wyoming", commonEdition: .nec2023,
                     authority: "State Electrical Board",
                     examProvider: "State-administered", path: .statewide),
        Jurisdiction(id: "PR", name: "Puerto Rico", commonEdition: .nec2020,
                     authority: "Colegio de Peritos Electricistas",
                     examProvider: nil, path: .statewide),
        other,
    ]

    /// Lookup by the persisted display name. `CandidateProfile.jurisdiction`
    /// has always held free text, so anything a candidate typed before this
    /// list existed simply fails to match and the app makes no suggestion,
    /// which is the correct behaviour rather than a migration.
    static func named(_ name: String) -> Jurisdiction? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return all.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
            ?? all.first { $0.id.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    /// Case- and prefix-insensitive search for the picker's search field.
    static func matching(_ query: String) -> [Jurisdiction] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.id.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
