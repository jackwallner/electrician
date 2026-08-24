import Foundation

/// The room structure. Two free rooms open the app, two paid rooms carry the
/// articles the exam actually fails people on.
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
