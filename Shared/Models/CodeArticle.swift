import Foundation

/// The article families a licensing exam actually navigates.
///
/// The exam is open book and timed, so the tested skill is not recall, it is
/// knowing which article owns a question before you open the book. That is what
/// `ArticleMatchQuestion` drills, and this enum is its answer set.
///
/// Article numbers are citations, not code text. Every description here is
/// written from scratch to point a reader at the right place to look.
enum CodeArticle: String, Codable, CaseIterable, Identifiable, Sendable {
    case definitions
    case branchCircuits
    case loadCalculations
    case overcurrent
    case grounding
    case conductors
    case boxes
    case raceways
    case motors

    var id: String { rawValue }

    /// The article number as an electrician would cite it out loud.
    var citation: String {
        switch self {
        case .definitions: return "Art. 100"
        case .branchCircuits: return "Art. 210"
        case .loadCalculations: return "Art. 220"
        case .overcurrent: return "Art. 240"
        case .grounding: return "Art. 250"
        case .conductors: return "Art. 310"
        case .boxes: return "Art. 314"
        case .raceways: return "Ch. 9"
        case .motors: return "Art. 430"
        }
    }

    var displayName: String {
        switch self {
        case .definitions: return "Definitions"
        case .branchCircuits: return "Branch Circuits"
        case .loadCalculations: return "Load Calculations"
        case .overcurrent: return "Overcurrent Protection"
        case .grounding: return "Grounding & Bonding"
        case .conductors: return "Conductors & Ampacity"
        case .boxes: return "Boxes & Enclosures"
        case .raceways: return "Raceway Fill"
        case .motors: return "Motors"
        }
    }

    /// Short label for a choice chip, where the citation carries the meaning.
    var shortName: String {
        switch self {
        case .definitions: return "100 Definitions"
        case .branchCircuits: return "210 Branch Ckts"
        case .loadCalculations: return "220 Load Calc"
        case .overcurrent: return "240 Overcurrent"
        case .grounding: return "250 Grounding"
        case .conductors: return "310 Conductors"
        case .boxes: return "314 Boxes"
        case .raceways: return "Ch. 9 Fill"
        case .motors: return "430 Motors"
        }
    }

    /// The tell that sends you to this article. Written as the cue an
    /// electrician actually uses, not as a table of contents entry.
    var howToSpot: String {
        switch self {
        case .definitions:
            return "The question turns on what a word means rather than on a number. If you are arguing about whether something counts as a dwelling unit, a device, or readily accessible, the answer is in the definitions and nowhere else."
        case .branchCircuits:
            return "Anything about what a circuit is allowed to serve and how outlets get placed: receptacle spacing, required small-appliance circuits, GFCI and AFCI coverage, the 15 and 20 amp rules."
        case .loadCalculations:
            return "The question hands you square footage, appliance nameplates, or a list of loads and wants a service or feeder size. If you are adding VA together, you are in load calculations."
        case .overcurrent:
            return "Sizing or placing the protection itself: breaker and fuse ratings, the standard sizes, the next-size-up rule, and the small-conductor ceiling that overrides the ampacity table."
        case .grounding:
            return "Anything with the word grounding, bonding, electrode, or equipment ground in it. The most-failed section on the exam, because the vocabulary is precise and close terms mean different things."
        case .conductors:
            return "The conductor itself: allowable ampacity, the temperature columns, ambient correction, and the adjustment for bundling more than three current-carrying conductors."
        case .boxes:
            return "How much fits in the box, and what the box has to be. Volume allowances per conductor, what a device or clamp counts as, and support requirements."
        case .raceways:
            return "How many conductors fit in a pipe. The fill percentages and the conductor and raceway area tables all live in Chapter 9, not in the raceway articles themselves, which is the part people miss."
        case .motors:
            return "Motors run on their own rules. The tables replace the nameplate for conductor sizing, the overload and short-circuit protection are separate calculations, and the numbers do not match anything in the ampacity table."
        }
    }
}
