import Foundation

/// One page of the quick-start primer.
///
/// Every explanation is written from scratch. Article numbers are citations
/// pointing the reader at their own code book; nothing here reproduces NEC
/// text.
struct HowToPlayPage: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let givens: [Given]
    let tip: String?

    init(id: String, icon: String, title: String, body: String,
         givens: [Given] = [], tip: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.givens = givens
        self.tip = tip
    }
}

/// The five-minute primer for anyone who picked "starting out" in onboarding.
/// It explains how the exam works before it explains any rule, because that is
/// the part nobody tells you and it changes how you study.
enum HowToPlayContent {
    static let pages: [HowToPlayPage] = [
        HowToPlayPage(
            id: "htp-openbook",
            icon: "book.closed.fill",
            title: "It is an open-book exam",
            body: "You bring the code book in with you. That sounds like relief and it is actually the whole difficulty: the exam is timed, and a question you have to hunt for costs you two more you never reach. What is being tested is navigation speed, not memory.",
            tip: "Tab your book. Candidates who tab and candidates who do not are not taking the same test."
        ),
        HowToPlayPage(
            id: "htp-structure",
            icon: "list.number",
            title: "Nine chapters, in an order that matters",
            body: "Chapters 1 through 4 apply everywhere. Chapters 5, 6 and 7 cover special occupancies, equipment and conditions, and they modify the general chapters. Chapter 8 is communications. Chapter 9 is nothing but tables, and it is where the fill math lives even though people look for it in the raceway articles.",
            tip: "When a special rule and a general rule disagree, the special rule wins."
        ),
        HowToPlayPage(
            id: "htp-columns",
            icon: "cable.connector",
            title: "Three temperature columns",
            body: "A conductor's insulation picks which column you read. The equipment it lands on picks which column you may finish in, and most equipment is 75°C. So the pattern for nearly every derating question is: start at 90, correct and adjust, then check it against 75 and take the lower number.",
            givens: [.conductor("6 AWG", "THHN"), .terminals(.c75)],
            tip: "Starting the derate from the 75°C value gives a wrong answer that looks right."
        ),
        HowToPlayPage(
            id: "htp-two-factors",
            icon: "thermometer.medium",
            title: "Heat and crowding both cost you",
            body: "The ampacity table assumes 30°C and no more than three current-carrying conductors. Hotter air multiplies the number down. Four or more current-carrying conductors multiplies it down again. Both apply together, and they multiply rather than add.",
            givens: [.ambient(45), .currentCarrying(6)],
            tip: "An equipment grounding conductor is never current-carrying. Count it and you get the wrong factor."
        ),
        HowToPlayPage(
            id: "htp-240-4-d",
            icon: "bolt.shield.fill",
            title: "The rule that beats the table",
            body: "14, 12 and 10 AWG copper are capped at 15, 20 and 30 amps for overcurrent protection no matter what the ampacity table says. Aluminum 12 and 10 cap at 15 and 25. More candidates lose points to this one rule than to any other in the book.",
            givens: [.conductor("12 AWG", "THWN-2"), .material(.copper)],
            tip: "If a question hands you a small conductor, check 240.4(D) before you answer."
        ),
        HowToPlayPage(
            id: "htp-practice",
            icon: "infinity",
            title: "Why this app generates problems",
            body: "Derating, breaker sizing, conduit fill, box fill and voltage drop are pure calculations: same inputs, same answer, every time. That means they can be generated endlessly instead of shipped as a fixed question bank you memorise the shape of. Every wrong choice you see is the number you get from one specific, common mistake.",
            tip: "Read the steps after a miss. The step you skipped is the one that will cost you again."
        ),
        HowToPlayPage(
            id: "htp-coverage",
            icon: "checklist",
            title: "What this app covers today",
            // The page before this one describes the whole code book, which is
            // an easy thing to mistake for a claim about the app. It is not.
            // Saying where the drills actually go is more useful than implying
            // a curriculum that does not exist yet, and a candidate who finds
            // the gap themselves after paying is right to be annoyed.
            body: "Six rooms: how the book is organized and how to find an article, conductors and ampacity, the installation rules you look up on site, the worked calculations, dwelling service and load calculations, and grounding with motors. On top of those the generator runs \(PracticeSkill.allCases.count) calculation shapes without limit. That is deliberately the part of the exam that is pure calculation and pure navigation.",
            tip: "Services, feeders, load calculations, wiring methods and the special occupancy chapters are not covered yet. Keep studying those from your own book."
        ),
    ]
}

extension HowToPlayContent {
    /// Maps the onboarding experience level (defaults key
    /// `electrician.skillLevel`) to the room recommended at the end of the
    /// primer. Someone already working in the trade does not need the chapter
    /// tour; they need the article that fails people.
    static func recommendedRoom(forSkillLevel skillLevel: String) -> Room {
        let roomID: String
        switch ExperienceLevel(rawValue: skillLevel) {
        case .apprentice: roomID = "conductors-room"
        case .working: roomID = "grounding-room"
        // Been once already: the calculations are what sent them back, so
        // that is where the primer points rather than the chapter tour.
        case .retaking: roomID = "calc-room"
        case .renewing: roomID = "grounding-room"
        case .new, .none: roomID = "basics-room"
        }
        return DrillLibrary.rooms.first { $0.id == roomID } ?? DrillLibrary.rooms[0]
    }

    /// A candidate's focus picks win over the experience-level default: they
    /// were asked the question directly and answering it should do something.
    static func recommendedRoom(forSkillLevel skillLevel: String,
                                focusAreas: Set<String>) -> Room {
        if let focused = DrillLibrary.rooms.first(where: { focusAreas.contains($0.id) }) {
            return focused
        }
        return recommendedRoom(forSkillLevel: skillLevel)
    }
}
