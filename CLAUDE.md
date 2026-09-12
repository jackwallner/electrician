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

## Rules that hold everywhere
Condensed from the deep notes below; the reasoning and the bugs behind each one live there.
- Every distractor is the number one specific, named common mistake produces, with a `MistakePattern` attached. No new shape ships without one. `MistakePattern.id` is persisted, so renaming one resets that tally. Four choices is a hard invariant.
- Generator extension files use `uniqueChoices` and `mistakeMap` from the base `CalcGenerator` file. If you narrow a parameter range, check the mistake catalogue still fires.
- Never raise `verifiedThrough` without checking the tables page by page against that edition's book. Lowering it is always safe.
- `Room.accents` has no `default` case. Every animation comes from `Theme.Motion`, titles use the five semantic type tokens, and anything painting a solid accent behind white text uses `Theme.voltageFill` / `Theme.copperFill`.
- Onboarding is a step machine: do not reintroduce a pager. Persisted raw values (`LicenseTrack`, `CandidateEdition`, `electrician.skillLevel`) must not be renamed.
- IAP setup is three scripts in order: `asc-setup-release.py`, `asc-equalize-sub-prices.py`, `asc-finish-products.py --screenshot`. Re-run `scripts/rc-setup.py` after touching products or offerings, then probe offerings with `X-Platform: ios`.
- Every localized description carries a functional Terms of Use (EULA) link and a privacy link, in all 50 locales.

## Deep notes (load on demand)
These files load automatically when you read a file matching their `paths:`. Agents that do not auto-load rules (AGENTS.md readers) should open the file for the area they are touching. Record new area-specific learnings in the matching file, not here.

| File | Covers | Read when |
|---|---|---|
| `.claude/rules/generator.md` | The generator is the moat: shapes, distractors, named mistakes, parameter ranges | `CalcGenerator*`, `EndlessPractice`, content validity tests |
| `.claude/rules/nec-edition.md` | Values follow the 2023 cycle; the three edition constants | `NECTables`, `EditionView`, anything that prints an edition |
| `.claude/rules/design-system.md` | Palette, accents, type roles, motion, dark-mode fills | `Theme` and any view |
| `.claude/rules/onboarding-and-pitch.md` | The step machine, jurisdictions, persisted keys, study pace, the `Electrician+` pitch | Onboarding, candidate profile, Home's pace card, the paywall pitch |
| `.claude/rules/release-and-iap.md` | IAP setup scripts, the RevenueCat probe | ASC product scripts, RevenueCat, StoreKit config |
| `.claude/rules/listing-and-localization.md` | Store name, marketing site, 50 locales, the EULA link, ASO | Metadata, localizations, `docs/` |

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
  `com.jackwallner.electrician`. `AppStoreLinks.appStoreID` is set. 1.0 has
  build 11 attached and is in `WAITING_FOR_REVIEW` (resubmitted 2026-08-31
  after a 3.1.2 rejection for a missing Terms of Use link).
  **`AppStoreLinks.isListingLive` is `false` and must be flipped the day the
  listing goes Ready for Sale.** Having an Apple ID is not having a listing:
  while it is false there is no share URL, no Rate button and no review funnel,
  because every `apps.apple.com/app/id...` URL built from a draft record 404s.
- **The price ladder is 9.99 monthly / 39.99 yearly / 89.99 lifetime**, matching
  `Electrician.storekit` and the `SubscriptionService` fallback. Change one and
  change all three or the paywall quotes a price the store will not charge. The
  ASO research argues this vertical sustains more (incumbents run $17.99 mo /
  $99.99 lifetime); going up is a deliberate decision, not a drift.
- **RevenueCat** project `projfc676ce9`, App Store app `app03a1f0929d`. The
  public `appl_` key ships in `SubscriptionService`; the `sk_` secret lives in
  `~/.electrician_credentials` and never enters source. DEBUG stays a
  placeholder until there is a test-store key, so debug builds run without
  RevenueCat rather than touching production.
- **The entitlement is `electrician_pro`.** `lookup_key` is immutable in both
  RevenueCat APIs, so the app matches the project. Change one and you get a
  purchase that charges and unlocks nothing.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, gotchas): always-loaded global CLAUDE.md + the `ios-dev` skill.
