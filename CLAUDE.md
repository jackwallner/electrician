# Electrician — Project Guide

NEC licensing-exam practice app for journeyman and master electrician
candidates. Drills code navigation, ampacity derating, overcurrent sizing,
raceway fill, box fill and voltage drop. XcodeGen project/scheme: `Electrician`,
sim lease owner `electrician`. Bundle ID `com.jackwallner.electrician`.

Ported from `~/mahj` (the shell: rooms, drills, generated practice, progress,
paywall, review funnel, release scripts). The mahjong domain is gone; only the
shell is shared.

## Why this app exists

`~/ios/aso/practice-app-fingerprint-2026-08-23.md` is the research. Short
version: Mahj Trainer earns because American Mah Jongg has no substitute
product, a standard that changes on a schedule, and in-person play. The NEC has
all three, plus a better generator, plus an open SERP (top incumbent 439
ratings). Read that file before changing positioning.

## Tech Stack
- Swift 6 / SwiftUI (strict concurrency)
- XcodeGen (`project.yml`). Targets: iOS 17+, `ElectricianTests`,
  `ElectricianScreenshots`
- RevenueCat, entitlement **`electrician_pro`** (not the fleet's `pro`), membership brand `Electrician+`

## Product rules

**Legal position, and it is load-bearing.** NFPA holds copyright in the text of
the National Electrical Code and enforces it. This app reproduces none of it.
What it ships is the underlying numbers (facts), article numbers (citations),
and explanations written from scratch. Cite `310.16`; never quote it. Same
discipline the fleet already applies to the NMJL card and the DSkV
Skatordnung, for the same reason.

**Accuracy is a product requirement, not a nicety.** A wrong ampacity is a
refund and a one-star review from a professional who trusted it in an exam.
`ContentValidityTests` therefore recomputes every authored calculation against
`NECTables` and fuzzes the generator (thousands of problems per run) for:
answer in range, no duplicate choices, derated ampacity never above the
termination limit, OCPD never above the 240.4(D) cap, conduit fill actually
fits and the next size down does not. Do not weaken those tests to make a
content change pass.

**The generator is the moat.** `CalcGenerator` emits ten problem shapes as
pure functions with exactly one correct answer, so the paid tier never runs
out. Unlike mahj's `RackGenerator` there is no ambiguity-rejection loop, because
a code calculation cannot be ambiguous. **Every distractor is the number you get
from one specific common mistake** (started the derate at 75°C, ignored
240.4(D), used 53% fill, counted grounds individually, sized a motor off the
nameplate, read Table 250.66 where 250.122 was wanted). Keep it that way: random
wrong numbers teach nothing.

The shapes are split across four files for readability and are one generator:
`CalcGenerator` (ampacity, OCPD, conduit fill, box fill, voltage drop),
`CalcGeneratorGrounding` (EGC and GEC sizing), `CalcGeneratorMotors` (motor
conductors, motor protection) and `CalcGeneratorLoads` (the dwelling service
calculation). The extension files must use `uniqueChoices` and `mistakeMap`
from the base file rather than rolling their own; the filtered
`mistakeMap(answerLabel:choices:_:)` overload exists because a shape with more
named mistakes than choice slots would otherwise map labels nobody can tap.
**Where a shape has more named mistakes than distractor slots, shuffle the
distractors from the problem's own stream.** A fixed order starves the last
ones, and a trap the generator never sets is one Fix My Mistakes can never
re-set: `testTargetedPracticeSetsTheRequestedTrap` fails the build for it.

Both generator suites iterate `PracticeSkill.allCases` through
`EndlessPractice.scenario`, not a hand-written list of makers, so adding a case
opts the new shape into every invariant automatically.

Those mistakes are **named**, not just implied: `CandidateMistake` holds the
catalogue and each generator attaches a `MistakePattern` to the distractor it
produces. Three things depend on it, so do not let a new shape ship without
one: a miss tells the reader what they actually did, `PracticeRecordStore`
tallies which errors they repeat, and Fix My Mistakes generates a NEW problem
that sets the same trap (a generated question is a one-off and can never come
back as itself). `MistakePattern.id` is persisted, so renaming one resets that
tally. Four choices is a hard invariant, enforced by test.

Generator parameter ranges are load-bearing, not decoration. The ampacity
shape draws ambient from 30°C up and current-carrying from 3 up **so the 75°C
termination cap sometimes binds**; with the old 35°C/4-conductor floors the
derated figure was always below the cap, so the app's own headline rule never
appeared as a wrong answer. If you narrow a range, check the mistake catalogue
still fires.

**Values follow the 2023 cycle**, and the app now says WHY rather than just
which. The edition is a user-visible fact, not a comment: `NECTables.edition`
is rendered on every citation line, in Field Tools, in Settings, on the Home
footer, on the website and in the store description, and `EditionView` is the
screen that answers "why does an app called 2026 quote 2023?".

Three constants carry that answer and they are not interchangeable.
`NECTables.edition` is the citation basis. `stableSince` is the oldest cycle
whose values match. **`verifiedThrough` is a claim about work someone actually
did**, and every "covers your edition" string is derived from it, so raising it
without checking the tables page by page against that edition's book turns the
study aid into a trap. Lowering it is always safe.
`testCoverageClaimIsSupportable` enforces that it is never older than
`NECEdition.app`. **To claim the 2026 cycle: check the tables against a 2026
book, then set `verifiedThrough = .nec2026`.** Nothing else changes; the
coverage label, the Home footer, Field Tools and `EditionView` all recompute.

What genuinely moves between cycles is coverage, not the tables, and
`EditionView` lists both sides of that. When a table does move, update
`NECTables` (including `edition`) and let the content tests catch the authored
content that drifted.

## Design system

The palette is **not** the cream-and-jade one this shell arrived with. Cream
paper and jade green are mahjong signals (tile faces, table felt). `Theme` now
reads as an electrician's vocabulary and the names are semantic, so a room
accent means something:

| Token | Colour | Used for |
|---|---|---|
| `voltage` | line-voltage blue | primary actions, `basics-room` |
| `copper` | copper | streaks and celebration, `conductors-room` |
| `brass` | brass | locks, best value, `Electrician+` |
| `conduit` | galvanized steel blue | `calc-room` |
| `ground` | equipment-grounding green | `grounding-room`, and nothing else |
| `highLeg` | delta high-leg orange | `install-room` |
| `service` | meter-can indigo | `loads-room` |

`Room.accents` is an explicit map with **no `default` case**. A room that
forgets to claim a colour used to inherit grounding green, which turned the one
semantic colour in the palette into a fallback; `testEveryRoomClaimsAnAccent`
now fails the build instead.

Surfaces are cool drawing paper over slate, `Theme.display` is heavy condensed
sans (panel-schedule lettering, not a members' club serif), `Theme.numeric` is
monospaced so amps and AWG read as instrument values, and `BlueprintGrid` /
`blueprintGrid()` rules the worksheet surfaces.

**Type is split by role, never by size** (`Theme`'s type section). Condensed
heavy is every TITLE at any size, system text is every sentence, monospace is
every number read as an instrument value. A card title and a screen title are
the same face; a card title and its subtitle are two faces. Titles come from
the five semantic tokens (`displayLarge`, `screenTitle`, `sectionTitle`,
`questionTitle`, `cardTitle`), which are built from `Font.TextStyle` so they
scale with Dynamic Type; the `CGFloat` overload of `Theme.display` is only for
the few places where the size IS the design. A title reaching for `.headline`
or `.title3` is what made the app look like it had picked up a new font.

**Motion has one vocabulary** (`Theme.Motion`) and every animation in the app
comes from it: `screen`, `card`, `reveal`, `meter`, `celebrate`, `flip`,
`fling`, `flash`, plus the `advance`/`retreat`/`riseIn` transitions. This is not
tidiness. A screen whose header, content and footer each animate on their own
curve does not read as one screen moving, it reads as three things arriving at
slightly different times, which is what the "sliding into place" wobble was.
Every token checks `Motion.reduced` in one place; `flourish` and `shake` return
`nil` under Reduce Motion so the caller SKIPS the effect rather than performing
a faster version of it, and `ConfettiBurst` is suppressed by it too.

**Every accent lightens in dark mode**, because most uses are ink and icons on
a dark surface. A filled button is the opposite case: the label is always
white, so a light accent lands near 2.3:1. `PrimaryCTAStyle` darkens its own
fill by 0.45 in dark mode, which is measured to hold the lightest accent above
5:1. Anything else that paints a solid accent behind white text must use
`Theme.voltageFill` / `Theme.copperFill`, not the base token. Adding a new
accent means adding its dark-mode check too.

## Onboarding

Twelve steps: three value pages, seven setup questions, a plan recap, then the
trial. It is a **step machine, not a paged `TabView`**, and that is not a style
choice. A page view cannot refuse a swipe, so the old version let a candidate
swipe past a disabled Continue into the paywall with no jurisdiction set; a
`ScrollView` with a `TextField` inside a horizontal pager fought both the swipe
and the keyboard; and the footer reserved purchase chrome on every page. Driving
one `step` with `canAdvance` gating it fixes all three. Do not reintroduce a
pager here.

`Jurisdictions` (all 50 states, DC, PR, plus a "Not listed" sentinel) is what
makes **"I'm not sure" a usable answer**: it carries the commonly adopted NEC
edition, the licensing authority, the licence route (state vs. contractor-only
vs. local) and the exam vendor, and `CandidateProfile.resolvedEdition` falls
back to the state's edition while the answer is `.unsure`. Adoption and vendors
move, so every surface labels the value "commonly adopted", stamps
`Jurisdictions.reviewed`, and names the authority to confirm with. Re-check the
table against the NFPA adoption map when that date goes stale; it is a
suggestion the candidate ratifies, never an assertion.

**Persisted keys that must not be renamed.** `LicenseTrack.journeyman`/`.master`
and `CandidateEdition.nec2023`/`.different` keep their original raw values
because they are already written to `candidate.licenseTrack` and
`candidate.edition`; the added cases are new spellings only. The three original
`electrician.skillLevel` values (`new`, `apprentice`, `working`) are switched on
by Home's primer card and `HowToPlayContent.recommendedRoom`. `CandidateProfile`
resolves an ABSENT `candidate.edition` to this app's own edition, not to
`.unsure`, because installs that answered the old two-option picker chose from a
list whose default was that; onboarding overrides it to `.unsure` for a fresh
install only.

**The exam date sets a PACE, not just a countdown.** `StudyPace` (cram, sprint,
build, foundation, undated) is derived from `daysUntilExam`, never stored, and
it is what makes the app useful to a candidate sitting the exam tomorrow. The
date presets start at "Tomorrow" for that reason: the shortest option used to be
two weeks out, so the most motivated reader the app will ever get either lied to
the setup or skipped it. `suggestedDailyQuestions` branches on the pace rather
than dividing a fixed total by the days left, which used to tell someone with
one day to do 600 and someone with a year to do ten. `StudyPaceCard` renders the
plan in onboarding, in the recap, and on Home while `pace.isUrgent`.

Setup answers have to keep paying off after onboarding or the seven questions
are a toll booth: the exam date drives Home's countdown card, the pace and
`suggestedDailyQuestions`; the licence track titles Home's header; and
`focusAreas` orders the rooms on Home (an ordering, never a filter).

**The `Electrician+` pitch is an argument, not a feature list.** Both purchase
surfaces compute it from `DrillLibrary.freeItemCount` and the reader's own daily
target: the free rooms hold N questions, at M a day that is D days, and the exam
is further away than that. Those counters are computed from the library so the
claim cannot rot, and `testContentCountsAreQuotable` stops a zero reaching the
paywall. The benefit ORDER also follows the pace: "targets the errors you
repeat" is a nice-to-have in March and the entire product on Thursday night.

## Structure
- `Shared/Models` — `Given` (a labelled condition chip, the equivalent of a
  dealt tile), `CodeArticle`, `Drill`, and the reference data split by subject:
  `NECTables` (conductors, ampacity, correction and adjustment, OCPD, fill),
  `NECGroundingTables` (250.66, 250.122, bonding), `NECMotorTables`
  (430.248/430.250 and the 430.52 percentages), `NECLoadTables` (Article 220),
  `NECInstallTables` (314.16(A), 110.26, 300.5, support spacing, 110.14(C))
- `Shared/Content` — `CalcGenerator` (the asset), authored content per room,
  `DrillLibrary` (rooms), `CodeMinuteContent` (seeded daily five)
- `Electrician/Views/Drills` — `CalcDrillView` is the one genuinely new screen:
  numbered working after the answer, because a miss is almost always one skipped
  step rather than bad arithmetic

Room ids (`basics-room`, `conductors-room`, `install-room`, `calc-room`,
`loads-room`, `grounding-room`) are referenced by `PracticeSkill.roomID`,
`Room.accents` and `CodeMinuteContent.category(forRoom:)`. Renaming one means
updating all three; tests enforce that they resolve and that each claims an
accent.

Three rooms are free (`basics`, `conductors`, `install`) and three are paid
(`calc`, `loads`, `grounding`). **Installation Rules is free deliberately**: it
is the widest door in the app, because working space, burial depth, support
spacing and receptacle placement are things an apprentice, a homeowner and a
licensed electrician all have a reason to look up, and every one of them lands
one tap from the paid calculations.

**Some strings look stale and are load-bearing.** The exam-warm-up feature was
renamed out of its inherited `gameNight` spelling, but four UserDefaults keys
(`settings.gameNight*`), one notification identifier
(`electrician.gameNightReminder`), the route value `game-night-prep` and the
drill id of the same name were deliberately left alone. They are already
written on device: changing a key does not migrate a setting, it silently
forgets it, and changing the route value orphans every pending notification.
The Swift symbols are the part that was safe to rename.

## App-specific notes
- **ASC record exists, not live.** Apple ID `6804828725`, bundle
  `com.jackwallner.electrician`, draft 1.0 in `PREPARE_FOR_SUBMISSION`.
  `AppStoreLinks.appStoreID` is set. Builds are going to TestFlight; the
  draft still has no build attached and has not been submitted.
  **`AppStoreLinks.isListingLive` is `false` and must be flipped the day the
  listing goes Ready for Sale.** Having an Apple ID is not having a listing:
  while it is false there is no share URL, no Rate button and no review funnel,
  because every `apps.apple.com/app/id...` URL built from a draft record 404s.
- **Store name is `Electrician Exam Practice 2026`.** The obvious
  `Electrician Exam Prep 2026` belongs to the incumbent the research file
  names as the SERP leader, and ASC rejects it with
  `DUPLICATE.DIFFERENT_ACCOUNT`. Keep the year suffix in whatever replaces
  it; that is the category's ranking lever. Name, subtitle and keywords are
  indexed as one bag, so a word in the name does not belong in the other two.
- **The price ladder is 9.99 monthly / 39.99 yearly / 89.99 lifetime**, matching
  `Electrician.storekit` and the `SubscriptionService` fallback. Change one and
  change all three or the paywall quotes a price the store will not charge. The
  ASO research argues this vertical sustains more (incumbents run $17.99 mo /
  $99.99 lifetime); going up is a deliberate decision, not a drift.
- **IAP setup is three scripts in order**, and skipping one leaves every product
  at `MISSING_METADATA`, where StoreKit never serves it and the paywall is dead
  on device: `asc-setup-release.py` (products, USA price, trials, categories),
  `asc-equalize-sub-prices.py` (the other 174 territories, because subscription
  prices do NOT equalize from the USA row the way a non-consumable schedule
  does), then `asc-finish-products.py --screenshot` (App Review screenshot).
  Subscriptions in one group also need distinct `groupLevel`s. Capture the
  screenshot with `scripts/capture-paywall.sh <udid> <dir>`.
- **RevenueCat** project `projfc676ce9`, App Store app `app03a1f0929d`. The
  public `appl_` key ships in `SubscriptionService`; the `sk_` secret lives in
  `~/.electrician_credentials` and never enters source. DEBUG stays a
  placeholder until there is a test-store key, so debug builds run without
  RevenueCat rather than touching production.
- **The entitlement is `electrician_pro`.** `lookup_key` is immutable in both
  RevenueCat APIs, so the app matches the project. Change one and you get a
  purchase that charges and unlocks nothing.
- **Re-run `scripts/rc-setup.py` after touching products or offerings**, then
  probe with the iOS platform header. The project shipped with the fleet's
  recurring empty-offering bug (Test Store products only, so iOS filtered every
  package out and the paywall was dead on device). Fixed 2026-08-24. A
  simulator can never catch this because it never configures RevenueCat (the
  Debug paywall reads `Electrician.storekit` instead, which is excluded from
  Release so the price catalog never ships in the binary):

  ```sh
  curl -s -H "Authorization: Bearer appl_JNXhRRCBfqpJqOpxFnylwNcqvby" \
       -H "X-Platform: ios" \
       https://api.revenuecat.com/v1/subscribers/probe-1/offerings
  ```
- Marketing site: `docs/` is served by Pages from `main` at
  `https://jackwallner.github.io/electrician/` (index, `privacy-policy`,
  `support`), and mirrored to `jackwallner.com/ios/electrician/` by
  `.github/workflows/sync-landing-page.yml`. That workflow needs the
  `PORTFOLIO_DEPLOY_KEY` secret on this repo before it can push the mirror.
- US-only. The 50-locale metadata machine does not apply here.
- ASO: the category's ranking lever is the year in the app name
  (`Electrician Test Prep 2026` and friends all do it). Decide the store name
  from the research file, not from the fleet's `X Trainer` habit.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, gotchas): always-loaded global CLAUDE.md + the `ios-dev` skill.
