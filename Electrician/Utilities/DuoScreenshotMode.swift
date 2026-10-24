#if DEBUG
import SwiftUI

/// Unattended iPhone Duo capture (gh-sim launch --device 'iPhone Duo').
/// DEBUG only, so none of it ships.
///
/// `-DuoSeed` fills the real stores with a believable month of study (no
/// network, no RevenueCat). `-DuoTour` then walks Home through `-DuoRoutes a,b`
/// on a timer, because `simctl openurl` raises a confirmation sheet and the
/// capture job cannot tap. `-DuoTourStep <s>` is the dwell per route and
/// `-DuoTourFirst <s>` the delay before the first; `-DuoTourStepRegular <s>`
/// overrides the dwell while split (the inner display). The tour restarts when
/// the panes split or join, so folded and unfolded each get the full walk.
///
/// Routes: home, quick, room-<id>, drill-<id>, endless, minute, warmup, timed,
/// fix, tools, readiness, howto, stats, settings, paywall.
enum DuoScreenshotMode {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var isSeeded: Bool { arguments.contains("-DuoSeed") }
    static var wantsTour: Bool { arguments.contains("-DuoTour") }

    static func value(_ key: String) -> String? {
        guard let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    /// A journeyman candidate five weeks out from the exam, a week into a
    /// streak, strong on the free rooms and still working on the calculations.
    @MainActor
    static func seedIfNeeded() {
        let defaults = UserDefaults.standard
        // gh-sim relaunches the app for the inner display; seed once, so both
        // displays show the same month.
        guard isSeeded, !defaults.bool(forKey: "duo.seeded") else { return }
        defaults.set(true, forKey: "duo.seeded")
        defaults.set(true, forKey: "progress.hasOnboarded")
        defaults.set(true, forKey: "electrician.hasReadPrimer")
        defaults.set("apprentice", forKey: "electrician.skillLevel")
        defaults.set(true, forKey: "subscription.localProOverride")

        let day: TimeInterval = 86_400
        let now = Date()

        let profile = CandidateProfile.shared
        profile.selectTrack(.journeyman)
        profile.jurisdiction = "Colorado"
        profile.edition = .nec2023
        profile.examDate = Calendar.current.startOfDay(for: now).addingTimeInterval(38 * day)
        profile.dailyGoal = 25
        profile.completeSetup()

        // A drill or two a day for a week, so the streak and the rings agree.
        let progress = ProgressStore.shared
        let finished = [
            ["meet-the-code", "navigation-quiz"], ["article-cards"], ["ampacity-cards", "ampacity-quiz"],
            ["workspace-cards"], ["install-quiz", "article-match"], ["worked-examples"], ["load-cards", "grounding-cards"],
        ]
        for (offset, drills) in finished.enumerated() {
            let when = now.addingTimeInterval(-Double(finished.count - 1 - offset) * day)
            for drillID in drills { progress.recordSession(drillID: drillID, now: when) }
        }

        // How much of each room is answered reliably; the misses keep the
        // calculation rooms honest rather than perfect.
        let known: [String: Double] = [
            "basics-room": 0.9, "conductors-room": 0.8, "install-room": 0.75,
            "calc-room": 0.55, "loads-room": 0.45, "grounding-room": 0.6,
        ]
        let records = PracticeRecordStore.shared
        for room in DrillLibrary.rooms {
            let ids = room.drills.flatMap(itemIDs)
            let share = known[room.id] ?? 0
            let answered = Int((Double(ids.count) * min(1, share + 0.2)).rounded())
            let locked = Int(Double(ids.count) * share)
            for (n, id) in ids.prefix(answered).enumerated() {
                let when = now.addingTimeInterval(-Double(n % 6 + 1) * day)
                records.record(itemID: id, roomID: room.id, correct: true, now: when)
                if n < locked {
                    records.record(itemID: id, roomID: room.id, correct: true, now: when.addingTimeInterval(3600))
                } else {
                    records.record(itemID: id, roomID: room.id, correct: false, now: when.addingTimeInterval(3600))
                }
                progress.recordItem(id: id, correct: n < locked)
            }
        }
        records.recordChallengeScore(14)

        // Generated calculations by skill: two strong, three worth sharpening.
        let skills: [(PracticeSkill, Int, Int)] = [
            (.ampacity, 24, 19), (.overcurrent, 16, 14), (.conduitFill, 14, 10),
            (.voltageDrop, 10, 6), (.egcSizing, 9, 7),
        ]
        for (skill, attempts, correct) in skills {
            for n in 0..<attempts {
                records.record(itemID: "\(skill.itemPrefix)duo-\(n)", roomID: skill.roomID, correct: n < correct,
                               now: now.addingTimeInterval(-day))
            }
        }
        // The traps this candidate keeps walking into, so Fix My Mistakes and
        // the breakdown have something specific to say.
        for (pattern, misses) in [(CandidateMistake.derateFrom75, 3), (CandidateMistake.ignoredTerminationCap, 2),
                                  (CandidateMistake.loadForgotLightingDemand, 1)] {
            for _ in 0..<misses { records.recordMistake(pattern, now: now.addingTimeInterval(-day)) }
        }

        // The last three Code Minutes, so the week reads as a habit; today's
        // is left open so its start button shows.
        let minutes = CodeMinuteStore.shared
        let scores: [[Bool]] = [[true, true, false, true, true], [true, true, true, true, false], [true, false, true, true, true]]
        for (offset, answers) in scores.enumerated() {
            let date = now.addingTimeInterval(-Double(offset + 1) * day)
            minutes.record(challenge: CodeMinuteContent.challenge(for: date), answers: answers, now: date)
        }
    }

    private static func itemIDs(_ drill: Drill) -> [String] {
        switch drill.kind {
        case .flashcards(let cards): cards.map(\.id)
        case .quiz(let questions): questions.map(\.id)
        case .articleMatch(let questions): questions.map(\.id)
        case .calc(let scenarios): scenarios.map(\.id)
        }
    }

    enum Route: Hashable {
        case quick
        case room(String)
        case drill(String)
        case stats, endless, minute, warmup, timed, fix, tools, readiness, howto
    }

    @MainActor @ViewBuilder
    static func destination(_ route: Route, progress: ProgressStore, subscriptions: SubscriptionService) -> some View {
        switch route {
        case .quick:
            QuickSessionView(items: quickSessionItems())
        case .room(let id):
            if let room = DrillLibrary.room(id: id) { RoomView(room: room) }
        case .drill(let id):
            drillView(id)
        case .stats: StatsView()
        case .endless: EndlessPickerView()
        case .minute: CodeMinuteView()
        case .warmup: ExamWarmUpView()
        case .timed: PracticeRunView(mode: .timed)
        case .fix:
            PracticeRunView(mode: .review, items: EndlessPractice.targetedItems(
                for: PracticeRecordStore.shared.outstandingMistakes(), count: 6))
        case .tools: FieldToolsView()
        case .readiness: PracticeReadinessView()
        case .howto: HowToPlayView()
        }
    }

    /// The real Quick Session reshuffles on every launch, so a capture could
    /// open on any of a few hundred items. This one is fixed: it leads with the
    /// 14 AWG cap question, whose givens and named trap are the app at its most
    /// typical, then fills the run from the pool in id order.
    private static func quickSessionItems() -> [QuickItem] {
        let pool = SessionBuilder.choicePool(includePro: true).sorted { $0.id < $1.id }
        let lead = pool.filter { $0.id == "cond-q-14awg" }
        let rest = pool.filter { $0.id != "cond-q-14awg" }
        return (lead + rest).prefix(10).map(SessionBuilder.prepared)
    }

    @MainActor @ViewBuilder
    private static func drillView(_ id: String) -> some View {
        if let room = DrillLibrary.rooms.first(where: { $0.drills.contains { $0.id == id } }),
           let drill = room.drills.first(where: { $0.id == id }) {
            switch drill.kind {
            case .flashcards(let cards): FlashcardDrillView(drill: drill, cards: cards, accent: room.accent)
            case .quiz(let questions): QuizDrillView(drill: drill, questions: questions)
            case .articleMatch(let questions): QuizDrillView(drill: drill, questions: questions.map(\.asQuizQuestion))
            case .calc(let scenarios): CalcDrillView(drill: drill, scenarios: scenarios)
            }
        }
    }
}

extension HomeView {
    /// Walks `-DuoRoutes` (default: the whole app). Sheets close first and the
    /// previous push pops, so every route is shown from a clean Home.
    @MainActor
    func runDuoTour() async {
        guard DuoScreenshotMode.wantsTour else { return }
        // The inner display's screenshots are slower, so it may want a longer dwell.
        let unfolded = split != nil
        let stepKey = unfolded ? "-DuoTourStepRegular" : "-DuoTourStep"
        let step = Double(DuoScreenshotMode.value(stepKey) ?? DuoScreenshotMode.value("-DuoTourStep") ?? "") ?? 10
        let first = Double(DuoScreenshotMode.value("-DuoTourFirst") ?? "") ?? 2
        let routes = (DuoScreenshotMode.value("-DuoRoutes") ?? Self.defaultDuoRoutes)
            .split(separator: ",").map(String.init)
        try? await Task.sleep(nanoseconds: UInt64(first * 1_000_000_000))
        for route in routes {
            if Task.isCancelled { return }
            NSLog("DUOTOUR %@ route=%@", unfolded ? "inner" : "outer", route)
            await openDuoRoute(route)
            try? await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
        }
    }

    static let defaultDuoRoutes =
        "home,quick,room-calc-room,drill-worked-examples,drill-ampacity-quiz,minute,tools,readiness,settings"

    @MainActor
    private func openDuoRoute(_ route: String) async {
        setDuoSheets(settings: false, paywall: false)
        duoRoute = nil
        try? await Task.sleep(nanoseconds: 700_000_000)
        switch route {
        case "settings": setDuoSheets(settings: true, paywall: false)
        case "paywall": setDuoSheets(settings: false, paywall: true)
        case "quick": duoRoute = .quick
        case "stats": duoRoute = .stats
        case "endless": duoRoute = .endless
        case "minute": duoRoute = .minute
        case "warmup": duoRoute = .warmup
        case "timed": duoRoute = .timed
        case "fix": duoRoute = .fix
        case "tools": duoRoute = .tools
        case "readiness": duoRoute = .readiness
        case "howto": duoRoute = .howto
        case _ where route.hasPrefix("room-"): duoRoute = .room(String(route.dropFirst(5)))
        case _ where route.hasPrefix("drill-"): duoRoute = .drill(String(route.dropFirst(6)))
        default: break
        }
    }
}
#endif
