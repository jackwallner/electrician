import SwiftUI

/// Practice history: overall accuracy, a bar per room, a bar per calculation
/// skill, and the specific errors still outstanding.
///
/// Free for everyone. Stats about your own effort are not a feature to sell
/// back to you, and a reader who can see they are 58% on derating has a reason
/// to care about the drills that would fix it.
///
/// Room accuracy alone was too coarse to study from: "71% in Conductors &
/// Ampacity" does not tell anyone what to do next. The skill rows and the
/// mistake list do, and they cost nothing extra because the record store was
/// already keeping both.
struct StatsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var records = PracticeRecordStore.shared
    @State private var showPaywall = false

    private var roomStats: [PracticeRecordStore.RoomStat] { records.roomStats() }
    private var skillStats: [PracticeRecordStore.RoomStat] { records.skillStats() }
    private var outstandingMistakes: [MistakePattern] { records.outstandingMistakes(limit: 5) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if records.totalAttempts == 0 {
                    emptyState
                } else {
                    summaryCard
                    if let weakest = records.weakestRoom(), roomStats.count > 1 {
                        weakSpotCard(weakest)
                    }
                    roomBreakdown
                    if !skillStats.isEmpty { skillBreakdown }
                    if !outstandingMistakes.isEmpty { mistakeBreakdown }
                }
                streakCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: "electrician_stats_mistakes")
        }
    }

    // MARK: - Cards

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.voltage.opacity(0.5))
            Text("No practice yet")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text("Answer a few questions and your accuracy for every room shows up here.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 12)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            metric(value: percent(records.overallAccuracy), caption: "accuracy", color: Theme.voltage)
            divider
            metric(value: "\(records.totalAttempts)", caption: "answered", color: Theme.ink)
            divider
            metric(value: "\(records.bestChallengeScore)", caption: "best challenge", color: Theme.copper)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 12)
    }

    private func metric(value: String, caption: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.display(26))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.rule)
            .frame(width: 1, height: 34)
    }

    private func weakSpotCard(_ stat: PracticeRecordStore.RoomStat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.copper)
                .frame(width: 38, height: 38)
                .background(Theme.copper.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Work on \(stat.name)")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(percent(stat.accuracy)) right across \(stat.attempts) questions, your lowest so far.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    private var roomBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY ROOM")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(roomStats) { stat in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(stat.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(percent(stat.accuracy))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(barColor(stat.accuracy))
                            .monospacedDigit()
                    }
                    accuracyBar(stat.accuracy)
                    Text("\(stat.correct) of \(stat.attempts) right")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    private var skillBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY CALCULATION")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(skillStats) { stat in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(stat.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(percent(stat.accuracy))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(barColor(stat.accuracy))
                            .monospacedDigit()
                    }
                    accuracyBar(stat.accuracy)
                    Text("\(stat.correct) of \(stat.attempts) right")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    /// The actual errors, named. This is the most useful screen in the app for
    /// someone with an exam date: not "you are 64%", but "you keep starting the
    /// derate in the wrong column".
    private var mistakeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT KEEPS CATCHING YOU")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(outstandingMistakes, id: \.id) { pattern in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.copper)
                        .padding(.top, 2)
                    Text(pattern.summary)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            Text("Fix My Mistakes builds fresh problems that set these same traps.")
                .font(.caption2)
                .foregroundStyle(Theme.inkTertiary)
                .padding(.top, 2)
            if subscriptions.isPro {
                NavigationLink {
                    PracticeRunView(mode: .review, items: targetedPracticeItems)
                } label: {
                    Label("Practice these traps now", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.voltage)
                }
                .padding(.top, 2)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock targeted practice", systemImage: "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.voltage)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    private func accuracyBar(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.well)
                Capsule()
                    .fill(barColor(fraction))
                    .frame(width: max(6, geo.size.width * fraction))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.copper)
                .frame(width: 38, height: 38)
                .background(Theme.copper.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.streakCount)-day streak")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(progress.totalSessions) drill\(progress.totalSessions == 1 ? "" : "s") finished")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    // MARK: - Helpers

    private func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    private func barColor(_ fraction: Double) -> Color {
        if fraction >= 0.8 { return Theme.rightGreen }
        if fraction >= 0.6 { return Theme.brass }
        return Theme.copper
    }

    private var targetedPracticeItems: [QuickItem] {
        let due = SessionBuilder.reviewSession(
            ids: records.reviewQueue(),
            includePro: subscriptions.isPro
        )
        let patterns = records.outstandingMistakes()
        let targeted = EndlessPractice.targetedItems(
            for: patterns,
            count: min(patterns.count * 2, max(0, 12 - due.count))
        )
        return due + targeted
    }
}
