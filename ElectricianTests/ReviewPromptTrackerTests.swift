import XCTest
@testable import Electrician

/// The rating-ask rules from the fleet policy: ask from the second launch,
/// wait out a 30-day cooldown, stop only when the reader opened the review
/// page, and never let feedback stop the asks.
@MainActor
final class ReviewPromptTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReviewPromptTracker.resetForTesting()
    }

    override func tearDown() {
        ReviewPromptTracker.resetForTesting()
        super.tearDown()
    }

    private func days(_ n: Double) -> Date { Date().addingTimeInterval(n * 86_400) }

    private func launch(_ times: Int) {
        for _ in 0..<times { ReviewPromptTracker.recordAppLaunch() }
    }

    private func canAsk(setup: Bool = true, at now: Date = Date()) -> Bool {
        ReviewPromptTracker.canRequestReview(hasCompletedSetup: setup, now: now, listingIsLive: true)
    }

    private func shouldAsk(setup: Bool = true) -> Bool {
        ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: setup, listingIsLive: true)
    }

    func testNeverAsksInTheFirstSession() {
        launch(1)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(shouldAsk())
    }

    func testAsksAtTheFirstPositiveMomentOfTheSecondLaunch() {
        launch(2)
        XCTAssertFalse(shouldAsk(), "No moment yet, so no ask")
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertTrue(shouldAsk())
    }

    func testRequiresFinishedOnboarding() {
        launch(2)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(shouldAsk(setup: false))
    }

    func testWaitsOutTheCooldown() {
        launch(2)
        ReviewPromptTracker.markShown()
        XCTAssertFalse(canAsk(at: days(29)))
        XCTAssertTrue(canAsk(at: days(31)))
    }

    func testOpeningTheReviewPageEndsTheAsks() {
        launch(2)
        ReviewPromptTracker.markOpenedWriteReview()
        XCTAssertFalse(canAsk(at: days(3650)))
    }

    func testFeedbackDoesNotStopTheAsks() {
        launch(2)
        ReviewPromptTracker.markFeedbackDraftOpened()
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedFeedbackDraft)
        XCTAssertTrue(canAsk(at: days(31)))
    }

    func testFeedbackAfterTheReviewPageKeepsTheAsksEnded() {
        launch(2)
        ReviewPromptTracker.markOpenedWriteReview()
        ReviewPromptTracker.markFeedbackDraftOpened()
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedWriteReview)
        XCTAssertFalse(canAsk(at: days(3650)))
    }

    func testBlockedAskKeepsTheMomentPending() {
        launch(2)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertTrue(shouldAsk())
        // The screen was busy, so nothing was marked: the moment is still there.
        XCTAssertTrue(shouldAsk())
        ReviewPromptTracker.markShown()
        XCTAssertFalse(shouldAsk())
    }

    /// Nothing asks while the App Store listing is a draft: there is no page
    /// to rate until Ready for Sale.
    func testNeverAsksUntilTheListingIsLive() {
        launch(2)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true, listingIsLive: false))
    }

    func testFeedbackMailURLCarriesTheMessage() {
        let url = FeedbackSheet.feedbackMailURL(body: "more box fill drills please")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.path, AppStoreLinks.feedbackEmail)
        XCTAssertTrue(url?.query?.contains("more%20box%20fill%20drills%20please") == true)
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
