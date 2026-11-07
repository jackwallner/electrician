# Fixes for the state machine audit, 2026-11-06

Fixes for the claims [the review](state-machines-2026-11-06-review.md) kept from [the audit](state-machines-2026-11-06.md), in the review's ranked order, plus its two unverified claims once settled. Branch `fleet/20261106-174539-f558-claude`, base `d3d128771286692fa80789ebc9f07bebd417c040`.

**Summary: 7 in-scope claims. 7 fixed, 0 held, 0 skipped.** B1, B2, B3, B4 and B7 were confirmed by the review; B5 and R1 were unverified and both settled as reachable (below). B6 (not a bug) and the five product calls were left alone.

Regression tests live in `ElectricianTests/StateMachineRegressionTests.swift` (14 tests). The audit's repro suite was never added to the test target; its B1 test is reused as `testB1_lapsedMemberLaunchClearsWarmUpReminder`. Its B2 and B3 tests asserted the auditor's preferred fix and an off-screen value; the review called them opinion tests, so they were rewritten to assert the broken promise (the card's "we will schedule it", and room accuracy after Undo).

## Every in-scope claim

| Id | Result | Commit | Regression test | What changed |
|---|---|---|---|---|
| B1 | Fixed | `8e3b22f` | `testB1_lapsedMemberLaunchClearsWarmUpReminder`, `testB1_staleCacheDoesNotClearPayingMembersReminder`, `testB1_onlyFreshNegativeAnswersCount` | `SubscriptionService.entitlementKnown` turns true on the first current answer: any entitled answer, or a not-entitled one whose RevenueCat `requestDate` is at most 5 minutes old (RevenueCat's own foreground cache lifetime), or at `start()` when RevenueCat is not configured. A cached answer more than a few days old is not current, so a paying member whose stale cache reads inactive keeps the reminder. Home clears the warm-up reminder when the answer arrives and is not a member, alongside the existing live true to false rule. |
| R1 | Fixed (with B1, same cause) | `8e3b22f` | `testR1_notificationTapWaitsForEntitlement` | `consumePendingDestination` leaves a notification tap pending until `isPro` or `entitlementKnown`, so a member cold-launching from the warm-up notification is no longer shown the paywall (and counted as an impression) before RevenueCat answers. |
| B2 | Fixed | `f234d82` | `testB2_laterGrantClearsDenialWarning`, `testB2_returningWithPermissionTurnsReminderBackOn`, `testB2_noRemindersEndsWarningAndRetry`, `testB2_noRetryWithoutAnEarlierRefusal` | A grant now clears `reminderPermissionDenied` (both reminders). A refused daily reminder is remembered for the session; when the app becomes active with notifications allowed, it is turned back on and scheduled, which makes the card's "Turn them on there and we will schedule it" true. "No reminders" clears the warning and the retry. Finishing onboarding clears the flag, so Settings no longer opens with a repeat "Notifications are off" alert. No copy changed. |
| B3 | Fixed | `0563588` | `testB3_undoneMissLeavesNoTrace`, `testB3_undoRestoresEarlierHistory` | A plain-card swipe snapshots the item's `PracticeRecord` and its seen and missed membership; Undo restores them (`PracticeRecordStore.snapshot/restore`, `ProgressStore.restoreItem`). Choice cards are unchanged: the review judged keeping a pick made before the answer showed to be right. |
| B4 | Fixed | `cc0971e` | `testB4_cancelRestoresExamDate`, `testB4_cancelLeavesAbsentEditionKeyAbsent` | Exam Target snapshots the profile once when it opens (`CandidateProfile.snapshot`); Cancel restores it, writing back only fields that changed, so a legacy install's absent `candidate.edition` key stays absent. Save is unchanged. |
| B7 | Fixed | `7f2d8cc` | `testB7_ineligibleBuyerDidNotStartTrial` | `startedTrial` (synced as `converted_with_trial`) now also requires trial eligibility from `trialEligibility`; unknown counts as eligible, matching the paywall. |
| B5 | Fixed (settled as reachable) | `6a8b2ae` | `testB5_dayClockPublishesWhenTheDayTurns` | New `DayClock` publishes the start of today and changes only when the date rolls over, fed by `NSCalendarDayChanged`, `significantTimeChangeNotification` and `willEnterForegroundNotification`. Home observes it, so every `Date()` read in its body (done-today card, streak, countdown, Code Minute badge) is recomputed when the day turns. |

### How the unverified claims were settled

- **B5.** The review left open only whether something else redraws Home on resume. That does not decide reachability: with Home open across midnight (studying at 11:55 pm), no store changes and nothing redraws it, so the done card and yesterday's Code Minute badge stay up. On resume, the only candidate redraw is RevenueCat delivering changed `CustomerInfo`, which never happens on an unconfigured build and does not happen on a configured one when nothing changed. The fix is cheap and has no downside, so it ships.
- **R1.** Reachable from code alone. `isPro` is false until RevenueCat's cached or fetched `CustomerInfo` lands asynchronously after `start()`; the warm-up notification is weekly, so a member who opens the app mainly from it has a cache about 7 days old, which RevenueCat reports as inactive (the 3-day rule the review cites for B1). Their tap is consumed while `isPro` is false and they get the paywall until the network fetch returns, or indefinitely offline.

## Held for Jack

None.

## Skipped

None.

## Test results

Full suite: `gh-sim test --scheme Electrician`, run `electrician@20261106-174539-f558-claude-mbpro3e22a-1106-182456-8462` (GitHub Actions run 42329135473), Xcode 27.1, iPhone 17, iOS 27.2: **212 passed, 0 failed, 0 skipped**, all 14 `StateMachineRegressionTests` among them. The run's snapshot holds every fix commit above. No test failed, so no baseline rerun on `d3d1287` was needed and no test already failed there.

Fail without the fix: every regression test except the B1 launch test calls an API the fix adds (`entitlementKnown`, `handleReminderAuthorization`, `snapshot`/`restore`, `DayClock`, `purchaseStartsTrial`), so none builds on `d3d1287`. The B1 launch test is the audit's repro test, which failed on that code in both the audit run (`electrician@20261106-142704-5eba-claude-imacc9d6-1106-143236-21901`) and the review run (`electrician@20261106-152436-781f-claude-imacfb50-1106-152953-23359`) with `examWarmUpReminderEnabled=true isPro=false`, and passes here.

Also run: `python3 Tools/Localization/check.py`, 0 problems (no copy was added or changed).
