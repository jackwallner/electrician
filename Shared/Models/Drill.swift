import Foundation

/// A two-option self-test on a card's front. Answering flips the card and
/// grades the pick before the explanation lands.
struct CardChoice: Sendable {
    let options: [String]
    let answerIndex: Int

    init(_ first: String, _ second: String, answerIndex: Int) {
        options = [first, second]
        self.answerIndex = answerIndex
    }
}

struct Flashcard: Identifiable, Sendable {
    let id: String
    let frontTitle: String
    let givens: [Given]
    let frontSubtitle: String?
    let backTitle: String
    let backBody: String
    /// The article to look this up in. Shown on the back so every card teaches
    /// navigation alongside the fact.
    let citation: String?
    let choice: CardChoice?

    init(id: String, frontTitle: String, givens: [Given] = [], frontSubtitle: String? = nil,
         backTitle: String, backBody: String, citation: String? = nil,
         choice: CardChoice? = nil) {
        self.id = id
        self.frontTitle = frontTitle
        self.givens = givens
        self.frontSubtitle = frontSubtitle
        self.backTitle = backTitle
        self.backBody = backBody
        self.citation = citation
        self.choice = choice
    }
}

struct QuizQuestion: Identifiable, Sendable {
    let id: String
    let prompt: String
    let givens: [Given]
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    let citation: String?

    init(id: String, prompt: String, givens: [Given] = [], choices: [String],
         answerIndex: Int, explanation: String, citation: String? = nil) {
        self.id = id
        self.prompt = prompt
        self.givens = givens
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.citation = citation
    }
}

/// "Which article governs this?" The open-book exam rewards knowing where to
/// look before you look, so this is a first-class drill and not a warm-up.
struct ArticleMatchQuestion: Identifiable, Sendable {
    let id: String
    let scenario: String
    let choices: [CodeArticle]
    let answer: CodeArticle
    let explanation: String
}

/// A worked calculation: conditions in, one number out, and the steps that got
/// there. The steps matter as much as the answer, because a candidate who
/// misses the order of operations misses every problem of that shape.
struct CalcScenario: Identifiable, Sendable {
    let id: String
    let situation: String
    let givens: [Given]
    /// The choices shown, already formatted (e.g. "60 A").
    let choices: [String]
    let answerIndex: Int
    /// Each step as one line of reasoning, in order.
    let steps: [String]
    let citation: String
}

enum DrillKind: Sendable {
    case flashcards([Flashcard])
    case quiz([QuizQuestion])
    case articleMatch([ArticleMatchQuestion])
    case calc([CalcScenario])

    var itemCount: Int {
        switch self {
        case .flashcards(let cards): return cards.count
        case .quiz(let questions): return questions.count
        case .articleMatch(let questions): return questions.count
        case .calc(let scenarios): return scenarios.count
        }
    }
}

struct Drill: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: DrillKind
    /// Extra practice sets inside an otherwise-free room: same mechanics, more
    /// original questions, locked behind Electrician+. Nothing that was free
    /// became paid; these are additions.
    let isPlus: Bool

    init(id: String, title: String, subtitle: String, kind: DrillKind, isPlus: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.isPlus = isPlus
    }
}

struct Room: Identifiable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let icon: String
    /// A free room still opens for everyone; individual `isPlus` drills inside
    /// it are the locked extras. A non-free room is locked whole.
    let isFree: Bool
    let drills: [Drill]

    /// Drills a member unlocks here: the whole room if it's paid, otherwise
    /// just the extra sets.
    var plusDrillCount: Int {
        isFree ? drills.filter(\.isPlus).count : drills.count
    }

    func isLocked(_ drill: Drill, isMember: Bool) -> Bool {
        guard !isMember else { return false }
        return !isFree || drill.isPlus
    }
}

extension ArticleMatchQuestion {
    /// Article match runs through the standard quiz view. The choices are
    /// article short names and the explanation gains the citation, so the
    /// reader always leaves with somewhere to look.
    var asQuizQuestion: QuizQuestion {
        QuizQuestion(
            id: id,
            prompt: scenario,
            choices: choices.map(\.shortName),
            answerIndex: choices.firstIndex(of: answer) ?? 0,
            explanation: explanation,
            citation: answer.citation
        )
    }
}
