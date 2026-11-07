import SwiftUI

struct RootView: View {
    // Same defaults key ProgressStore.hasOnboarded writes, so finishing
    // onboarding flips this live. Branching (not a cover) means Home never
    // flashes behind onboarding on first launch.
    @AppStorage("progress.hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if hasOnboarded {
                HomeView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
            }
        }
        .animation(Theme.Motion.screen, value: hasOnboarded)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            settings.resumeDailyReminderIfAllowed()
        }
    }
}
