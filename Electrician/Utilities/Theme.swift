import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Electrical design system: cool drawing-paper and slate surfaces, a deep
/// line-voltage blue primary, copper for energy, brass for the membership, and
/// condensed sans display type that reads like panel labelling. Every color
/// adapts to dark mode via dynamic providers.
///
/// The palette is deliberately *not* the cream-and-jade one this shell was
/// ported with. Cream paper and jade green are mahjong signals (tile faces and
/// table felt); an electrician's visual vocabulary is drawing paper, painted
/// steel, copper, brass and the green of an equipment grounding conductor.
enum Theme {
    // MARK: Brand
    //
    // Every accent is named after the thing it comes from, and the room accents
    // below use them semantically: blue for the book, copper for conductors,
    // steel for the calculations, green for grounding.

    /// Line-voltage blue. Primary actions, progress, selected states.
    /// 6.6:1 on white with white text on the fill, so it works as a CTA.
    static let voltage = Color(light: (0.05, 0.34, 0.64), dark: (0.42, 0.70, 1.0))
    /// Copper. Energy moments: streaks, celebration, conductor identity.
    static let copper = Color(light: (0.70, 0.36, 0.15), dark: (0.91, 0.58, 0.33))
    /// Brass. Locks, "best value", membership highlights.
    static let brass = Color(light: (0.63, 0.47, 0.10), dark: (0.87, 0.72, 0.34))
    /// Galvanized steel blue. The calculations room.
    static let conduit = Color(light: (0.30, 0.36, 0.47), dark: (0.60, 0.69, 0.82))
    /// The same blue and copper, held dark enough that WHITE text on top of a
    /// solid fill still clears AA in dark mode.
    ///
    /// `voltage` and `copper` above lighten in dark mode because most of their
    /// uses are ink and icons on a dark surface, where a dark accent would
    /// disappear. A filled CTA is the opposite problem: light-blue fill with
    /// white text lands around 2.3:1 and is unreadable. Anything that paints a
    /// solid accent behind white must use these instead.
    static let voltageFill = Color(light: (0.05, 0.34, 0.64), dark: (0.11, 0.44, 0.80))
    static let copperFill = Color(light: (0.65, 0.31, 0.11), dark: (0.72, 0.36, 0.14))

    /// Equipment-grounding green. The grounding room, and nothing else.
    /// Kept distinct from `rightGreen` so a room accent never reads as a mark.
    static let ground = Color(light: (0.13, 0.45, 0.24), dark: (0.42, 0.76, 0.50))

    /// Delta high-leg orange, the marking 110.15 requires on the B phase of a
    /// four-wire delta. The installation-rules room: working space, supports,
    /// burial depths, the things that are orange tape and site signage.
    static let highLeg = Color(light: (0.71, 0.34, 0.03), dark: (0.95, 0.60, 0.25))
    /// Meter-can indigo. The service and load-calculation room, which is the
    /// only place in the app where the answer is a service size.
    static let service = Color(light: (0.29, 0.24, 0.60), dark: (0.66, 0.62, 0.95))

    // MARK: Surfaces

    /// Cool drawing-paper background in light, slate in dark
    /// (never pure white / pure black).
    static let background = Color(light: (0.937, 0.949, 0.961), dark: (0.070, 0.078, 0.094))
    /// Raised card surface.
    static let card = Color(light: (0.996, 1.0, 1.0), dark: (0.125, 0.141, 0.169))
    /// Slightly sunken surface for wells inside cards.
    static let well = Color(light: (0.902, 0.922, 0.941), dark: (0.094, 0.106, 0.129))
    /// Hairline stroke on cards.
    static let rule = Color(light: (0.796, 0.827, 0.859), dark: (0.235, 0.259, 0.302))

    // MARK: Ink

    // Contrast is not a style knob here. This app's readers skew 50+ and read
    // it on a couch in bad light, and tertiary ink carries the money disclosure
    // and the swipe instructions. Every level below clears WCAG AA (4.5:1) on
    // both backgrounds; tertiary used to sit at 2.8:1, which is decorative-text
    // territory. Re-check with a contrast calculator before lightening the paper.
    static let ink = Color(light: (0.09, 0.12, 0.16), dark: (0.93, 0.95, 0.97))
    /// 6.7:1 light / 7.7:1 dark.
    static let inkSecondary = Color(light: (0.31, 0.35, 0.41), dark: (0.70, 0.74, 0.79))
    /// 4.7:1 light / 5.9:1 dark.
    static let inkTertiary = Color(light: (0.39, 0.43, 0.49), dark: (0.60, 0.64, 0.70))

    // MARK: Worksheet and grading

    /// The card/working-panel stock, a shade cooler and brighter than `card`.
    /// Used for the faces of flashcards and for the numbered working panel, so
    /// both read as a page torn out of a code book rather than another app
    /// surface. Pair it with `blueprintGrid()` on the working panel.
    static let worksheet = Color(light: (0.980, 0.988, 1.0), dark: (0.918, 0.937, 0.957))
    static let worksheetEdge = Color(light: (0.769, 0.812, 0.859), dark: (0.635, 0.678, 0.729))
    /// The faint ruled grid drawn on worksheet surfaces. Low enough to sit
    /// behind text without fighting it at any Dynamic Type size.
    static let grid = Color(light: (0.05, 0.30, 0.55), dark: (0.10, 0.25, 0.45))
    /// Ink for anything drawn ON a worksheet surface.
    ///
    /// `worksheet` stays light in dark mode on purpose: it is a page torn out
    /// of a code book, and a code book does not invert. That makes the normal
    /// ink scale wrong on it, because `ink` and `inkSecondary` go near-white in
    /// dark mode and would land white-on-white. These three do not adapt, and
    /// nothing on a worksheet surface may use the adaptive ones.
    static let worksheetInk = Color(red: 0.09, green: 0.12, blue: 0.16)
    static let worksheetInkSecondary = Color(red: 0.29, green: 0.33, blue: 0.39)
    static let worksheetInkTertiary = Color(red: 0.40, green: 0.44, blue: 0.50)
    /// The accent for a number or step marker on a worksheet, held at the
    /// light-mode blue for the same reason.
    static let worksheetAccent = Color(red: 0.05, green: 0.34, blue: 0.64)

    /// Grading colors. Deliberately not `voltage`/`copper`: right and wrong have
    /// to read as a verdict, not as brand accents used elsewhere on the screen.
    static let rightGreen = Color(red: 0.12, green: 0.47, blue: 0.29)
    static let wrongRed = Color(red: 0.72, green: 0.17, blue: 0.16)

    // MARK: Type
    //
    // Three faces, and only three, each with one job:
    //
    //   condensed heavy  every TITLE, at any size (`display` and the semantic
    //                    tokens below). Panel-schedule lettering.
    //   system text      every sentence: body, subtitle, caption, detail.
    //   monospaced       every NUMBER read as an instrument value.
    //
    // The rule that keeps them from reading as "several fonts" is that the
    // split is by ROLE, never by size. A card title and a screen title are the
    // same face at different sizes; a card title and its subtitle are two
    // faces because they are two different kinds of text. Anything that is a
    // title and reaches for `.headline` or `.title3` instead breaks that, and
    // it is what made the app look like it had picked up a new font.

    /// Display type for titles. Heavy condensed sans, which is the lettering on
    /// a panel schedule, a breaker, and a code-book tab, not the serif of a
    /// members' club.
    ///
    /// Prefer the `TextStyle` overload and the semantic tokens under it. A
    /// point size does not scale with Dynamic Type, so a fixed-size title is
    /// frozen at whatever the designer's device was set to; this overload is
    /// for the handful of places where the size IS the design (a 190pt score,
    /// an icon-sized glyph) and reflowing it would break the layout.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }

    /// The scaling version: same condensed face, sized from a text style, so it
    /// grows and shrinks with the reader's Dynamic Type setting.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .heavy) -> Font {
        .system(style, design: .default, weight: weight).width(.condensed)
    }

    /// The title scale. Every title in the app comes from one of these five.
    /// Onboarding and marketing value pages.
    static var displayLarge: Font { display(.largeTitle) }
    /// A screen's own name: Home's header, an onboarding step, a paywall.
    static var screenTitle: Font { display(.title) }
    /// The title of a full-width hero card (Get Started, a room header).
    static var sectionTitle: Font { display(.title2, weight: .bold) }
    /// A question prompt, and any title that carries a sentence's worth of text.
    static var questionTitle: Font { display(.title3, weight: .bold) }
    /// A card or list-row title. This is the one that used to be `.headline`.
    static var cardTitle: Font { display(.headline, weight: .bold) }

    /// The all-caps, letter-spaced section marker ("THE ROOMS"). One token so
    /// the kerning cannot drift between sections.
    static var eyebrow: Font { .caption.weight(.heavy) }
    static let eyebrowKerning: CGFloat = 1.4

    /// Numbers read as instrument readings, not prose: ampacities, AWG sizes,
    /// article numbers and percentages all use this so columns line up and a
    /// value never reflows differently from the one above it.
    static func numeric(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Dynamic-Type-scaling monospace, for numbers that sit in flowing layout.
    static func numeric(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }

    // MARK: Motion
    //
    // One vocabulary for every animation in the app, for two reasons. The first
    // is that a screen whose header, content and footer each animate on their
    // own curve does not read as one screen moving; it reads as three things
    // arriving at slightly different times, which is exactly the "sliding into
    // place" wobble. The second is Reduce Motion: honouring it needs one place
    // to check, not sixty.
    //
    // Durations are deliberately shorter than the ported defaults. The shell
    // arrived with 0.4-0.5s springs on screen changes, which is fine for a
    // leisurely card game and too slow for an app whose core loop is answer,
    // grade, next, several hundred times.
    enum Motion {
        /// Set in iOS Settings > Accessibility > Motion. Read at view-update
        /// time, which is when SwiftUI asks for the animation.
        static var reduced: Bool {
            #if canImport(UIKit)
            UIAccessibility.isReduceMotionEnabled
            #else
            false
            #endif
        }

        /// A whole screen or step changing. The one curve every page-level
        /// change uses, so a header, its content and its footer move together.
        static var screen: Animation {
            reduced ? .easeOut(duration: 0.16) : .spring(response: 0.32, dampingFraction: 0.92)
        }

        /// A card or row changing state in place.
        static var card: Animation {
            reduced ? .easeOut(duration: 0.14) : .spring(response: 0.26, dampingFraction: 0.86)
        }

        /// Content appearing after a grade: the working, the coaching note.
        static var reveal: Animation {
            reduced ? .easeOut(duration: 0.12) : .easeOut(duration: 0.22)
        }

        /// A progress bar or ring moving to a new value.
        static var meter: Animation {
            reduced ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28)
        }

        /// The one bouncy curve, reserved for a correct answer landing.
        static var celebrate: Animation {
            reduced ? .easeOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.58)
        }

        /// A flashcard turning over. Physical rather than UI, so it keeps a
        /// little more travel than `card`, but not much: this fires several
        /// hundred times in a study session and every extra tenth of a second
        /// is paid on every one of them.
        static var flip: Animation {
            reduced ? .easeOut(duration: 0.16) : .spring(response: 0.40, dampingFraction: 0.86)
        }

        /// A card being thrown off the deck. Ease IN, because it is leaving.
        static var fling: Animation {
            reduced ? .easeOut(duration: 0.14) : .easeIn(duration: 0.28)
        }

        /// The full-screen tint that flashes on a correct answer, fading out.
        static var flash: Animation {
            reduced ? .easeOut(duration: 0.2) : .easeOut(duration: 0.45)
        }

        /// Decoration that exists only to move: the wrong-answer shake, the
        /// shine sweep across a winning row. `nil` where Reduce Motion is on,
        /// so the caller can skip the effect rather than animate it faster.
        /// A shake with the motion taken out is not a gentler shake, it is a
        /// jump, and that is worse than nothing for the reader who asked.
        static var flourish: Animation? {
            reduced ? nil : .easeInOut(duration: 0.7)
        }

        static var shake: Animation? {
            reduced ? nil : .linear(duration: 0.35)
        }

        /// The horizontal advance every stepped flow shares: onboarding, the
        /// primer, the tour, and the question runners. Reduce Motion gets a
        /// plain crossfade, because the slide is the part that causes trouble.
        static var advance: AnyTransition {
            guard !reduced else { return .opacity }
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }

        /// The same, backwards, for a Back tap.
        static var retreat: AnyTransition {
            guard !reduced else { return .opacity }
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }

        /// Something arriving under what is already there.
        static var riseIn: AnyTransition {
            guard !reduced else { return .opacity }
            return .opacity.combined(with: .move(edge: .bottom))
        }
    }

static let cardCorner: CGFloat = 20
    static let deckCorner: CGFloat = 26
    /// Keeps reading and answering comfortable on iPad instead of stretching
    /// phone-sized interactions across the full window.
    static let readableContentWidth: CGFloat = 760
    static let wideContentWidth: CGFloat = 1120
}

/// Room identity: each room keeps its own accent so the four doors feel like
/// four places, not four list rows.
extension Room {
    /// Every room id is listed. There is no `default` accent on purpose: a new
    /// room that forgets to claim a colour should fail the accent test rather
    /// than quietly inherit grounding green and turn the one semantic colour in
    /// the palette into a generic fallback.
    static let accents: [String: Color] = [
        "basics-room": Theme.voltage,
        "conductors-room": Theme.copper,
        "calc-room": Theme.conduit,
        // Green, because the equipment grounding conductor is green in every
        // jurisdiction this app ships to.
        "grounding-room": Theme.ground,
        "install-room": Theme.highLeg,
        "loads-room": Theme.service,
    ]

    var accent: Color { Room.accents[id] ?? Theme.voltage }
}

/// The membership brand. The RevenueCat entitlement is `electrician_pro`;
/// this is only what readers see.
enum Membership {
    static let name = "Electrician+"
}

/// The brass pill that marks anything behind the membership.
struct PlusBadge: View {
    var text: String = Membership.name

    var body: some View {
        Text(text)
            .font(.caption.weight(.heavy))
            .foregroundStyle(Theme.brass)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.brass.opacity(0.15), in: Capsule())
    }
}

extension Color {
    /// Adaptive color from light/dark RGB triples.
    init(light: (Double, Double, Double), dark: (Double, Double, Double)) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #else
        self.init(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

// MARK: - Shared styles

extension View {
    /// Standard raised card: cool surface, hairline, soft shadow.
    func themedCard(corner: CGFloat = Theme.cardCorner) -> some View {
        self
            .background(Theme.card, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.rule, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    func primaryCTA(color: Color = Theme.voltage) -> some View {
        modifier(PrimaryCTAStyle(color: color))
    }
}

/// A faint ruled grid, the way a worksheet or a wiring diagram is ruled.
///
/// This is the one piece of ornament in the app and it is load-bearing for the
/// rebrand: a plain rounded rectangle reads as "any iOS app", while a ruled
/// panel reads as engineering paper. It is drawn with `Canvas` rather than a
/// tiled image so it stays crisp at any size and costs nothing to ship, and it
/// is clipped to the caller's shape so it never bleeds past a card edge.
struct BlueprintGrid: View {
    var spacing: CGFloat = 14
    var opacity: Double = 0.07
    var lineWidth: CGFloat = 0.5

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = spacing
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = spacing
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(path, with: .color(Theme.grid.opacity(opacity)), lineWidth: lineWidth)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Overlays `BlueprintGrid` inside a rounded rect, for worksheet surfaces.
    func blueprintGrid(corner: CGFloat = Theme.cardCorner,
                       spacing: CGFloat = 14,
                       opacity: Double = 0.07) -> some View {
        overlay(
            BlueprintGrid(spacing: spacing, opacity: opacity)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        )
    }
}

/// The thin energized rule used as a section divider and under the onboarding
/// progress. A gradient from `voltage` to `copper`, i.e. the two ends of the
/// palette, so a 2pt line still carries the brand.
struct BusBar: View {
    var height: CGFloat = 3
    var progress: Double = 1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.rule)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.voltage, Theme.copper],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// The filled primary button.
///
/// Every accent in this palette lightens in dark mode, because most of its uses
/// are ink and icons on a dark surface. A filled button is the opposite case:
/// the label is always white, so a light-blue or light-copper fill lands near
/// 2.3:1 and is unreadable. Rather than ask each of the six call sites to
/// remember a separate "fill" token, the button darkens its own fill in dark
/// mode, which keeps white legible on whichever accent it was handed.
struct PrimaryCTAStyle: ViewModifier {
    let color: Color
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return content
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                shape
                    .fill(color)
                    .overlay(shape.fill(Color.black.opacity(scheme == .dark ? 0.45 : 0)))
            }
            // 0.45 is measured, not chosen by eye: it takes the lightest
            // accent in the palette to roughly 5:1 against white. The dark
            // shadow is also pulled back, because a full-strength glow around
            // a darkened fill reads as a halo rather than a lift.
            .shadow(color: color.opacity(scheme == .dark ? 0.18 : 0.35), radius: 8, y: 4)
    }
}

/// Press-scale feedback for card-shaped buttons.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(Theme.Motion.card, value: configuration.isPressed)
    }
}

// MARK: - Haptics

/// Main-actor isolated on purpose: `UIFeedbackGenerator` and its subclasses are
/// main-actor types, and every caller here is a SwiftUI view already on the main
/// actor. Leaving these nonisolated is what produced the Swift 6 actor-isolation
/// warnings, and the warnings were right.
@MainActor
enum Haptics {
    enum Impact { case soft, light, rigid, heavy }

    /// Settings gate: reads the same key AppSettings writes, defaulting on.
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "settings.haptics") as? Bool ?? true
    }

    static func impact(_ style: Impact, intensity: CGFloat = 1.0) {
        #if canImport(UIKit)
        guard enabled else { return }
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .soft: uiStyle = .soft
        case .light: uiStyle = .light
        case .rigid: uiStyle = .rigid
        case .heavy: uiStyle = .heavy
        }
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred(intensity: intensity)
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Grading haptics have to feel like OPPOSITES in the hand, not like two
    /// versions of the same buzz. Apple's `.success` and `.error` notification
    /// patterns are both stutters and are easy to confuse mid-drill, so:
    /// right = a crisp light tap rising into the success chime; wrong = a
    /// single dull heavy thud, no chime, nothing bright about it.
    static func correctAnswer() {
        #if canImport(UIKit)
        guard enabled else { return }
        impact(.light, intensity: 0.75)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000)
            success()
        }
        #endif
    }

    static func wrongAnswer() {
        #if canImport(UIKit)
        guard enabled else { return }
        impact(.heavy, intensity: 0.85)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 110_000_000)
            impact(.heavy, intensity: 0.45)
        }
        #endif
    }
}
