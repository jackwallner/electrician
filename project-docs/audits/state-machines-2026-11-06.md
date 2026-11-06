# State machine audit, 2026-11-06

Scope: iOS app and `Shared/` of the committed tree on branch `fleet/20261106-142704-5eba-claude` (the working tree was clean, `git stash -u` had nothing to stash). There are no widget or watch targets and no backend function in this repo; entitlement is read only from RevenueCat (`SubscriptionService.swift:481-484`). Android is out of scope. No app code was changed.

**Summary: 7 bugs. 2 proved by test (B1, B2), 5 code path only (B3 to B7).** B3 and B4 have replay tests that reproduce the store calls the views make, but they cannot press the real buttons, so they are not counted as proved. 5 product calls (not counted). 1 unproven risk (R1).

Evidence run: `gh-sim test --scheme Electrician --only ElectricianTests/StateMachineAuditRepro`, run `electrician@20261106-142704-5eba-claude-imacc9d6-1106-143236-21901`, Xcode 27.1, iPhone 17, iOS 27.2: 8 tests, 4 failed (the claims), 4 passed (the controls). Every test asserts its own preconditions first; no precondition failed. Suite: `state-machines-2026-11-06-repro.swift` (copy into `ElectricianTests/` to rerun).

Test seams that exist and were used: `AppSettings(defaults:)`, `CandidateProfile(defaults:)`, `PracticeRecordStore(defaults:)`, `ProgressStore(defaults:)`, `CodeMinuteStore(defaults:)`, `now:` parameters on the stores, `ConversionDiagnostics.defaultsOverride`, DEBUG `SubscriptionService.setLocalOverride`, and hosting `HomeView` in a `UIHostingController` with injected environment objects. Seams that do not exist: any wrapper around `UNUserNotificationCenter` (it is called as `.current()` in `AppSettings.swift` and `AppRouter.swift` only), a public `CustomerInfo` fixture path in the app, a clock for views, and a UI-test target that drives Exam Target or the flashcard deck (`ElectricianUITests` has `FleetQA` and `ReleaseJourneysUITests` only).

## Bugs, ranked by users reached times cost

| Id | Bug | What the user sees | Promise | User route | Impact | Evidence | file:line |
|---|---|---|---|---|---|---|---|
| B2 | Reminder denial flag outlives the choice and the "we will schedule it" promise is never kept | After refusing notifications and tapping "No reminders" the card still says to turn them on "and we will schedule it". Turning them on later schedules nothing. Settings later opens with a "Notifications are off" alert nobody asked for | "Turn them on there and we will schedule it." | Fresh install, onboarding "One nudge a day?" step, Remind me daily, Don't Allow, tap No reminders | Every new install that taps Remind me daily and refuses (a large share of the people who tap it); cost is a contradictory message plus a reminder they asked for that never arrives | Tested (flag part): `testB2_denialFlagSurvivesChoosingNoReminders` recorded `reminderEnabled=false reminderPermissionDenied=true`. Code path (never schedules later, spurious alert) | `AppSettings.swift:103,171-172`; `OnboardingView.swift:732,746-750`; `SettingsView.swift:66` |
| B3 | Flashcard Undo restores the deck but not the practice record | The card comes back, but the answer you undid still counts: accuracy is lowered and the card can sit in Fix My Mistakes | "Undo last answer" | Home, Code Basics (free), How the Book Is Built, swipe Again on a card, tap the undo arrow, swipe Knew it | Any user who uses Undo in any flashcard drill (free and paid decks); small distortion per use, accumulates in the room accuracy and the review queue | Code path with replay `testB3_flashcardUndoLeavesPhantomMiss`: recorded `attempts=2 correct=1 streak=1 needsReview=true`, expected 1, 1, false. Control passes | `FlashcardDrillView.swift:91,350-362,375-385` |
| B5 | Home does not refresh across midnight | After leaving the app backgrounded overnight, Home can still show yesterday's "Get Started done" card, yesterday's Code Minute score badge and the old day count | ProgressStore doc: "a fresh mix each day, and once today's is done the Home card rests until tomorrow" | Finish the daily Get Started at night, background (do not kill) the app, reopen after local midnight | Everyone who keeps the app in the background across a day boundary (common); cost is low and clears on the next re-render | Code path: no `scenePhase`, `significantTimeChange`, `NSCalendarDayChanged` or timeline anywhere in `Electrician/` or `Shared/` (grep). `HomeView.swift:276,386-387,740` read `Date()` inside `body`. Settled by a UI test that changes the device date while the app is backgrounded | `ProgressStore.swift:115-126`; `HomeView.swift:276,386,740`; `CodeMinuteView.swift:6-8` |
| B1 | Weekly Exam Warm-Up reminder survives a lapsed membership | A former member keeps getting "Your warm-up is ready" weekly; tapping it opens the paywall; Settings has no row to turn it off; the locked Home tile still shows the weekday badge | Members-only feature ("Exam Warm-Up targets your weak spots", included with Electrician+); the app's own rule clears it on loss (`HomeView.swift:189-190`) | Member turns on Home, Exam Warm-Up, Weekly study reminder. Subscription expires while the app is closed. Launch. Settings, Practice: no Exam Warm-Up row. Wait for the weekly notification | Lapsed or refunded members who had the warm-up reminder on (a subset of members, expiries are routine); cost is a weekly unwanted notification that only iOS Settings can stop, plus a paywall on tap | Tested: `testB1_lapsedMemberLaunchLeavesWarmUpReminderOn` recorded `examWarmUpReminderEnabled=true isPro=false`; control `testB1_control_liveLapseClearsWarmUpReminder` recorded `false` | `HomeView.swift:181-191,748`; `SettingsView.swift:111`; `AppSettings.swift:113-122,233`; `ShellCopy.swift:20` (`Tour.proLockedBody`) |
| B6 | Reminder toggles never reconcile with the iOS permission | Daily Reminder shows On and a time, but iOS notifications were turned off later, so nothing is delivered | Toggle "Daily Reminder" on, "Reminder Time" shown | Enable Daily Reminder, grant. iOS Settings, Electrician, Notifications off. Open Electrician, Settings | Anyone who later disables notifications at OS level with a reminder on; silent failure | Code path. Every scheduler call site: `AppSettings.swift:110` (time change), `:169` (granted callback), `:128,137,204` (warm-up); cancel at `:95,120`; `UNUserNotificationCenter` appears only in `AppSettings.swift` and `AppRouter.swift`; no `getNotificationSettings`, `getPendingNotificationRequests` or foreground hook exists, and `init` assigns properties directly so `didSet` never runs at launch. Settled by a fake center behind `AppSettings` | `AppSettings.swift:89-100,165-176` |
| B4 | Exam Target "Cancel" keeps every edit | Cancel looks like discard but nothing is reverted; turning off "I know my exam date" then Cancel permanently deletes the date | Button labelled "Cancel" beside "Save" | Home exam countdown card (or Settings, Exam Target), toggle I know my exam date off, tap Cancel; reopen | Anyone editing Exam Target and cancelling; rare, cost is re-entering a date (turning it back on gives today plus 30 days, not the old date) | Code path with replay `testB4_cancelDoesNotRestoreExamDate`: persisted `examDate` recorded `nil` after the edit. Control passes (`dailyGoal` writes through) | `CandidateProfileView.swift:55-61,100-105`; `CandidateProfile.swift:281-288` |
| B7 | Every plan purchase is recorded as a trial start | RevenueCat attribute `converted_with_trial=true` for a buyer who was ineligible for the trial | ConversionDiagnostics doc: "Freezes what the funnel looked like at that moment" | Previously-subscribed Apple Account, paywall shows no trial, buys monthly | No user-visible effect; wrong analytics for returning subscribers | Code path: `startedTrial` reads the product's introductory offer, not eligibility. Settled by a `TestStoreProduct` package and an ineligible `trialEligibility` entry | `SubscriptionService.swift:438,447` |

### Bug notes

**B1.** `HomeView` clears `examWarmUpReminderEnabled` only inside `.onChange(of: subscriptions.isPro)` when the value becomes false. `isPro` starts false (`SubscriptionService.swift:88`) and a lapsed member resolves to false again, so `onChange` never fires and the persisted flag and the pending `electrician.gameNightReminder` request stay. The test hosts the real `HomeView` and also proves the same view clears the flag on a live true to false change.

**B2.** `reminderPermissionDenied` is one singleton Bool shared by Onboarding, Settings and Exam Warm-Up. Only the two alerts' binding resets it. The onboarding card reads the flag alone (`OnboardingView.swift:746`), not the selection. Nothing re-attempts scheduling after permission arrives later: `scheduleReminder()` is reachable only from the granted callback and `reminderTime.didSet` while enabled (see B6 list). Not tested: the spurious alert on first opening Settings, and the missing later schedule (both need the notification center or a rendered alert).

**B3.** `commit` records through `progress.recordItem` and `PracticeRecordStore.record` (`:357-361`); `undo` touches only `lastSwipe`, `choicePick`, `queue`, `isFlipped`. The same applies to choice cards (`choose`, `:248-249`), which can be answered again after Undo. Undo is one level deep.

**B5.** Confidence is moderate: SwiftUI may re-render Home on resume for unrelated reasons, which is why this is not counted as proved.

## Unproven risk (not counted)

**R1.** Cold launch from the warm-up notification for a paying member. `AppDelegate.didReceive` sets `pendingDestination`; `HomeView.onAppear` consumes it (`HomeView.swift:134,313-319`) while `isPro` is still false until RevenueCat answers (`ElectricianApp.swift:30` starts it in parallel). If the tap is delivered first the member gets the paywall (and a counted paywall impression) until `isPro` flips, then `path = [pendingAfterUpgrade]` and the paywall dismisses itself (`PaywallView.swift:425`). Depends on delivery order; not reproducible without a device and RevenueCat.

## Product calls (not counted: no promise contradicted)

1. The daily reminder fires even after the user has already practiced that day; copy is generic ("Time for a quick drill").
2. Both reminders keep repeating after the exam date has passed; `daysUntilExam` becomes nil but nothing cancels them.
3. The Code Minute weekly goal counts by completion time, so five archive days finished in one sitting read "Weekly goal complete" (the copy says "Any five days count. Miss one, catch up from the archive").
4. Abandoning a quick session or Code Minute halfway and replaying it records those questions twice in `PracticeRecordStore` (attempts inflate).
5. Onboarding goes straight to Home after a purchase without waiting for the entitlement (`OnboardingView.swift:1244-1288`); the paywall does wait (`confirmEntitlement`). The RevenueCat delegate update repairs it, so the exposure is a moment of locked content.

## Related fixes, in order

1. B1 and B6 together: reconcile reminder state at launch and on foreground. Read authorization and pending requests, and make `isPro == false` at launch clear the warm-up flag (not only on a live change). One `NotificationScheduling` seam makes both testable.
2. B2: clear `reminderPermissionDenied` when the user picks "No reminders" or when authorization later reads granted; stop one flag from serving three screens; decide whether to keep the "we will schedule it" sentence (needs fix 1 to be true).
3. B3: make Undo reverse the record (snapshot the `PracticeRecord`, seen/missed membership and tally before each grade) or remove the arrow.
4. B4: edit a draft copy and commit on Save, or drop the Cancel button.
5. B5: observe `scenePhase` and `.NSCalendarDayChanged` in Home and re-derive day-dependent values.
6. B7: base `startedTrial` on `isEligibleForTrial` for the plan.

## State machines

Notation: **I** is an invariant, **T** a transition. "Breaks" names the invariant a reachable bad transition violates and the bug id. Sources are file:line in the committed tree (nothing was stashed: the working tree was clean).

### M1. Reminder completion (per reminder, derived)

Not stored. It is a pure function of `(reminder, acted events, now)`: `ReminderDTO.isCompleted(in:at:)` (`Shared/Models/ReminderCompletion.swift:35`). The home list, Handled screen, widget-adjacent counts and `NotificationScheduler.reschedule` all call it.

States: **Open** (no acted event for the period), **DoneForPeriod** (repeating: recurring or daily random, acted event at or after `currentPeriodStart`), **Handled** (one-shot, any acted event, forever), **PastDue** (one-time, `fireAt < now`, not acted), **Deleted**.

Invariants
- I1.1 At most one acted event per reminder per period. Guard is `togglingIds` in `ReminderListView` (`:26`, `:504`), per device and per view only. The table has no unique key (`0001_init.sql` `reminder_events`).
- I1.2 Undo returns the reminder to Open. `currentCompletionEvent` returns one event (`ReminderCompletion.swift:45`).
- I1.3 The local list and the server's `reminder_done_now` agree on which period an event belongs to (`0014:132`, "Mirrors ReminderCompletion").
- I1.4 What a user sees is `authorId == me || targetId == me` (`ReminderListView.swift:186-191`).

| T | From | To | Breaks |
|---|---|---|---|
| Tap circle or swipe Done | Open | Done/Handled | CP-6 (a failed insert is swallowed with `try?`, `:507`, and the review counter still moves) |
| Second Done on a stale list (partner phone, or insert ok but re-read failed) | Done | Done with 2 events | I1.1 |
| Not done | Done with 2 events | still Done | I1.2, SM-6 |
| Midnight, week or month rollover | DoneForPeriod | Open | I1.3 on Sunday-first locales (SM-3) |
| Edit time of a Handled one-shot | Handled | Handled | PC-1 (documented rule) |
| Partner marks it done on their phone | Open | Done (server) | local copy only learns at the next foreground, `reminder_events` is not on the realtime feed (`ReminderRepository.subscribeRealtime` filters `reminders` only) |
| Delete | any | Deleted | none found (`delete` removes the row, `rescheduleNotifications` follows) |

### M2. On-device notification schedule

State is the set of pending `UNNotificationRequest`s. Written only by `NotificationScheduler.reschedule` (removes everything except `milestone.*`, then adds) and `rescheduleMilestones`. Call sites of the reminder rebuild (all route through `ReminderRepository.rescheduleNotifications`, which waits for `hasLoaded`): `ReminderListView.task` (`:122`), primer grant (`:103`), complete, undo, delete (`:508`, `:521`, `:526`, `:552`), Handled delete (`HandledRemindersView` `:596`), `refreshAndRearm` (`:541`), `ReminderEditorView.save` (`:609`), `importReminders` (`ReminderRepository.swift:219`), `rearm()` (realtime, watch, push registration, relationship change), `catchUp` (foreground, silent push). A direct `NotificationScheduler.reschedule` call exists only inside the repository's default closure (`:58`).

States: **Unarmed** (`!hasLoaded`), **Armed(L, E, perm, serverDelivers)** where L is the list and E the completions at the last rebuild, **Stale** (L or E differ from the server, or the clock/zone moved).

Invariants
- I2.1 Never rebuild from a list that was not fetched (`hasLoaded`, `ReminderRepository.swift:22`).
- I2.2 Never rebuild from completions that were not fetched. **Not enforced** for events: `eventsRepo.events` starts `[]` and `refresh()` swallows errors (SM-5).
- I2.3 Pending set equals f(L, E) for the user's current zone and day.
- I2.4 A phone arms partner reminders locally unless `PushRegistrar.serverDelivers` (`NotificationScheduler.armsLocally`, `:60`).

| T | Trigger | Effect | Breaks |
|---|---|---|---|
| Launch | `ReminderListView.task` | refresh, events refresh, rebuild | I2.2 when only the events request fails (SM-5) |
| Silent-push launch | `onRemoteChange` (`BondApp.swift:33`) | catchUp with `events.events` | I2.2, same, fresh process so E is `[]` |
| Save / reschedule | editor | upsert, refresh (errors swallowed), rebuild | I2.3 when the refresh fails (SM-2) |
| Foreground | `catchUpOnForeground` | pair lookup, catchUp, push refresh | none (reconciles permission granted later: `.notDetermined` -> granted arms everything, control) |
| 5 days idle | none | daily-random runway ends (`:151`) | I2.3 (CP-3) |
| Zone change | none (no observer exists, grep `TimeZoneDidChange` is empty) | calendar triggers float with the zone | I2.3 (CP-5) |
| Recurring with far "Starting" | save | repeating trigger ignores the anchor day (`:285-299`) | I2.3 (CP-2) |
| Unpair | `onRelationshipChange` | rebuild drops partner rows locally | server side keeps pushing (CP-1) |
| Complete a repeating reminder | Done | one-shot skipped, random-daily skips today, repeating trigger not skipped | PC-2 |

### M3. Push delivery registration (`PushRegistrar`, `0014_partner_delivery.sql`)

State is three UserDefaults keys (`push.token`, `push.user`, `push.synced`) plus the server's `push_devices` and `reminder_push_queue`.

States: **None**, **Registered(me, token, tz, day)**, **Forgotten** (after sign-out, delete, or `.denied`).

Invariants
- I3.1 `push.user == me` implies the server has a live device row for this phone and a queue row for each partner reminder addressed to me.
- I3.2 The queue only holds rows for reminders whose target and author are in one couple (not enforced, CP-1).
- I3.3 Re-registration when token, user, zone or day changes (`store`, `:59`).

| T | Effect | Breaks |
|---|---|---|
| Permission granted | `refresh` -> `registerForRemoteNotifications` -> `store` -> RPC -> `onRegistered` rearm drops local partner copies | none |
| Permission denied later | `refresh` unregisters, forget; next rebuild arms locally | none (note `catchUpOnForeground` rebuilds before the refresh, irrelevant while denied) |
| Sign out | `unregister` then `forget` | none |
| Unpair (either side) | `leave_couple` updates `couple_id` only | I3.2 (CP-1) |
| Token rotates / APNs 410 | server deletes row; next foreground `store` sees new token | none |

### M4. Notification permission and primer

States: notDetermined -> (primer shown, flag `hasShownNotificationPrimer` written *before* the sheet, `ReminderListView.swift:182`) -> requested -> authorized | denied. "Maybe later" leaves notDetermined with the flag set, the system prompt then comes from the first save or Done (`requestAuthIfNeeded` defaults true) or the Milestones tab.

Invariants: I4.1 the system prompt is not raised at launch (`requestAuthIfNeeded: false`); I4.2 granted later is picked up on foreground. Both hold. The Settings label (`SettingsView.swift:221`) is read once per appearance: PC-3.

### M5. Entitlement and purchase (`PurchasesService`)

States: **Unresolved** (`isPremium == false`, `customerInfo == nil`), **Free**, **Premium**, **Purchasing** (`purchaseInFlight`), **Pending** (payment ok, entitlement not yet visible, up to 15 polls of 0.6 s after `syncPurchases`), **Restoring**, **Error**. `isPremium = hasActivePremium(info)` on every `apply`.

Invariants
- I5.1 `isPremium` is derived from the last `CustomerInfo` for the current RevenueCat user.
- I5.2 The RevenueCat user is the Supabase user (`identify`, `BondApp.swift:359`, `:463`, `PairingView.swift:373`, `InviteWelcomeView.swift:112`).
- I5.3 No paywall on a beat where the entitlement may still be resolving (AGENTS.md). Post-pair and post-onboarding both check `!store.isPremium` at the moment, the bootstrap `refresh()` has long finished by those taps.

| T | Notes | Breaks |
|---|---|---|
| Launch | `bootstrap` refresh + offerings + stream | gates flash teaser for a beat (I5.3 not at risk, nothing raises a paywall there) |
| Purchase `.pending` | restore then error with Restore | none |
| Sign out | `purchases.signOut()` then `supabase.signOut()`; a thrown `logOut` leaves the old `isPremium` | PC-9, I5.1 only if `logOut` throws |
| Sign out, then new anonymous user | RevenueCat stays anonymous until next launch `identify` | PC-9, I5.2 |
| Renewal | Settings reads `latestPurchaseDate` | CP-7 |

### M6. Root routing and session (`RootDestination.resolve`, `SupabaseService`)

States: loading, intentSetup, inviteWelcome, inviteeIntake, pairingSuccess, home. Inputs: bootstrapped, authenticated, hasCouple, coupleLookupFailed, deferred invite, justPaired, solo, intake captured. Tested in `RootDestinationTests`.

Invariants: I6.1 a failed lookup is not "no couple" (held); I6.2 a failed restore is not "no session" (held, `shouldStartFreshSession`); I6.3 after the identity changes, the couple, reminders and completions in memory are re-read.

| T | Breaks |
|---|---|
| Apple link works | none |
| Apple link fails, server answered (identity belongs to an older account) -> `signIn` as that account | I6.3: nothing reloads `PairingService` / repositories, the old anonymous couple stays in memory until the next foreground (CP-9) |
| Sign out | `pairing.reset()` clears the couple; repositories keep the old arrays but `hasLoaded` goes false |
| Delete account | same |

### M7. Pairing (`PairingService`, `0005`, `0009`, `0010`)

States: **Uncoupled**, **Solo** (own couple row, partner_a == partner_b), **Paired**, **Unpaired** (split into two solo couples), plus invite sub-state (code pending 24 h, consumed, expired) and `deferredInviteCode` + `requiresSignInToPair` for anonymous users.

Invariants: I7.1 `!solo` implies `partnerProfile != nil` (nothing enforces it, SM-4); I7.2 a failed lookup changes nothing (`PairingService.swift:102`, broken half-way in SM-4); I7.3 after unpair, the other partner cannot send anything (`SettingsView.swift:76`, broken server-side, CP-1).

| T | Notes | Breaks |
|---|---|---|
| Consume code | merges the invitee's solo rows onto the survivor | none |
| Lookup with profile fetch failing | `coupleId`/`solo` already written, `lastLoadFailed`, `onRelationshipChange` still fires | I7.1, I7.2 (SM-4) |
| Unpair | `leave_couple` | I7.3 (CP-1) |

### M8. Paywall and review presentation flags

UserDefaults: `hasShownPostPairPaywall`, `hasShownPostOnboardingPaywall` (set at `IntentSetupView.enterTrialStep`, `:430`, and again on the `.intentSetup -> .home` edge, `BondApp.swift:408`), `hasShownNotificationPrimer`, `pairingNudgeDismissed`. View state: `pendingPostOnboardingPaywall`, `showPostPairPaywall`, `showReviewPrompt`, `reviewPromptShownThisSession`. `ReviewPromptTracker` (app group): launch count, first open, positive moments, last shown, outcome.

Invariants: each one-shot flag is written before its sheet appears (a sheet that fails to present is never retried, by design). Review funnel needs a real done (AGENTS.md): CP-6.

### M9. Daily check-in (`DailyCheckInService`)

Per local calendar day: noQuestion -> pending -> awaitingPartner -> readyToReveal -> revealed (`revealPhase`, `reveal-shown-<yyyy-MM-dd>`). The question index is `(local day ordinal + coupleSeed) % count` (`:37-43`); responses are matched by question id.

Invariant I9.1: both partners are on the same question on the same day. Broken whenever their local dates differ (CP-8). `todaysQuestion`, `myResponse`, `partnerResponse` are not cleared on sign-out or unpair; they are reassigned by the next successful load.

### M10. Milestones and widget/watch sync

Milestones: `refresh` writes list, widget snapshot, and `milestone.*` notifications (next occurrence only; 7 days, 1 day, day-of at 9:00). Re-armed only when the list is re-read. Widget snapshot is rebuilt whole and waits for `reminderRepo.hasLoaded`; a failed load keeps the last good one (documented). Watch: `createReminder` -> `upsert` -> `rearm()`; reply carries the real outcome.

### M11. Server push queue (SQL)

`reminder_push_queue(reminder_id, next_push_at, silent)`. Rows are written by trigger `reminders_sync_push_queue` on insert or update of `fire_at, rrule, geofence, window_start, window_end, trigger_type, author_id, target_id, surprise_hidden_from_partner`, by `register_push_device`, and by `claim_due_reminder_pushes` (which moves each row on before sending). Not in the column list: `couple_id`. Invariants: I11.1 a row exists only while the target should still receive it; I11.2 done-for-period uses the same period as the client (SM-3); I11.3 claim skips rows stale by more than an hour.
