import XCTest
@testable import Electrician

@MainActor
final class ReviewPromptTrackerTests: XCTestCase {

    // The async overrides are deliberate. XCTest's synchronous setUp/tearDown
    // are nonisolated, so overriding them from a @MainActor test case is an
    // isolation mismatch Swift 6 rejects; the async pair inherits the class's
    // isolation, which is what the main-actor store fixtures below need.
    override func setUp() async throws {
        try await super.setUp()
        ReviewPromptTracker.resetForTesting()
    }

    override func tearDown() async throws {
        ReviewPromptTracker.resetForTesting()
        try await super.tearDown()
    }

    private func earnTheAsk() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        for _ in 0..<ReviewPromptTracker.minimumPositiveMoments {
            ReviewPromptTracker.recordPositiveMoment()
        }
    }

    func testGateStaysShutUntilThePlayerHasDoneEnough() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(listingIsLive: true))

        earnTheAsk()
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(listingIsLive: true))
    }

    func testNotNowHoldsTheGateShutForTheCooldown() {
        earnTheAsk()
        ReviewPromptTracker.markShown()

        let day = TimeInterval(86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: Date().addingTimeInterval(30 * day), listingIsLive: true))
        let afterCooldown = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.cooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: afterCooldown, listingIsLive: true))
    }

    /// "Maybe later" spends only Apple's silent prompt, so it must not cost us
    /// the full 120-day jail the way a flat "Not now" does.
    func testMaybeLaterUsesTheShortCooldown() {
        earnTheAsk()
        ReviewPromptTracker.markSoftDeferred()

        let day = TimeInterval(86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: Date().addingTimeInterval(10 * day), listingIsLive: true))
        let afterSoftCooldown = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.softDeferCooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: afterSoftCooldown, listingIsLive: true))
    }

    func testRatingOrFeedbackRetiresThePromptForGood() {
        earnTheAsk()
        ReviewPromptTracker.markOpenedWriteReview()

        let inTenYears = Date().addingTimeInterval(3650 * 86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: inTenYears, listingIsLive: true))
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedWriteReview)

        ReviewPromptTracker.resetForTesting()
        earnTheAsk()
        ReviewPromptTracker.markFeedbackDraftOpened()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: inTenYears, listingIsLive: true))
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedFeedbackDraft)
    }

    func testFeedbackMailURLCarriesTheMessage() {
        let url = ReviewPromptSheet.feedbackMailURL(body: "more box fill drills please")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.path, AppStoreLinks.feedbackEmail)
        XCTAssertTrue(url?.query?.contains("more%20box%20fill%20drills%20please") == true)
    }

    /// The funnel must stay shut while the App Store listing is a draft: its
    /// happy path opens an apps.apple.com URL that 404s until Ready for Sale.
    func testFunnelStaysShutUntilTheListingIsLive() {
        earnTheAsk()
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(listingIsLive: true))
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(listingIsLive: false))
    }

    /// The raw value is persisted, so renaming the case must not orphan an
    /// outcome already written on someone's device.
    func testFeedbackOutcomeKeepsItsPersistedRawValue() {
        XCTAssertEqual(ReviewPromptOutcome.openedFeedbackDraft.rawValue, "submittedFeedback")
        XCTAssertEqual(ReviewPromptOutcome(rawValue: "submittedFeedback"), .openedFeedbackDraft)
    }

    /// No share URL and no rate URL while the listing is a draft.
    func testStoreURLsAreWithheldUntilTheListingIsLive() {
        if AppStoreLinks.isListingLive {
            XCTAssertNotNil(AppStoreLinks.productURL)
            XCTAssertNotNil(AppStoreLinks.writeReviewURL)
        } else {
            XCTAssertNil(AppStoreLinks.productURL)
            XCTAssertNil(AppStoreLinks.writeReviewURL)
        }
    }
}
