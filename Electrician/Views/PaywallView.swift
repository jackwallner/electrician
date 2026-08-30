import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, lifetime, monthly

    /// The CTA has to name what THIS Apple Account will actually get. A
    /// returning subscriber is not eligible for the introductory offer, and
    /// promising them a free trial is a promise the store refuses at the
    /// confirmation sheet.
    func ctaTitle(trial: String?) -> String {
        guard self != .lifetime else { return "Unlock \(Membership.name) Forever" }
        guard let trial else { return "Subscribe to \(Membership.name)" }
        return "Start \(trial) free"
    }

    var packageType: PackageType {
        switch self {
        case .yearly: return .annual
        case .monthly: return .monthly
        case .lifetime: return .lifetime
        }
    }
}

enum PaywallLinks {
    /// Apple's standard EULA. If the app ever ships a custom EULA, this is the
    /// one place to swap it; App Review requires a functional Terms link here.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://jackwallner.github.io/electrician/privacy-policy")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}

/// Shared paywall content used by the locked-drill sheet and Settings.
///
/// App Review 3.1.2 wants all of this ON the purchase screen, not buried:
/// the membership name, what each plan costs, the billing period, an explicit
/// auto-renew statement, Restore, and working Terms + Privacy links. Every one
/// of those lives in this file; don't trim them for layout.
struct PaywallContent: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var profile: CandidateProfile
    @Binding var selectedPlan: PaywallPlan

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Get \(Membership.name)")
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.ink)
                Text(subhead)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // The argument goes ABOVE the prices, not below them. A reader
            // deciding between three amounts has already been told what the
            // app is; what they have not been told is why the free half will
            // not carry them to the exam, and that is the only thing on this
            // screen that can change the answer.
            runsOutNotice
            // Put the decision in view before the longer value explanation.
            // The lifetime amount used to sit under the sticky purchase footer
            // on a phone-sized sheet, which made the least obvious plan the
            // hardest one to compare.
            planCards
            VStack(alignment: .leading, spacing: 9) {
                benefit("Endless Practice: \(PracticeSkill.allCases.count) calculation shapes generated fresh, so you learn a method instead of memorising a question")
                // Precise on purpose. Generated questions are one-offs and can
                // never return as themselves; what returns is a NEW problem
                // that sets the same trap. Saying "the exact questions come
                // back" would describe a feature the generator cannot have.
                benefit("Fix My Mistakes: every wrong answer is a named error, and new problems set the same trap until you stop falling for it")
                benefit("Exam Warm-Up: a short session built from your own weak spots, for the morning of")
                benefit("\(DrillLibrary.membershipItemCount) more authored questions: the worked dwelling calculation, grounding, motors, and extra sets in every room")
                benefit("Code Minute: the shared five-question daily challenge")
                benefit("Timed Challenge: 90 seconds, chase your best")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var subhead: String {
        guard let countdown = profile.examCountdownSummary else {
            return "Everything you have stays free. \(Membership.name) is the half that does not run out."
        }
        return "\(countdown). Everything you have stays free; \(Membership.name) is the half that does not run out before then."
    }

    /// The same arithmetic the onboarding trial step makes, for the reader who
    /// skipped it and is meeting the offer here instead. Counted from the
    /// library rather than written into a string, so it cannot go stale.
    ///
    /// It makes a DIFFERENT argument for a candidate sitting the exam within a
    /// few days. Telling someone with one day left that they are about to run
    /// out of free questions is both false (they will not get through them
    /// either) and the wrong pitch: what decides tomorrow is not volume, it is
    /// whether their repeated errors get named and set again.
    private var runsOutNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: profile.pace == .cram ? "scope" : "hourglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.copper)
            Text(runsOutText)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.copper.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.copper.opacity(0.24), lineWidth: 1)
        )
    }

    private var runsOutText: String {
        let free = DrillLibrary.freeItemCount
        let daily = profile.suggestedDailyQuestions
        let days = max(1, Int((Double(free) / Double(max(daily, 1))).rounded(.up)))
        if profile.pace == .cram {
            return "More questions is not what decides an exam this close. Every wrong answer here is a named error, and \(Membership.name) builds fresh problems that set the same trap until you stop falling for it."
        }
        return "The free rooms hold \(free) questions. At \(daily) a day that is about \(days == 1 ? "1 day" : "\(days) days"), and after that you are re-reading answers you already remember. The generator is what makes the reps keep counting."
    }

    private func benefit(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.voltage)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The trial length for a plan, or nil when this account cannot start one.
    private func trial(_ plan: PaywallPlan) -> String? {
        guard subscriptions.isEligibleForTrial(plan) else { return nil }
        return subscriptions.trialLengthText(for: plan)
    }

    private var planCards: some View {
        // Yearly, then monthly, then lifetime. Monthly sits DIRECTLY under yearly
        // on purpose: the yearly card's whole pitch is a discount off the monthly
        // price, and a discount only reads as one when the thing it's discounting
        // is the next line down. Lifetime is a different decision (own it vs rent
        // it) and belongs after that comparison, not inside it.
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: PaywallPricing.priceText(subscriptions, .yearly),
                     perMonth: PaywallPricing.perMonthEquivalent(subscriptions),
                     anchor: PaywallPricing.monthlyAnchor(subscriptions),
                     detail: trial(.yearly).map { "\($0) free, then billed yearly. Auto-renews." }
                         ?? "Billed yearly. Auto-renews.",
                     badge: PaywallPricing.savingsBadge(subscriptions))
            planCard(.monthly, title: "Monthly", price: PaywallPricing.priceText(subscriptions, .monthly),
                     perMonth: nil, anchor: nil,
                     detail: trial(.monthly).map { "\($0) free, then billed monthly. Auto-renews." }
                         ?? "Billed monthly. Auto-renews.",
                     badge: nil)
            planCard(.lifetime, title: "Lifetime", price: PaywallPricing.priceText(subscriptions, .lifetime),
                     perMonth: nil, anchor: nil,
                     detail: "One payment. No subscription, nothing renews.", badge: "NO SUBSCRIPTION")
        }
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, perMonth: String?,
                          anchor: String?, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Theme.cardTitle)
                            .foregroundStyle(Theme.ink)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.brass.opacity(0.18), in: Capsule())
                                .foregroundStyle(Theme.brass)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    if let perMonth {
                        // The struck-through monthly price beside the yearly
                        // per-month figure is the discount, stated. Without it
                        // the two cards are just two numbers and the bigger one
                        // looks like the worse deal.
                        HStack(spacing: 5) {
                            if let anchor {
                                Text(anchor)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.inkTertiary)
                                    .strikethrough(true, color: Theme.inkTertiary)
                            }
                            Text(perMonth)
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                isSelected ? Theme.voltage.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.voltage : Theme.rule, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Price and terms strings, live from StoreKit.
///
/// Hardcoded fallback amounts used to live here, and they had already drifted a
/// full price tier out of date, so the screen could quietly quote $19.99/year on
/// a $9.99 product. A price the store did not give us is worse than no price at
/// all (3.1.2 wants the amount the customer will actually be charged), so an
/// unresolved product renders the loading placeholder and the disclosure drops
/// the amount rather than inventing one.
@MainActor
enum PaywallPricing {
    /// Shown in the amount's place until StoreKit answers.
    static let placeholder = "Loading price…"

    /// The localized billed amount, or nil while the product is still in flight.
    static func price(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String? {
        guard let base = subscriptions.paywallPrice(for: plan)?.localized else {
            return nil
        }
        switch plan {
        case .yearly: return "\(base)/year"
        case .monthly: return "\(base)/month"
        case .lifetime: return base
        }
    }

    /// The same, ready to render: the amount or the placeholder.
    static func priceText(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        price(subscriptions, plan) ?? placeholder
    }

    /// Yearly billed amount restated per month, e.g. "$3.33/mo". Yearly is the
    /// only plan this makes sense for; everything else returns nil.
    ///
    /// This is the line that keeps a yearly price legible next to the monthly
    /// one. Without it a 4x sticker gap reads as a penalty instead of a saving.
    static func perMonthEquivalent(_ subscriptions: SubscriptionService) -> String? {
        guard let product = subscriptions.paywallPrice(for: .yearly) else { return nil }
        let monthly = product.amount / 12
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.locale = product.locale
        guard let text = fmt.string(from: monthly as NSDecimalNumber) else { return nil }
        return "\(text)/mo"
    }

    /// The monthly plan's own price restated as a per-month anchor, e.g.
    /// "$9.99/mo". This is the number the yearly card is discounting; it is
    /// struck through beside the yearly per-month figure.
    static func monthlyAnchor(_ subscriptions: SubscriptionService) -> String? {
        guard let product = subscriptions.paywallPrice(for: .monthly) else { return nil }
        return "\(product.localized)/mo"
    }

    /// Whole-percent saving of the yearly plan against twelve months of the
    /// monthly plan. nil when either product is missing or the yearly plan is
    /// not actually cheaper, so the badge can never claim a saving that isn't
    /// there (PPP territories price the two plans independently).
    static func savingsPercent(_ subscriptions: SubscriptionService) -> Int? {
        guard let yearly = subscriptions.paywallPrice(for: .yearly),
              let monthly = subscriptions.paywallPrice(for: .monthly) else { return nil }
        let twelveMonths = monthly.amount * 12
        guard twelveMonths > 0, yearly.amount < twelveMonths else { return nil }
        var rounded = Decimal()
        var raw = (twelveMonths - yearly.amount) / twelveMonths * 100
        NSDecimalRound(&rounded, &raw, 0, .plain)
        let percent = NSDecimalNumber(decimal: rounded).intValue
        return percent > 0 ? percent : nil
    }

    /// The yearly card's badge: the quantified saving when we can compute it,
    /// otherwise the generic claim. "SAVE 67%" outsells "BEST VALUE" because it
    /// says what the value is.
    static func savingsBadge(_ subscriptions: SubscriptionService) -> String {
        guard let percent = savingsPercent(subscriptions) else { return "BEST VALUE" }
        return "SAVE \(percent)%"
    }

    /// One concise point-of-purchase line: price, trial, auto-renew, cancel.
    /// The full legalese lives in the EULA behind the Terms link.
    ///
    /// The trial half is conditional for the same reason the CTA is: an
    /// ineligible Apple Account must be quoted the amount it will actually be
    /// charged, on the first billing period, with no mention of a free week it
    /// will not receive.
    static func terms(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        let trial = subscriptions.isEligibleForTrial(plan)
            ? subscriptions.trialLengthText(for: plan)
            : nil
        guard let amount = price(subscriptions, plan) else {
            switch plan {
            case .lifetime:
                return "One-time purchase. Not a subscription, nothing renews."
            case .yearly, .monthly:
                guard let trial else { return "Auto-renews until canceled." }
                return "Includes \(trial) free. Auto-renews until canceled."
            }
        }
        switch plan {
        case .lifetime:
            return "\(amount) one-time. Not a subscription, nothing renews."
        case .yearly, .monthly:
            guard let trial else { return "\(amount). Auto-renews until canceled." }
            return "\(trial) free, then \(amount). Auto-renews until canceled."
        }
    }
}

/// Standalone paywall sheet (locked drills, locked rooms, Settings upgrade).
struct PaywallView: View {
    /// Which surface opened the sheet; reported to RevenueCat.
    var source: String = "electrician_paywall_sheet"
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false
    @State private var restoring = false
    @State private var message: String?
    @State private var retrying = false

    /// Whether there is a real, purchasable package behind the selected plan.
    ///
    /// Without this the Buy button stayed live under a permanent "Loading
    /// price..." and answered a tap with a generic App Store error. Someone who
    /// has just decided to pay reads that as a broken purchase, and the one
    /// thing they still need, Restore, was the least prominent control on the
    /// screen.
    private var canPurchase: Bool {
        PaywallPricing.price(subscriptions, selectedPlan) != nil
    }

    private var pricesUnavailable: Bool {
        subscriptions.offeringState == .unavailable && !canPurchase
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContent(selectedPlan: $selectedPlan)
                    .padding()
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if pricesUnavailable {
                        unavailableNotice
                    } else {
                        Text(PaywallPricing.terms(subscriptions, selectedPlan))
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button {
                        if pricesUnavailable { retry() } else { purchase() }
                    } label: {
                        Group {
                            if purchasing || retrying {
                                ProgressView().tint(.white)
                            } else if pricesUnavailable {
                                Text("Try Again")
                            } else {
                                Text(selectedPlan.ctaTitle(trial: ctaTrial))
                            }
                        }
                        .primaryCTA()
                    }
                    .disabled(purchasing || retrying || (!canPurchase && !pricesUnavailable))
                    .opacity(!canPurchase && !pricesUnavailable ? 0.5 : 1)
                    footerLinks
                }
                .padding()
                .background(.thinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .alert("Electrician", isPresented: .init(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .onChange(of: subscriptions.isPro) { _, isPro in
                if isPro { dismiss() }
            }
            .task { subscriptions.trackPaywallImpression(id: source) }
        }
    }

    private var ctaTrial: String? {
        guard subscriptions.isEligibleForTrial(selectedPlan) else { return nil }
        return subscriptions.trialLengthText(for: selectedPlan)
    }

    /// Explicit failure beats a placeholder that never resolves. Restore stays
    /// live beneath it, because the most likely person staring at this screen
    /// with no prices is someone who already paid on another device.
    private var unavailableNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(Theme.copper)
            Text("Prices could not be loaded. Check your connection and try again. Already a member? Tap Restore.")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func retry() {
        retrying = true
        Task {
            defer { retrying = false }
            await subscriptions.loadOfferings()
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Restore") { restore() }
                .disabled(restoring)
            Link("Terms of Use", destination: PaywallLinks.terms)
            Link("Privacy Policy", destination: PaywallLinks.privacy)
        }
        .font(.caption)
        .foregroundStyle(Theme.inkSecondary)
    }

    private func purchase() {
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                // Resolving the package separately is what lets "we could not
                // reach the store" and "this product is misconfigured" stay
                // different errors instead of collapsing into one sentence that
                // fits neither.
                let package = try await subscriptions.resolvePackage(for: selectedPlan)
                let outcome = try await subscriptions.purchase(package)
                guard outcome == .purchased else { return }
                Haptics.success()
                // The sheet dismisses itself the moment `isPro` flips. If the
                // entitlement hasn't landed after a few seconds, say so and
                // point at Restore, rather than leaving someone who just paid
                // looking at the paywall that charged them.
                if await !subscriptions.confirmEntitlement() {
                    message = "Your purchase went through, but \(Membership.name) hasn't unlocked yet. Give it a moment, then tap Restore. You will not be charged twice."
                }
            } catch let error as PurchaseError {
                // A cancel never lands here (it's an outcome, not a throw), so
                // anything that does is worth telling the player about.
                print("[paywall] purchase blocked: \(error.diagnosticDescription)")
                message = error.errorDescription
            } catch {
                message = error.localizedDescription
            }
        }
    }

    private func restore() {
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if !subscriptions.isPro {
                    message = "No previous purchase found on this Apple Account."
                }
            } catch {
                message = error.localizedDescription
            }
        }
    }
}
