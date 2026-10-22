---
paths:
  - "Electrician/Views/HomeView.swift"
  - "Electrician/Utilities/UnfoldedSplit.swift"
  - "Electrician/Utilities/DuoScreenshotMode.swift"
  - "Electrician/Views/StatsView.swift"
  - "Electrician/Views/SettingsView.swift"
---

# Electrician: iPhone Duo (2026-10-21)

- Unfolded (regular width, at least 720 pt), `HomeView` puts its own
  NavigationStack (Home, rooms, drills, Field Tools) on the leading side of the
  fold and Your Progress (`StatsView`) on the trailing side, so the accuracy by
  room, the calculation skills and the outstanding mistakes a drill is building
  sit beside it and update as answers land. Fold edges come from
  `GeometryProxy.verticalFold()` (iOS 27.1 `reservedRegions(.division)`), else
  an even split (`UnfoldedSplit`, tested in `UnfoldedSplitTests`). Folded, every
  ordinary iPhone, and the unfolded Duo in portrait keep the single column.
  iPad splits evenly by the same rule, which replaced Home's old two-column
  regular layout there (the iPad store shots predate it). Same shape as
  Sheepshead, Cribbage, Bridge and Total Calories.
- Both panes get `horizontalSizeClass = .compact`, so each lays out as on a
  phone. Inside HomeView, `horizontalSizeClass` is a computed property that
  already reflects the pane; the window's class is `windowSizeClass`.
- Folding only moves frames. The progress pane mounts on the first unfold and
  is then hidden, never removed, and the Home stack is never rebuilt, so a
  drill in progress survives the fold. Do not wrap either pane in an `if`.
- While split: the stat chips are inert (the breakdown is already open), and
  Settings opens in the trailing pane instead of a sheet (`settingsSheet`
  binding; opening the Duo with the sheet up moves it to the pane).
- iOS 27.1 places the leading pane's toolbar (gear, back) either in a
  vertical side column toward the fold (content inset to about 357 pt) or in
  a top horizontal bar (content to about 441 pt), from one launch to the next.
  Both clear the fold and there is no tab bar to cover content, so it is not
  forced: `toolbarVerticalBehavior(.disabled)` added blank edge strips in Quit
  Zyn (`nicfree`). Take a store set's inner shots from one run so the panes match.
- Still system sheets, so centred across the fold: the paywall, What's New,
  feedback and the sheets raised from inside Settings. Onboarding is a
  full-width readable column shown before Home exists.

## Capture

DEBUG only (`DuoScreenshotMode.swift`). `-DuoSeed` seeds a journeyman
candidate in Colorado five weeks out, once per install (`duo.seeded`): a 7-day
streak, room rings, about 80% accuracy, five generated skills, three named
mistakes, three Code Minutes, best challenge 14, `Electrician+` local
override. No RevenueCat, no network. `-DuoTour -DuoRoutes a,b` walks Home
through routes on a timer (the capture job cannot tap); dwell is
`-DuoTourStep` folded and `-DuoTourStepRegular` unfolded, and the tour restarts
on fold/unfold. Routes: home, quick, room-<id>, drill-<id>, endless, minute,
warmup, timed, fix, tools, readiness, howto, stats, settings, paywall. The
`stats` route pushes Your Progress on the left too, so skip it for inner shots.
Pass `-electrician.suppressWhatsNew`.

```bash
gh-sim launch --device 'iPhone Duo' --wait 6 \
  --args "-DuoSeed -DuoTour -electrician.suppressWhatsNew -DuoTourFirst 1 -DuoTourStep 8 -DuoTourStepRegular 13 -DuoRoutes home,quick,room-calc-room" \
  --url noop://1 ... --url noop://8
```

Keep to about 7 routes and 8 urls per launch (10 minute launch cap). Native
video: record in a separate `gh-sim launch --record-seconds 20` with
`-DuoTourFirst 6 -DuoTourStep 4 -DuoTourStepRegular 4` and about 3 urls;
`gh-sim all` holds the recorder for the test step. Score with
`fleet-record60.py verify`.
