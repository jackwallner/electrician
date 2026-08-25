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

**Values follow the 2023 cycle** while the 2026 adoptions roll out. When the
tables move, update `NECTables` and let the tests catch the authored content
that drifted.

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

## App-specific notes
- **ASC record exists, not live.** Apple ID `6804828725`, bundle
  `com.jackwallner.electrician`, draft 1.0 in `PREPARE_FOR_SUBMISSION`.
  `AppStoreLinks.appStoreID` is set. The listing name is still
  "Electrician Placeholder". No TestFlight build and no IAPs/subs on the
  record yet.
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
  simulator can never catch this because it never configures RevenueCat:

  ```sh
  curl -s -H "Authorization: Bearer appl_JNXhRRCBfqpJqOpxFnylwNcqvby" \
       -H "X-Platform: ios" \
       https://api.revenuecat.com/v1/subscribers/probe-1/offerings
  ```
- **No GitHub remote yet.** `~/electrician` is local-only, so
  `.github/workflows/sync-landing-page.yml` never fires, `docs/` is not served,
  and `https://jackwallner.github.io/electrician/support` (the support URL
  `scripts/asc-finish-submission.py` sets) 404s. Creating the public repo and
  enabling Pages is a prerequisite for submission, not a nicety.
- US-only. The 50-locale metadata machine does not apply here.
- ASO: the category's ranking lever is the year in the app name
  (`Electrician Test Prep 2026` and friends all do it). Decide the store name
  from the research file, not from the fleet's `X Trainer` habit.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, gotchas): always-loaded global CLAUDE.md + the `ios-dev` skill.
