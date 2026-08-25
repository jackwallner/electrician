import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var profile: CandidateProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showWhatsNew = false
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?
    /// Non-nil while the review funnel is up; the value is where it opens.
    @State private var reviewPromptStep: ReviewPromptSheet.Step?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                examTargetSection
                practiceSection
                proSection
                dataSection
                supportSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.jade)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView(source: "electrician_settings_sheet") }
            .sheet(isPresented: $showWhatsNew) {
                if let release = WhatsNew.currentRelease {
                    WhatsNewSheet(release: release) {
                        showWhatsNew = false
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            showPaywall = true
                        }
                    }
                }
            }
            .sheet(item: $reviewPromptStep) { step in
                ReviewPromptSheet(initialStep: step) { outcome in
                    if outcome == .enjoyedMaybeLater { requestReview() }
                }
            }
            .alert("Restore", isPresented: .init(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
            .alert("Notifications are off", isPresented: $settings.reminderPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Electrician cannot send reminders until notifications are turned on in iOS Settings.")
            }
            .alert("Reset all progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    progress.resetAll()
                    PracticeRecordStore.shared.resetAll()
                    CodeMinuteStore.shared.resetAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                // The exact scope, because "Reset Progress" reads like a full
                // reset and is not one. Someone troubleshooting or handing the
                // phone to a colleague needs to know what survives.
                Text("Clears your streak, completed drills, per-question history, tracked mistakes, and Code Minute results. Keeps your purchases, appearance, reminders, and how you answered onboarding.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(AppSettings.Appearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
        }
    }

    private var practiceSection: some View {
        Section("Practice") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
            Toggle("Sound Effects", isOn: $settings.soundEnabled)
            Toggle("Celebration Effects", isOn: $settings.celebrationsEnabled)
            Toggle("Daily Reminder", isOn: $settings.reminderEnabled)
            if settings.reminderEnabled {
                DatePicker("Reminder Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
            }
            if subscriptions.isPro {
                NavigationLink {
                    ExamWarmUpView()
                } label: {
                    Label("Exam Warm-Up", systemImage: "person.2.fill")
                }
            }
        }
    }

    private var examTargetSection: some View {
        Section("Exam Target") {
            NavigationLink {
                CandidateProfileView()
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.targetSummary)
                        .foregroundStyle(Theme.ink)
                    Text("\(profile.editionSummary) study set")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            NavigationLink {
                PracticeReadinessView()
            } label: {
                Label("Practice Readiness", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }

    /// Reset gets its own section. A destructive red button sitting between
    /// Haptics and Sound Effects is a trap for anyone who taps to see what
    /// something does.
    private var dataSection: some View {
        Section("Your Practice History") {
            NavigationLink {
                StatsView()
            } label: {
                Label("Your Progress", systemImage: "chart.bar.fill")
            }
            Button("Reset Progress", role: .destructive) {
                showResetConfirm = true
            }
        }
    }

    private var proSection: some View {
        Section("Membership") {
            if subscriptions.isPro {
                Label("\(Membership.name) unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.jade)
                Link("Manage Subscription", destination: PaywallLinks.manageSubscriptions)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Get \(Membership.name)", systemImage: "sparkles")
                }
            }
            Button("Restore Purchases") {
                Task {
                    do {
                        try await subscriptions.restore()
                        restoreMessage = subscriptions.isPro
                            ? "\(Membership.name) restored!"
                            : "No previous purchase found on this Apple Account."
                    } catch {
                        restoreMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                HowToPlayView()
            } label: {
                Label("How the Exam Works", systemImage: "book.fill")
            }
            if WhatsNew.currentRelease != nil {
                Button {
                    showWhatsNew = true
                } label: {
                    Label("What's New", systemImage: "sparkle")
                }
            }
            // Hidden until the listing is live: the button opens an
            // apps.apple.com URL that 404s while the record is still a draft.
            if AppStoreLinks.isPublished {
                Button {
                    reviewPromptStep = .reviewPitch
                } label: {
                    Label("Rate Electrician", systemImage: "star.fill")
                }
            }
            Button {
                reviewPromptStep = .feedback
            } label: {
                Label("Send Feedback", systemImage: "envelope.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            // The edition is the most important thing on this screen and it used
            // to be buried inside a paragraph. A candidate cannot tell a
            // 2023-cycle answer from a 2026-cycle one by looking at it.
            LabeledContent("Code edition", value: NECTables.edition)
            Text("Every number in this app comes from the \(NECTables.edition). Electrician is a study aid, not a code book. It is not affiliated with, endorsed by, or connected to the NFPA. It teaches concepts and calculations in original wording and cites article numbers so you can verify each one yourself. Your jurisdiction may examine against a different edition or amend it locally, so always check the code in force where you work.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Developer") {
            Toggle("Local Pro override", isOn: .init(
                get: { subscriptions.isPro },
                set: { subscriptions.setLocalOverride(isPro: $0) }
            ))
        }
    }
    #endif
}
