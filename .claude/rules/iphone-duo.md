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
- iOS 27.1 can move a `NavigationStack`'s toolbar (gear, back button) into a
  vertical bar on the stack's trailing edge, which in the leading pane put
  the back chevron beside the fold with the title still leading. Supervisor
  review rejected that (2026-10-21), so both panes set
  `toolbarVerticalBehavior(.disabled)` while split (`horizontalToolbarInPane`
  in `UnfoldedSplit.swift`): back button at the pane's leading edge, title
  centred, as on a phone and in Bridge's Auction Room. Folded keeps
  `.automatic`, so the outer display is unchanged.
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

Never pass `--url` (no `noop://` padding: the app registers no URL scheme and
`simctl openurl` on a custom scheme raises a confirmation sheet anyway). With
no urls, gh-sim takes one folded and one unfolded shot `--wait` seconds after
each launch, so give each launch the route it should show; the tour holds the
last route:

```bash
gh-sim launch --device 'iPhone Duo' --wait 10 \
  --args "-DuoSeed -DuoTour -electrician.suppressWhatsNew -DuoTourFirst 1 -DuoTourStep 8 -DuoTourStepRegular 8 -DuoRoutes drill-worked-examples"
```

One inner surface per job, so plan the set against the six-run cap. Native
video: `--record-seconds` must outlast `--wait` (30 with `--wait 20`, a fast
tour of about four routes, `-DuoTourFirst 3 -DuoTourStep 3
-DuoTourStepRegular 4`). When the wait outlasted the recording, the
watchdog's SIGINT and gh-sim's stop both hit the outer recorder, it never
finalized (0-byte mp4) and the inner recorder then failed with "A recording is
already in progress". Score with `fleet-record60.py verify`.
