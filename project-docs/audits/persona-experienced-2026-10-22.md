# Persona audit: experienced user repeating core tasks

Date: 2026-10-22. Persona: an experienced user repeating core tasks and
looking for accurate, efficient deeper features (a journeyman candidate five
weeks from the exam, a month into the app, Electrician+ unlocked).

Method: source walk of Home, Endless picker and run, Timed Challenge, Fix My
Mistakes, Field Tools, Your Progress and the completion screen, plus a
deterministic XCUITest observation pass on GitHub (`ExperiencedAuditUITests`,
`-DuoSeed` fixture, no RevenueCat, no network). Each finding is labelled
RUNTIME (seen in a screenshot or test note) or SOURCE (read from code, not yet
seen running). Frame rate and motion smoothness were not measured here.

Not repeated from earlier reports: `audit824.md` and `aso827.md` cover content
accuracy, store metadata and release readiness.

## Findings

### 1. Leaving a Timed Challenge with Back loses the run silently (Medium, SOURCE)
`PracticeRunView` hides the Finish button in `.timed` mode, but the navigation
back button is still there. `recordChallengeScore` and the completion screen
only run from `finish()`, so Back mid-run discards the score and any chance of
a new best, with no confirmation. A 90 second run with 12 correct answers is
gone on a mis-tap at the top left.
Repro: Home > Timed Challenge, answer a few, tap Back.
Fix: on Back during `.timed` with `attempted > 0`, confirm ("End challenge and
keep score?") or call `finish()` through `interactiveDismissDisabled` plus a
Finish button. Individual answers are still saved (records.record), only the
challenge best and completion are lost.

### 2. Field Tools forget every input on re-entry (Medium, SOURCE)
Every tool keeps its inputs in `@State` of a private view built inside a
`NavigationLink` closure, so popping back to the tool list and reopening resets
size, material, ambient, load and length to defaults. An experienced user
checking a feeder across several sizes, or returning to the same circuit after
looking at conduit fill, re-enters everything each time.
Fix: persist the last inputs per tool with `@AppStorage` or a small
`ToolInputStore`, and add a "Reset" toolbar item.

### 3. Numeric tools have no keyboard dismissal (Medium, SOURCE, verify in run)
Voltage drop and Ohm's law use `.decimalPad`, which has no return key, and the
screens have no keyboard toolbar "Done". In a `Form` the keyboard covers the
Result section, which is the thing the user is typing for. See the
`45-vdrop-keyboard` and `47-vdrop-after-swipe` captures.
Fix: `.toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { ... } } }`
and `.scrollDismissesKeyboard(.interactively)`; show the result in a sticky
header so it stays visible above the keyboard.

### 4. Your Progress identifies weak spots but cannot act on them (Medium, SOURCE)
"Work on Conductors & Ampacity", the BY ROOM bars and the BY CALCULATION skill
rows are plain text. Tapping the lowest skill does nothing. An experienced user
who has just seen "Conduit fill 58%" has to go Home > Endless > find the shape.
Only the mistake list has a single "Practice these traps now" link.
Fix: make each skill row a NavigationLink to `PracticeRunView(mode:
.endless(skill))` (skill rows have `PracticeSkill` ids); make the weak-spot card
open the weakest room.

### 5. No way to repeat the same Endless skill from the finish screen (Low, SOURCE)
`DrillCompleteView` has one button, Done, which pops to the picker. The core
repeated task is "another round of the same shape". Cost: Done, then tap the
same card again, every round. Fix: a secondary "Another round" button when the
drill is an endless skill.

### 6. Two taps per question, no fast mode (Low, SOURCE)
Each question is pick, then Next. The held answer with explanation is the
teaching beat and is deliberate, but an experienced user drilling a shape they
get right 90% of the time has no way to skip the hold. Suggestion: auto-advance
after a correct answer (setting, off by default), keeping the hold on a miss.

### 7. Training row hides Fix My Mistakes off screen (Low, RUNTIME/SOURCE)
The tiles scroll sideways at 128 pt wide; order is Endless, Code Minute, Exam
Warm-Up, Timed, Fix My Mistakes, so on a 6.1 inch phone the fifth tile (the
one an experienced user returns for) starts off screen with no scroll
indicator (`showsIndicators: false`). See `01-home-top` and `03-training-row-swiped`.
Fix: move Fix My Mistakes ahead of Exam Warm-Up when `fixableCount > 0`, or
show a trailing fade.

### 8. Calculator domain is narrow for a working electrician (Low, SOURCE)
Ampacity ambient caps at 55 C, current-carrying at 40, and conduit fill is
THHN in EMT only (stated up front on the list, which is good). Field Tools
shows the limit once on the list but not on each tool; someone who opens
Conduit fill directly sees a result with no hint that RMC/PVC are not covered.
Fix: one line under each tool's Result section repeating the coverage.

### 9. Endless run counter gives no session time or pace (Info, SOURCE)
The header shows "3 of 5 correct" and a streak chip at 3+, but no elapsed time
or per-question time, which an experienced user timing exam pace wants.

## Strengths worth keeping
- Ohm's law warns when typed values disagree instead of silently picking a pair.
- Every miss names the specific mistake (`missNote`), and the Stats list of
  "What keeps catching you" is the most useful screen for this persona.
- Endless and Timed answers are persisted per answer, so quitting Endless never
  loses progress.
