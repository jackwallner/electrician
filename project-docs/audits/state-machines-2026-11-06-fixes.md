# Fixes for the state machine audit, 2026-11-06

Fixes for the claims [the review](state-machines-2026-11-06-review.md) kept from [the audit](state-machines-2026-11-06.md), in the review's ranked order, plus its two unverified claims. Base `d3d128771286692fa80789ebc9f07bebd417c040`. This revision answers [the verification](state-machines-2026-11-06-verify.md), which rejected B5 and R1 because no test failed on the base for either.

**Summary: 7 in-scope claims. 6 fixed, 1 held for Jack, 0 skipped.** B1, B2, B3, B4 and B7 were confirmed by the review. B5 was unverified and is now settled by a hosted test that fails on `d3d1287`, so its fix stays. R1 was unverified, cannot be settled headlessly, and is backed out and held. B6 (not a bug) and the five product calls were left alone.

Regression tests live in `ElectricianTests/StateMachineRegressionTests.swift` (14 tests). The audit's repro suite was never added to the test target. Its B1 test is reused as `testB1_lapsedMemberLaunchClearsWarmUpReminder`. Its B2 and B3 tests asserted the auditor's preferred fix and an off-screen value, and the review called them opinion tests, so they were rewritten to assert the broken promise (the card's "we will schedule it", and room accuracy after Undo).

## Every in-scope claim

| Id | Result | Commit subject | Regression test | What changed |
|---|---|---|---|---|
| B1 | Fixed | `fix: clear the warm-up reminder for members who lapsed while away` | `testB1_lapsedMemberLaunchClearsWarmUpReminder`, `testB1_staleCacheDoesNotClearPayingMembersReminder`, `testB1_onlyFreshNegativeAnswersCount` | `SubscriptionService.entitlementKnown` turns true on the first current answer: any entitled answer, or a not-entitled one whose RevenueCat `requestDate` is at most 5 minutes old, or at `start()` when RevenueCat is not configured. A stale cache is not an answer, so a paying member whose old cache reads inactive keeps the reminder. Home clears the warm-up reminder when that answer says not a member. |
| B2 | Fixed | `fix: keep the onboarding promise after a refused reminder` | `testB2_laterGrantClearsDenialWarning`, `testB2_returningWithPermissionTurnsReminderBackOn`, `testB2_noRemindersEndsWarningAndRetry`, `testB2_noRetryWithoutAnEarlierRefusal` | A grant clears `reminderPermissionDenied`. A refused daily reminder is remembered for the session. When the app becomes active with notifications allowed, it is turned back on and scheduled, which makes the card's "we will schedule it" true. "No reminders" clears the warning and the retry. Finishing onboarding clears the flag. No copy changed. |
| B3 | Fixed | `fix: make flashcard Undo take back the undone answer` | `testB3_undoneMissLeavesNoTrace`, `testB3_undoRestoresEarlierHistory` | A plain-card swipe snapshots the item's `PracticeRecord` and its seen and missed membership, and Undo restores them. Choice cards are unchanged, as the review advised. |
| B4 | Fixed | `fix: make Exam Target Cancel discard the edits` | `testB4_cancelRestoresExamDate`, `testB4_cancelLeavesAbsentEditionKeyAbsent` | Exam Target snapshots the profile when it opens. Cancel restores it, writing back only fields that changed. Save is unchanged. |
| B7 | Fixed | `fix: record converted_with_trial only for trial-eligible buyers` | `testB7_ineligibleBuyerDidNotStartTrial` | `startedTrial` (synced as `converted_with_trial`) also requires trial eligibility. Unknown counts as eligible, matching the paywall. |
| B5 | Fixed (settled by a failing test) | `fix: redraw Home when the day turns`, `fix: drive Home's day from one clock and test the midnight turn` | `testB5_homeLeavesTheDoneCardWhenTheDayTurns`, `testB5_dayClockPublishesWhenTheDayTurns` | `DayClock` publishes the start of today, fed by `NSCalendarDayChanged`, `significantTimeChangeNotification` and `willEnterForegroundNotification`, and Home observes it. Home's done-card check, Code Minute badge and `DayClock` now read one `AppClock`, which only tests replace. |
| R1 | Held for Jack | `fix: back out the unproven hold on warm-up notification taps` | none (see Held) | The hold in `consumePendingDestination` and its release on `entitlementKnown` are removed, which restores the base behaviour. B1's reminder clearing does not depend on it and stays. |

### How B5 was settled

The review asked for "an injected clock on Home plus a hosted test that posts the foreground notifications". `testB5_homeLeavesTheDoneCardWhenTheDayTurns` mounts the real `HomeView` with today's Get Started done at 23:55 on the injected clock. It waits until Home stops redrawing, moves the clock to 00:05, posts `NSCalendarDayChanged` (the notification iOS sends when the date turns with the app open) and asserts that Home has judged "done today" again on the new date.

- Run on `d3d1287` plus only the seam (`AppClock` and the two Home reads, no `DayClock`), GitHub Actions 42356332387 (`electrician-b5proof-imac817d-1107-003816-1418`): **failed**, "Home last judged the day at 2026-11-07 23:55:00 +0000, so the done card is still up".
- A diagnostic on the same base (run 42353198813) logged Home's clock reads. After Home settled, posting `NSCalendarDayChanged`, `significantTimeChangeNotification` and `willEnterForegroundNotification` caused no redraw at all (reads 6, 6, 6). Home also redraws once more 3 to 5 s after mounting. That late redraw is why a first version of the test, which moved the clock after 1.5 s, passed on the base (run 42350325874). The final test waits 6 s and then for 2 quiet seconds before it moves the clock.
- On HEAD the same test passes in the full suite below.

The test covers the route where Home stays open across midnight. It cannot change the scene phase, so whether a real resume redraws Home without `DayClock` is still unshown. The fix covers that route too.

## Disputed

None. The verification's three items are all accepted: R1 is backed out, B5 now has a test that fails on `d3d1287`, and the table cites commit subjects instead of hashes.

## Held for Jack

- **R1, a paying member cold-launching from the warm-up notification may see the paywall first.** Decision: should a notification tap wait for RevenueCat's answer before deciding between the drill and the paywall? This changes when the paywall appears, which is held by rule, and it is unproven. The earlier fix also had a downside the verification found: for a member offline with an old cache, a held tap could fire later and replace an open drill. What would settle it is a device check on a TestFlight build with RevenueCat configured. Sign in as a member, turn the Exam Warm-Up reminder on, force-quit, wait for (or trigger) the weekly notification, tap it from a cold start, and see whether the paywall flashes before the drill opens. Run it once with the network on and once in airplane mode. No headless test can stand in, because only a configured RevenueCat run shows the order of `didReceive` against Home's first `onAppear`, and production keys never go on a simulator.

## Skipped

None.

## Test results

| Run | What | Result |
|---|---|---|
| `electrician@20261106-230927-c22f-claude-imac817d-1107-013639-16794` (GitHub Actions 42360471840) | `gh-sim test --scheme Electrician` on HEAD, Xcode 27.1, iPhone 17, iOS 27.2 | **212 passed, 0 failed, 0 skipped.** All 14 `StateMachineRegressionTests` among them, `testB5_homeLeavesTheDoneCardWhenTheDayTurns` in 11.6 s. |
| `electrician-b5proof-imac817d-1107-003816-1418` (GitHub Actions 42356332387) | B5 test on `d3d1287` plus only the clock seam | **1 failed**, as required (see How B5 was settled). |
| `electrician-b5proof-imac817d-1106-235418-32169` (GitHub Actions 42353198813) | B5 diagnostic on the same base | Home made no redraw on any of the three notifications. |
| `electrician-b5proof-imac817d-1106-231253-29834` (GitHub Actions 42350325874) | First B5 test version on the same base | Passed, confounded by Home's late launch redraw. Superseded by the version above. |

No test failed on HEAD, so no test needed a baseline rerun and none is known to have already failed on `d3d1287`. The proof suite lived only in a throwaway worktree and was never in this branch's test target.

The earlier fix commits' hashes (`e3a8dc4` and the rest) differ per branch, so the table above cites subjects. The B1 commit's message still mentions R1; R1's code was removed by the back-out commit.

Also run: `python3 Tools/Localization/check.py`, 0 problems (no copy was added or changed).
