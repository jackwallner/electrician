import RevenueCat
import XCTest
@testable import Electrician

final class PurchaseErrorCopyTests: XCTestCase {
    /// Ask to Buy: RevenueCat's pending error reads as waiting, not failure.
    func testAskToBuyIsShownAsWaitingForApproval() {
        let shown = PurchaseError.shown(RevenueCat.ErrorCode.paymentPendingError)
        XCTAssertEqual(shown as? PurchaseError, .waitingForApproval)
        XCTAssertEqual(
            shown.localizedDescription,
            "Waiting for approval. Your purchase unlocks once it is approved."
        )
        XCTAssertFalse(shown.localizedDescription.lowercased().contains("error"))
    }

    /// A lost connection reads as the app's own translated line, and is not
    /// the products-failed case that opens onboarding's plan picker.
    func testNetworkErrorsReadAsTheReachableLine() {
        let reachable = String(localized: "The App Store isn't reachable right now. Check your connection and try again.")
        for code in [RevenueCat.ErrorCode.networkError, .offlineConnectionError] {
            let shown = PurchaseError.shown(code)
            XCTAssertEqual(shown as? PurchaseError, .storeUnreachable)
            XCTAssertEqual(shown.localizedDescription, reachable)
        }
        XCTAssertEqual(PurchaseError.offeringsUnavailable.localizedDescription, reachable)
        XCTAssertNotEqual(PurchaseError.storeUnreachable, .offeringsUnavailable)
    }

    func testOtherErrorsPassThroughUntouched() {
        let other = RevenueCat.ErrorCode.purchaseNotAllowedError
        XCTAssertEqual(PurchaseError.shown(other) as? RevenueCat.ErrorCode, other)
        XCTAssertEqual(PurchaseError.shown(PurchaseError.offeringsUnavailable) as? PurchaseError, .offeringsUnavailable)
    }
}
