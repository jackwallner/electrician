import SwiftUI

/// The post-trial feature tour: right after the trial decision, every player
/// gets a quick show of where things live. The Pro beat is premium-aware.
/// subscribers see what their trial already opened (shine, confetti), free
/// players see exactly what Pro would unlock, gleaming behind the lock.
struct FeatureTourView: View {
    let onDone: () -> Void

    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var progress: ProgressStore
    @State private var index = 0
    @State private var shineTrigger = 0
    @State private var confettiTrigger = 0
    @State private var showQuickSession = false

    private struct TourPage {
        let eyebrow: String
        let title: String
        let body: String
        let hero: AnyView
        /// Gold-accented "jackpot" beat (the Pro reveal), regardless of position.
        var accentGold: Bool = false
    }

    var body: some View {
        let pages = tourPages
        let page = pages[index]
        let isLast = index == pages.count - 1
        return VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { dot in
                    Capsule()
                        .fill(dot == index ? Theme.voltage : Theme.voltage.opacity(0.22))
                        .frame(width: dot == index ? 20 : 7, height: 7)
                        .animation(Theme.Motion.card, value: index)
                }
            }
            .padding(.top, 10)
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                Text(page.eyebrow)
                    .font(.caption.weight(.heavy))
                    .kerning(2)
                    .foregroundStyle(page.accentGold ? Theme.brass : Theme.voltage)
                page.hero
                Text(page.title)
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .themedCard(corner: 22)
            .shine(trigger: shineTrigger, corner: 22)
            .id(index)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            Spacer(minLength: 0)
            // The escape hatch is offered on EVERY page, not just at the
            // session prompt: by the time someone has tapped through a trial
            // page and a tour, "let me just use the app" is a fair ask.
            VStack(spacing: 10) {
                Button {
                    advance(pageCount: pages.count)
                } label: {
                    Text(isLast ? "Start my first session" : "Show me").primaryCTA()
                }
                Button {
                    Haptics.impact(.light, intensity: 0.6)
                    onDone()
                } label: {
                    Text(isLast ? "Skip it, take me to the app" : "Skip the tour")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .fullScreenCover(isPresented: $showQuickSession, onDismiss: onDone) {
            NavigationStack {
                QuickSessionView(
                    items: SessionBuilder.quickSession(
                        seen: progress.seenItems,
                        missed: progress.missedItems,
                        includePro: subscriptions.isPro
                    ),
                    isDaily: false,
                    onClose: { showQuickSession = false }
                )
            }
        }
        .onAppear { fireShine() }
    }

    // MARK: - Pages

    private var tourPages: [TourPage] {
        [
            TourPage(
                eyebrow: "THE ROOMS",
                title: "Six rooms, six skills",
                body: ShellCopy.Tour.roomsBody,
                hero: AnyView(roomsHero)
            ),
            TourPage(
                eyebrow: "KEEP IT LIT",
                title: "Streaks make it stick",
                body: "Finish a drill a day and your streak grows. Anything you miss quietly returns until you own it.",
                hero: AnyView(streakHero)
            ),
            subscriptions.isPro
                ? TourPage(
                    eyebrow: "YOURS NOW",
                    title: "\(Membership.name) is open",
                    body: "Your trial already includes Code Minute, personalized Exam Warm-Up, Endless Practice across all \(PracticeSkill.allCases.count) shapes, the timed challenge, the extra sets in every room, and the worked calculations.",
                    hero: AnyView(proHero(locked: false)),
                    accentGold: true
                )
                : TourPage(
                    eyebrow: "BEHIND THE GOLD DOOR",
                    title: "\(Membership.name) adds more of it",
                    body: ShellCopy.Tour.proLockedBody,
                    hero: AnyView(proHero(locked: true)),
                    accentGold: true
                ),
            // Last on purpose: this is the one page whose CTA is real. Tapping
            // it opens an actual Quick Session, not a preview of one.
            TourPage(
                eyebrow: "YOUR TURN",
                title: "Let's try a real one",
                body: "Get Started builds this same short mix any time from Home: exactly what you need next, misses first. Let's run your first one now.",
                hero: AnyView(getStartedHero)
            ),
        ]
    }

    // MARK: - Heroes

    /// A live replica of Home's Get Started card, not a picture of one: it
    /// looks like a button because it IS one, and tapping it opens the same
    /// real Quick Session as the CTA below.
    private var getStartedHero: some View {
        Button {
            startQuickSession()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Started")
                        .font(Theme.cardTitle)
                        .foregroundStyle(.white)
                    Text("A short mix of what you need next")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 4)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Theme.voltageFill, Theme.voltageFill.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Drawn from the library rather than hardcoded, and using each room's own
    /// icon and accent, so the tour shows the rooms that actually exist. The
    /// old version was four fixed chips with icons and colours belonging to no
    /// room in particular, which meant adding a room silently made the tour a
    /// lie about the product.
    private var roomsHero: some View {
        HStack(spacing: 8) {
            ForEach(DrillLibrary.rooms) { room in
                roomChip(room.icon, room.accent)
            }
        }
    }

    private func roomChip(_ icon: String, _ color: Color) -> some View {
        Image(systemName: icon)
            .font(.body.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: 46, height: 46)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var streakHero: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.copper)
            Text("7-day streak")
                .font(Theme.cardTitle)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.copper.opacity(0.10), in: Capsule())
    }

    private func proHero(locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: locked ? "lock.fill" : "sparkles")
                    .foregroundStyle(Theme.brass)
                Text(Membership.name.uppercased())
                    .font(Theme.eyebrow)
                    .kerning(Theme.eyebrowKerning)
                    .foregroundStyle(Theme.brass)
                Spacer()
                if !locked {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.voltage)
                }
            }
            // The same three modes the paywall leads with. Extra sets and the
            // Worked Calculations are carried by the page body, so the hero does not
            // have to say everything.
            ForEach(["Code Minute, one shared daily challenge", "Exam Warm-Up, built around your weak spots", "Endless Practice, never repeats"], id: \.self) { line in
                HStack(spacing: 8) {
                    Image(systemName: locked ? "sparkles" : "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(locked ? Theme.brass : Theme.voltage)
                    Text(line)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brass.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.brass.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Flow

    /// The finale is genuinely actionable: it opens a real Quick Session
    /// rather than just advancing a tour page. The tour only finishes
    /// (`onDone`) once that session's `fullScreenCover` is dismissed.
    private func startQuickSession() {
        Haptics.success()
        showQuickSession = true
    }

    private func advance(pageCount: Int) {
        if index == pageCount - 1 {
            startQuickSession()
            return
        }
        Haptics.impact(.soft, intensity: 0.6)
        withAnimation(Theme.Motion.screen) {
            index += 1
        }
        if tourPages[index].accentGold {
            // The Pro beat is the jackpot moment either way.
            confettiTrigger += 1
        }
        fireShine()
    }

    private func fireShine() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            shineTrigger += 1
        }
    }
}
