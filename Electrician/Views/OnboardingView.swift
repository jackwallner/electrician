import SwiftUI

/// Onboarding: three value pages, a seven-step exam setup, a plan recap, then
/// the trial step.
///
/// **Why this is a step machine and not a paged `TabView`.** The paged version
/// this replaces had three defects that all came from the same place. A page
/// view cannot refuse a swipe, so the Continue button could be disabled on the
/// setup page while a swipe walked straight past it into the paywall with no
/// jurisdiction set. A `ScrollView` with a `TextField` inside a horizontal
/// pager fights both the swipe gesture and the keyboard, so the footer CTA
/// jumped. And the footer reserved height for controls that only exist on the
/// last page, so every page carried the dead space. Driving one `step` value
/// and transitioning explicitly fixes all three: advancing is the only way
/// forward, `canAdvance` gates it, and each step draws only its own chrome.
struct OnboardingView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var profile: CandidateProfile
    @EnvironmentObject private var settings: AppSettings

    @State private var step: Step = .openBook
    @State private var purchasing = false
    @State private var showPaywallFallback = false
    @State private var purchaseError: String?
    @State private var jurisdictionQuery = ""
    /// Set when the candidate reopens the list after already choosing. The
    /// list is 53 rows: leaving it expanded under the answer pushes the facts
    /// card off screen the moment they pick, which is the one thing they
    /// picked in order to read.
    @State private var pickingState = false
    @State private var editionPrefilled = false
    /// Which way the last navigation went, so a Back tap slides back rather
    /// than forward. A step machine that always animates forward reads as if
    /// Back re-entered the previous screen instead of returning to it.
    @State private var goingForward = true
    @AppStorage("electrician.skillLevel") private var skillLevel = ""

    private enum Stage: Equatable { case steps, tour, howToPlay }
    @State private var stage: Stage = .steps

    /// The order of the flow, and the only place it is written down.
    private enum Step: Int, CaseIterable, Comparable {
        case openBook, whatFails, walkInReady
        case track, jurisdiction, edition, examDate, experience, focus, reminder
        case plan, trial

        static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }

        /// Value pages carry no progress bar: nothing has been asked yet.
        var isSetup: Bool { self >= .track && self <= .reminder }
        static var setupSteps: [Step] { allCases.filter(\.isSetup) }
    }

    var body: some View {
        Group {
            switch stage {
            case .steps:
                stepsBody
            case .howToPlay:
                // Skip lands on Home, not on the next onboarding step: the
                // whole point of an escape hatch is that it escapes.
                HowToPlayView(onDone: { stage = .tour }, onSkip: { finish() })
                    .transition(Theme.Motion.advance)
            case .tour:
                FeatureTourView { finish() }
                    .transition(Theme.Motion.advance)
            }
        }
        .animation(Theme.Motion.screen, value: stage)
    }

    // MARK: - Shell

    private var stepsBody: some View {
        VStack(spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .background(Theme.background)
        .task {
            // `CandidateProfile` resolves an absent key to this app's own
            // edition, which is right for an install that answered the old
            // two-option picker and wrong for a first run: here the honest
            // starting answer is "not sure", so the state table gets to make
            // the suggestion. Guarded on setup so re-running onboarding after
            // a reset cannot wipe a real answer.
            guard !profile.setupComplete, !editionPrefilled else { return }
            editionPrefilled = true
            profile.edition = .unsure
        }
        .onChange(of: step) { _, newStep in
            guard newStep == .trial else { return }
            subscriptions.trackPaywallImpression(id: "electrician_onboarding_trial", oncePerSession: true)
        }
        .sheet(isPresented: $showPaywallFallback, onDismiss: paywallDismissed) {
            PaywallView(source: "electrician_onboarding_fallback")
        }
        .alert("Purchase Issue", isPresented: .init(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "")
        }
    }

    /// Back arrow, a bus-bar progress line, and the step count. Only the setup
    /// run gets the count: "4 of 7" on a marketing page is a chore bar.
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(width: 34, height: 34)
                    .background(Theme.card, in: Circle())
            }
            .opacity(step == .openBook ? 0 : 1)
            .disabled(step == .openBook)
            .accessibilityLabel("Back")

            BusBar(height: 4, progress: progressFraction)
                .frame(maxWidth: .infinity)

            Text(stepCountLabel)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.inkTertiary)
                .frame(width: 42, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .animation(Theme.Motion.screen, value: step)
    }

    private var progressFraction: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    private var stepCountLabel: String {
        guard step.isSetup, let index = Step.setupSteps.firstIndex(of: step) else { return " " }
        return "\(index + 1)/\(Step.setupSteps.count)"
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch step {
            case .openBook:
                infoPage(
                    icon: "book.closed.fill",
                    tint: Theme.voltage,
                    title: "The exam is open book",
                    body: "Which means it is not testing what you remember. It is testing how fast you find it. Short drills on where each kind of question actually lives.",
                    givens: []
                )
            case .whatFails:
                infoPage(
                    icon: "thermometer.medium",
                    tint: Theme.copper,
                    title: "The problems that fail people",
                    body: "Derating, breaker sizing, conduit and box fill, grounding conductors, motor circuits, the whole dwelling service. Every one is a pure calculation, so we generate them forever instead of shipping the same fifty questions.",
                    givens: [.conductor("6 AWG", "THHN"), .ambient(45), .currentCarrying(6)]
                )
            case .walkInReady:
                infoPage(
                    icon: "checkmark.seal.fill",
                    tint: Theme.ground,
                    title: "Walk in ready",
                    body: "Know the small-conductor cap, size a motor off the table and not the nameplate, and stop reading Table 250.66 where 250.122 was wanted. Sitting it this week? Tell us the date and we will tell you what to skip.",
                    givens: []
                )
            case .track: trackStep
            case .jurisdiction: jurisdictionStep
            case .edition: editionStep
            case .examDate: examDateStep
            case .experience: experienceStep
            case .focus: focusStep
            case .reminder: reminderStep
            case .plan: planStep
            case .trial: trialStep
            }
        }
        .transition(stepTransition)
        .animation(Theme.Motion.screen, value: step)
    }

    // MARK: - Value pages

    private func infoPage(icon: String, tint: Color, title: String,
                          body bodyText: String, givens: [Given]) -> some View {
        VStack(spacing: 26) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 96, height: 96)
                .background(tint.opacity(0.12), in: Circle())
                .overlay(Circle().strokeBorder(tint.opacity(0.25), lineWidth: 1))
            Text(title)
                .font(Theme.displayLarge)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if !givens.isEmpty {
                GivensView(givens: givens, scale: 1.15)
                    .padding(.horizontal, 24)
            }
            Text(bodyText)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Setup steps

    /// Shared chrome so all seven setup steps line up: same title position,
    /// same subtitle voice, same scroll behaviour.
    private func setupStep<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(Theme.screenTitle)
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                content()
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// The one row shape every choice in setup uses.
    private func choiceRow(title: String, detail: String?, icon: String?,
                           tint: Color = Theme.voltage, selected: Bool,
                           multi: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selected ? tint : Theme.inkTertiary)
                        .frame(width: 30, height: 30)
                        .background(
                            (selected ? tint : Theme.inkTertiary).opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.cardTitle)
                        .foregroundStyle(Theme.ink)
                    if let detail {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            // Wrap rather than truncate: the HStack will
                            // otherwise compress this to one line and clip it
                            // on a narrow phone or at larger type sizes.
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selectionIcon(selected: selected, multi: multi))
                    .font(.title3)
                    .foregroundStyle(selected ? tint : Theme.inkTertiary)
            }
            // The row grows with its detail text; without this the icon and
            // the radio drift to the vertical centre of a three-line row while
            // the title sits at the top, and the row reads as misaligned.
            .frame(minHeight: 30)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selected ? tint.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(selected ? tint : Theme.rule, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func selectionIcon(selected: Bool, multi: Bool) -> String {
        if multi { return selected ? "checkmark.square.fill" : "square" }
        return selected ? "checkmark.circle.fill" : "circle"
    }

    // MARK: Track

    private var trackStep: some View {
        setupStep(
            title: "Which licence?",
            subtitle: "It changes what we put in front of you first."
        ) {
            VStack(spacing: 10) {
                ForEach(LicenseTrack.allCases) { track in
                    choiceRow(
                        title: track.displayName,
                        detail: track.detail,
                        icon: nil,
                        selected: profile.licenseTrack == track && profile.hasSelectedTrack
                    ) {
                        profile.selectTrack(track)
                    }
                }
            }
            if profile.hasSelectedTrack {
                infoCard(icon: "target", tint: Theme.voltage, text: profile.licenseTrack.emphasis)
            }
        }
    }

    // MARK: Jurisdiction

    private var jurisdictionStep: some View {
        setupStep(
            title: "Where are you sitting it?",
            subtitle: "We use this to work out which code edition your exam is written against, and who actually issues your licence."
        ) {
            if showsStateList {
                stateSearchField
            }

            if let record = profile.jurisdictionRecord {
                JurisdictionFactsCard(record: record)
            }

            if showsStateList {
                let matches = Jurisdictions.matching(jurisdictionQuery)
                if matches.isEmpty {
                    Text("No match. Choose \(Jurisdictions.other.name) and set your edition by hand on the next step.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                }
                // A plain VStack, not a List: this already lives in the step's
                // ScrollView, and nesting a scrolling List inside it is what
                // makes a picker feel broken.
                VStack(spacing: 8) {
                    ForEach(matches) { record in
                        stateRow(record)
                    }
                }
            } else {
                Button("Choose a different state") { pickingState = true }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.voltage)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var stateSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.inkTertiary)
            TextField("Search states", text: $jurisdictionQuery)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            if !jurisdictionQuery.isEmpty {
                Button {
                    jurisdictionQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.inkTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Theme.well, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var showsStateList: Bool {
        pickingState || profile.jurisdictionRecord == nil
    }

    private func stateRow(_ record: Jurisdiction) -> some View {
        let selected = profile.trimmedJurisdiction.caseInsensitiveCompare(record.name) == .orderedSame
        return Button {
            profile.selectJurisdiction(record)
            jurisdictionQuery = ""
            pickingState = false
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack(spacing: 12) {
                Text(record.id)
                    .font(Theme.numeric(13, weight: .bold))
                    .foregroundStyle(selected ? .white : Theme.inkSecondary)
                    .frame(width: 34, height: 26)
                    .background(
                        selected ? Theme.voltageFill : Theme.well,
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                    )
                Text(record.name)
                    .font(.body.weight(selected ? .semibold : .regular))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(record.editionLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                selected ? Theme.voltage.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? Theme.voltage : Theme.rule, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    // MARK: Edition

    private var editionStep: some View {
        setupStep(
            title: "Which code edition?",
            subtitle: "Exams are written against one cycle. This app's numbers are \(NECTables.edition), and we would rather tell you where that differs than let you find out in the exam."
        ) {
            VStack(spacing: 10) {
                choiceRow(
                    title: suggestedEditionTitle,
                    detail: suggestedEditionDetail,
                    icon: "wand.and.stars",
                    tint: Theme.brass,
                    selected: profile.edition == .unsure
                ) {
                    profile.edition = .unsure
                }
                ForEach(offeredEditions, id: \.self) { candidate in
                    choiceRow(
                        title: candidate.displayName,
                        detail: candidate == .nec2023 ? "Matches this app's tables exactly" : nil,
                        icon: nil,
                        selected: profile.edition == candidate
                    ) {
                        profile.edition = candidate
                    }
                }
                choiceRow(
                    title: CandidateEdition.different.displayName,
                    detail: "Older than 2014, or a state code with heavy local amendments",
                    icon: nil,
                    selected: profile.edition == .different
                ) {
                    profile.edition = .different
                }
            }
            infoCard(
                icon: profile.editionMatchesApp ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tint: profile.editionMatchesApp ? Theme.ground : Theme.brass,
                text: profile.editionAdvice
            )
        }
    }

    /// 2014 through 2026: the editions a candidate can plausibly be examined on
    /// today. Anything older is `.different`, which is honest about the fact
    /// that the app cannot help with the values.
    private var offeredEditions: [CandidateEdition] {
        [.nec2014, .nec2017, .nec2020, .nec2023, .nec2026]
    }

    private var suggestedEditionTitle: String {
        guard let suggested = profile.suggestedEdition else { return "I'm not sure" }
        return "I'm not sure, use \(suggested.displayName)"
    }

    private var suggestedEditionDetail: String {
        guard let record = profile.jurisdictionRecord, record.commonEdition != nil else {
            return "Pick a state on the previous step and we can suggest one. Otherwise check with your board."
        }
        return "Commonly adopted in \(record.name) as of \(Jurisdictions.reviewed). Confirm with \(record.authority)."
    }

    // MARK: Exam date

    private var examDateStep: some View {
        setupStep(
            title: "When is the exam?",
            subtitle: "The date changes what we put in front of you, not just what the countdown says. Sitting it this week gets a different plan from sitting it in the spring. You can skip it."
        ) {
            VStack(spacing: 10) {
                ForEach(datePresets, id: \.label) { preset in
                    choiceRow(
                        title: preset.label,
                        detail: preset.detail,
                        icon: "calendar",
                        selected: matchesPreset(preset)
                    ) {
                        profile.examDate = preset.days.map {
                            Calendar.current.date(byAdding: .day, value: $0, to: Date())
                        } ?? nil
                    }
                }
            }
            if profile.examDate != nil {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker(
                        "Exam date",
                        selection: Binding(
                            get: { profile.examDate ?? Date() },
                            set: { profile.examDate = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(Theme.voltage)
                    if profile.daysUntilExam != nil {
                        Divider().overlay(Theme.rule)
                        HStack(spacing: 14) {
                            statPill(value: "\(profile.daysUntilExam ?? 0)", caption: countdownCaption)
                            statPill(value: "\(profile.suggestedDailyQuestions)", caption: "Questions a day")
                        }
                    }
                }
                .padding(14)
                .themedCard(corner: 16)

                // Shown the moment a date is set, not saved for the recap: the
                // reader who just tapped "Tomorrow" is deciding right now
                // whether this app is any use to them.
                StudyPaceCard(pace: profile.pace, daily: profile.suggestedDailyQuestions)
            }
        }
    }

    private struct DatePreset {
        let label: String
        let detail: String
        /// nil means "no date", which is a deliberate answer.
        let days: Int?
        /// How far the real date may sit from this preset and still light it
        /// up. Wider presets need wider tolerance; the near ones need almost
        /// none, or "tomorrow" and "later this week" would both look selected.
        let tolerance: Int
    }

    /// The list starts the day after tomorrow and not two weeks out, and that
    /// is the whole fix for the case this flow used to have no answer for.
    ///
    /// A candidate sitting the exam tomorrow is the most motivated reader this
    /// app will ever get: they have a date, they are frightened, and they will
    /// pay today. The old shortest option was "in about 2 weeks", so that
    /// reader either lied to the setup and got a plan built for someone with
    /// fourteen days, or skipped the step and got no plan at all. Both throw
    /// away the one thing the app could have done for them, which is tell them
    /// what to skip.
    private var datePresets: [DatePreset] {
        [
            DatePreset(label: "Tomorrow", detail: "No time to cover everything. We will tell you what to skip.",
                       days: 1, tolerance: 0),
            DatePreset(label: "Later this week", detail: "Triage: calculations, then the mistakes you repeat.",
                       days: 5, tolerance: 2),
            DatePreset(label: "In about 2 weeks", detail: "Every problem shape twice, then the weak ones.",
                       days: 14, tolerance: 3),
            DatePreset(label: "In about a month", detail: "Enough to cover every room twice.",
                       days: 30, tolerance: 5),
            DatePreset(label: "In about 3 months", detail: "Comfortable. Build the navigation habit first.",
                       days: 90, tolerance: 20),
            DatePreset(label: "No date yet", detail: "Study now, book later. Nothing is locked by this.",
                       days: nil, tolerance: 0),
        ]
    }

    private func matchesPreset(_ preset: DatePreset) -> Bool {
        guard let days = preset.days else { return profile.examDate == nil }
        guard let actual = profile.daysUntilExam else { return false }
        // Presets are approximate by design, so the selected state has to be
        // approximate too, or picking "about a month" then nudging the date by
        // a day would visibly deselect the row the candidate just tapped. The
        // tolerance is per preset rather than a flat three days: a flat three
        // would light "later this week" up for someone sitting it tomorrow.
        return abs(actual - days) <= preset.tolerance
    }

    private var countdownCaption: String {
        (profile.daysUntilExam ?? 0) == 1 ? "Day out" : "Days out"
    }

    private func statPill(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.numeric(.title3, weight: .bold))
                .foregroundStyle(Theme.voltage)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(Theme.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Experience

    private var experienceStep: some View {
        setupStep(
            title: "Where are you starting from?",
            subtitle: "This decides which room we open first and whether you get the primer."
        ) {
            VStack(spacing: 10) {
                ForEach(ExperienceLevel.allCases) { level in
                    choiceRow(
                        title: level.title,
                        detail: level.detail,
                        icon: level.icon,
                        selected: skillLevel == level.rawValue
                    ) {
                        skillLevel = level.rawValue
                    }
                }
            }
        }
    }

    // MARK: Focus

    private var focusStep: some View {
        setupStep(
            title: "What do you want to hit hardest?",
            subtitle: "Pick as many as you like, or none. We surface these first on Home; everything stays available either way."
        ) {
            VStack(spacing: 10) {
                ForEach(DrillLibrary.rooms) { room in
                    choiceRow(
                        title: room.name,
                        detail: room.tagline,
                        icon: room.icon,
                        tint: room.accent,
                        selected: profile.focusAreas.contains(room.id),
                        multi: true
                    ) {
                        profile.toggleFocus(room.id)
                    }
                }
            }
            infoCard(
                icon: "infinity",
                tint: Theme.conduit,
                text: "Whatever you pick, Endless Practice generates \(PracticeSkill.allCases.count) calculation shapes without limit, so no room ever runs out of questions."
            )
        }
    }

    // MARK: Reminder

    private var reminderStep: some View {
        setupStep(
            title: "One nudge a day?",
            subtitle: "Code Minute is five questions. The candidates who pass are the ones who did it on the days they did not feel like it."
        ) {
            VStack(spacing: 10) {
                choiceRow(
                    title: "Remind me daily",
                    detail: "One notification, at a time you choose",
                    icon: "bell.badge.fill",
                    selected: settings.reminderEnabled
                ) {
                    settings.reminderEnabled = true
                }
                choiceRow(
                    title: "No reminders",
                    detail: "You can switch this on later in Settings",
                    icon: "bell.slash",
                    selected: !settings.reminderEnabled
                ) {
                    settings.reminderEnabled = false
                }
            }
            if settings.reminderEnabled {
                DatePicker(
                    "Reminder time",
                    selection: $settings.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .tint(Theme.voltage)
                .padding(14)
                .themedCard(corner: 16)
            }
            if settings.reminderPermissionDenied {
                infoCard(
                    icon: "exclamationmark.triangle.fill",
                    tint: Theme.brass,
                    text: "Notifications are turned off for this app in iOS Settings. Turn them on there and we will schedule it."
                )
            }
            if let goalTarget = goalSuggestion {
                infoCard(icon: "flag.checkered", tint: Theme.voltage, text: goalTarget)
            }
        }
    }

    private var goalSuggestion: String? {
        guard let countdown = profile.examCountdownSummary else { return nil }
        return "\(countdown). At \(profile.suggestedDailyQuestions) questions a day you will have worked roughly 600 problems before you sit it."
    }

    // MARK: Plan recap

    /// Everything the setup collected, read back. This is the step that makes
    /// the seven questions feel like they bought something.
    private var planStep: some View {
        setupStep(
            title: "Your plan",
            subtitle: "Change any of it later in Exam Target and Settings."
        ) {
            VStack(spacing: 0) {
                planRow(icon: "person.text.rectangle", label: "Licence",
                        value: profile.licenseTrack.displayName)
                planDivider
                planRow(icon: "mappin.and.ellipse", label: "Jurisdiction",
                        value: profile.trimmedJurisdiction.isEmpty ? "Not set" : profile.trimmedJurisdiction,
                        detail: profile.jurisdictionRecord.map {
                            "\($0.path.summary). Exam via \($0.providerLabel)."
                        })
                planDivider
                planRow(icon: "books.vertical", label: "Code edition",
                        value: profile.editionSummary,
                        detail: profile.editionMatchesApp
                            ? "Every answer in the app is built from this edition."
                            : profile.editionAdvice)
                planDivider
                planRow(icon: "calendar", label: "Exam date",
                        value: profile.examCountdownSummary ?? "No date set",
                        detail: "\(profile.pace.title): \(profile.suggestedDailyQuestions) questions a day.")
                planDivider
                planRow(icon: "figure.stand", label: "Starting from",
                        value: ExperienceLevel(rawValue: skillLevel)?.title ?? "Not set")
                planDivider
                planRow(icon: "scope", label: "Focus",
                        value: focusSummary)
            }
            .padding(4)
            .themedCard(corner: 18)

            // The plan the date implies, not just the date. This is the row a
            // candidate screenshots.
            StudyPaceCard(pace: profile.pace, daily: profile.suggestedDailyQuestions)

            infoCard(
                icon: "shield.lefthalf.filled",
                tint: Theme.conduit,
                text: "This app teaches the numbers, the article citations and the method. It never reproduces NEC text, which is NFPA's copyright. Keep your own code book beside you."
            )
        }
    }

    private var planDivider: some View {
        Divider().overlay(Theme.rule).padding(.leading, 52)
    }

    private var focusSummary: String {
        let names = DrillLibrary.rooms
            .filter { profile.focusAreas.contains($0.id) }
            .map(\.name)
        return names.isEmpty ? "Everything" : names.joined(separator: ", ")
    }

    private func planRow(icon: String, label: String, value: String, detail: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.voltage)
                .frame(width: 28, height: 28)
                .background(Theme.voltage.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
                    .textCase(.uppercase)
                Text(value)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }

    private func infoCard(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - Trial step

    /// The membership pitch, and the one screen in the flow that has to ARGUE
    /// rather than describe.
    ///
    /// What was here before was a feature list: five ticks naming five things
    /// the app contains. A feature list answers "what do I get" and never
    /// answers the question a reader actually has, which is "why would I need
    /// that". So this version does three things instead.
    ///
    /// It states the problem with a number the reader can check. The free
    /// rooms hold a countable number of questions; the setup they just
    /// finished says how many they should do a day and how many days they
    /// have. Those three facts multiply out to a date the free content runs
    /// out, and for most candidates it is before the exam. That is the whole
    /// pitch, and it is arithmetic rather than adjectives.
    ///
    /// It reads back their own answers, so the seven setup questions visibly
    /// bought something on the screen that asks for money.
    ///
    /// And it leads with whichever benefit their pace makes load-bearing: a
    /// candidate three days out does not need "extra practice sets", they need
    /// the thing that finds their repeated errors and re-traps them.
    private var trialStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(Theme.brass)
                    .frame(width: 64, height: 64)
                    .background(Theme.brass.opacity(0.14), in: Circle())
                    .overlay(Circle().strokeBorder(Theme.brass.opacity(0.28), lineWidth: 1))

                Text(trialHeadline)
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                runsOutCard

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(trialBenefits, id: \.text) { benefit in
                        trialBenefit(benefit)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 26)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    /// Named on purpose so the headline can be personal without being creepy:
    /// it repeats a fact the reader typed in two screens ago.
    private var trialHeadline: String {
        switch profile.pace {
        case .cram:
            return trialLength == nil
                ? "\(profile.examCountdownSummary ?? "Exam soon"). Make it count."
                : "\(profile.examCountdownSummary ?? "Exam soon"). Try it free."
        case .sprint:
            return trialLength == nil ? "Two weeks is enough, if you spend it right" : "Try \(Membership.name) free"
        default:
            return trialLength == nil ? "Get \(Membership.name)" : "Try \(Membership.name) free"
        }
    }

    /// The arithmetic. Every figure here comes from the library or from the
    /// setup answers, so it cannot drift the way a hardcoded marketing number
    /// would, and it stays true if a room is added tomorrow.
    private var runsOutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: profile.pace == .cram ? "scope" : "hourglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.copper)
                Text(runsOutHeadline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            Text(runsOutDetail)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.copper.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.copper.opacity(0.24), lineWidth: 1)
        )
    }

    /// How many days of practice the free rooms hold at this candidate's own
    /// daily target. At least one, because "0 days" is not a sentence.
    private var daysOfFreeContent: Int {
        max(1, Int((Double(DrillLibrary.freeItemCount)
                    / Double(max(profile.suggestedDailyQuestions, 1))).rounded(.up)))
    }

    /// The argument, and it is a DIFFERENT argument for someone sitting the
    /// exam tomorrow.
    ///
    /// The running-out pitch is honest for a candidate with weeks: they will
    /// finish the free questions and then be re-reading answers they remember.
    /// It is nonsense for a candidate with one day, who will not get through
    /// the free rooms either. Telling them they are about to run out is both
    /// false and the wrong thing to sell: what decides tomorrow is not volume,
    /// it is whether the mistakes they keep making get named and set again.
    private var runsOutHeadline: String {
        let free = DrillLibrary.freeItemCount
        // No day count in the cram line: the headline above already says how
        // long is left, and repeating it two lines down reads as a template
        // filled in twice rather than as an argument.
        if profile.pace == .cram {
            return "More questions is not what decides an exam this close."
        }
        guard let until = profile.daysUntilExam else {
            return "The free rooms hold \(free) questions. At \(profile.suggestedDailyQuestions) a day that is about \(dayCount(daysOfFreeContent)) of practice, and then you are re-reading answers you remember."
        }
        if daysOfFreeContent >= until {
            return "The free rooms hold \(free) questions, about \(dayCount(daysOfFreeContent)) at \(profile.suggestedDailyQuestions) a day. That barely covers your \(dayCount(until)), once, with nothing left to repeat."
        }
        return "The free rooms hold \(free) questions. At \(profile.suggestedDailyQuestions) a day you finish them in about \(dayCount(daysOfFreeContent)), with \(dayCount(until - daysOfFreeContent)) still to go."
    }

    private var runsOutDetail: String {
        if profile.pace == .cram {
            return "Every wrong answer here is a named error. Fix My Mistakes builds fresh problems that set the same trap until you stop falling for it, and that is what moves a score overnight."
        }
        return "\(Membership.name) generates the calculations instead of storing them. \(PracticeSkill.allCases.count) problem shapes, new numbers every time, so the practice cannot run out before the exam does."
    }

    /// "1 day" / "12 days". Written out rather than interpolated at each call
    /// site, because "your 1 days" is the kind of thing that ships.
    private func dayCount(_ days: Int) -> String {
        days == 1 ? "1 day" : "\(days) days"
    }

    private struct TrialBenefit {
        let icon: String
        let text: String
    }

    /// Ordered by what this candidate's pace makes matter most. Same features,
    /// different argument, which is the point: "targets the errors you repeat"
    /// is a nice-to-have in March and the entire product on Thursday night.
    private var trialBenefits: [TrialBenefit] {
        let endless = TrialBenefit(
            icon: "infinity",
            text: "Endless Practice: ten calculation shapes, generated fresh, so you never memorise a question instead of a method."
        )
        let fix = TrialBenefit(
            icon: "arrow.trianglehead.counterclockwise",
            text: "Fix My Mistakes: every wrong answer is a NAMED error, and this builds new problems that set the same trap until you stop falling for it."
        )
        let warmUp = TrialBenefit(
            icon: "person.2.fill",
            text: "Exam Warm-Up: a short session built from your own weak spots, for the morning of."
        )
        let rooms = TrialBenefit(
            icon: "square.grid.2x2.fill",
            text: "\(DrillLibrary.membershipItemCount) more authored questions: the worked dwelling calculation, grounding, motors, and extra sets in every room."
        )
        let minute = TrialBenefit(
            icon: "calendar.badge.clock",
            text: "Code Minute: five questions a day, for the days you would otherwise skip."
        )

        // Four at most. This screen has a hero, an argument card, a price
        // disclosure and two footers competing for a phone-sized viewport, and
        // a fifth bullet is what pushes the CTA under the fold.
        switch profile.pace {
        case .cram:
            // Fix My Mistakes is deliberately absent: the card above already
            // makes that argument in full, and a bullet restating it reads as
            // padding rather than as a second reason.
            return [warmUp, endless, rooms, minute]
        case .sprint:
            return [endless, fix, warmUp, rooms]
        default:
            return [endless, rooms, fix, minute]
        }
    }

    private func trialBenefit(_ benefit: TrialBenefit) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: benefit.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.voltage)
                .frame(width: 24, height: 24)
                .background(Theme.voltage.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(benefit.text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    /// The trial length this Apple Account can actually start, or nil when it
    /// cannot start one. A returning subscriber gets the price, not an offer the
    /// store will refuse at the confirmation sheet.
    private var trialLength: String? {
        guard subscriptions.isEligibleForTrial(.monthly) else { return nil }
        return subscriptions.trialLengthText(for: .monthly)
    }

    /// One concise line, matching the approved fleet pattern (StatScout): trial
    /// length, price, that it renews, how to cancel. The EULA behind the Terms
    /// link carries the full legalese; this is the point-of-purchase micro copy.
    ///
    /// Must name the SAME plan the CTA buys. This onboarding tap buys monthly
    /// (see `primaryAction`), so quoting a yearly amount here would misstate
    /// what the candidate is charged, which is a 3.1.2 problem and a refund
    /// magnet. If the product has not loaded, drop the amount rather than
    /// invent one.
    private var trialDisclosure: String {
        guard let price = PaywallPricing.price(subscriptions, .monthly) else {
            guard let trialLength else { return "Auto-renews until canceled." }
            return "Includes \(trialLength) free. Auto-renews until canceled."
        }
        guard let trialLength else { return "\(price). Auto-renews until canceled." }
        return "\(trialLength) free, then \(price). Auto-renews until canceled."
    }

    private var trialCTATitle: String {
        guard let trialLength else { return "Subscribe to \(Membership.name)" }
        return "Start \(trialLength) free"
    }

    // MARK: - Footer

    /// Only the trial step draws the purchase chrome. Reserving its height on
    /// every other step (which the paged version did) is 80pt of dead space on
    /// eleven screens to avoid one transition.
    private var footer: some View {
        VStack(spacing: 8) {
            if step == .trial {
                Button {
                    startTour()
                } label: {
                    // "Get Started", not "Skip" or "No trial": it is the free
                    // way in, worded so it does not read as a loud escape from
                    // the offer.
                    Text("Get Started")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(height: 30)

                Text(trialDisclosure)
                    .font(.caption2)
                    .foregroundStyle(Theme.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                primaryAction()
            } label: {
                Group {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(primaryTitle)
                    }
                }
                .primaryCTA()
            }
            .disabled(purchasing || !canAdvance)
            .opacity(canAdvance ? 1 : 0.5)

            if step == .trial {
                HStack(spacing: 14) {
                    Link("Terms", destination: PaywallLinks.terms)
                    Link("Privacy", destination: PaywallLinks.privacy)
                    Button("Restore") {
                        Task { try? await subscriptions.restore() }
                    }
                }
                .font(.caption2)
                .foregroundStyle(Theme.inkTertiary)
                .frame(height: 20)
            } else if let skip = skipTitle {
                Button(skip) { advance() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 20)
            } else {
                Color.clear.frame(height: 20)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
        .animation(Theme.Motion.screen, value: step)
    }

    private var primaryTitle: String {
        switch step {
        case .trial: return trialCTATitle
        case .plan: return "Looks right"
        case .walkInReady: return "Set up my exam"
        default: return "Continue"
        }
    }

    /// Steps whose answer is genuinely optional say so, instead of leaving a
    /// candidate hunting for a way past a question they do not have an answer
    /// to. Jurisdiction is not on this list; it is the one answer the rest of
    /// the setup reads from.
    private var skipTitle: String? {
        switch step {
        case .examDate, .focus, .reminder: return "Skip"
        default: return nil
        }
    }

    /// The gate that the old paged version could not enforce.
    private var canAdvance: Bool {
        switch step {
        case .jurisdiction: return profile.canCompleteSetup
        case .experience: return !skillLevel.isEmpty
        default: return true
        }
    }

    // MARK: - Navigation

    private var stepTransition: AnyTransition {
        goingForward ? Theme.Motion.advance : Theme.Motion.retreat
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        goingForward = true
        step = next
    }

    private func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        goingForward = false
        step = previous
    }

    /// The trial CTA is the Apple purchase trigger, nothing else. One tap goes
    /// straight to StoreKit's confirm sheet.
    ///
    /// It must NOT open a second paywall. Backing out of Apple's sheet leaves
    /// the candidate exactly where they were (they can still tap Get Started, or
    /// the CTA again); the full plan-picker fallback is reserved for the one
    /// case it was designed for, products that genuinely failed to load, so
    /// the button is never dead.
    private func primaryAction() {
        guard step == .trial else {
            advance()
            return
        }
        purchasing = true
        Task {
            defer { purchasing = false }
            await subscriptions.ensureOfferings()
            // Monthly, not yearly, and this is deliberate. Two different people
            // reach the two purchase surfaces: whoever taps through onboarding
            // has not used the app yet and is reacting to the number on Apple's
            // sheet, while whoever hits the paywall later has already decided the
            // app is worth something. The paywall still leads with yearly. Here
            // the smaller recurring figure is what gets the trial started, and
            // `trialDisclosure` above must keep naming this same plan.
            do {
                let monthly = try await subscriptions.resolvePackage(for: .monthly)
                let outcome = try await subscriptions.purchase(monthly)
                switch outcome {
                case .purchased:
                    startTour()
                case .cancelled:
                    break // They said no to Apple, not to the app. Stay put.
                }
            } catch let error as PurchaseError {
                // Products that genuinely failed to load get the plan-picker
                // fallback, which is the surface designed for it. A real
                // purchase failure gets an explanation instead.
                print("[onboarding] purchase blocked: \(error.diagnosticDescription)")
                switch error {
                case .notConfigured, .offeringsUnavailable, .packageMissing:
                    showPaywallFallback = true
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    /// Both exits from the trial step land on Home. The primer remains one tap
    /// away for new candidates, while experienced candidates can answer first.
    private func startTour() {
        profile.completeSetup()
        finish()
    }

    /// A successful purchase in the products-failed fallback must rejoin the
    /// onboarding path instead of dropping the candidate back on the trial step.
    private func paywallDismissed() {
        guard subscriptions.isPro else { return }
        startTour()
    }

    private func finish() {
        // RootView branches on this key, so setting it swaps Home in.
        // A brand-new candidate has never run an older version, so there is
        // nothing "new" to tell them. Stamping the baseline here is what keeps
        // the update sheet off a fresh install.
        WhatsNew.markCurrentAsBaseline()
        profile.completeSetup()
        progress.hasOnboarded = true
    }
}

/// The facts we hold about a state, shown the moment one is selected. Every
/// value is labelled as a starting point and points at the authority that can
/// confirm it, because adoption dates and vendors move.
struct JurisdictionFactsCard: View {
    let record: Jurisdiction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(record.id)
                    .font(Theme.numeric(13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 24)
                    .background(Theme.voltageFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(record.name)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.worksheetInk)
                Spacer()
            }
            factRow(label: "Commonly adopted", value: record.editionLabel)
            factRow(label: "Licence issued by", value: record.authority)
            factRow(label: "Licence route", value: record.path.summary)
            factRow(label: "Exam delivered by", value: record.providerLabel)
            Text("Checked \(Jurisdictions.reviewed). Adoption and vendors change, and local amendments are common. Confirm with \(record.authority) before you rely on it.")
                .font(.caption2)
                .foregroundStyle(Theme.worksheetInkTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.worksheet, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .blueprintGrid(corner: 16, spacing: 12, opacity: 0.06)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.worksheetEdge, lineWidth: 1)
        )
    }

    private func factRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.worksheetInkTertiary)
                .frame(width: 118, alignment: .leading)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.worksheetInk)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
