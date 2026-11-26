import Foundation
import RevenueCat

/// Everything RevenueCat can change without a release, read from the CURRENT
/// offering's metadata, so a running Experiment's variant is the one read.
/// Every variant ships in the binary; a missing, non-string or unknown value is
/// the control, which is what the app shipped before this reader existed.
///
/// Wording tests go through the offering metadata key `trial_cta`. A key that a
/// switch reads (`rating_prompt`) must be set the same on every offering, or an
/// Experiment arm would flip it as a side effect.
///
/// DEBUG builds can pin any key for captures: `-electrician.rc.<key> <value>`.

/// The trial button's wording on the onboarding trial page and the paywall.
/// Both surfaces are sentence case in the control, so the arms are too.
enum TrialCTA: String, CaseIterable, Sendable {
    static let metadataKey = "trial_cta"

    /// Control: "Start 7 days free", the store's own trial length in the
    /// sentence, as shipped before the test.
    case sevenDay = "seven_day"
    case my
    case your

    static func from(metadata: [String: Any]?) -> TrialCTA {
        RemoteConfig.value(metadataKey, in: metadata, default: .sevenDay)
    }

    /// `trialLength` is the store's length for the plan ("7 days"), or nil when
    /// this Apple Account cannot start a trial: it is then charged on day one,
    /// so the button promises no trial in any arm (3.1.2).
    func title(trialLength: String?) -> String {
        guard let trialLength else { return String(localized: "Subscribe to \(Membership.name)") }
        switch self {
        case .sevenDay: return String(localized: "Start \(trialLength) free")
        case .my: return String(localized: "Start my free trial")
        case .your: return String(localized: "Start your free trial")
        }
    }
}

/// Remote off switches, for what is worth pausing without a release. On unless
/// the metadata says "off".
enum RemoteSwitch: String, CaseIterable, Sendable {
    /// Apple's rating prompt after a good result. "off" pauses the automatic ask.
    case ratingPrompt = "rating_prompt"
}

enum RemoteConfig {
    /// The value for `key`, or `fallback` when it is missing, not a string, or
    /// not one of the shipped variants.
    static func value<T: RawRepresentable>(_ key: String, in metadata: [String: Any]?, default fallback: T) -> T
    where T.RawValue == String {
        #if DEBUG
        if let pinned = launchOverride(key).flatMap(T.init(rawValue:)) { return pinned }
        #endif
        guard let raw = metadata?[key] as? String else { return fallback }
        return T(rawValue: raw) ?? fallback
    }

    static func isOn(_ remoteSwitch: RemoteSwitch, in metadata: [String: Any]?) -> Bool {
        #if DEBUG
        if let pinned = launchOverride(remoteSwitch.rawValue) { return pinned != "off" }
        #endif
        return (metadata?[remoteSwitch.rawValue] as? String) != "off"
    }

    #if DEBUG
    private static func launchOverride(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-electrician.rc.\(key)"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
    #endif
}

extension SubscriptionService {
    private var remoteMetadata: [String: Any]? { offerings?.current?.metadata }

    var trialCTAArm: TrialCTA { TrialCTA.from(metadata: remoteMetadata) }

    func isOn(_ remoteSwitch: RemoteSwitch) -> Bool { RemoteConfig.isOn(remoteSwitch, in: remoteMetadata) }
}
