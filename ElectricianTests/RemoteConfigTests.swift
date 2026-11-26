import XCTest
@testable import Electrician

/// The offering-metadata reader and the trial button wording it drives. The
/// control arm is the copy that shipped before the reader existed.
final class RemoteConfigTests: XCTestCase {

    // MARK: Reader

    func testMissingMetadataIsControl() {
        XCTAssertEqual(TrialCTA.from(metadata: nil), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: [:]), .sevenDay)
    }

    func testNonStringValueIsControl() {
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": 3]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": true]), .sevenDay)
    }

    func testUnknownValueIsControl() {
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "free_forever"]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": ""]), .sevenDay)
    }

    func testKnownValuesPickTheirArm() {
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "seven_day"]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "my"]), .my)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "your"]), .your)
    }

    func testMetadataKeyAndControlRawValue() {
        XCTAssertEqual(TrialCTA.metadataKey, "trial_cta")
        XCTAssertEqual(TrialCTA.sevenDay.rawValue, "seven_day")
    }

    // MARK: Titles

    /// Character for character what the onboarding page and the paywall said
    /// before the test existed.
    func testControlIsTodaysCopy() {
        XCTAssertEqual(TrialCTA.sevenDay.title(trialLength: "7 days"), "Start 7 days free")
        XCTAssertEqual(TrialCTA.sevenDay.title(trialLength: "2 weeks"), "Start 2 weeks free")
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(trial: "7 days"), "Start 7 days free")
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(trial: "7 days", cta: .sevenDay), "Start 7 days free")
    }

    func testEachArmsTitle() {
        XCTAssertEqual(TrialCTA.my.title(trialLength: "7 days"), "Start my free trial")
        XCTAssertEqual(TrialCTA.your.title(trialLength: "7 days"), "Start your free trial")
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(trial: "7 days", cta: .my), "Start my free trial")
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(trial: "7 days", cta: .your), "Start your free trial")
    }

    /// An Apple Account that already used its trial is charged on day one, so
    /// no arm promises one (3.1.2).
    func testIneligibleWordingIsUnchangedInEveryArm() {
        let expected = String(localized: "Subscribe to \(Membership.name)")
        for arm in TrialCTA.allCases {
            XCTAssertEqual(arm.title(trialLength: nil), expected)
            XCTAssertEqual(PaywallPlan.monthly.ctaTitle(trial: nil, cta: arm), expected)
        }
    }

    func testLifetimeButtonIgnoresTheArm() {
        for arm in TrialCTA.allCases {
            XCTAssertEqual(
                PaywallPlan.lifetime.ctaTitle(trial: nil, cta: arm),
                String(localized: "Unlock \(Membership.name) Forever")
            )
        }
    }

    // MARK: Switch

    func testSwitchIsOnByDefault() {
        XCTAssertTrue(RemoteConfig.isOn(.ratingPrompt, in: nil))
        XCTAssertTrue(RemoteConfig.isOn(.ratingPrompt, in: [:]))
        XCTAssertTrue(RemoteConfig.isOn(.ratingPrompt, in: ["rating_prompt": "on"]))
        XCTAssertTrue(RemoteConfig.isOn(.ratingPrompt, in: ["rating_prompt": false]), "Only the string off pauses it")
        XCTAssertTrue(RemoteConfig.isOn(.ratingPrompt, in: ["rating_prompt": "OFF"]))
    }

    func testSwitchIsOffOnlyForOff() {
        XCTAssertFalse(RemoteConfig.isOn(.ratingPrompt, in: ["rating_prompt": "off"]))
        XCTAssertEqual(RemoteSwitch.ratingPrompt.rawValue, "rating_prompt")
    }
}
