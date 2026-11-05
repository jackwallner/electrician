---
paths:
  - "Shared/**"
  - "Electrician/**"
  - "ElectricianTests/LocalizationTests.swift"
  - "Tools/Localization/**"
---

# Electrician: localization (added 2026-11-04)

The app is routed for translation and ships English only. No other language is
in the catalog and `CFBundleLocalizations` is untouched; separate runs add
languages.

## Setup
- One catalog, `Shared/Localizable.xcstrings` (source `en`, every key
  `extractionState: manual`, an explicit `en` value on each key). `Shared/` is a
  source of the app target, and the unit tests are hosted in the app, so they
  read the same compiled catalog. `ElectricianScreenshots` and
  `ElectricianUITests` compile no app code and need none.
- No `InfoPlist.xcstrings`: there are no permission purpose strings, and the
  display name `Electrician` is the brand.
- `python3 Tools/Localization/check.py` (repo root, no Xcode) fails on a source
  literal with no key, a key missing a language in `LANGS` (empty for now),
  mismatched format specifiers, a `return "..."` or ternary literal that reaches
  the screen, and a bare literal given to a content label (`frontTitle:`,
  `prompt:`, `explanation:`, `summary:` ...). Mark a literal that is not copy with
  `// l10n:ignore`. Run it before every build that touches copy.
- `LocalizationTests` proves the catalog compiles and pins the English plural
  forms. When a language is added, put its `.lproj` check and one plural test
  beside them and extend `LANGS` in `check.py`.

## Adding or changing copy
- `Text("literal")`, `Button`, `Label`, `Section`, `navigationTitle`, `alert`,
  `LabeledContent`, `Picker` localize themselves. Copy held in a `String`
  (content structs, enums, view parameters, errors, notifications) is
  `String(localized: "...")`. Whole sentences only, never spliced fragments:
  branch and give each variant its own key.
- Authored content in `Shared/Content`, every `displayName`, `summary`,
  `howToSpot`, step line and generated-problem sentence is keyed. The key is the
  English sentence, so a key edit is an English copy edit.
- Counts: a number inside a sentence is `\(n)` in the key, with `en` plural
  variations in the catalog where the noun changes (`%lld days`, `%lld drills
  finished`). A sentence with other arguments uses a `%#@name@` substitution
  (see `%lld due mistakes first, then extra work in %@.`). A count label drawn
  beside a separately rendered number (the "day" under the exam countdown, the
  unit on a given chip) cannot be a plural key: `PluralLabel` asks the
  `"%lld plural category"` key for the CLDR category and picks one whole key per
  category. The `(few)` and `(many)` keys carry English wording until a language
  needs them.
- Mid-sentence names use `inlineName` (`ConductorMaterial`, grounding electrode,
  motor protection device) with their own keys. Never `.lowercased()` or
  `.capitalized` translated text; uppercase through `.textCase(.uppercase)`.
- Persisted values stay English and are translated at display time, never
  migrated: `Jurisdiction.name` is the stored and matched key (screens show
  `displayName`, and `CandidateProfile.displayJurisdiction` for the saved
  value), `MistakeTally` summaries are re-read from `CandidateMistake` by id,
  and a saved Code Minute date is formatted from its `dayKey`
  (`CodeMinuteResult.displayDate`). Weekday names come from `Calendar`.
- Grading, mistake lookup and de-duplication compare indexes and the formatted
  choice label, never a translated sentence. Choice labels (`"60 A"`) are built
  with hand formatting on purpose (see `Int.groupedText`) because they are
  compared against each other and against the `mistakes` map.
- Prices come only from StoreKit. Support email lines (`ContentReport`,
  `FeedbackSheet`) and diagnostics stay English by design.

## What stays English on purpose
- NEC article numbers, table references and units (A, V, VA, kW, AWG, kcmil,
  in², ft). A citation key such as `Art. 100` or `Table 250.122` has an English
  word around exact numbers; translators keep the numbers and subsection letters
  identical.
- Brand and vendor names: Electrician+, NFPA, NEC, PSI, Pearson VUE.
- Uppercase eyebrow keys (`THE CALL`, `YOUR TURN`) are translated in capitals.
- Ids, `UserDefaults` keys, notification identifiers, route values, analytics
  attributes and RevenueCat ids.

## Proving a change
`gh-sim test --scheme Electrician` for the unit suite (ContentValidityTests must
still pass), then `python3 scripts/sync-android-content.py --check` if content
changed: the Android export compiles the same Shared sources without a catalog,
so `String(localized:)` returns the English key there.
