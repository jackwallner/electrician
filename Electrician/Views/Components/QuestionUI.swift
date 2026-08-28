import SwiftUI
import UIKit

/// Where the correct answer row sits, published up to whichever drill is
/// hosting it, so a celebration can fire FROM the thing that was right instead
/// of from the middle of the screen. Reported in the `.drillStage` coordinate
/// space, which the host installs on its root.
struct AnswerRowFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension CoordinateSpace {
    static let drillStageName = "drillStage"
}

extension View {
    /// Installs the coordinate space the winning answer row reports into, and
    /// binds that row's frame so the host can fire its celebration from it.
    func drillStage(answerRect: Binding<CGRect?>) -> some View {
        coordinateSpace(name: CoordinateSpace.drillStageName)
            .onPreferenceChange(AnswerRowFrameKey.self) { [answerRect] rect in
                answerRect.wrappedValue = rect
            }
    }
}

/// Scroll target for the coaching note revealed on grading. Lives outside
/// `QuestionPager` because a generic type cannot hold a static stored property.
private let questionExplanationID = "question-explanation"

/// Shared question scaffolding: prompt + givens + choices + explanation, the
/// shape every choice-based drill uses (Quiz, Which Article?, Quick Session).
struct QuestionPager<Choices: View>: View {
    let prompt: String
    let givens: [Given]
    let explanation: String
    /// A calculation's working. When present it replaces the explanation
    /// paragraph with numbered steps, because a paragraph hides which step was
    /// skipped and a skipped step is how these are actually missed.
    var steps: [String] = []
    var citation: String? = nil
    /// The named mistake behind the reader's wrong pick, when the item knows
    /// one. Shown FIRST: "here is what you did" lands better than "here is the
    /// right method", and it is the whole reason the distractors are built the
    /// way they are.
    var missNote: String? = nil
    /// Non-nil once the question has been graded and can be reported.
    var reportContext: ContentReport.Context? = nil
    let answered: Bool
    /// The room/source eyebrow. It belongs INSIDE the pager so it centres with
    /// the question: pinned above it on an iPad, the eyebrow sat alone at the
    /// top with a hand's width of empty cream between it and the prompt.
    var eyebrow: String? = nil
    @ViewBuilder let choices: () -> Choices

    var body: some View {
        // Centering, not top-aligned: on a 13-inch iPad a three-choice question
        // used to sit in the top quarter of the screen. See CenteringScrollView.
        CenteringScrollView {
            ScrollViewReader { proxy in
            VStack(spacing: 20) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(.caption2.weight(.heavy))
                        .kerning(1.4)
                        .foregroundStyle(Theme.inkTertiary)
                        .padding(.bottom, -8)
                }
                Text(prompt)
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                if !givens.isEmpty {
                    GivensView(givens: givens)
                        .padding(.horizontal, 4)
                }
                choices()
                if answered {
                    VStack(spacing: 12) {
                        if let missNote {
                            MissNoteView(note: missNote)
                        }
                        if steps.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Theme.brass)
                                Text(explanation)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.brass.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            if let citation {
                                CitationLabel(citation)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            WorkedStepsView(steps: steps, citation: citation)
                        }
                        if let reportContext {
                            ReportIssueButton(context: reportContext)
                        }
                    }
                    .id(questionExplanationID)
                }
            }
            // Headroom so the winning row's pop and glow have somewhere to go.
            // A ScrollView clips its content, so a row that scales up to the
            // full content width would get its sides sheared off (that was the
            // "glitchy edges" on the correct answer). The padding is what buys
            // that room. Do NOT reach for `scrollClipDisabled()` instead: an
            // unclipped scroll view draws its overflow straight through the
            // navigation bar above and the drill's Next button below.
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .onChange(of: answered) { _, isAnswered in
                guard isAnswered else { return }
                // Bring the coaching note into view rather than leaving it
                // parked below the fold behind the Next button.
                withAnimation(.easeOut(duration: 0.35)) {
                    proxy.scrollTo(questionExplanationID, anchor: .bottom)
                }
            }
            }
        }
    }
}

/// The answer buttons every question type shares. On reveal the correct
/// answer LANDS: it pops, glows, and a shine sweeps across it, and the graded
/// state holds until the drill's Next button advances and never auto-skips.
///
/// Two rules learned the hard way: (1) the correct row is never dimmed, ever.
/// It's the answer the player is supposed to be reading. (2) Nothing here uses
/// `.disabled()` to stop taps after grading, because SwiftUI dims disabled
/// button labels, and that dimming hit the winning row.
struct ChoiceList: View {
    let labels: [String]
    let selection: Int?
    let answerIndex: Int
    let onPick: (Int) -> Void

    @State private var shineTrigger = 0
    @State private var landed = false
    @State private var shakes: CGFloat = 0

    private var answered: Bool { selection != nil }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(labels.indices, id: \.self) { index in
                row(index)
            }
        }
        .onChange(of: answered) { _, isAnswered in
            guard isAnswered else {
                // New question: reset the celebration state.
                landed = false
                shakes = 0
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.05)) {
                landed = true
            }
            shineTrigger += 1
            if selection != answerIndex {
                withAnimation(.linear(duration: 0.4)) { shakes = 2 }
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let isAnswer = index == answerIndex
        let isMiss = answered && index == selection && !isAnswer
        // Wrong rows the player didn't pick recede a little so the eye goes to
        // the answer, but they stay readable: the miss and the answer are the
        // two rows that matter and neither is faded.
        let recedes = answered && !isAnswer && !isMiss
        return Button {
            onPick(index)
        } label: {
            HStack {
                Text(labels[index])
                    .font(.body.weight(answered && isAnswer ? .semibold : .medium).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if answered {
                    if isAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Theme.rightGreen)
                            .scaleEffect(landed ? 1.2 : 0.4)
                    } else if isMiss {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.wrongRed)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(background(index), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border(index), lineWidth: answered && isAnswer ? 2.5 : 1)
            )
            .background {
                // Publish the winning row's position for the host's confetti.
                if isAnswer {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: AnswerRowFrameKey.self,
                            value: geo.frame(in: .named(CoordinateSpace.drillStageName))
                        )
                    }
                }
            }
            .shine(trigger: answered && isAnswer ? shineTrigger : 0)
            .winGlow(Theme.rightGreen, active: answered && isAnswer && landed)
            .scaleEffect(answered && isAnswer && landed ? 1.035 : 1)
            .modifier(ShakeEffect(travels: isMiss ? shakes : 0))
            .opacity(recedes ? 0.72 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: answered)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!answered)
    }

    private func background(_ index: Int) -> Color {
        guard answered else { return Theme.card }
        if index == answerIndex { return Theme.rightGreen.opacity(0.18) }
        if index == selection { return Theme.wrongRed.opacity(0.15) }
        return Theme.card
    }

    private func border(_ index: Int) -> Color {
        guard answered else { return Theme.rule }
        if index == answerIndex { return Theme.rightGreen.opacity(0.6) }
        if index == selection { return Theme.wrongRed.opacity(0.5) }
        return Theme.rule
    }
}


// MARK: - After the answer

/// "Here is the mistake you made", named, before any method is re-explained.
///
/// The generator's whole design is that every wrong choice is the number one
/// specific error produces. That is worth nothing if the reader is never told
/// which error they just made, which is what a generic explanation does.
struct MissNoteView: View {
    let note: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.copper)
            VStack(alignment: .leading, spacing: 3) {
                Text("WHAT HAPPENED")
                    .font(.caption2.weight(.heavy))
                    .kerning(1.2)
                    .foregroundStyle(Theme.copper)
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.copper.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("What happened. \(note)")
    }
}

/// The numbered working, and the article to check it against.
///
/// Shared by `CalcDrillView` and every generated calculation in a session, so
/// the authored room and the paid generator explain a miss the same way. They
/// used to differ: the generator flattened its steps into one paragraph.
struct WorkedStepsView: View {
    let steps: [String]
    var citation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Working")
                .font(.caption.weight(.heavy))
                .kerning(1.2)
                .foregroundStyle(Theme.worksheetInkTertiary)
            ForEach(Array(steps.enumerated()), id: \.offset) { position, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(position + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.worksheetAccent)
                        .frame(width: 18, height: 18)
                        .background(Theme.worksheetAccent.opacity(0.14), in: Circle())
                        .accessibilityHidden(true)
                    Text(step)
                        .font(.callout)
                        .foregroundStyle(Theme.worksheetInkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(position + 1). \(step)")
            }
            if let citation {
                CitationLabel(citation, onWorksheet: true)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.worksheet, in: RoundedRectangle(cornerRadius: 14))
        .blueprintGrid(corner: 14, spacing: 16, opacity: 0.06)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.worksheetEdge, lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// Where to verify this, and against which edition. The edition is not
/// decoration: the same article number resolves to different numbers across
/// cycles, and the reader is being sent to their own book to check.
struct CitationLabel: View {
    let citation: String
    /// Set on the light worksheet stock, which does not invert in dark mode
    /// and therefore needs ink that does not either.
    var onWorksheet = false

    init(_ citation: String, onWorksheet: Bool = false) {
        self.citation = citation
        self.onWorksheet = onWorksheet
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "book.closed")
            Text("\(citation) · \(NECTables.edition)")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(onWorksheet ? Theme.worksheetInkTertiary : Theme.inkTertiary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Look it up: \(citation), \(NECTables.edition)")
    }
}

/// The escape hatch for "this number is wrong".
struct ReportIssueButton: View {
    let context: ContentReport.Context

    @State private var showingCategories = false
    @State private var mailFailed = false

    var body: some View {
        Button {
            showingCategories = true
        } label: {
            Label("Report a possible issue", systemImage: "flag")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkTertiary)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .confirmationDialog("Report a possible issue", isPresented: $showingCategories, titleVisibility: .visible) {
            ForEach(ContentReport.Category.allCases) { category in
                Button(category.displayName) { report(category) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Opens a mail draft with this question's details already filled in.")
        }
        .alert("Your mail app didn't open", isPresented: $mailFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Email \(AppStoreLinks.feedbackEmail) and mention item \(context.itemID).")
        }
    }

    private func report(_ category: ContentReport.Category) {
        guard let url = ContentReport.mailURL(
            context: context,
            category: category,
            appVersion: ContentReport.appVersion
        ) else {
            mailFailed = true
            return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
            Task { @MainActor in
                if !opened { mailFailed = true }
            }
        }
    }
}
