---
paths:
  - "android/**"
  - "scripts/sync-android-content.py"
  - "scripts/android-export/**"
---

# Electrician Android

Package and namespace: `com.jackwallner.electrician`. Launcher label
`Electrician Exam Prep`, Play listing name `Electrician Exam Prep: NEC`
(`android/play-assets/listing-en-US.md`). Membership brand Electrician+,
entitlement `electrician_pro` (`ENTITLEMENT` in `SubscriptionService.kt`).
Product IDs: `com.jackwallner.electrician.monthly`,
`com.jackwallner.electrician.yearly`, `com.jackwallner.electrician.lifetime`.
Reuse RevenueCat project `projfc676ce9` and its `default` offering
(`$rc_monthly`, `$rc_annual`, `$rc_lifetime`).

## Content and generators

The Swift app is the spec. Run `python3 scripts/sync-android-content.py`
after source content/table/generator changes; `--check` validates existing
exports. Authored content and numeric tables live in the main resource export;
generator/calculation references live in test resources. Do not replace native
endless generators with the finite reference cases.

`content/CalcGenerator.kt` is a line-for-line port of all four Swift generator
files: same parameter lists, same draw order, same distractors and named
mistakes. `GeneratorParityTest` replays the 640 Swift problems (ten shapes,
eight seeds, eight in a row) and the Code Minute dailies byte for byte, so any
drift in a Swift shape fails the Android build after a re-export. When a Swift
shape changes, port the change and re-export; never edit the expected JSON.
`GeneratorValidityTest` ports the iOS invariants (four distinct choices, cap
never exceeded, fill fits and the next size down does not, every catalogue
mistake is set and Fix My Mistakes re-sets it, authored calculations recompute).

There are two different random streams. `SeededGenerator` takes a UInt64 seed
and uses xorshift12/25/27; `StableSeededGenerator` hashes a string with FNV-1a
and uses xorshift13/7/17. Swift integer/Boolean/closed-Double draws and shuffles
are reproduced by `SeededRandom.kt`. Numeric labels use C-compatible decimal
rounding, independently from Swift's away-from-zero integral rounding.

## Shell

Ported from the mahj Android shell (theme renamed to `Elec*`, palette from
iOS `Theme.swift`). `CandidateProfile` keeps the iOS `candidate.*` keys and
derives the pace from the exam date. Onboarding is the twelve-step machine
(no pager). Named mistakes persist in `practice.mistakePatterns`; a right
answer on a problem that set an outstanding trap works it off by one.
`PrimaryCTA` darkens its fill by 0.45 in dark mode and white-on-accent
surfaces use `voltageFill` / `copperFill`.

Three rooms are free (basics, conductors, installation), with some paid extra
drills. Endless practice, Code Minute, timed challenge, Exam Warm-Up and Fix My
Mistakes are paid. All eight Field Tools are free. Keep the 2023 table basis
and verified-through claim. No new 2026 coverage claim without the book
verification required by `nec-edition.md`.

## Build and test (jmbp)

```sh
cd android
export JAVA_HOME=~/jdks/temurin-17/Contents/Home ANDROID_HOME=~/Library/Android/sdk
./gradlew testDebugUnitTest assembleDebug lintDebug assembleQa
ANDROID_SERIAL=emulator-5584 ./gradlew connectedDebugAndroidTest
```

Debug uses the RevenueCat Test Store app `appd3c90178cf` (its public `test_`
key in ignored `local.properties` as `REVENUECAT_TEST_KEY`); the `qa` build has
no key and ignores debug hooks. On jmbp boot `agent-emu-1` headless on port
5584 (`emulator -avd agent-emu-1 -port 5584 -no-window -no-audio -no-boot-anim
-no-metrics -no-snapshot-save`) after checking `adb devices` and running
emulator processes; stop it with `adb -s emulator-5584 emu kill`. jmbp is a
2-core 2015 i7: a cold boot takes minutes and the image's Bluetooth stack
crash-loops until `adb shell cmd bluetooth_manager disable`.

Play store graphics live in `android/play-assets/` (its README records how
they were made). On `agent-emu-1`, `wm size 1080x1920` gives black captures
from the software GPU while `1080x2160` (2:1, Play's limit) renders; changing
`font_scale` resets SystemUI demo mode, so re-enter it before each capture.

## Play reviewer unlock

Long-press Settings > Version opens a masked Password-keyboard dialog (autocorrect
off). The code's SHA-256 is compared with `PLAY_REVIEW_CODE_SHA256` (ignored
`local.properties` into `BuildConfig`; never the plaintext). A match stores the
digest as `reviewAccessDigest` and unlocks `electrician_pro` for that install
only (`ReviewAccess`, applied in `SubscriptionService.apply` so a customer-info
refresh keeps it). No purchase is written, and changing the digest revokes
every earlier grant. `validateReleaseConfiguration` fails without a valid
digest; generate it with `printf '%s' CODE | shasum -a 256`. Tests:
`ReviewAccessTest` (JVM) and `ReviewerUnlockTest` (device, pass a throwaway code
as `-Pandroid.testInstrumentationRunnerArguments.reviewCode=...` with its digest
in `local.properties`; never a real code).

## Release preparation and Play state

No Play app exists yet (verified 2026-10-20 against the fleet rollout table).
Remaining, in order, all outside agent build scope:

1. Air release worker: signed AAB vc2 / 1.0.3, 16 KB alignment check. The
   upload keystore exists (2026-10-20): `~/.android/keystores/electrician-upload.p12`
   (PKCS12, RSA 4096, alias `upload`, backup in `~/.android/keystores/backups/`),
   password `ELECTRICIAN_PLAY_UPLOAD_PASSWORD` in `~/.electrician_credentials`.
   `android/local.properties` on the Air has the Test Store key and `PLAY_UPLOAD_*`
   entries. Still missing: `REVENUECAT_PLAY_KEY`. `projfc676ce9` has only the
   App Store app `app03a1f0929d` and Test Store `appd3c90178cf`, so the Play app
   (step 4) must exist in RevenueCat before the release build can pass
   `validateReleaseConfiguration`.
2. Play Console: create the app (package above), internal track upload.
3. Play prices (Jack left it to the agent, 2026-10-20): about 20% under the iOS
   ladder of 9.99 / 39.99 / 89.99, so Monthly 7.99, Yearly 31.99, Lifetime 71.99
   (USD base, Play converts the rest). Create the subscriptions (base plans
   `monthly`, `yearly`, trial offer 7 days) and the lifetime product at those
   prices. The RevenueCat Test Store products (9.99 / 79.99 / 99.99) are debug
   only and stay as they are.
4. RevenueCat: add the Play app to `projfc676ce9` (service account needs Jack's
   approval), attach Play products to `electrician_pro` and the existing
   `default` packages without touching iOS products; register in rc-clean.
5. Listing from `android/play-assets/`, privacy `docs/android-privacy.html`,
   terms `docs/terms.html` (both go live when `docs/` publishes), Data safety:
   purchase history and app-generated ID to RevenueCat, nothing else; no ads,
   Education category, IARC questionnaire.
6. Production review only in its pacing slot.

Port status and evidence: [Android project notes](../../project-docs/android/README.md).

## Play staging, 2026-10-21

Play app 4976071235428841185 (Draft). vc1 1.0.3 drafts on internal and
production; products active. RevenueCat Play app `app6a7ee048e7` in
`projfc676ce9`, products attached to the entitlement and the three packages
(lifetime non-consumable). App content saved except sign-in details and target
audience, which wait for the reviewer unlock; data safety is a saved draft
until the audience is in. Left: reviewer unlock, vc2 rebuild with the code's
SHA, listing and graphics, Send for review in its pacing slot.
