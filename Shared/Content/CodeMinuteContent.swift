import Foundation

enum CodeMinuteCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case navigation
    case ampacity
    case calculation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigation: return "Navigation"
        case .ampacity: return "Ampacity"
        case .calculation: return "Calculation"
        }
    }

    var icon: String {
        switch self {
        case .navigation: return "book.closed.fill"
        case .ampacity: return "cable.connector"
        case .calculation: return "function"
        }
    }
}

struct CodeMinuteQuestion: Sendable {
    let category: CodeMinuteCategory
    let item: QuickItem
}

struct CodeMinuteChallenge: Identifiable, Sendable {
    let day: Date
    let dayKey: String
    let shortDate: String
    let questions: [CodeMinuteQuestion]

    var id: String { dayKey }
    var items: [QuickItem] { questions.map(\.item) }
}

/// One shared five-question set per Code Minute day.
///
/// Everyone who opens the app on the same day gets the same five, which is what
/// makes the score shareable. Two are generated calculations seeded off the
/// date so they are identical for every reader without being stored anywhere;
/// three are drawn from the authored pool by the same seed.
enum CodeMinuteContent {
    static let questionCount = 5

    /// The day boundary, fixed rather than local.
    ///
    /// "The same five questions for every member" is a promise, and
    /// `Calendar.current` breaks it: two readers either side of midnight local
    /// time get different sets while their share cards claim the same day. The
    /// app is US-only, so the boundary is US Pacific: the challenge turns over
    /// at midnight for the latest US time zone and no reader is more than three
    /// hours from their own midnight. Change this and every stored `dayKey`
    /// shifts, so it is effectively permanent.
    static let dayCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    static let drill = Drill(
        id: "code-minute",
        title: "Code Minute",
        subtitle: "Today's shared five-question challenge",
        kind: .quiz([]),
        isPlus: true
    )

    static func challenge(for day: Date = Date(), calendar: Calendar = dayCalendar) -> CodeMinuteChallenge {
        let dayKey = key(for: day, calendar: calendar)
        var rng = SeededGenerator(seed: seed(from: dayKey))

        var questions: [CodeMinuteQuestion] = []

        // Two generated calculations, seeded so every reader sees the same two.
        var generator: RandomNumberGenerator = rng
        let shapes: [(CodeMinuteCategory, (inout RandomNumberGenerator) -> CalcScenario)] = [
            (.ampacity, CalcGenerator.ampacityProblem),
            (.calculation, CalcGenerator.conduitFillProblem),
        ]
        for (index, shape) in shapes.enumerated() {
            let scenario = shape.1(&generator)
            questions.append(CodeMinuteQuestion(
                category: shape.0,
                item: QuickItem(
                    id: "minute-\(dayKey)-gen-\(index)",
                    prompt: scenario.situation,
                    givens: scenario.givens,
                    choices: scenario.choices,
                    answerIndex: scenario.answerIndex,
                    explanation: scenario.steps.first ?? "",
                    steps: scenario.steps,
                    citation: scenario.citation,
                    sourceLabel: "Code Minute",
                    roomID: shape.0 == .ampacity ? "conductors-room" : "calc-room",
                    trackingID: "code-minute-rollup",
                    isReviewable: false,
                    mistakes: scenario.mistakes
                )
            ))
        }
        rng = generator as? SeededGenerator ?? rng

        // Three authored items, chosen deterministically from the same seed.
        let pool = SessionBuilder.choicePool(includePro: true).sorted { $0.id < $1.id }
        if !pool.isEmpty {
            var used: Set<String> = []
            var attempts = 0
            while questions.count < questionCount, attempts < pool.count * 4 {
                attempts += 1
                let picked = pool[Int(rng.next() % UInt64(pool.count))]
                guard used.insert(picked.id).inserted else { continue }
                questions.append(CodeMinuteQuestion(
                    category: category(forRoom: picked.roomID),
                    item: SessionBuilder.prepared(picked)
                ))
            }
        }

        return CodeMinuteChallenge(
            day: day,
            dayKey: dayKey,
            shortDate: shortDate(for: day, calendar: calendar),
            questions: questions
        )
    }

    private static func category(forRoom roomID: String) -> CodeMinuteCategory {
        switch roomID {
        case "conductors-room": return .ampacity
        case "calc-room": return .calculation
        default: return .navigation
        }
    }

    static func key(for day: Date, calendar: Calendar = dayCalendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static func shortDate(for day: Date, calendar: Calendar = dayCalendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        // The time zone as well as the calendar: without it the formatter falls
        // back to the device zone and can print a different date than `dayKey`
        // was computed from, which is exactly the bug the fixed boundary exists
        // to prevent.
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMM d"
        return formatter.string(from: day)
    }

    private static func seed(from dayKey: String) -> UInt64 {
        // FNV-1a. Small, stable, and identical on every device, which is the
        // only property that matters for a shared daily.
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in dayKey.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
