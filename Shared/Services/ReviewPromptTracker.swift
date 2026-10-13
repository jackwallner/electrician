import Foundation

enum AppStoreLinks {
    /// Numeric Apple ID for `com.jackwallner.electrician`.
    static let appStoreID = "6804828725"

    /// True since the listing went Ready for Sale on 2026-09-01.
    ///
    /// Having an Apple ID is not the same as having a listing. The ASC record
    /// has existed since long before there was anything to link to, and while
    /// it sits in PREPARE_FOR_SUBMISSION every `apps.apple.com/app/id...` URL
    /// built from it is a 404. Treating a non-empty id as "published" meant the
    /// share sheet handed TestFlight testers a dead link and the old rating
    /// sheet offered to open a store page that does not exist.
    ///
    /// While this is false: no share URL, no Rate row, no rating prompt. The
    /// feedback path still works, and that is the one that matters pre-launch.
    static let isListingLive = true

    static var isPublished: Bool { isListingLive && !appStoreID.isEmpty }

    static var productURL: URL? {
        guard isPublished else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    /// The write-a-review page. No storefront prefix: the App Store resolves
    /// the bare app id into the viewer's own storefront, and hardcoding one
    /// only risks sending a UK reader to the US store.
    static var writeReviewURL: URL? {
        guard isPublished else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    static let feedbackEmail = "jackwallner+e@gmail.com"
}

/// What the reader did about a review. Only opening the review page ends the
/// passive asks: someone who opened a feedback draft can still rate later.
enum ReviewPromptOutcome: String, Sendable {
    case openedWriteReview
    /// A mail draft OPENED. The app cannot know whether it was ever sent, and
    /// the old name (`submittedFeedback`) claimed more than that. The raw value
    /// is unchanged because it is already persisted on device.
    case openedFeedbackDraft = "submittedFeedback"
}

/// When to call Apple's rating prompt. There is no question in front of it:
/// App Review 5.6.1 rejects an "Enjoying it?" gate that routes only happy
/// readers to the store. A finished drill marks a positive moment, and the
/// next clear screen after it asks.
@MainActor
enum ReviewPromptTracker {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let launchCount = "reviewPrompt.launchCount"
        static let firstOpen = "reviewPrompt.firstOpenDate"
        static let lastShown = "reviewPrompt.lastShownDate"
        static let outcome = "reviewPrompt.outcome"
        static let positiveMoments = "reviewPrompt.positiveMomentCount"
        static let pendingMoment = "reviewPrompt.pendingPositiveMoment"
        /// Written by the old gate's "Maybe later". Only cleared now.
        static let softDefer = "reviewPrompt.softDefer"
    }

    /// Ask early: most installs are gone within a week. The only tenure gate
    /// is "not the first session", a second cold launch.
    static let minimumLaunchCount = 2
    /// Days between our calls. Apple shows the prompt at most three times a
    /// year per device and decides each time, so this only paces the asks.
    static let cooldownDays = 30

    static var launchCount: Int {
        get { max(defaults.integer(forKey: Keys.launchCount), 0) }
        set { defaults.set(newValue, forKey: Keys.launchCount) }
    }

    static var positiveMomentCount: Int {
        get { max(defaults.integer(forKey: Keys.positiveMoments), 0) }
        set { defaults.set(newValue, forKey: Keys.positiveMoments) }
    }

    static var hasPendingPositiveMoment: Bool {
        get { defaults.bool(forKey: Keys.pendingMoment) }
        set { defaults.set(newValue, forKey: Keys.pendingMoment) }
    }

    static var outcome: ReviewPromptOutcome? {
        get { defaults.string(forKey: Keys.outcome).flatMap(ReviewPromptOutcome.init(rawValue:)) }
        set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: Keys.outcome)
            } else {
                defaults.removeObject(forKey: Keys.outcome)
            }
        }
    }

    static var lastShownDate: Date? {
        get { defaults.object(forKey: Keys.lastShown) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.lastShown)
            } else {
                defaults.removeObject(forKey: Keys.lastShown)
            }
        }
    }

    /// Call once per cold launch, from the app's init.
    static func recordAppLaunch(now: Date = Date()) {
        if defaults.object(forKey: Keys.firstOpen) == nil {
            defaults.set(now, forKey: Keys.firstOpen)
        }
        launchCount += 1
    }

    static func recordPositiveMoment() {
        positiveMomentCount += 1
        hasPendingPositiveMoment = true
    }

    /// `listingIsLive` is a parameter only so the rules stay testable whatever
    /// `AppStoreLinks.isListingLive` says; production passes the real value.
    /// Pre-launch there is no listing to rate, so nothing asks.
    static func canRequestReview(
        hasCompletedSetup: Bool,
        now: Date = Date(),
        listingIsLive: Bool = AppStoreLinks.isPublished
    ) -> Bool {
        guard listingIsLive, hasCompletedSetup else { return false }
        guard outcome != .openedWriteReview else { return false }
        guard launchCount >= minimumLaunchCount else { return false }
        guard let last = lastShownDate else { return true }
        return now.timeIntervalSince(last) >= TimeInterval(cooldownDays) * 86_400
    }

    /// Eligible and a positive moment is still waiting. An ask that finds the
    /// screen busy leaves the moment pending, so the next one can ask.
    static func shouldRequestAfterPositiveMoment(
        hasCompletedSetup: Bool,
        now: Date = Date(),
        listingIsLive: Bool = AppStoreLinks.isPublished
    ) -> Bool {
        guard hasPendingPositiveMoment else { return false }
        return canRequestReview(hasCompletedSetup: hasCompletedSetup, now: now, listingIsLive: listingIsLive)
    }

    static func markShown(now: Date = Date()) {
        lastShownDate = now
        hasPendingPositiveMoment = false
    }

    static func markOpenedWriteReview() {
        outcome = .openedWriteReview
        markShown()
    }

    /// A feedback draft opened. That never ends the asks, and never overwrites
    /// a review-page stop.
    static func markFeedbackDraftOpened() {
        if outcome != .openedWriteReview {
            outcome = .openedFeedbackDraft
        }
        markShown()
    }

    static func resetForTesting() {
        [Keys.launchCount, Keys.firstOpen, Keys.lastShown, Keys.outcome,
         Keys.positiveMoments, Keys.pendingMoment, Keys.softDefer]
            .forEach(defaults.removeObject(forKey:))
    }
}
