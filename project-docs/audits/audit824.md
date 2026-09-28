# Electrician end-to-end product audit

Date: 2026-08-24

Audience: product, engineering, content, App Store release, and market
positioning decisions for the US electrician licensing-exam market.

Audit status: complete for the available local source, simulator, tests,
release scripts, metadata, and draft App Store Connect record. The product is
not ready for public submission yet.

## Scope and success criterion

The requested outcome was a read-only, end-to-end audit of the ported
Electrician app, with detailed findings recorded here instead of implementing
the fixes. The audit covers:

- Every user-facing SwiftUI surface, including onboarding, Home, rooms, drills,
  tools, progress, settings, paywall, notifications, review prompts, and
  release-facing links.
- Shared models, authored content, generated calculations, persistence,
  session assembly, subscription state, and the inherited shell.
- Accuracy and content-validity tests, screenshot tests, build behavior,
  simulator behavior, accessibility exposure visible to automation tools, and
  concurrency warnings.
- Store metadata, marketing copy, legal posture, screenshots, App Store
  Connect readiness, subscription products, and review information.
- Fit for apprentice, journeyman, master, and working-electrician audiences,
  including code edition, jurisdiction, exam workflow, and professional tone.

No app source, project, content, test, or local metadata files were fixed in
this pass. The only external changes were the four repository-defined,
pre-submission ASC fields described in the ASC section below. No build was
uploaded, no screenshot was uploaded, no browser form was saved, and no
version or product was submitted for review.

## Executive verdict

The core learning idea is credible: original explanations cite article
numbers, calculations show their working, distractors represent recognizable
mistakes, and the numeric test suite is substantially stronger than a typical
content app. The visual shell is coherent and the free calculators provide a
useful retention surface.

The surrounding product is not yet sufficiently tailored to the licensing
market. It currently presents as a polished calculation and code-navigation
trainer with a four-room shell, while the store and website imply a broader
journeyman and master exam-preparation product. The largest risks are:

1. A candidate cannot identify their license goal, state, licensing authority,
   adopted NEC edition, exam date, or exam type.
2. The app says 2026 while its reference values explicitly follow the 2023
   cycle, with no user-visible edition or jurisdiction mode.
3. The visible substantive coverage is narrow. Generated practice has only
   five calculation skills and the authored library has four rooms.
4. Several paid-feature promises do not match the implementation, especially
   generated mistake review and the free-user Fix My Mistakes entry point.
5. The draft ASC version has no attached build, no listing screenshots, no
   privacy-policy URL or privacy questionnaire, and incomplete App Review
   information.
6. A valid build and passing tests do not establish market readiness. The
   screenshot UI suite was not usable in this environment, purchase behavior
   could not be exercised against RevenueCat without touching production, and
   the app has no end-to-end test for candidate profile, edition, or exam
   readiness because those concepts do not exist yet.

Recommended release decision: hold public submission. Resolve the P0 items,
make the store promise match the actual coverage, and complete the ASC draft
record before treating the app as a market candidate.

## Severity and confidence

- P0: blocks a trustworthy market promise, a safe public release, or the core
  licensing-exam use case.
- P1: materially harms conversion, trust, learning outcomes, or release
  reliability and should be resolved before launch if the relevant surface is
  marketed.
- P2: important quality, accessibility, professional-fit, or retention work
  that should follow the launch blockers.
- P3: cleanup, maintainability, or polish with limited immediate user impact.

Confidence labels:

- Confirmed: directly supported by source, API state, test output, or visible
  runtime behavior.
- High: behavior follows directly from source and is highly likely in the app.
- Needs runtime confirmation: observed through automation or inferred from a
  path that could be affected by a simulator or test harness limitation.

## Evidence collected

### Source and product inspection

- Inspected all Swift files under `Electrician/`, `Shared/`,
  `ElectricianTests/`, and `ElectricianScreenshots/`.
- Inspected project generation, release scripts, ASC scripts, Fastlane
  metadata, `docs/`, StoreKit configuration, and the project guide.
- Compared the shell and feature patterns with `/Users/jackwallner/mahj` and
  used `/Users/jackwallner/mahj/audit823.md` as a structural audit reference.
- Read the market research at
  `/Users/jackwallner/ios/aso/practice-app-fingerprint-2026-08-23.md`.

### Build, tests, and runtime

- The XcodeGen project built successfully with scheme `Electrician` on the
  electrician-owned headless simulator, group `agent-sim-4`, iOS 26.3,
  iPhone 17 Pro, UDID
  `3BA38835-1CCB-4BBA-8045-4F0DD14AED56`.
- The test run passed 65 tests, with zero failures and zero skipped tests.
- The build emitted six Swift 6 actor-isolation warnings in
  `Electrician/Utilities/Theme.swift:181`, `:188`, and `:195`.
- The test target emitted 14 actor-isolation warnings in
  `ElectricianTests/ReviewPromptTrackerTests.swift:9`, `:13`,
  `ElectricianTests/ProgressStoreTests.swift:11-17`, and
  `ElectricianTests/PracticeRecordStoreTests.swift:11-17`.
- A real onboarding screenshot rendered with the warm cream background, book
  icon, open-book message, page dots, and green Continue CTA. The first page
  looked visually coherent and market-specific.
- XcodeBuildMCP's accessibility snapshot exposed only one element and no
  actionable targets for the SwiftUI onboarding view. This is recorded as an
  automation limitation, not as proof that the production UI has no
  accessibility tree.
- The dedicated screenshot UI scheme was not usable in this environment. The
  run repeatedly hung with
  `DebuggerLLDB.DebuggerVersionStore.StoreError: no debugger version`.
  `ScreenshotTests` also deliberately records missing elements instead of
  failing hard, so a partial capture can be exported without proving that the
  full screenshot set exists.
- The independent Luna 5.6 subagent inspected the full user-facing flow,
  compared the port with Mahj, built and tested the app, launched it on the
  headless simulator, and supplied a separate UX and market-fit review. No
  subagent files or changes were retained.

### ASC and Chrome inspection

- Inspected the existing signed-in Chrome profile through the Chrome control
  integration, using a separate ASC task tab.
- Inspected App Information, App Privacy, Accessibility, Pricing, the draft
  iOS version, subscription group, monthly and yearly subscriptions, lifetime
  IAP, and review-related fields.
- Queried the App Store Connect API through the repository's read-only and
  setup scripts to reconcile UI state with API state.
- No ASC version, product, subscription, screenshot, or submission was
  uploaded or submitted.

## Coverage map

| Surface | Inspected | Current result | Audit conclusion |
| --- | --- | --- | --- |
| App lifecycle | `ElectricianApp`, `RootView`, `AppRouter`, `AppDelegate` | Shared state and onboarding branch are present | Good shell, incomplete cold-start notification coverage |
| Onboarding | `OnboardingView` | Five value/profile/trial pages, then primer/tour | Visually good, insufficient candidate targeting and purchase testability |
| Home | `HomeView` | Daily session, primer, tools, rooms, training, upsell | Clear hierarchy, but feature promises and market scope overreach |
| Rooms | `RoomView`, `DrillLibrary` | Four rooms, two free and two paid | Too narrow for the stated journeyman/master promise |
| Authored drills | `ArticleContent`, `CodeBasicsContent`, `ConductorContent`, `PlusContent`, `ProContent`, `CalcContent` | Original wording and citations | Strong legal posture, insufficient domain breadth and citation rendering gap |
| Generated practice | `CalcGenerator`, `EndlessPractice` | Five calculation generators | Promising moat, but not a complete exam engine and not mistake-reviewable |
| Daily and quick sessions | `CodeMinuteContent`, `SessionBuilder`, `QuickSessionView` | Choice-only, deterministic daily and quick modes | Useful loop, timezone, naming, and promise issues |
| Calculation drill | `CalcDrillView` | Numbered working and citation after answer | Strongest differentiated experience |
| Flashcards | `FlashcardDrillView` | Tap, answer, swipe grading | Citation is stored but not shown on the back; gesture-only grading is inaccessible |
| Field tools | `FieldToolsView`, `FieldCalculators` | Ampacity, conduit fill, voltage drop, Ohm's law | Useful study tools, but input validation and field-scope disclosures need work |
| Progress | `ProgressStore`, `PracticeRecordStore`, `StatsView` | Accuracy, room rollups, streak, timed best | Measures activity, not licensing readiness |
| Settings | `SettingsView`, `AppSettings` | Appearance, haptics, sound, reminders, restore, support | Solid foundation, stale internal names and missing profile/edition controls |
| Notifications | `AppSettings`, `AppRouter`, `AppDelegate` | Daily and weekly reminders | User copy is renamed, storage and routing remain Mahj-derived |
| Monetization | `SubscriptionService`, `PaywallView`, StoreKit catalog | Safe simulator guard, custom paywall, three products | Good safety posture, weak error and trial-eligibility states |
| Review funnel | `ReviewPromptTracker`, `ReviewPromptSheet`, `AppStoreLinks` | Positive-moment prompt, feedback path, App Store link | Prelaunch URL is treated as published; feedback completion is optimistic |
| Accessibility | SwiftUI labels, dynamic colors, screenshot/UI test surfaces | Some labels and contrast intent | No broad Dynamic Type, VoiceOver, Reduce Motion, or color testing |
| Release assets | screenshot tests, compositor, upload scripts | Scripts exist, local screenshot folder is empty | ASC listing remains without screenshots |
| ASC | Draft app and products | Products mostly ready, version not ready | Submission blockers remain |

## What is working and should be preserved

### Legal and content posture

`Shared/Models/NECTables.swift:3-17` clearly separates facts and article
citations from copyrighted NEC text. The app's explanations are written from
scratch, the UI points candidates to their own code book, and Settings repeats
the NFPA non-affiliation and local-amendment disclaimer at
`Electrician/Views/SettingsView.swift:188-194`. This is the correct legal
posture for this product and should not be weakened while expanding coverage.

### Numeric integrity foundation

`ElectricianTests/ContentValidityTests.swift:149-175` recomputes authored
ampacity and OCPD examples against `NECTables`. The generator tests at
`:273-305` fuzz all five generator functions, and targeted tests at
`:308-367` check termination limits, the small-conductor cap, and smallest
raceway sizing. `ElectricianTests/FieldCalculatorTests.swift:6-79` covers the
main field-calculator formulas and invalid empty or zero input cases.

This is a real product asset. A wrong ampacity is a trust event, not a cosmetic
bug. Preserve the invariant that every distractor is a named common mistake,
and expand the test suite when the domain expands.

### Calculation teaching interaction

`Electrician/Views/Drills/CalcDrillView.swift:93-125` presents numbered working
steps and a citation after grading. This is materially more useful than a bare
answer and should become the standard for every generated calculation shape.

### Clear free versus paid structure

`DrillLibrary` makes Code Basics and Conductors & Ampacity free, while the
calculation and Grounding & Motors rooms are paid. `RoomView` previews locked
content and explains what membership adds. The free field tools are a good
acquisition and retention choice. The structure needs better scope and promise
alignment, but the basic conversion architecture is understandable.

### Subscription safety

`Shared/Services/SubscriptionService.swift:13-23` keeps DEBUG on a placeholder
key, and `:94-105` refuses to configure RevenueCat on a simulator unless the
key is a test key. This avoids creating fake production customers in simulator
charts. The release entitlement is documented as `electrician_pro`, and the
ASC and RevenueCat product IDs match the local StoreKit catalog.

### Visual direction

The warm cream, jade, coral, gold, and serif display system is distinctive and
coherent. `Theme.swift:6-42` contains deliberate adaptive colors and a
contrast rationale. The onboarding screenshot visually reads as a study tool,
not as an unmodified Mahjong screen. The market-specific content and numbered
calculation working are the strongest signs that the port has already moved
beyond a simple recolor.

# Detailed findings

## Market fit, audience, and positioning

### MKT-001, P0, confirmed: onboarding cannot identify the candidate

Evidence:

- `Electrician/Views/OnboardingView.swift:121-156` asks only “Where are you
  starting from?”
- The three options at `:129-133` are “Just starting,” “In the
  apprenticeship,” and “Sitting the exam soon.”
- `HowToPlayContent.recommendedRoom` at
  `Shared/Content/HowToPlayContent.swift:80-93` maps this value only to a
  recommended room.

Missing user model:

- License goal: apprentice, journeyman, master, or continuing education.
- State, territory, or licensing authority.
- Adopted NEC edition.
- Exam type and exam date.
- Open-book navigation versus calculation versus field-reference priority.
- Whether the candidate is studying for a first attempt, retake, or general
  practice.

Impact: a master candidate and a first-year apprentice receive the same
product structure, difficulty, terminology, and progress model. The selected
value does not materially personalize the curriculum. This weakens activation,
market segmentation, retention, and the credibility of the “Journeyman &
Master” store promise.

Recommendation: add a lightweight candidate profile with a skip path. Use it
to order rooms, choose daily mixes, label edition and jurisdiction, set a
study target, and calculate readiness. Do not force an exam date if the user
does not have one.

Acceptance criteria:

- A user can state journeyman or master separately.
- A user can choose a state or explicitly choose “not sure yet.”
- The selected edition and jurisdiction are visible later in Settings and on
  relevant result screens.
- A profile change updates recommendations without deleting history.
- Tests cover every profile branch and the skip path.

### MKT-002, P0, confirmed: edition and jurisdiction are not operationalized

Evidence:

- `Shared/Models/NECTables.swift:16-17` says values follow the 2023 cycle
  while 2026 adoptions roll out.
- The store name is `Electrician Exam Practice 2026`.
- The website support copy at `docs/support.html:25` makes the same 2023 and
  2026-adoption statement.
- Settings only shows a general warning at
  `Electrician/Views/SettingsView.swift:188-194`; there is no edition or state
  selector.

Impact: the most important accuracy context is hidden. A candidate may assume
the 2026-branded app reflects their jurisdiction's 2026 code when the actual
tables are 2023-cycle values. Because local amendments vary, a generic warning
does not establish which study target the app supports.

Recommendation: choose one honest initial market position and make it
visible. For example, “2023 NEC reference values, US jurisdictions vary” is a
different product promise from “2026 exam preparation.” If the target is 2026,
create a versioned content layer and a jurisdiction/adoption model instead of
relying on a disclaimer.

Acceptance criteria:

- The app's supported edition is shown before the first drill.
- Every calculation or article result can identify the relevant edition.
- The App Store description, website, onboarding, and paywall use the same
  edition language.
- Content validity tests run per edition and fail when a table is missing.

### MKT-003, P0, confirmed: visible coverage is too narrow for the stated market

Evidence:

- `Shared/Content/DrillLibrary.swift:10-134` has only four rooms: Code Basics,
  Conductors & Ampacity, Worked Calculations, and Grounding & Motors.
- `Shared/Content/EndlessPractice.swift:11-16` has only five generated skills:
  ampacity, overcurrent, conduit fill, box fill, and voltage drop.
- `Shared/Models/CodeArticle.swift:11-20` names nine article families, but
  naming an article is not the same as providing a substantive curriculum.
- `fastlane/metadata/en-US/description.txt:3-30` markets “the licensing exam,”
  branch circuits, load calculations, and journeyman/master preparation.

The missing or shallow domains include services, feeders, load calculations,
branch circuits beyond navigation cues, wiring methods, boxes and enclosures
as a larger topic, transformers, special occupancies, special equipment,
communications, full grounding and bonding breadth, and realistic mock exams.

Impact: a buyer looking for a journeyman or master exam product can quickly
exhaust the authored content and discover that the procedural generator only
covers five calculation families. The app currently reads as a calculation
trainer with navigation support, not a complete exam-prep curriculum.

Recommendation: create a coverage matrix by license goal, edition, and exam
blueprint before adding more paywalled tiles. Either expand the curriculum or
narrow every public claim to the specialized product that exists.

Acceptance criteria:

- Each marketed domain has a visible room, drill, or an explicit planned label
  that is not presented as current coverage.
- Each room has enough items to establish mastery and a reason for repeated use.
- A mock exam maps questions to a declared blueprint rather than mixing the
  current five generator shapes.
- The store description and website can be checked against the coverage matrix
  without interpreting marketing language generously.

### MKT-004, P1, confirmed: metadata claims exceed current implementation

Evidence:

- `fastlane/metadata/en-US/description.txt:3-30` says “Branch circuits or
  load calculations,” says Fix My Mistakes brings back exactly missed
  questions, and says Exam Warm-Up builds from the weakest area.
- `SessionBuilder.swift:51-54` intentionally excludes plain flashcards and
  worked calculations from the uniform quick session.
- `PracticeRecordStore.swift:65-94` suppresses generated items from the review
  queue.

Impact: App Store acquisition creates expectations that the first-run product
cannot consistently fulfill. This is a refund and review risk even if every
calculation currently shown is numerically valid.

Recommendation: update the product behavior and metadata together. Do not
solve a behavioral gap only by softening a sentence if the missing feature is a
central reason people would buy.

### MKT-005, P1, high confidence: there is no exam mode or readiness contract

Evidence:

- `StatsView.swift:58-70` reports accuracy, answered count, and best timed
  challenge.
- `PracticeRecordStore` aggregates by room and generated skill, not by an exam
  blueprint, article, edition, or question type.
- `PracticeRunView` offers a 90-second timed challenge, but it is not a mock
  exam and has no declared passing threshold.

Impact: the core customer question, “Am I ready to pass this exam?”, is not
answered. Streaks and total answers show activity but not readiness.

Recommendation: add study mode, exam mode, and field mode as explicit product
concepts. Exam mode should have a declared blueprint, time limit, score model,
review behavior, and readiness trend. Avoid presenting an arbitrary timed
score as an exam prediction.

## Onboarding and activation

### UX-001, P1 pending confirmation: onboarding Continue did not advance in runtime automation

Evidence:

- The onboarding screenshot rendered correctly on the electrician simulator.
- The state transition is plainly implemented at
  `Electrician/Views/OnboardingView.swift:331-334`.
- The Luna subagent reported that tapping Continue through XcodeBuildMCP and
  AXE left the first page visible.
- The XcodeBuildMCP snapshot exposed no actionable SwiftUI targets, so the
  observation may be an automation or accessibility-tree issue rather than a
  production defect.
- The screenshot UI test scheme separately failed with a debugger-version
  error, so it did not provide an independent traversal result.

Impact if reproduced on a device: a fresh user cannot reach the product after
install, making this a release blocker.

Recommendation: verify on a real device or a reliable XCUITest that each
Continue changes the page, the skill page requires a choice, the free path
reaches the tour, the tour can be skipped, and the final session can be exited.
Add a deterministic onboarding navigation test. Do not close this finding
based only on source inspection.

### UX-002, P1, confirmed for DEBUG and simulator: the trial CTA cannot purchase

Evidence:

- DEBUG uses `test_PLACEHOLDER` at
  `Shared/Services/SubscriptionService.swift:18-20`.
- Simulator configuration refuses a production key at `:94-105`.
- `SubscriptionService.purchase` throws `productsUnavailable` when not
  configured at `:240-244`.
- The local StoreKit catalog is used only to render prices at `:158-226`.

Impact: the onboarding trial and standalone paywall look purchasable in the
local UI but cannot exercise the purchase, unlock, restore, or post-purchase
flow. This is intentional safety behavior, but it leaves a critical revenue
path untested until release.

Recommendation: add a non-production RevenueCat test-store configuration or a
fully isolated StoreKit transaction test that can prove purchase, cancellation,
restore, entitlement propagation, and failure states without touching
production charts. Keep the simulator production-key guard.

### UX-003, P1, confirmed: trial copy is unconditional

Evidence:

- `PaywallView.swift:7-9` returns “Start 7-Day Free Trial” for every recurring
  plan.
- `PaywallView.swift:83-94` says “7 days free” for yearly and monthly cards.
- `OnboardingView.swift:242-246` also says “7 days free” whenever the price is
  available.
- ASC currently has one-week introductory offers for the monthly and yearly
  subscriptions across the configured territories, but the UI does not ask
  StoreKit or RevenueCat whether the current Apple Account is eligible.

Impact: a returning customer or ineligible Apple Account may see a promise the
store will not grant. This is a purchase-trust and App Review risk.

Recommendation: derive the CTA and disclosure from introductory-offer
eligibility. Use “Start 7-day free trial” only when eligible, and otherwise
show “Subscribe” with the actual billing amount and renewal terms.

### UX-004, P2, confirmed: onboarding is long and profile-light for experienced candidates

Evidence: the five value/trial pages at
`OnboardingView.swift:48-92`, followed by the optional primer and feature tour
at `:365-370` and `FeatureTourView.swift:26-105`.

Impact: a master candidate or experienced electrician gets a sequence designed
around a beginner value story, while still receiving no relevant exam profile.
The long path delays the first useful drill and increases the importance of a
working free escape path.

Recommendation: branch onboarding by intent. Let experienced users choose goal,
edition, and focus in a compact setup, then offer the primer from Settings.
Keep the current educational path for new candidates.

### UX-005, P2, confirmed risk: fixed onboarding compositions need Dynamic Type validation

Evidence:

- `OnboardingView.swift:94-119` uses fixed vertical spacers and a large display
  title without a dedicated scroll container.
- `HowToPlayView.swift:138-177` uses a fixed card composition containing title,
  body, tip, and recommendation.
- `FeatureTourView.swift:41-59` uses a similarly fixed card.

Impact: large accessibility sizes, small phones, landscape, and localization
can push the CTA or educational text below the usable area. The code has
comments acknowledging narrow-layout risk at `OnboardingView.swift:173-176`,
but there is no runtime coverage for it.

Recommendation: run the onboarding and primer at every accessibility content
size, iPhone dimensions, landscape where supported, and VoiceOver. Make the
content region scrollable while keeping the CTA anchored.

### UX-006, P2, confirmed: “no timer required” and timed positioning are not separated

Evidence:

- Onboarding says “At your own pace, no timer required” at
  `OnboardingView.swift:63-67`.
- Home says “Open book. Beat the clock.” at `HomeView.swift:215-223`.
- The product contains a 90-second Timed Challenge.

Impact: the two messages can both be true, but the app does not name the
different modes. A candidate may interpret the product as either a relaxed
study tool or a timer-first game.

Recommendation: use explicit labels: untimed Study, timed Exam Practice, and
Field Tools. Keep the user in an untimed explanatory flow by default.

## Navigation, Home, and session composition

### NAV-001, P0, confirmed: the room architecture underrepresents the exam

This is the runtime manifestation of MKT-003. Home exposes exactly four rooms
through `DrillLibrary.rooms` at `Shared/Content/DrillLibrary.swift:10-134`.
The paid Grounding & Motors room is described as “The two articles that decide
a pass” at `:102-105`, which is a strong claim for a room containing only
grounding and motor flashcards and quizzes.

Recommendation: create a blueprint-driven information architecture before
adding more decorative room cards. The top-level structure should make it
obvious which content supports navigation, calculations, grounding, motors,
load calculations, wiring methods, and exam simulation.

### NAV-002, P2, confirmed: “Electrician Minute” and “Code Minute” are inconsistent

Evidence:

- Home labels the tile “Electrician Minute” at
  `Electrician/Views/HomeView.swift:437-443`.
- The destination title and model use “Code Minute” at
  `Electrician/Views/CodeMinuteView.swift:23-38` and
  `Shared/Content/CodeMinuteContent.swift:42-55`.
- Paywall copy uses “Code Minute.”

Impact: the feature name is split across Home, destination, paywall,
notifications, screenshots, and the store funnel.

Recommendation: choose one name. “Code Minute” is already the data-model and
paywall name and is more specific.

### NAV-003, P2, confirmed: “five-minute” copy is not tied to a measured session

Evidence:

- Home and the feature tour call Get Started “A five-minute mix” at
  `FeatureTourView.swift:151-180`.
- `SessionBuilder.quickSession` defaults to `count: 10` at
  `Shared/Content/SessionBuilder.swift:78-83`.

Impact: ten questions may or may not fit five minutes depending on explanation
length and candidate ability. The claim is not backed by a time budget or a
measurement.

Recommendation: either measure representative completion time and test the
claim, or replace it with “a short mix.” If the goal is five minutes, make the
session time-bounded and show its expected length.

### NAV-004, P1, confirmed: free users see a review badge that routes to a paywall

Evidence:

- Home shows Fix My Mistakes when `records.dueCount > 0` at
  `Electrician/Views/HomeView.swift:461-477`.
- Every training tile is converted to a paywall button for non-members at
  `:481-503`.

Reproduction:

1. Use a free account and complete enough authored questions to create due
   review items.
2. Return to Home.
3. See “Fix My Mistakes, N due.”
4. Tap it.
5. Receive the paywall instead of a review session.

Impact: the tile looks available because it contains a due count, then denies
the user at the point of intent. This is especially harmful when the user has
just made a mistake and wants the promised correction loop.

Recommendation: allow a small free review set, hide the due count for free
users, or label the tile “Unlock mistake review.”

### NAV-005, P1, confirmed: empty review sessions can render as completion

Evidence:

- `PracticeRunView.body` routes `finished || items.isEmpty` to
  `DrillCompleteView` at `Electrician/Views/Drills/PracticeRunView.swift:72-77`.
- `QuickSessionView.body` routes `finished || items.isEmpty` to its completion
  view at `Electrician/Views/Drills/QuickSessionView.swift:85-99`.

Impact: an empty deep link, stale queue, or free-user filtering can produce a
0/0-like completion state instead of an honest empty state.

Recommendation: provide “No mistakes are due right now,” “Answer a few
questions first,” or “This session could not load” states with back and retry
actions. Add tests for empty review, empty quick session, and empty Code Minute
pool behavior.

### NAV-006, P3, confirmed: room art is a dead decoration hook

Evidence:

- `Theme.swift:88-90` returns `room-(id)` and comments that bundled room art
  should exist.
- The asset inventory contains only AppIcon, AccentColor, LaunchBackground,
  and sounds. No room art assets were found.
- No call site uses `Room.artName`.

Impact: low immediate user impact, but the dead hook suggests an unfinished
visual layer and creates false confidence in asset completeness.

Recommendation: either remove the dead API and stale comment or add a real,
purposeful room illustration system after the information architecture is
settled. Do not add decorative art before the coverage problem is solved.

## Learning loop and content presentation

### LEARN-001, P1, confirmed: flashcards store citations but do not show them on the back

Evidence:

- `Shared/Models/Drill.swift:15-37` stores `Flashcard.citation` and explicitly
  describes it as the article to look up.
- `FlashcardDrillView.swift:463-495` renders the back title, body, verdict,
  swipe hints, and Next, but never renders `card.citation`.
- The accessibility label at `FlashcardDrillView.swift:424-425` includes only
  the back title and body.
- Calculation cards do show citations at
  `Electrician/Views/Drills/CalcDrillView.swift:93-125`, which makes the
  omission on ordinary cards more visible.

Impact: the app's central open-book navigation promise is lost exactly where
the candidate flips a fact card. Grounding, motor, conductor, and basic cards
can teach a fact without telling the user where to verify it.

Recommendation: render a clearly labeled citation on every card back and add
it to the VoiceOver label. Add a UI or view-model test that every card with a
citation exposes it after reveal.

### LEARN-002, P2, confirmed: plain flashcards require gesture grading

Evidence:

- `FlashcardDrillView.swift:483-492` presents “Knew it? Swipe right, Again?
  Swipe left” when there is no button-based choice.
- The card's accessibility label and hint at `:424-425` do not expose visible
  Knew It and Again controls.

Impact: VoiceOver users, users with motor limitations, and users who do not
discover horizontal gestures lack an equivalent grading path.

Recommendation: add visible and accessible Reveal, Knew It, Again, and Undo
controls. Keep swipe as an optional shortcut.

### LEARN-003, P2, confirmed: drill progress bars never visibly reach 100 percent

Evidence:

- `QuizDrillView.swift:34-37` uses `Double(index)` over `questions.count`.
- `CalcDrillView.swift:43-46` uses `Double(index)` over `scenarios.count`.
- `QuickSessionView.swift:105-108` uses the same pattern.
- `PracticeRunView.swift:173-175` uses the same index-based value for review.

On the final item, the index is generally `count - 1`, so the progress bar is
short of full completion until the completion screen replaces it.

Impact: minor, but it makes the current question state and completion state
feel less precise in a product that sells exam pacing.

Recommendation: decide whether the bar represents the current item or
completed items. If it represents completion, use `(index + 1) / count` after a
graded answer. Add a UI-state test for first, middle, final, and completed
states.

### LEARN-004, P2, confirmed: generated explanations lose the numbered-working advantage

Evidence:

- `CalcDrillView` keeps steps as a numbered list.
- `Shared/Content/EndlessPractice.swift:103-117` joins generated steps into
  one paragraph at `:113`.

Impact: the paid generator is the product moat, but a miss in Endless Practice
is harder to inspect than a miss in the authored Worked Calculations room. The
user cannot quickly identify which operation was skipped.

Recommendation: pass the generated `CalcScenario.steps` through a calculation
result view instead of flattening them into a paragraph. Preserve the scenario
shape and citation in the session model.

### LEARN-005, P1, confirmed: inherited card-game completion language remains

Evidence:

- `Electrician/Views/Drills/DrillCompleteView.swift:110-112` uses “Deck
  cleared!” and “Perfect round!”.
- `Shared/Content/ShellCopy.swift:22` contains “All the cards down”.
- `FlashcardDrillView.swift` still describes its primary model as a deck in
  comments and uses deck-specific styling names.
- Internal identifiers remain `GameNightPrepView`, `game-night-prep`, and
  `gameNightPrepSession` in `Electrician/AppRouter.swift:5-12`,
  `Shared/Services/AppSettings.swift:57-64`, and
  `Electrician/Views/GameNightPrepView.swift`.

The existing stale-term test at
`ElectricianTests/ContentValidityTests.swift:117-132` bans Mahj-specific words
but not generic deck, round, cards-down, lobby, or game-night language.

Impact: a professional electrician can encounter vocabulary that makes the
port obvious and lowers trust in the domain content.

Recommendation: replace visible strings with “Session complete,” “Review
complete,” “All terms reviewed,” and “Calculation set complete.” Rename or
quarantine internal identifiers when practical. Expand stale-copy tests to
catch the generic shell residue.

### LEARN-006, P2, confirmed: celebration emphasis may not fit the professional audience

Evidence:

- `QuickSessionView.swift:209-230` describes confetti, escalating particles,
  haptics, sounds, flashes, and streak banners on correct answers.
- `FeatureTourView.swift:117-121` leads with “Streaks make it stick.”
- Completion copy includes “Perfect round!” at
  `DrillCompleteView.swift:110-112`.

Impact: gamification can help habit formation, but journeyman and master
candidates are often working adults buying confidence, speed, and exam
readiness. Repeated screen flashes and celebratory interruptions can feel
juvenile or distracting during serious study.

Recommendation: offer a professional default with calm feedback, accuracy by
topic, time per question, and next-study guidance. Keep streaks and
celebrations as optional settings or a lighter mode.

### LEARN-007, P1, confirmed: primer language can imply broader coverage than the app has

Evidence:

- `HowToPlayContent.swift:40-44` says “Nine chapters” and describes the whole
  NEC chapter structure.
- The app has article families, but the actual drill library is only four
  rooms and many chapter domains have no substantive drill set.

Impact: the primer establishes an expectation that the app teaches the book as
a whole, while the product currently teaches a selected subset.

Recommendation: distinguish “how the code book is organized” from “topics
currently covered by this app,” and surface a coverage map before purchase.

### LEARN-008, P2, confirmed: no way to report a questionable answer

Evidence: answer screens show explanations and citations, but no report action
or question identifier is exposed in `QuizDrillView`, `CalcDrillView`,
`PracticeRunView`, or `QuickSessionView`.

Impact: the app's most important trust risk, a questionable calculation or
edition mismatch, has no low-friction feedback path.

Recommendation: add “Report a possible issue” after grading. Include item ID,
article citation, edition, selected answer, and categories for wrong answer,
unclear explanation, edition mismatch, and typo.

### LEARN-009, P1, confirmed: generated mistakes cannot come back as targeted practice

Evidence:

- `Shared/Content/EndlessPractice.swift:103-117` marks generated items
  `isReviewable: false`.
- `Shared/Services/PracticeRecordStore.swift:65-94` rolls generated IDs into
  a skill row and sets `reviewSuppressed` for generated items.
- `PaywallView.swift:53-59` promises “Fix My Mistakes: misses come back until
  they stick.”
- `fastlane/metadata/en-US/description.txt:21` says the exact questions keep
  coming back.

Impact: a user can miss a generated derating problem, see the miss counted in
aggregate accuracy, and never see the item or the same mistake pattern in Fix
My Mistakes. The implementation comment says generated questions never repeat,
but the marketing promise describes a general mistake loop.

Recommendation: preserve the no-repeat value while recording the mistake type.
Generate a new targeted problem for the same error pattern, such as starting
at 75 degrees, missing the termination cap, using the wrong fill percentage,
or counting grounds individually. Rewrite copy to say “new problems targeting
the mistakes you make” unless exact-item review is implemented.

### LEARN-010, P1, confirmed: progress lacks skill, article, and readiness detail

Evidence:

- `StatsView.swift:58-70` only gives overall accuracy, answered count, and best
  timed challenge.
- `StatsView.swift:92-142` provides room-level breakdown, not article-level or
  skill-level breakdown.
- Generated records collapse to skill rows in `PracticeRecordStore.swift:76-95`.

Impact: a candidate cannot see whether they are weak at Article 240 versus
Article 250, whether errors are primarily timed, or what to study next. The
weakest-room card is too coarse for exam preparation.

Recommendation: add topic and article views, recent trend, timed versus
untimed performance, mistake type, edition coverage, and a clearly qualified
readiness indicator tied to the user's chosen goal.

## Calculators, reference data, and numeric trust

### CALC-001, P1, confirmed: Ohm's law silently ignores extra inputs

Evidence:

- The UI says “Enter any two” at
  `Electrician/Views/Tools/FieldToolsView.swift:244-250`.
- `FieldCalculators.ohmsLaw` at `Shared/Models/FieldCalculators.swift:144-174`
  chooses the first matching pair and ignores additional values.
- Existing tests at `ElectricianTests/FieldCalculatorTests.swift:65-79` cover
  valid pairs and missing or zero inputs, but not three or four simultaneous
  values or contradictory values.

Reproduction: enter voltage and amperage, then enter a resistance value that
does not agree with them. The implementation still uses the earlier matching
pair without explaining the conflict.

Impact: the tool appears to validate a circuit when it is actually ignoring
part of the user's input. That is a trust issue for an electrician audience.

Recommendation: require exactly two inputs, or calculate from all provided
values and show whether they agree. Tell the user which pair is being used and
which values conflict.

### CALC-002, P1, confirmed: voltage-drop tool is a simplified approximation but is framed as a field tool

Evidence:

- `FieldCalculators.voltageDrop` uses the simple K, circular-mil, current,
  length, and phase-factor formula at
  `Shared/Models/FieldCalculators.swift:110-131`.
- The generated explanation identifies the 3% figure as an informational note
  at `Shared/Content/CalcGenerator.swift:293-295` and `:340-346`.
- The Field Tools result presents the 3% status and citation, but the visible
  result does not clearly enumerate omitted variables such as conductor
  temperature, reactance, power factor, raceway geometry, or load type.

Impact: a user may treat the result as a complete field-sizing answer rather
than a study approximation. The 3% figure can also be misread as a universal
enforceable limit.

Recommendation: label the tool “study estimate” or “approximate resistive
voltage drop,” state the assumptions beside the result, and explicitly say the
3% language is an informational recommendation rather than a general mandate.
Keep the citation.

### CALC-003, P1, confirmed: field tools are too narrow for the stated field-reference promise

Evidence:

- `FieldToolsView.swift:14-27` exposes only ampacity, conduit fill, voltage
  drop, and Ohm's law.
- The conduit tool takes one conductor size and a count, and only EMT is
  available in the current model.
- The app has an authored box-fill calculation, but no corresponding field
  calculator workflow.

Missing or unclear workflows:

- Mixed conductor sizes in a raceway.
- Raceway types beyond EMT.
- Grounding conductor and fill treatment.
- Box fill with actual box volume and conductor/device selection.
- Continuous-load and breaker-sizing workflow.
- Service, feeder, and load calculations.
- Local amendments.
- Result-adjacent study and verification warning.

Recommendation: position the current tools as study and field-reference aids,
then prioritize mixed raceway fill, box fill, conductor sizing, and load
calculation workflows.

### CALC-004, P1, confirmed: generated OCPD prompt lacks realistic load context

Evidence:

- `Shared/Content/CalcGenerator.swift:92-154` creates a question saying “Size
  the overcurrent protection for this conductor” and mentions a continuous-
  duty general load with no next-size-up allowance.
- The givens include conductor, material, and termination, but no actual load
  calculation or circuit context.

Impact: this teaches a table and cap lookup, but it can be interpreted as a
general breaker-selection workflow. Real exam questions require the candidate
to understand load, continuous-load multiplication, equipment limits, and
exceptions. The current wording may train an incomplete mental model.

Recommendation: either label this explicitly as a conductor-protection lookup
exercise or add distinct scenarios that separate load sizing, conductor
ampacity, OCPD standard size, and next-size-up exceptions.

### CALC-005, P2, confirmed: reference data has a narrow supported domain

Evidence:

- `NECTables.swift:25-38` covers a limited set of conductor sizes.
- Aluminum starts at 12 AWG at `:64-83`.
- Ambient correction bands stop at 60 C at `:97-119`.
- Box-fill volumes cover 18 through 6 AWG at `:170-176`.
- Raceway types and areas are EMT-only at `:178-199`.

Impact: unsupported combinations return nil or are absent. That is safer than
inventing values, but the user experience does not consistently explain the
boundary or help the candidate move to a supported study scenario.

Recommendation: show the supported table scope before input, explain why a
combination is unavailable, and expand the reference data only with a declared
edition and a corresponding validity suite.

### CALC-006, P2, confirmed test gap: four-choice intent is not enforced

Evidence:

- `CalcGenerator.swift:357-374` declares `choiceCount = 4` but intentionally
  degrades to a shorter list after 40 padding attempts.
- `ContentValidityTests.swift:80-88`, `:273-305`, and
  `:385-393` assert only at least two choices.

Impact: a generator edge case can produce two or three choices even though the
product design and comments say four. It may not be numerically wrong, but it
changes difficulty and makes a question look unfinished.

Recommendation: decide whether four choices are a hard product invariant. If
yes, make the generator guarantee them or reject the scenario before display.
If no, update copy and tests to make variable choice counts intentional.
Add coverage for adversarial collision cases, not only random fuzzing.

### CALC-007, P3, confirmed: generator documentation is stale

Evidence: `CalcGenerator.swift:11-15` says “The four shapes” while the enum
implements five shapes, including voltage drop.

Impact: small maintainability issue, but stale documentation in the generator
is risky because the generator is the paid product moat.

Recommendation: update the model documentation and add a test or generated
catalog that keeps the documented shape count aligned with `PracticeSkill`.

### CALC-008, P2, confirmed: test breadth is lower than the project guide implies

Evidence:

- The project guide describes fuzzing thousands of problems per run.
- `ContentValidityTests.swift:273-305` runs 400 iterations for each of five
  generator functions, and targeted tests run 300 iterations for three shapes
  at `:311-367`.

Impact: 3,200 total iterations is meaningful, but the project documentation
overstates the current test breadth and the tests do not cover all runtime
assumptions, input combinations, or editions.

Recommendation: either correct the guide or increase the test matrix. Add
seeded edge cases for boundaries, supported/unsupported data, formatting,
choice collisions, and new edition layers.

### CALC-009, P2, confirmed: Code Minute is not globally date-stable

Evidence:

- The model says one shared set per calendar date at
  `Shared/Content/CodeMinuteContent.swift:42-47`.
- The default calendar is `Calendar.current` at `:59-60` and the date key is
  derived from local date components at `:123-126`.
- The app says “The same five questions for every member” at
  `Electrician/Views/CodeMinuteView.swift:35-38`.

Impact: users in different time zones can receive different question sets near
midnight. Shareable scores may refer to different challenges while still
looking like the same day.

Recommendation: choose a fixed boundary such as US Pacific or UTC, store the
boundary in the model, and show the challenge date in the share text.

## Monetization and paywall reliability

### MON-001, P1, confirmed: release offering failure has no explicit retry state

Evidence:

- `SubscriptionService.loadOfferings` silently sets `offerings` to nil on
  failure at `Shared/Services/SubscriptionService.swift:129-132`.
- `PaywallPricing.placeholder` is “Loading price...” at
  `Electrician/Views/PaywallView.swift:163-190`.
- The standalone paywall calls `ensureOfferings()` but ignores the Boolean at
  `PaywallView.swift:337-356`.
- The purchase button remains available unless it is actively purchasing.

Impact: a network or RevenueCat configuration failure leaves a customer with
loading prices and a CTA that produces a generic App Store reachability error.
This can look like a broken purchase flow immediately after a user decides to
pay.

Recommendation: model loading, available, unavailable, and retry states. Keep
the Restore path available independently. Disable purchase until the selected
package exists and provide a visible retry action.

### MON-002, P1, confirmed: standalone paywall does not distinguish no-package from purchase failure

Evidence: `PaywallView.purchase` awaits `ensureOfferings` and then passes
`subscriptions.package(for: selectedPlan)` to `purchase` regardless of the
Boolean result at `:337-356`. `SubscriptionService.purchase` then throws the
same `productsUnavailable` error for both unconfigured RevenueCat and a nil
package at `:240-244`.

Impact: diagnostics and user copy cannot tell whether the issue is an offline
network, missing offering, product configuration, or unavailable Apple Store.

Recommendation: preserve a typed state for offering load failure and a typed
state for product missing. Log the product ID and offering identifier without
exposing implementation details to the customer.

### MON-003, P1, confirmed: simulator safety prevents full monetization QA

The production-key guard is correct, but there is no test-store path in the
current DEBUG configuration. The following remain unverified in an environment
that cannot affect production:

- Trial eligibility and display.
- Subscription purchase and entitlement propagation.
- Apple purchase cancellation.
- Lifetime purchase.
- Restore after reinstall.
- RevenueCat offering failure and retry.
- Paywall dismissal after entitlement confirmation.

Recommendation: configure a separate RevenueCat test-store key and products,
or build a StoreKit test harness that covers the same state machine. Never
replace the simulator guard with the production `appl_` key.

### MON-004, P2, confirmed: recurring trial language must stay synchronized with ASC

The ASC API currently reports one-week free-trial introductory offers for both
monthly and yearly plans across 50 territory rows per product. The UI says
seven days, which is aligned today. This is a dependency, not a permanent
truth. Any ASC offer change must update the UI and screenshots together.

Recommendation: add a release check that compares displayed trial duration,
product eligibility behavior, and ASC product configuration before submission.

### MON-005, P3, confirmed: product identifiers and entitlement alignment are strong

The local StoreKit product IDs, ASC products, and documented RevenueCat
entitlement `electrician_pro` align. This should be preserved. A mismatch here
would allow a charge with no unlock.

## Persistence, privacy, and review funnel

### DATA-001, P1, confirmed: generated practice contributes to stats but not review

This is the data implementation behind LEARN-009. `PracticeRecordStore` keeps a
bounded skill row, increments attempts and accuracy, and suppresses generated
items from scheduling. The behavior is internally consistent with the no-repeat
design, but it contradicts broad “misses return” messaging.

Recommendation: add mistake-pattern persistence separate from exact-item
review. Track the pattern, not an unbounded generated question ID.

### DATA-002, P2, confirmed: reset scope is not fully explained

`SettingsView.swift:76-85` resets progress, practice records, and Code Minute
results, while explicitly preserving purchases. Onboarding profile values,
appearance, reminders, and review-prompt history are not reset.

Impact: “Reset Progress” can be interpreted as a full reset, but it leaves
profile and funnel state in place. A shared-device or troubleshooting user may
not get the result they expect.

Recommendation: label the exact scope in the confirmation dialog and provide a
separate “Reset onboarding and preferences” action only if needed.

### DATA-003, P2, high confidence: local-history privacy copy should distinguish analytics and purchase data

The app describes practice history as staying on the phone, which is
consistent with the local stores inspected. RevenueCat still receives an
anonymous customer identifier and transaction/subscription information, and
the privacy page at `docs/privacy-policy.html:19-27` describes that flow.

Recommendation: keep the strong no-account/no-practice-history claim, but make
the distinction explicit in the in-app privacy text and ASC privacy answers:
local practice data is separate from anonymous purchase telemetry.

### REVIEW-001, P1, confirmed: prelaunch App Store links are treated as published

Evidence:

- `Shared/Services/ReviewPromptTracker.swift:4-25` treats any nonempty
  `appStoreID` as published.
- The file comments acknowledge the listing is still a draft and URLs can 404,
  but the code still exposes `productURL` and `writeReviewURL`.
- `CodeMinuteStore.swift:25-26` includes `AppStoreLinks.productURL` in share
  text.
- The ASC record remains `PREPARE_FOR_SUBMISSION`.

Impact: pre-release testers or users who receive a share can be sent to an
unavailable listing. A manual Rate action can also point at a listing that is
not live.

Recommendation: use an explicit release-state flag, or gate the public URL on
`READY_FOR_SALE`. Keep native `requestReview()` for live positive moments and
provide a tester-safe share URL before launch.

### REVIEW-002, P2, confirmed: feedback is retired when the mail app opens, not when a message is sent

Evidence:

- `ReviewPromptSheet.swift:196-207` marks `submittedFeedback` after
  `UIApplication.shared.open` reports that a mail URL opened.
- There is no way for the app to know whether the user actually sent the
  message.

Impact: a user who opens a draft and abandons it will never receive the prompt
again. The behavior is understandable, but the persisted outcome name is too
strong and the funnel metric is optimistic.

Recommendation: rename the state to feedback draft opened, or provide an
explicit “I sent it” action before retiring the prompt.

### REVIEW-003, P2, confirmed: technical content reporting should precede rating requests

The review funnel routes unhappy users to general feedback, but it does not
offer a direct path from a questionable answer to a report with the question
context. For an accuracy-sensitive exam product, reporting a suspected content
error is more valuable than a generic product comment.

Recommendation: add the content report flow described in LEARN-008 and use it
as the first support action after a miss or disputed explanation.

## Notifications and lifecycle

### LIFE-001, P2, confirmed: notification storage and routing retain GameNight names

Evidence:

- `AppSettings.swift:57-64` uses `gameNight` keys and reminder identifiers.
- `AppSettings.swift:186-218` has `scheduleGameNightReminder` and routes the
  notification using `AppNotification.gameNightPrepValue`.
- `AppRouter.swift:5-12` exposes `gameNightPrepSession` and
  `game-night-prep`.
- User-facing copy was renamed to Exam Warm-Up in the same implementation.

Impact: no current visible Mahj wording was found in the notification copy,
but stale identifiers make future source-app regressions likely and make
diagnostics harder.

Recommendation: migrate keys and identifiers with backward compatibility for
existing installations, then remove the legacy naming from active code.

### LIFE-002, P1 pending confirmation: cold-start and onboarding notification routing need a real test

Evidence:

- `AppDelegate` routes a notification response asynchronously at
  `AppRouter.swift:39-50`.
- `ElectricianApp` consumes shared router state only through view composition;
  there is no explicit `launchOptions` route handling at
  `Electrician/AppRouter.swift:30-37`.
- No test covers tapping the weekly reminder from a terminated app, from
  onboarding, or when the destination is already presented.

Impact: a notification can arrive before Home exists, during onboarding, or
while the user is in a sheet. The shared `pendingDestination` may be lost or
consumed at the wrong presentation level.

Recommendation: test foreground, background, terminated, onboarding, and
already-on-Home states. Define whether a pre-onboarding notification should
finish onboarding, queue the destination, or open a safe fallback.

## Accessibility, visual quality, and concurrency

### A11Y-001, P2, confirmed risk: gesture-first interaction lacks equivalent controls

This is the accessibility manifestation of LEARN-002. The app provides some
labels and hints, and `GivenChipView` combines condition labels, but a hint
about swiping is not an equivalent action. Add controls and test with
VoiceOver, Switch Control, and Voice Control.

### A11Y-002, P2, confirmed risk: large text and contrast claims are not backed by broad UI tests

`Theme.swift:33-42` documents intended contrast ratios and dynamic colors. That
is good design intent, but the test suite does not exercise:

- Dark mode across every screen.
- Accessibility content sizes.
- Bold Text.
- Reduce Motion.
- VoiceOver focus order and hints.
- Voice Control labels.
- Color-only meaning in answer states.
- iPad split view, 13-inch layout, and landscape.

Recommendation: add an accessibility matrix and screenshot baselines for the
highest-risk screens: onboarding, paywall, flashcard back, calculation steps,
field-tool result, and completion.

### A11Y-003, P2, confirmed: Swift 6 actor-isolation warnings remain in haptics and tests

Build warnings identify UIKit feedback generator initialization and calls in
`Theme.swift:171-195` from synchronous nonisolated functions. Tests also call
main-actor stores from nonisolated test setup methods.

Impact: the current build passes, but warning debt weakens the concurrency
contract and can become an error as compiler enforcement changes.

Recommendation: isolate haptic APIs on the main actor or use an explicitly
main-actor-owned service. Annotate or restructure test setup and store fixtures
so Swift 6 concurrency is warning-free.

### A11Y-004, P2, confirmed: screenshot capture does not fail on missing navigation

Evidence:

- `ElectricianScreenshots/ScreenshotTests.swift:8-24` sets
  `continueAfterFailure = true` and records missing elements rather than
  failing.
- `:43-82` attempts six captures but exports whatever attachments exist.
- `scripts/capture-screenshots.sh:28-60` explicitly exports partial results
  after a test failure.

Impact: the script is resilient for development, but a release process can
produce an incomplete screenshot directory without a hard minimum-count or
required-screen check.

Recommendation: keep diagnostic attachments, but fail the release command when
required screens are missing, dimensions are wrong, or an expected display
type has no captures.

### A11Y-005, P3, confirmed: source color names still contain Mahj residue

Evidence: `Theme.swift:44-59` has `tileIvory`, `tileEdge`, `crakRed`,
`bamGreen`, `dotBlue`, `jokerPurple`, `flowerPink`, and legacy aliases such as
`felt` and `cardBackground`. `StatsView.swift:184-187` still uses
`Theme.bamGreen`.

Impact: no current user-facing Mahj term was found in those color values, but
the names make the port visible to maintainers and invite accidental reuse of
domain-specific colors.

Recommendation: rename the colors to Electrician semantics after the design
system is stable. Add no compatibility alias unless a migration requires it.

## ASC and release readiness

### Current record identity

Read-only API and Chrome inspection confirmed:

- App name: `Electrician Exam Practice 2026`.
- Apple ID: `6804828725`.
- Bundle ID: `com.jackwallner.electrician`.
- SKU: `com.jackwallner.electrician`.
- Primary language: English (US).
- Public URL: `https://apps.apple.com/us/app/electrician-exam-practice-2026/id6804828725`.
- Category: Education, secondary category Reference.
- Age rating declaration: present.
- App state: `PREPARE_FOR_SUBMISSION`.

### ASC-001, P0, confirmed: no build is attached to version 1.0

`python3 scripts/asc-readiness.py` reported:

```text
Version: 1.0  state=PREPARE_FOR_SUBMISSION
Build attached (linkage id): NONE
   build 3: processing=VALID expired=False
   build 2: processing=VALID expired=False
```

There are valid processed builds available, but neither is linked to the draft
version. A version without an attached build cannot proceed through the normal
submission flow.

Recommendation: attach the intended processed build after verifying its build
number, Info.plist, entitlements, product configuration, and release notes.
Do not upload a new build just to change metadata that can be handled in ASC.

### ASC-002, P0, confirmed: listing screenshots are missing

The version-localization API returned no screenshot sets. Chrome showed the
iPhone 6.5-inch set at `0 of 10 Screenshots` and zero previews. The local
repository has the capture and compositor scripts, but no
`fastlane/screenshots/en-US/*.png` files were present.

The app supports iPhone and iPad through `project.yml:29-31`, while
`scripts/asc-upload-screenshots.py:25-31` expects 1320x2868 iPhone and
2064x2752 iPad PNGs. The capture script documents that a throwaway iPad
simulator is needed at `scripts/capture-screenshots.sh:10-12`.

Impact: the store listing has no visual explanation of the product and cannot
be considered submission-ready.

Recommendation:

1. Repair or replace the screenshot UI-test runtime path.
2. Capture the six planned user flows for iPhone and the approved iPad set.
3. Run the compositor and inspect every output for copy, dimensions, contrast,
   and claims.
4. Upload through `scripts/asc-upload-screenshots.py` only after the local set
   is complete.
5. Verify ASC screenshot counts after upload.

### ASC-003, P0, confirmed: App Privacy is not configured in ASC

Chrome showed App Privacy with no privacy policy URL and a questionnaire that
had not started. The API returned `privacyPolicyUrl: None` and
`privacyChoicesUrl: None` for the English US app-info localization.

The repository does contain a policy URL in
`fastlane/metadata/en-US/privacy_url.txt`, but local metadata does not populate
ASC automatically. The privacy page describes local practice history and
anonymous RevenueCat purchase information at `docs/privacy-policy.html:19-27`.

Recommendation: complete the ASC App Privacy questionnaire from the actual
data flow, then verify the public privacy URL resolves and matches the answer.
Do not guess the answers from the store description.

### ASC-004, P0, confirmed: App Review details are blank while sign-in is marked required

Chrome showed the Sign-in required checkbox selected while username and
password fields were blank. Contact name, phone, email, and review notes were
also blank. The API's `appStoreReviewDetail` relationship returned no object.

The app has no account or sign-in surface, so the correct review configuration
is likely to uncheck sign-in required. That needs confirmation in the ASC form.
If Apple review needs a tester path for any subscription behavior, provide
review notes and a safe test-store instruction without exposing production
credentials.

Recommendation: configure accurate review details, including contact data and
review notes, then re-read the page before adding the version for review. Do
not leave a checked sign-in requirement with blank credentials.

### ASC-005, P1, confirmed: accessibility questionnaire is not configured

Chrome showed the accessibility page in its initial “Showcase Your
Accessibility Support” state, with no selected support capabilities.

Recommendation: inspect the final app at runtime and answer only for support
that is actually implemented and tested. Do not select VoiceOver, Larger Text,
Dark Interface, Reduced Motion, or contrast support solely because the code
contains an intent or a color provider.

### ASC-006, P1, confirmed: release type is automatic after approval

The version's `releaseType` is `AFTER_APPROVAL`, and Chrome showed the automatic
release option selected.

Impact: once Apple approves the first build, the app can become available
without a final operational check of the listing, purchase products, support
site, and live review funnel.

Recommendation: choose manual release if the intended launch requires a final
go/no-go check. This is a commercial release choice and should not be inferred
from the code.

### ASC-007, P1, confirmed: new social-media age-rating questions are pending

Chrome displayed an ASC warning that new social media age-rating questions are
required by 2026-09-07 when submitting a new app or updating other answers.
The current date is 2026-08-24.

Recommendation: answer the new questions as part of the submission checklist,
even though the current age-rating declaration exists.

### ASC-008, P1, confirmed: App Information content rights was initially missing, now set through the safe CLI path

Before the setup command, Chrome and the API showed no content-rights
declaration. The repository's `scripts/asc-finish-submission.py` defines
`DOES_NOT_USE_THIRD_PARTY_CONTENT`, which matches the legal posture in
`NECTables.swift`.

That script was run once. The current API now reports:

```text
contentRightsDeclaration 'DOES_NOT_USE_THIRD_PARTY_CONTENT'
```

This is a draft metadata prerequisite, not a source-code fix.

### ASC-009, P1, confirmed: copyright and free base-app pricing were initially incomplete, now set through the safe CLI path

Before setup, version copyright was blank and the app price schedule existed
without a confirmed free base-app price. The same repository script now reports:

```text
copyright 'Jack Wallner'
app price schedule: present
```

The support URL was already present, so the script patched `0/1` localizations.
The source metadata remains the authority for the URL:
`https://jackwallner.com/electrician/support`.

### ASC-010, P1, confirmed: subscription and lifetime product records are largely complete

The API and Chrome inspection found:

- Subscription group `Pro`, state Prepare for Submission.
- Monthly product `com.jackwallner.electrician.monthly`, state
  `READY_TO_SUBMIT`.
- Yearly product `com.jackwallner.electrician.yearly`, state
  `READY_TO_SUBMIT`.
- Lifetime product `com.jackwallner.electrician.lifetime`, non-consumable,
  state `READY_TO_SUBMIT`.
- Product availability across configured territories.
- Review screenshots present for monthly, yearly, and lifetime products.
- One-week free-trial introductory-offer rows present for monthly and yearly
  products across 50 territory rows each.
- Localized product display names and descriptions.

`asc-readiness.py` reported:

```text
In-app purchases: 1
   com.jackwallner.electrician.lifetime: state=READY_TO_SUBMIT type=NON_CONSUMABLE
   sub com.jackwallner.electrician.monthly: state=READY_TO_SUBMIT
   sub com.jackwallner.electrician.yearly: state=READY_TO_SUBMIT
Price schedule: present
```

Do not rerun product-creation or product-screenshot scripts blindly. The
product setup appears complete enough that the remaining work is version
attachment, App Privacy, review information, listing screenshots, and final
submission sequencing.

### ASC-011, P1, confirmed: version metadata is partly populated but not complete

The English US version localization contains promotional text, description,
keywords, support URL, and marketing URL. The version still lacks:

- Attached build.
- Listing screenshots.
- App Review detail object.
- Correct review sign-in state and contact information.
- Privacy policy URL and App Privacy questionnaire.
- Accessibility questionnaire.
- A deliberate release-type decision.

Copyright was blank before the safe CLI pass and is now `Jack Wallner`.

### ASC-012, P1, confirmed: local and ASC privacy URLs are inconsistent in the app surfaces

The source has multiple privacy URLs:

- `PaywallView.swift:20-25` links to
  `https://jackwallner.github.io/electrician/privacy-policy`.
- Fastlane metadata points to
  `https://jackwallner.com/electrician/privacy-policy`.
- ASC App Privacy was blank at inspection time.

Impact: the paywall, store listing, and website can point at different hosts.
This creates avoidable trust and review friction.

Recommendation: choose the canonical public URL and use it consistently in the
app, metadata, ASC, and screenshot review. Verify redirects and HTTPS.

### ASC-013, P1, confirmed: review email and privacy contact are not aligned by repository metadata

The privacy page uses `jackwallner+e@gmail.com` at
`docs/privacy-policy.html:42`. The app feedback funnel uses the same address at
`ReviewPromptTracker.swift:25`. The ASC setup script has a fallback of
`jackwallner+m@gmail.com`, and there is no `fastlane/metadata/review_information`
directory in the repository.

Impact: App Review contact, support contact, and user feedback may route to
different aliases.

Recommendation: choose one operational contact, store it in the appropriate
private release configuration, and verify it in ASC. Do not put private review
credentials or contact details in source.

### ASC-014, P1, confirmed: screenshot UI test has no complete-set assertion

The capture script extracts `MARKETING_VERSION` from `project.yml` and passes
it as a test-runner environment variable. The test suppresses What's New by
launch argument, which is sensible. However, the test records missing elements
and keeps going, while the export script writes whatever attachments exist.

Recommendation: make the script report the exact expected screen names and
fail if any are absent. Verify both iPhone and iPad display-type counts before
upload.

### ASC-015, P1, confirmed: product setup and version setup are at different readiness levels

The product rows are Ready to Submit, while the version remains Prepare for
Submission with no build and no screenshots. The ASC UI makes this easy to
misread because the product pages and subscription group each show their own
Prepare for Submission or Add for Review state.

Recommendation: use one release checklist that treats the version as the
submission unit and verifies product rows, attached build, screenshots,
metadata, App Privacy, age rating, accessibility, review information, and
release type together.

## Recommended priority order

### P0, resolve before public submission

1. Decide the actual initial market: specialized calculation trainer versus
   broad journeyman/master exam preparation.
2. Add candidate license goal, edition, and jurisdiction context, or narrow the
   market promise until those concepts exist.
3. Build and publish a coverage matrix. Expand the high-value domains or stop
   claiming full licensing-exam coverage.
4. Verify onboarding navigation on a real device or reliable XCUITest.
5. Attach the intended processed build to ASC version 1.0.
6. Generate, inspect, and upload listing screenshots for the supported device
   classes.
7. Complete ASC App Privacy from the actual data flow.
8. Correct App Review sign-in state and provide review contact information and
   notes.

### P1, resolve before or immediately after first launch depending on scope

1. Make generated mistake patterns reviewable and align Fix My Mistakes copy.
2. Fix or relabel the free-user Fix My Mistakes tile.
3. Make trial language eligibility-aware.
4. Add paywall loading, unavailable, and retry states.
5. Validate Ohm's law extra inputs and disclose voltage-drop assumptions.
6. Render citations on flashcard backs and in accessibility labels.
7. Replace inherited deck, round, cards-down, and game-night language.
8. Add exam mode and a readiness model, or narrow the readiness promise.
9. Add empty-state handling for review and quick sessions.
10. Complete accessibility and notification cold-start testing.
11. Resolve Swift 6 actor-isolation warnings.

### P2, follow with the product expansion

1. Add topic, article, mistake-type, timed, and trend progress views.
2. Add accessible non-gesture alternatives and Dynamic Type coverage.
3. Split Study, Exam Practice, and Field Tools language.
4. Fix progress-bar semantics and make Code Minute date boundaries stable.
5. Add content issue reporting with citations and question IDs.
6. Offer calm professional celebration defaults with optional gamification.
7. Expand field tools and reference-table scope with edition-specific tests.
8. Rename legacy color and notification identifiers after behavior is stable.

## Suggested acceptance checklist for the next implementation cycle

### Product and content

- [ ] Candidate profile exists for license goal, state, edition, and optional
  exam date.
- [ ] Every current store claim maps to a real current feature.
- [ ] Coverage matrix identifies current, planned, and unsupported domains.
- [ ] Generated OCPD prompts separate conductor protection from load-sizing
  questions.
- [ ] Generated mistake patterns create targeted follow-up problems.
- [ ] All flashcard citations render and are accessible.
- [ ] Field tools state assumptions and reject conflicting input.
- [ ] A content-report path includes question ID, citation, and edition.

### UX and accessibility

- [ ] Onboarding advances in a real device/XCUITest run.
- [ ] The free onboarding path reaches Home without purchase.
- [ ] Trial CTA reflects eligibility.
- [ ] Paywall has loading, unavailable, retry, and restore states.
- [ ] Empty review and empty session states are explicit.
- [ ] Dynamic Type, VoiceOver, Voice Control, Reduce Motion, dark mode, and
  iPad layouts are tested.
- [ ] Flashcards have visible Reveal, Knew It, Again, and Undo actions.
- [ ] Professional mode can suppress distracting celebration effects.
- [ ] Build and test warnings are zero or documented with a deliberate reason.

### ASC and release

- [ ] Processed build attached to version 1.0.
- [ ] iPhone screenshot set present and visually reviewed.
- [ ] iPad screenshot set present if iPad remains enabled.
- [ ] Screenshot dimensions and count verified by the upload script.
- [ ] Privacy policy URL is canonical and live.
- [ ] App Privacy questionnaire is complete and matches the policy.
- [ ] Accessibility questionnaire is answered from tested support.
- [ ] Social-media age-rating questions are answered.
- [ ] Review sign-in requirement is accurate.
- [ ] Review contact and notes are populated through the private ASC path.
- [ ] Product availability, trial, prices, and review screenshots rechecked.
- [ ] Release type is an intentional launch decision.
- [ ] App Store links remain gated until the listing is live.
- [ ] Add for Review and submit actions happen only after the final checklist.

## Verification log

Commands and results:

```text
xcodebuild / XcodeBuildMCP build_run_sim
Result: succeeded, 6 main-actor isolation warnings in Theme.swift.

xcodebuild / XcodeBuildMCP test_sim
Result: 65 passed, 0 failed, 0 skipped, 14 test actor-isolation warnings.

python3 scripts/asc-readiness.py
Result: draft version 1.0, no build attached, valid builds 2 and 3 available,
age declaration present, three products/subscriptions ready to submit, price
schedule present.

python3 scripts/asc-finish-submission.py
Result: content rights set to DOES_NOT_USE_THIRD_PARTY_CONTENT, free USA base
price schedule set, copyright set to Jack Wallner, support URL already present,
no review-detail email change because no review-detail object exists.
```

Runtime and automation limitations:

- The first onboarding page rendered visually.
- XcodeBuildMCP and the independent subagent could not establish a reliable
  semantic tap traversal through onboarding.
- The dedicated screenshot UI test hit the debugger-version-store error.
- RevenueCat purchase behavior was not exercised because DEBUG and simulator
  deliberately avoid the production key.
- No browser form was saved because App Privacy, Accessibility, review data,
  and submission actions require deliberate ASC choices and action-time
  confirmation.

## Change boundary

No local app files were fixed. No Swift, `project.yml`, Xcode-generated
project, content, tests, screenshot assets, Fastlane metadata, or docs were
edited by this audit. The audit file is the only new repository artifact.

The ASC CLI setup command changed only draft account state already determined
by repository metadata and legal posture: content rights, free base pricing,
copyright, and a missing support URL if needed. It did not submit, release,
upload a build, upload listing screenshots, enter review credentials, or
change App Privacy.

The next action requiring a user decision is the ASC web form completion and
eventual submission sequence. That should happen only after the P0 product and
release blockers above are resolved or explicitly accepted.
