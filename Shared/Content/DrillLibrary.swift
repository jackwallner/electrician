import Foundation

/// The room structure. Three free rooms open the app, three paid rooms carry
/// the calculations and the articles the exam actually fails people on.
///
/// Installation Rules is free on purpose, and it is the widest door in the app:
/// working space, burial depth, support spacing and receptacle placement are
/// the questions an apprentice, a homeowner and a licensed electrician all have
/// a reason to look up, so it brings in readers a pure exam-prep room never
/// would, and every one of them lands one tap from the paid calculations.
///
/// Room ids are referenced by `PracticeSkill.roomID` and by the stats
/// breakdown, so renaming one means updating both.
enum DrillLibrary {

    static let rooms: [Room] = [
        Room(
            id: "basics-room",
            name: "Code Basics",
            tagline: "How the book works before what it says",
            icon: "book.closed.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "meet-the-code",
                    title: "How the Book Is Built",
                    subtitle: "Flashcards: chapters, mandatory language, and the words that decide answers",
                    kind: .flashcards(CodeBasicsContent.meetTheCode)
                ),
                Drill(
                    id: "navigation-quiz",
                    title: "Find It Fast",
                    subtitle: "Quiz: where each kind of question actually lives",
                    kind: .quiz(CodeBasicsContent.navigationQuiz)
                ),
                Drill(
                    id: "article-cards",
                    title: "Know the Articles",
                    subtitle: "Flashcards: every article family and the tell that sends you there",
                    kind: .flashcards(ArticleContent.articleCards)
                ),
                Drill(
                    id: "article-match",
                    title: "Which Article?",
                    subtitle: "Read a scenario, name the article, before you open the book",
                    kind: .articleMatch(ArticleContent.articleMatch)
                ),
                Drill(
                    id: "plus-basics-extras",
                    title: "Find It Fast: Extra Reps",
                    subtitle: "Four more on scope, the double 125%, and Annex C",
                    kind: .quiz(PlusContent.basicsExtras),
                    isPlus: true
                ),
                Drill(
                    id: "plus-article-extras",
                    title: "Which Article? Extra Reps",
                    subtitle: "Taps, GFCI placement, and support spacing",
                    kind: .articleMatch(PlusContent.articleExtras),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "conductors-room",
            name: "Conductors & Ampacity",
            tagline: "Three columns, two factors, one cap",
            icon: "cable.connector",
            isFree: true,
            drills: [
                Drill(
                    id: "ampacity-cards",
                    title: "Reading the Table",
                    subtitle: "Flashcards: the columns, the corrections, and 240.4(D)",
                    kind: .flashcards(ConductorContent.ampacityCards)
                ),
                Drill(
                    id: "ampacity-quiz",
                    title: "Ampacity Check",
                    subtitle: "Quiz: terminations, counting conductors, and the small-conductor cap",
                    kind: .quiz(ConductorContent.ampacityQuiz)
                ),
                Drill(
                    id: "plus-conductor-extras",
                    title: "Ampacity Check: Extra Reps",
                    subtitle: "Combining factors, paralleling, and aluminum's own numbers",
                    kind: .quiz(PlusContent.conductorExtras),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "install-room",
            name: "Installation Rules",
            tagline: "Working space, cover, support, spacing",
            icon: "ruler.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "workspace-cards",
                    title: "Room to Work",
                    subtitle: "Flashcards: depth, width, headroom, and the space above the panel",
                    kind: .flashcards(InstallContent.workingSpaceCards)
                ),
                Drill(
                    id: "cover-support-cards",
                    title: "Depth and Straps",
                    subtitle: "Flashcards: burial cover, support spacing, and the 360 degree rule",
                    kind: .flashcards(InstallContent.coverAndSupportCards)
                ),
                Drill(
                    id: "install-quiz",
                    title: "Rules Check",
                    subtitle: "Quiz: the numbers that are worth the most per minute on the paper",
                    kind: .quiz(InstallContent.installQuiz)
                ),
                Drill(
                    id: "install-match",
                    title: "Which Article? Installation",
                    subtitle: "Article 110, 230 and 300 against the ones they get confused with",
                    kind: .articleMatch(InstallContent.installArticleMatch)
                ),
            ]
        ),
        Room(
            id: "calc-room",
            name: "Worked Calculations",
            tagline: "One number out, and the steps that got there",
            icon: "function",
            isFree: false,
            drills: [
                Drill(
                    id: "worked-examples",
                    title: "The Five Shapes",
                    subtitle: "Derating, breaker sizing, conduit fill, box fill, voltage drop",
                    kind: .calc(CalcContent.workedExamples)
                ),
            ]
        ),
        Room(
            id: "loads-room",
            name: "Service & Load Calc",
            tagline: "The longest question on the paper",
            icon: "house.fill",
            isFree: false,
            drills: [
                Drill(
                    id: "load-cards",
                    title: "What Goes Where",
                    subtitle: "Flashcards: which loads take a demand factor and which have their own table",
                    kind: .flashcards(LoadContent.loadCards)
                ),
                Drill(
                    id: "load-quiz",
                    title: "Load Check",
                    subtitle: "Quiz: the eight steps, one at a time",
                    kind: .quiz(LoadContent.loadQuiz)
                ),
                Drill(
                    id: "load-worked",
                    title: "One House, Both Methods",
                    subtitle: "The same dwelling worked standard and optional, so the difference is visible",
                    kind: .calc(LoadContent.workedExamples)
                ),
            ]
        ),
        Room(
            id: "grounding-room",
            name: "Grounding & Motors",
            tagline: "The two articles that decide a pass",
            icon: "bolt.horizontal.circle.fill",
            isFree: false,
            drills: [
                Drill(
                    id: "grounding-cards",
                    title: "Four Terms, Four Meanings",
                    subtitle: "Flashcards: grounded, grounding, electrode, equipment",
                    kind: .flashcards(ProContent.groundingCards)
                ),
                Drill(
                    id: "grounding-quiz",
                    title: "Grounding Check",
                    subtitle: "Quiz: sizing from the right table, and the rod ceiling",
                    kind: .quiz(ProContent.groundingQuiz)
                ),
                Drill(
                    id: "motor-cards",
                    title: "Nameplate or Table",
                    subtitle: "Flashcards: the reversal at the centre of Article 430",
                    kind: .flashcards(ProContent.motorCards)
                ),
                Drill(
                    id: "motor-quiz",
                    title: "Motor Check",
                    subtitle: "Quiz: conductors, overload, and which value feeds which",
                    kind: .quiz(ProContent.motorQuiz)
                ),
            ]
        ),
    ]

    // MARK: - Counting what is actually here
    //
    // The membership pitch quotes these rather than an adjective. "More
    // practice" is a claim a reader discounts on sight; "the free rooms hold 74
    // questions and you will finish them in three days" is an argument, and it
    // is only an argument if the number is computed from the library rather
    // than typed into a marketing string and left to rot.

    /// Authored items a non-member can reach.
    static var freeItemCount: Int {
        rooms.filter(\.isFree)
            .flatMap(\.drills)
            .filter { !$0.isPlus }
            .reduce(0) { $0 + $1.kind.itemCount }
    }

    /// Authored items the membership unlocks: whole paid rooms, plus the extra
    /// sets inside the free ones.
    static var membershipItemCount: Int {
        rooms.reduce(0) { total, room in
            total + room.drills
                .filter { room.isLocked($0, isMember: false) }
                .reduce(0) { $0 + $1.kind.itemCount }
        }
    }

    /// Drills the membership unlocks, across every room.
    static var membershipDrillCount: Int {
        rooms.reduce(0) { $0 + $1.plusDrillCount }
    }

    /// The room a given id belongs to, for stats labelling.
    static func room(id: String) -> Room? {
        rooms.first { $0.id == id }
    }

    /// The room that owns a drill, for the per-room accuracy breakdown.
    static func roomID(forDrillID drillID: String) -> String {
        rooms.first { room in
            room.drills.contains { $0.id == drillID }
        }?.id ?? "basics-room"
    }
}
