import Foundation

/// One normalized, single-select item inside a Quick Session. Built from
/// whichever choice-gradeable content is behind it (quiz, hand-match, or a
/// flashcard with a CardChoice) so the session itself never has to know the
/// source shape, just prompt/givens/choices/answer.
struct QuickItem: Identifiable, Sendable {
    let id: String
    let prompt: String
    let givens: [Given]
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    /// A calculation's working, one line per step, in order. Empty for items
    /// that are not calculations. Kept as a list rather than flattened into
    /// `explanation` because a paragraph hides WHICH step was skipped, and a
    /// skipped step is how almost every calculation is actually missed.
    let steps: [String]
    /// The article to look the answer up in, rendered under the working.
    let citation: String?
    /// e.g. "Conductors & Ampacity", shown as a small tag above the prompt.
    let sourceLabel: String
    /// The room this item came from, for per-room accuracy stats. Generated
    /// items report the room whose skill they drill.
    let roomID: String
    /// The persistence row this answer contributes to. Most authored items use
    /// their own id. Procedural daily items can share one bounded rollup row.
    let trackingID: String
    /// False for one-off generated prompts that can never be scheduled back
    /// into Fix My Mistakes as the same question. Their mistake PATTERN still
    /// comes back; see `mistakes`.
    let isReviewable: Bool
    /// Choice label to the named mistake that produces it. A wrong pick that
    /// appears here can be named to the reader and tallied for targeted
    /// practice.
    let mistakes: [String: MistakePattern]

    init(
        id: String,
        prompt: String,
        givens: [Given],
        choices: [String],
        answerIndex: Int,
        explanation: String,
        steps: [String] = [],
        citation: String? = nil,
        sourceLabel: String,
        roomID: String,
        trackingID: String? = nil,
        isReviewable: Bool = true,
        mistakes: [String: MistakePattern] = [:]
    ) {
        self.id = id
        self.prompt = prompt
        self.givens = givens
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.steps = steps
        self.citation = citation
        self.sourceLabel = sourceLabel
        self.roomID = roomID
        self.trackingID = trackingID ?? id
        self.isReviewable = isReviewable
        self.mistakes = mistakes
    }

    /// The named mistake behind a pick, if this item knows one.
    func mistake(forChoiceAt index: Int) -> MistakePattern? {
        guard choices.indices.contains(index) else { return nil }
        return mistakes[choices[index]]
    }
}

/// Builds the Quick Session: a short run of choice-only items pulled from
/// across the rooms, weighted so misses come back first and unseen material
/// beats review. Plain flip flashcards and worked calculations are excluded;
/// they aren't right/wrong in one tap and don't belong in a uniform choice flow.
enum SessionBuilder {

    static let sessionDrill = Drill(
        id: "quick-session",
        title: "Quick Session",
        subtitle: "A short mix of what you need next",
        kind: .flashcards([])
    )

    static let reviewDrill = Drill(
        id: "review-session",
        title: "Fix My Mistakes",
        subtitle: "The questions you keep getting wrong",
        kind: .flashcards([])
    )

    static let examWarmUpDrill = Drill(
        // Same rule as the notification route: this id keys completion counts
        // already on device, so it stays put while the symbol gets the honest
        // name.
        id: "game-night-prep",
        title: "Exam Warm-Up",
        subtitle: "A short targeted mix before the exam",
        kind: .flashcards([])
    )

    static func quickSession(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        includePro: Bool
    ) -> [QuickItem] {
        let pool = choicePool(includePro: includePro)

        // Priority tiers: missed first, unseen next, review last.
        func tier(_ item: QuickItem) -> Int {
            if missed.contains(item.id) { return 0 }
            if !seen.contains(item.id) { return 1 }
            return 2
        }
        let picked = Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)

        return picked.map(prepared)
    }

    /// The Fix My Mistakes session: exactly the items the scheduler says are
    /// due, in the order it ranked them. Unlike Quick Session this never pads
    /// with fresh material - the whole point is a short run of the questions a
    /// player actually keeps getting wrong.
    static func reviewSession(ids: [String], includePro: Bool) -> [QuickItem] {
        let pool = Dictionary(choicePool(includePro: includePro).map { ($0.id, $0) }) { first, _ in first }
        return ids.compactMap { pool[$0] }.map(prepared)
    }

    /// A member's pre-game session. Due mistakes lead, then the weakest room,
    /// then unseen material. The final tier keeps the session full for a new
    /// player who has not built enough history to personalize yet.
    static func examWarmUp(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        dueIDs: [String],
        weakestRoomID: String?
    ) -> [QuickItem] {
        let due = Set(dueIDs)
        let pool = choicePool(includePro: true)

        func tier(_ item: QuickItem) -> Int {
            if due.contains(item.id) { return 0 }
            if missed.contains(item.id) { return 1 }
            if item.roomID == weakestRoomID { return 2 }
            if !seen.contains(item.id) { return 3 }
            return 4
        }

        return Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)
            .map(prepared)
    }

    /// Used by deterministic daily features to draw from a particular room
    /// without exposing locked content to callers that did not request it.
    static func choiceItems(in roomID: String, includePro: Bool) -> [QuickItem] {
        choicePool(includePro: includePro).filter { $0.roomID == roomID }
    }

    /// Answer-position variety: shuffle each item's choices deterministically
    /// by its own id so the order is stable across re-render/undo but not
    /// always the authored slot.
    static func prepared(_ item: QuickItem) -> QuickItem {
        let shuffled = ChoiceShuffle.shuffledChoices(labels: item.choices, answerIndex: item.answerIndex, seed: item.id)
        // `mistakes` is keyed by choice LABEL, not by index, so it survives the
        // shuffle untouched. Keying it by index is the bug waiting to happen.
        return QuickItem(
            id: item.id,
            prompt: item.prompt,
            givens: item.givens,
            choices: shuffled.labels,
            answerIndex: shuffled.answerIndex,
            explanation: item.explanation,
            steps: item.steps,
            citation: item.citation,
            sourceLabel: item.sourceLabel,
            roomID: item.roomID,
            trackingID: item.trackingID,
            isReviewable: item.isReviewable,
            mistakes: item.mistakes
        )
    }

    /// Every choice-gradeable item a player is entitled to: the free rooms'
    /// free drills, plus (for members) the locked extra sets and the paid room.
    static func choicePool(includePro: Bool) -> [QuickItem] {
        var pool: [QuickItem] = []
        for room in DrillLibrary.rooms where room.isFree || includePro {
            for drill in room.drills where !room.isLocked(drill, isMember: includePro) {
                switch drill.kind {
                case .quiz(let questions):
                    pool += questions.map { question in
                        QuickItem(
                            id: question.id,
                            prompt: question.prompt,
                            givens: question.givens,
                            choices: question.choices,
                            answerIndex: question.answerIndex,
                            explanation: question.explanation,
                            citation: question.citation,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .articleMatch(let questions):
                    pool += questions.map { question in
                        let labels = question.choices.map(\.shortName)
                        let answerIndex = question.choices.firstIndex(of: question.answer) ?? 0
                        return QuickItem(
                            id: question.id,
                            prompt: question.scenario,
                            givens: [],
                            choices: labels,
                            answerIndex: answerIndex,
                            explanation: question.explanation,
                            citation: question.answer.citation,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .flashcards(let cards):
                    pool += cards.compactMap { card in
                        guard let choice = card.choice else { return nil }
                        var prompt = card.frontTitle
                        if let subtitle = card.frontSubtitle {
                            prompt += "\n\(subtitle)"
                        }
                        return QuickItem(
                            id: card.id,
                            prompt: prompt,
                            givens: card.givens,
                            choices: choice.options,
                            answerIndex: choice.answerIndex,
                            explanation: card.backBody,
                            citation: card.citation,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .calc:
                    break // Worked calculations need their steps; they get their own runner.
                }
            }
        }
        return pool
    }
}
