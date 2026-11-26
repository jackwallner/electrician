import StoreKit
import SwiftUI
import UIKit

extension View {
    /// Calls Apple's rating prompt about three seconds after a positive moment,
    /// with no question in front of it. Bump `moment` when the moment happens
    /// (a finished drill, a finished Code Minute) after recording it in
    /// `ReviewPromptTracker`.
    ///
    /// Only a good result bumps `moment` (see
    /// `ReviewPromptTracker.isGoodResult`). RevenueCat's `rating_prompt: off`
    /// pauses the asks without a release.
    ///
    /// Everything is checked again when the wait is over: the view must still
    /// be on screen, `isClear` must hold, and nothing may have been presented
    /// over it since the moment (a sheet, alert, full-screen cover, share sheet,
    /// paywall or trial offer). A blocked ask keeps the moment pending for the
    /// next one.
    func requestsReview(after moment: Int, isClear: @escaping () -> Bool = { true }) -> some View {
        modifier(ReviewRequestModifier(moment: moment, isClear: isClear))
    }
}

private struct ReviewRequestModifier: ViewModifier {
    let moment: Int
    let isClear: () -> Bool

    @Environment(\.requestReview) private var requestReview
    @State private var onScreen = false

    func body(content: Content) -> some View {
        content
            .onAppear { onScreen = true }
            .onDisappear { onScreen = false }
            .onChange(of: moment) { _, _ in schedule() }
    }

    private var eligible: Bool {
        SubscriptionService.shared.isOn(.ratingPrompt)
            && ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: ProgressStore.shared.hasOnboarded)
    }

    private func schedule() {
        guard eligible else { return }
        let depthAtMoment = Self.presentationDepth
        Task { @MainActor in
            // Let the celebration land first.
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard onScreen, isClear(), Self.presentationDepth <= depthAtMoment,
                  !Self.systemSheetIsUp, eligible else { return }
            ReviewPromptTracker.markShown()
            requestReview()
        }
    }

    /// A sheet, cover, share sheet or alert opened from this screen, or over
    /// it, is invisible to SwiftUI state, so look at what UIKit has presented.
    /// The screen may itself live in a cover (the onboarding tour), so the
    /// depth is compared with the depth at the moment, not with zero.
    @MainActor
    private static var topViewController: UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    @MainActor
    private static var presentationDepth: Int {
        var depth = 0
        var top = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        while let presented = top?.presentedViewController {
            depth += 1
            top = presented
        }
        return depth
    }

    @MainActor
    private static var systemSheetIsUp: Bool {
        let top = topViewController
        return top is UIActivityViewController || top is UIAlertController
    }
}
