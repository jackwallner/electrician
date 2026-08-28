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

**The generator is the moat.** `CalcGenerator` emits five problem shapes as
pure functions with exactly one correct answer, so the paid tier never runs
out. Unlike mahj's `RackGenerator` there is no ambiguity-rejection loop, because
a code calculation cannot be ambiguous. **Every distractor is the number you get
from one specific common mistake** (started the derate at 75°C, ignored
240.4(D), used 53% fill, counted grounds individually). Keep it that way: random
wrong numbers teach nothing.

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

**Values follow the 2023 cycle** while the 2026 adoptions roll out. The edition
is a user-visible fact, not a comment: `NECTables.edition` is rendered on every
citation line, in Field Tools, in Settings, on the Home footer, on the website
and in the store description. A candidate cannot tell a 2023-cycle answer from
a 2026-cycle one by looking at it, and the app name carries a year. When the
tables move, update `NECTables` (including `edition`) and let the tests catch
the authored content that drifted.

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

Surfaces are cool drawing paper over slate, `Theme.display` is heavy condensed
sans (panel-schedule lettering, not a members' club serif), `Theme.numeric` is
monospaced so amps and AWG read as instrument values, and `BlueprintGrid` /
`blueprintGrid()` rules the worksheet surfaces.

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

Setup answers have to keep paying off after onboarding or the seven questions
are a toll booth: the exam date drives Home's countdown card and
`suggestedDailyQuestions`, and `focusAreas` orders the rooms on Home (an
ordering, never a filter).

## Structure
- `Shared/Models` — `Given` (a labelled condition chip, the equivalent of a
  dealt tile), `CodeArticle`, `NECTables` (all reference data), `Drill`
- `Shared/Content` — `CalcGenerator` (the asset), authored content per room,
  `DrillLibrary` (rooms), `CodeMinuteContent` (seeded daily five)
- `Electrician/Views/Drills` — `CalcDrillView` is the one genuinely new screen:
  numbered working after the answer, because a miss is almost always one skipped
  step rather than bad arithmetic

Room ids (`basics-room`, `conductors-room`, `calc-room`, `grounding-room`) are
referenced by `PracticeSkill.roomID` and `Theme`'s accent map. Renaming one
means updating both; a test enforces that they resolve.

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
