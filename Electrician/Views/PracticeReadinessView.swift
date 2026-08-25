import SwiftUI

struct PracticeReadinessView: View {
    @EnvironmentObject private var profile: CandidateProfile
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var records = PracticeRecordStore.shared

    private var metrics: PracticeReadinessMetrics {
        let availableIDs = Set(DrillLibrary.rooms.filter { $0.isFree || subscriptions.isPro }.map(\.id))
        let practiced = records.roomStats().filter { availableIDs.contains($0.id) }.count
        return PracticeReadinessMetrics(
            attempts: records.totalAttempts,
            correct: records.totalCorrect,
            practicedRooms: practiced,
            availableRooms: availableIDs.count
        )
    }

    private var diagnosticItems: [QuickItem] {
        SessionBuilder.quickSession(
            count: 10,
            seen: progress.seenItems,
            missed: progress.missedItems,
            includePro: subscriptions.isPro
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                targetCard
                readinessCard
                metricCard
                NavigationLink {
                    QuickSessionView(items: diagnosticItems, isDaily: false)
                } label: {
                    Label("Start a 10-question diagnostic", systemImage: "play.fill")
                        .primaryCTA()
                }
                .buttonStyle(.plain)
                Text("This is a practice signal, not a pass prediction. It only reflects answers in this app and does not account for your state's exam blueprint, local amendments, or code edition.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Practice Readiness")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var targetCard: some View {
        NavigationLink {
            CandidateProfileView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.text.rectangle.fill")
                    .foregroundStyle(Theme.jade)
                    .frame(width: 38, height: 38)
                    .background(Theme.jade.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.targetSummary)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("\(profile.editionSummary) study set")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(14)
            .themedCard(corner: 16)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var readinessCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(readinessColor)
            Text(metrics.title)
                .font(Theme.display(27))
                .foregroundStyle(Theme.ink)
            Text(metrics.message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .themedCard()
    }

    private var metricCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            metricRow(title: "Accuracy", value: metrics.accuracyText, progress: metrics.accuracy)
            metricRow(title: "Room coverage", value: metrics.coverageText, progress: metrics.coverage)
            metricRow(title: "Questions answered", value: "\(metrics.attempts)", progress: min(1, Double(metrics.attempts) / 30))
        }
        .padding(16)
        .themedCard()
    }

    private func metricRow(title: String, value: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.jade)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
                .tint(Theme.jade)
        }
    }

    private var readinessColor: Color {
        switch metrics.level {
        case .notStarted: return Theme.gold
        case .building: return Theme.coral
        case .consistent: return Theme.jade
        }
    }
}
