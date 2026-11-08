# Pre-submit review, 2026-11-07

Last check before 1.0.6 (build 30) goes to App Review.

## Scope

- Live App Store version: **1.0.4** (iTunes lookup for id 6804828725, released 2026-11-04). 1.0.5 is still in review, so it is not the live baseline.
- Base: `7e16df5^` (the last commit carrying `MARKETING_VERSION: "1.0.4"`, build 25). Head: `7dfbaa3` (1.0.6, build 30), `origin/main`.
- App sources only: `Electrician/`, `Shared/`, `project.yml`, `Info.plist`. 17 files, +477/-61. Docs, fastlane, qa, android and tests were excluded.

What changed in that range: the 2026-11-06 state machine fixes (lapsed-member warm-up reminder, the refused-reminder retry, flashcard Undo, Exam Target Cancel, `converted_with_trial` eligibility, `DayClock`), the Language row in Settings with `UIPrefersShowingLanguageSettings`, accessibility-size layouts on Home and onboarding, 44 pt hit targets in the onboarding footer, the overflow-driven pin in `QuestionPager`, and zero-length Reduce Motion animations.

## Findings

| # | Severity | File:line | What happens | Status |
|---|---|---|---|---|
| 1 | P2 | `Electrician/Views/CandidateProfileView.swift:60` | Exam Target Cancel now restores the snapshot taken on open, but the screen is pushed with `NavigationLink` from Home, Settings and Practice Readiness. Leaving it with the back button or the edge swipe keeps every edit, so Cancel and Back now disagree. Save is unaffected. | Not fixed: whether Back should discard or keep is a product call, and the write-through on Back is the 1.0.4 behaviour, not a regression. |
| 2 | P2 | `Shared/Services/AppSettings.swift:108` | `dailyReminderAwaitingPermission` lives in memory only. If a candidate refuses notifications during onboarding and iOS ends the app before they allow them in Settings, the "we will schedule it" retry no longer runs on return and the Daily Reminder stays off. | Not fixed: the 2026-11-06 fix scoped this to the session on purpose; persisting it is a design change. |
| 3 | P2 | `Electrician/Views/HomeView.swift:324` | R1 from the 2026-11-06 audit is still open: a paying member who cold-launches from the Exam Warm-Up notification may see the paywall before RevenueCat answers. | Not fixed: held for Jack in `state-machines-2026-11-06-fixes.md`; needs a device check with RevenueCat configured. |
| 4 | P2 (checked, no defect) | `Electrician/Views/Drills/FlashcardDrillView.swift:343`, `Electrician/Utilities/Theme.swift:237` | Under Reduce Motion `Theme.Motion.fling` is now `.linear(duration: 0)`, and the flashcard swipe only grades and advances the deck in that animation's completion. If a zero-length animation skipped its completion, a Reduce Motion user would be stuck on the first card. | No change needed: `ReducedMotionCompletionTests` proves the completion runs. Kept as a guard. |

No P0 or P1 found.

## Checked and clean

- **Crashes and data loss.** No new force unwraps, subscripts or decoding of saved data in the range. `DayClock` hops to the main queue before `MainActor.assumeIsolated`. Undo snapshots and restores the exact `PracticeRecord` key `record(itemID:)` writes, and the seen and missed sets. `CandidateProfile.restore` writes only changed fields, so an absent `candidate.edition` stays absent. `RootView`'s new `AppSettings` environment object is injected in `ElectricianApp`.
- **Purchases.** `entitlementKnown` only gates clearing the warm-up reminder, never the paywall or room locks; a stale or offline cache leaves it false, which fails safe for paying members. `purchase`, `restore` and `confirmEntitlement` are unchanged apart from the trial-eligibility flag sent as `converted_with_trial`. Entitlement id is still `electrician_pro`. The local Pro override is DEBUG-only in both the toggle and `applyEntitlement`.
- **State.** The reminder retry is guarded by the earlier refusal, clears on "No reminders" and on grant, and `scheduleReminder` removes the pending request before adding, so it cannot double-schedule. Finishing onboarding clears the denial flag so Settings does not raise the alert again. All seven setup steps render through `setupStep`, so the footer that moves into the scroll view at accessibility sizes is never lost.
- **App Review.** The onboarding trial footer and `PaywallView` keep working Terms and Privacy links and Restore. Prices come only from StoreKit; the 9.99 / 39.99 / 89.99 literals are the DEBUG StoreKit fallback. No other-platform links, placeholder text or health claims in the range. The Language row opens the app's own iOS Settings page, and the app ships six localizations besides English, so the page has a Language option. `python3 Tools/Localization/check.py`: 1721 keys, 6 languages, 0 problems.

## Tests

RESULT_PLACEHOLDER
