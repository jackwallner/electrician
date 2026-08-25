import Foundation
import RevenueCat
#if DEBUG
import StoreKit
#endif

enum RevenueCatConfig {
    /// The PUBLIC Apple SDK key for this app's own RevenueCat project. Public
    /// keys are meant to ship inside the binary; the matching SECRET (`sk_`)
    /// key never appears in source and lives in `~/.electrician_credentials`,
    /// which the release scripts read.
    ///
    /// DEBUG stays a placeholder until this project has a RevenueCat test-store
    /// key. `configureIfNeeded` early-returns on it, so debug builds simply run
    /// without RevenueCat rather than touching production. That is deliberate:
    /// a debug build pointed at the production key mints fake customers in the
    /// real charts.
    #if DEBUG
    static let apiKey = "test_PLACEHOLDER"
    #else
    static let apiKey = "appl_JNXhRRCBfqpJqOpxFnylwNcqvby"
    #endif
}

/// What actually happened at Apple's sheet. A cancel is an outcome, not an error.
enum PurchaseOutcome: Sendable {
    case purchased
    case cancelled
}

/// Why a purchase could not start. These used to be one case, which meant a
/// customer who was offline, a customer whose offering had not loaded, and a
/// customer whose product was misconfigured in App Store Connect all saw the
/// same sentence, and so did we in the logs. They are three different problems
/// with three different fixes.
enum PurchaseError: LocalizedError {
    /// RevenueCat is not configured at all (simulator, or the DEBUG placeholder
    /// key). Only reachable in development.
    case notConfigured
    /// The offering never arrived: offline, or RevenueCat is unreachable.
    case offeringsUnavailable
    /// The offering arrived but has no package for this plan, which means the
    /// product is missing or misconfigured rather than the network being down.
    case packageMissing(PaywallPlan)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Purchases are not available in this build."
        case .offeringsUnavailable:
            return "The App Store isn't reachable right now. Check your connection and try again."
        case .packageMissing:
            return "That plan isn't available right now. Try another plan, or Restore if you have already bought it."
        }
    }

    /// Never shown to a customer; this is the half that makes a support email
    /// answerable.
    var diagnosticDescription: String {
        switch self {
        case .notConfigured: return "RevenueCat not configured"
        case .offeringsUnavailable: return "no current offering"
        case .packageMissing(let plan): return "offering has no \(plan.rawValue) package"
        }
    }
}

/// Where the price catalog is in its lifecycle. The paywall renders a different
/// screen for each: a placeholder, the real prices, or an explicit failure with
/// a retry, instead of a permanent "Loading price..." above a live Buy button.
enum OfferingState: Equatable {
    case idle
    case loading
    case ready
    case unavailable
}

struct PaywallPrice {
    let amount: Decimal
    let localized: String
    let locale: Locale
}

@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var isPro = false
    @Published private(set) var offerings: Offerings?
    @Published private(set) var offeringState: OfferingState = .idle
    /// Product identifier to whether this Apple Account may still start the
    /// introductory offer. Empty until StoreKit answers.
    @Published private(set) var trialEligibility: [String: Bool] = [:]

    private var isConfigured = false
    private let localOverrideKey = "subscription.localProOverride"
    private var paywallImpressionsThisSession: Set<String> = []
    /// DEBUG StoreKit Testing catalog prices. Used when RevenueCat is not
    /// configured (simulator / placeholder key) so the paywall can still
    /// render the three packages without minting a production customer.
    #if DEBUG
    @Published private var storeKitPrices: [PaywallPlan: PaywallPrice] = [:]

    private static let storeKitProductIDs: [PaywallPlan: String] = [
        .monthly: "com.jackwallner.electrician.monthly",
        .yearly: "com.jackwallner.electrician.yearly",
        .lifetime: "com.jackwallner.electrician.lifetime",
    ]
    #endif

    override private init() {
        super.init()
        isPro = UserDefaults.standard.bool(forKey: localOverrideKey)
    }

    func start() {
        configureIfNeeded()
        #if DEBUG
        if storeKitPrices.isEmpty {
            storeKitPrices = Self.pricesFromStoreKitCatalog()
        }
        #endif
        Task {
            await loadStoreKitPricesIfNeeded()
            guard isConfigured else { return }
            await refreshCustomerInfo()
            await loadOfferings()
        }
    }

    /// Dev/testing switch: flips Pro without a live RC key (Settings toggle).
    func setLocalOverride(isPro: Bool) {
        UserDefaults.standard.set(isPro, forKey: localOverrideKey)
        self.isPro = isPro
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        #if targetEnvironment(simulator)
        guard RevenueCatConfig.apiKey.hasPrefix("test_") else { return }
        #endif
        guard !RevenueCatConfig.apiKey.contains("PLACEHOLDER") else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        Purchases.shared.delegate = self
        isConfigured = true
    }

    /// Feeds RevenueCat's `paywall_encounter_v3`. A custom paywall emits no
    /// events of its own, so without this call everything between "installed"
    /// and "started a trial" is invisible for this app.
    func trackPaywallImpression(id: String, oncePerSession: Bool = false) {
        guard isConfigured else { return }
        if oncePerSession {
            guard !paywallImpressionsThisSession.contains(id) else { return }
            paywallImpressionsThisSession.insert(id)
        }
        Purchases.shared.trackCustomPaywallImpression(
            CustomPaywallImpressionParams(paywallId: id)
        )
    }

    func refreshCustomerInfo() async {
        guard isConfigured else { return }
        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }
    }

    func loadOfferings() async {
        guard isConfigured else {
            offeringState = .unavailable
            return
        }
        offeringState = .loading
        do {
            let loaded = try await Purchases.shared.offerings()
            offerings = loaded
            offeringState = loaded.current == nil ? .unavailable : .ready
        } catch {
            // Keep whatever prices we already had rather than blanking a
            // working paywall on a transient refresh failure.
            offeringState = offerings?.current == nil ? .unavailable : .ready
        }
        await refreshTrialEligibility()
    }

    /// Asks StoreKit whether THIS Apple Account can still start the free trial.
    ///
    /// The paywall used to promise "7 days free" unconditionally, which is a
    /// promise the store will not keep for anyone who has subscribed before.
    /// That is a 3.1.2 problem and, worse, it is the customer finding out at
    /// the confirmation sheet that the offer they tapped does not apply to
    /// them.
    private func refreshTrialEligibility() async {
        guard isConfigured else { return }
        let identifiers = PaywallPlan.allCases.compactMap {
            package(for: $0)?.storeProduct.productIdentifier
        }
        guard !identifiers.isEmpty else { return }
        let results = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: identifiers
        )
        var next: [String: Bool] = [:]
        for (identifier, eligibility) in results {
            switch eligibility.status {
            case .eligible:
                next[identifier] = true
            case .ineligible, .noIntroOfferExists:
                next[identifier] = false
            case .unknown:
                // Deliberately absent rather than false. `.unknown` is "could
                // not determine", which is the common answer offline and for a
                // brand-new install, and the overwhelming majority of those are
                // eligible. Recording it as ineligible would hide the trial
                // from almost everyone the moment the check hiccups. The case
                // that actually caused harm, a returning subscriber, comes back
                // as a definite `.ineligible`.
                continue
            @unknown default:
                continue
            }
        }
        trialEligibility = next
    }

    /// Whether to advertise the free trial for a plan.
    func isEligibleForTrial(_ plan: PaywallPlan) -> Bool {
        guard plan != .lifetime else { return false }
        guard let product = package(for: plan)?.storeProduct else {
            // No live product: the DEBUG StoreKit catalog stands in, and it
            // carries the trials, so the simulator paywall reads the way the
            // shipped one does.
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        guard product.introductoryDiscount != nil else { return false }
        return trialEligibility[product.productIdentifier] ?? true
    }

    /// The trial length as the STORE reports it, not as a constant in our copy.
    /// If the offer in App Store Connect ever changes from one week, the paywall
    /// follows it instead of quietly lying.
    func trialLengthText(for plan: PaywallPlan) -> String {
        guard let period = package(for: plan)?.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return "7 days"
        }
        let value = period.value
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = value == 1 ? "7 days" : "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "day"
        }
        if period.unit == .week, value == 1 { return "7 days" }
        return "\(value) \(unit)\(value == 1 ? "" : "s")"
    }

    func package(for plan: PaywallPlan) -> Package? {
        guard let offering = offerings?.current else { return nil }
        switch plan {
        case .yearly: return offering.annual
        case .monthly: return offering.monthly
        case .lifetime: return offering.lifetime
        }
    }

    func paywallPrice(for plan: PaywallPlan) -> PaywallPrice? {
        if let product = package(for: plan)?.storeProduct {
            return PaywallPrice(
                amount: product.price,
                localized: product.localizedPriceString,
                locale: product.priceFormatter?.locale ?? .current
            )
        }
        #if DEBUG
        return storeKitPrices[plan]
        #else
        return nil
        #endif
    }

    /// Reads display prices from the bundled StoreKit Testing catalog so a
    /// simulator UI test can render the three plan cards without configuring
    /// the production RevenueCat key. `Product.products` is empty unless
    /// StoreKit Testing is actually attached, which xcodebuild does not do
    /// reliably, so the bundled `.storekit` file is the source of truth.
    private func loadStoreKitPricesIfNeeded() async {
        #if DEBUG
        var next = Self.pricesFromStoreKitCatalog()
        let ids = Array(Self.storeKitProductIDs.values)
        if let products = try? await Product.products(for: ids), !products.isEmpty {
            for (plan, id) in Self.storeKitProductIDs {
                guard let product = products.first(where: { $0.id == id }) else { continue }
                next[plan] = PaywallPrice(
                    amount: product.price,
                    localized: product.displayPrice,
                    locale: Locale.current
                )
            }
        }
        storeKitPrices = next
        #endif
    }

    #if DEBUG
    /// Parses `Electrician.storekit` from the app bundle. Falls back to the
    /// catalog's listed USD amounts if the file is missing at runtime.
    private static func pricesFromStoreKitCatalog() -> [PaywallPlan: PaywallPrice] {
        let locale = Locale(identifier: "en_US")
        func formatted(_ amount: Decimal) -> PaywallPrice {
            let fmt = NumberFormatter()
            fmt.numberStyle = .currency
            fmt.locale = locale
            let text = fmt.string(from: amount as NSDecimalNumber) ?? "\(amount)"
            return PaywallPrice(amount: amount, localized: text, locale: locale)
        }

        var amounts: [PaywallPlan: Decimal] = [
            .monthly: Decimal(string: "9.99")!,
            .yearly: Decimal(string: "39.99")!,
            .lifetime: Decimal(string: "89.99")!,
        ]

        if let url = Bundle.main.url(forResource: "Electrician", withExtension: "storekit"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            func ingest(_ productID: String, _ displayPrice: String) {
                guard let plan = storeKitProductIDs.first(where: { $0.value == productID })?.key,
                      let amount = Decimal(string: displayPrice)
                else { return }
                amounts[plan] = amount
            }
            for product in json["products"] as? [[String: Any]] ?? [] {
                if let id = product["productID"] as? String,
                   let price = product["displayPrice"] as? String {
                    ingest(id, price)
                }
            }
            for group in json["subscriptionGroups"] as? [[String: Any]] ?? [] {
                for sub in group["subscriptions"] as? [[String: Any]] ?? [] {
                    if let id = sub["productID"] as? String,
                       let price = sub["displayPrice"] as? String {
                        ingest(id, price)
                    }
                }
            }
        }

        return amounts.mapValues(formatted)
    }
    #endif

    /// Offerings can still be in flight when a player reaches the trial CTA on
    /// a cold, slow network. Give them one more chance to land before we call
    /// the products missing, so the button isn't dead on a fast tapper.
    @discardableResult
    func ensureOfferings() async -> Bool {
        guard isConfigured else { return false }
        if offerings?.current != nil { return true }
        await loadOfferings()
        return offerings?.current != nil
    }

    /// Loads offerings if needed, then hands back the package for the plan.
    /// Throws the specific reason it could not, so the paywall can tell a
    /// network problem from a misconfigured product.
    func resolvePackage(for plan: PaywallPlan) async throws -> Package {
        guard isConfigured else { throw PurchaseError.notConfigured }
        guard await ensureOfferings() else { throw PurchaseError.offeringsUnavailable }
        guard let package = package(for: plan) else { throw PurchaseError.packageMissing(plan) }
        return package
    }

    func purchase(_ package: Package?) async throws -> PurchaseOutcome {
        guard isConfigured else {
            throw PurchaseError.notConfigured
        }
        guard let package else { throw PurchaseError.offeringsUnavailable }
        let result = try await Purchases.shared.purchase(package: package)
        // RevenueCat reports a user backing out of Apple's sheet as a normal
        // result, not an error. Treating it as a failure is what used to shove
        // a second paywall in front of someone who just said "not now".
        if result.userCancelled { return .cancelled }
        apply(result.customerInfo)
        return .purchased
    }

    /// StoreKit says the money moved; RevenueCat's entitlement can take a beat
    /// to catch up. Poll briefly rather than leave someone who just paid
    /// staring at the paywall that took their money.
    @discardableResult
    func confirmEntitlement(attempts: Int = 3) async -> Bool {
        guard isConfigured else { return isPro }
        for attempt in 0..<attempts {
            await refreshCustomerInfo()
            if isPro { return true }
            if attempt < attempts - 1 {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
        }
        return isPro
    }

    func restore() async throws {
        guard isConfigured else { return }
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
    }

    /// The entitlement key must match the RevenueCat project exactly. It is
    /// `electrician_pro`, not the fleet's usual `pro`: a `lookup_key` is
    /// immutable in both RevenueCat APIs, so the app matches the project rather
    /// than the other way round. Get this wrong and a purchase completes,
    /// charges the customer, and unlocks nothing.
    private static let entitlementKey = "electrician_pro"

    private func apply(_ info: CustomerInfo) {
        let entitled = info.entitlements[Self.entitlementKey]?.isActive == true
        let override = UserDefaults.standard.bool(forKey: localOverrideKey)
        isPro = entitled || override
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}
