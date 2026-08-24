import SwiftUI

/// The worked-calculation runner.
///
/// The difference from a quiz is what happens after the answer: a quiz shows a
/// paragraph, this shows numbered steps. That is deliberate. A candidate who
/// misses a derating problem almost never misses the arithmetic, they miss one
/// step, and a paragraph hides which one. Numbered steps let them find it.
struct CalcDrillView: View {
    let drill: Drill
    let scenarios: [CalcScenario]

    @EnvironmentObject private var progress: ProgressStore

    @State private var index = 0
    @State private var selection: Int?
    @State private var score = 0
    @State private var finished = false
    @State private var confettiTrigger = 0
    @State private var answerRect: CGRect?

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: scenarios.count)
        } else {
            drillBody
        }
    }

    private var scenario: CalcScenario { scenarios[index] }
    private var answered: Bool { selection != nil }

    /// Seeded by the scenario id so the correct answer is not always in the
    /// authored slot, and stays put across a re-render.
    private var shuffled: (labels: [String], answerIndex: Int) {
        ChoiceShuffle.shuffledChoices(
            labels: scenario.choices,
            answerIndex: scenario.answerIndex,
            seed: scenario.id
        )
    }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(scenarios.count))
                .tint(Theme.jade)
            VStack(spacing: 16) {
                CenteringScrollView {
                    VStack(spacing: 18) {
                        Text(scenario.situation)
                            .font(Theme.display(21))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        if !scenario.givens.isEmpty {
                            GivensView(givens: scenario.givens)
                                .padding(.horizontal, 4)
                        }
                        ChoiceList(
                            labels: shuffled.labels,
                            selection: selection,
                            answerIndex: shuffled.answerIndex
                        ) { pick in
                            select(pick)
                        }
                        if answered { steps }
                    }
                    .padding(.horizontal, 4)
                }
                footer
            }
            .id(index)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
        .drillStage(answerRect: $answerRect)
        .overlay {
            ConfettiBurst(
                trigger: confettiTrigger,
                origin: .init(x: 0.5, y: 0.35),
                sourceRect: answerRect
            )
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Working")
                .font(.caption.weight(.heavy))
                .kerning(1.2)
                .foregroundStyle(Theme.inkTertiary)
            ForEach(Array(scenario.steps.enumerated()), id: \.offset) { position, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(position + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.jade)
                        .frame(width: 18, height: 18)
                        .background(Theme.jade.opacity(0.14), in: Circle())
                    Text(step)
                        .font(.callout)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Label(scenario.citation, systemImage: "book.closed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkTertiary)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.ivory, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.ivoryShadow, lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var footer: some View {
        Button {
            advance()
        } label: {
            Text(index == scenarios.count - 1 ? "Finish" : "Next").primaryCTA()
        }
        .disabled(!answered)
        .opacity(answered ? 1 : 0.4)
    }

    private func select(_ pick: Int) {
        guard selection == nil else { return }
        withAnimation(.easeOut(duration: 0.25)) { selection = pick }
        let correct = pick == shuffled.answerIndex
        if correct {
            score += 1
            confettiTrigger += 1
        }
        progress.recordItem(id: scenario.id, correct: correct)
        PracticeRecordStore.shared.record(itemID: scenario.id, roomID: roomID, correct: correct)
        if correct {
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        } else {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
    }

    private func advance() {
        if index == scenarios.count - 1 {
            finished = true
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                index += 1
                selection = nil
            }
        }
    }

    /// The room a worked example belongs to, so its result lands in the same
    /// stats bucket as the generated practice for the same skill.
    private var roomID: String { DrillLibrary.roomID(forDrillID: drill.id) }
}
