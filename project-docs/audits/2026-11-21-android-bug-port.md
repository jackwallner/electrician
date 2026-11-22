# Android port of the 2026-11-20 bug fixes

Checked 2026-11-22 on `main`. Each row of
[2026-11-20-bug-fixes.md](2026-11-20-bug-fixes.md) was checked against the
`android/` port by reading the code. Bugs that exist there were fixed with the
smallest change that matches the iOS behavior.

Unit runs (`fm-gradle testDebugUnitTest`, GitHub Linux):

- Before the B5 fix, with the re-exported fixture and the new tests:
  `electrician-mbairfcc1-1122-094745-16409`, 75 tests, 3 failed (the three B5 tests).
- At HEAD `90fbe94`: `electrician-mbairfcc1-1122-095221-32727`, **82 passed, 0 failed.**

No emulator run. The Compose wiring of B3, B4, B8 and B10 was checked by
reading the code; the unit tests cover the decision each one makes.

| iOS bug | Android verdict | Commit | Test | Notes |
|---|---|---|---|---|
| B1 Exam Target pops back | not applicable | | | Android has no Exam Target editor outside onboarding: `Route` in `ui/nav/Navigation.kt` has no such destination |
| B2 Streak gains a day after flying west | already fine | | `StoreTest.streakCountsConsecutiveDaysAndResetsOnAGap` | `ProgressStore.kt` stores `progress.lastActiveDay` as a `LocalDate` string and counts gaps between strings |
| B3 Reminders never rescheduled at launch | ported | c70447d | `ReminderRefreshTest` (4 tests; new API, so it does not compile without the fix) | `AppSettings.refreshReminders` runs on every `ON_START`. Allowed: the alarms are laid again. Not allowed: Android is asked, and a refusal switches the reminders off with the existing "Notifications are off" alert |
| B4 Closing Fix My Mistakes part-way counts as a finished run | ported | 997685a | `NavigationTest.closingFixMyMistakesPartWayIsNotAFinishedRun` (new property, does not compile without the fix) | In review mode the bar's Close pops the screen. Only the last item's Finish completes the run |
| B5 Code Minute generated items share one tracking row | ported | 7725178 | `StoreTest.generatedDailyItemsRollUpOneRowPerRoom`, `generatedDailyAnswersKeepTheirRoomInStats`, `GeneratorParityTest.codeMinuteMatchesSwiftAcrossPacificMidnight` (now checks the tracking id). All three failed before the fix | `EndlessPractice.kt` writes `code-minute-rollup-ampacity` and `code-minute-rollup-calc`. `electrician-parity.json` and `swift-content-manifest.json` re-exported with `scripts/sync-android-content.py` |
| B6 Get Started done card lost after flying west | already fine | | `StoreTest` quick session tests | `quickSessionCompletedToday` compares `LocalDate` strings |
| B7 Paywall plan cards do not report selection | already fine | | | `PlanCard` in `PaywallSheet.kt` sets `selected` in its merged semantics |
| B8 Onboarding offers the trial to someone already entitled | ported | f3e3d83 | `OnboardingStepsTest.entitledCandidateSkipsTheTrialStep` (new function, does not compile without the fix) | Android showed a member the "Get Electrician+" page with a Continue button. The plan recap now leads straight in, and membership arriving on the trial step ends onboarding |
| B9 Voltage drop keeps the old answer when a field is cleared | already fine | | `FieldCalculatorTest` | `VoltageDropTool` reads three text fields and shows no result unless all three parse |
| B10 Exam Warm-Up notification over an open sheet shows nothing | ported | 90fbe94 | `NavigationTest.warmUpNotificationOverOpenSheetsOpensTheSession` (new class, does not compile without the fix) | Settings is a pushed screen on Android and was already popped. What's New, Feedback and the paywall are sheets and were left over the session; `AppSheets.open` closes them first |
| B11 Purchase footer docked at accessibility text sizes | not applicable | | | iOS Dynamic Type accessibility sizes (AX1 to AX5). Android font scale stops at 2x and the paywall body already scrolls above the footer |

Counts: 5 ported, 4 already fine, 2 not applicable. B5 includes the fixture re-export.

## Needs Jack

Nothing blocking. Not uploaded to Play; the fixes ship with the next Android
build when you ask for one.
