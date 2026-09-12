---
paths:
  - "Electrician/Utilities/Theme.swift"
  - "Electrician/Views/**/*.swift"
  - "Electrician/RootView.swift"
  - "Shared/Models/Drill.swift"
  - "ElectricianTests/ContentValidityTests.swift"
---

# Electrician: the design system

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Design system

The palette is **not** the cream-and-jade one this shell arrived with. Cream
paper and jade green are mahjong signals (tile faces, table felt). `Theme` now
reads as an electrician's vocabulary and the names are semantic, so a room
accent means something:

| Token | Colour | Used for |
|---|---|---|
| `voltage` | line-voltage blue | primary actions, `basics-room` |
| `copper` | copper | streaks and celebration, `conductors-room` |
| `brass` | brass | locks, best value, `Electrician+` |
| `conduit` | galvanized steel blue | `calc-room` |
| `ground` | equipment-grounding green | `grounding-room`, and nothing else |
| `highLeg` | delta high-leg orange | `install-room` |
| `service` | meter-can indigo | `loads-room` |

`Room.accents` is an explicit map with **no `default` case**. A room that
forgets to claim a colour used to inherit grounding green, which turned the one
semantic colour in the palette into a fallback; `testEveryRoomClaimsAnAccent`
now fails the build instead.

Surfaces are cool drawing paper over slate, `Theme.display` is heavy condensed
sans (panel-schedule lettering, not a members' club serif), `Theme.numeric` is
monospaced so amps and AWG read as instrument values, and `BlueprintGrid` /
`blueprintGrid()` rules the worksheet surfaces.

**Type is split by role, never by size** (`Theme`'s type section). Condensed
heavy is every TITLE at any size, system text is every sentence, monospace is
every number read as an instrument value. A card title and a screen title are
the same face; a card title and its subtitle are two faces. Titles come from
the five semantic tokens (`displayLarge`, `screenTitle`, `sectionTitle`,
`questionTitle`, `cardTitle`), which are built from `Font.TextStyle` so they
scale with Dynamic Type; the `CGFloat` overload of `Theme.display` is only for
the few places where the size IS the design. A title reaching for `.headline`
or `.title3` is what made the app look like it had picked up a new font.

**Motion has one vocabulary** (`Theme.Motion`) and every animation in the app
comes from it: `screen`, `card`, `reveal`, `meter`, `celebrate`, `flip`,
`fling`, `flash`, plus the `advance`/`retreat`/`riseIn` transitions. This is not
tidiness. A screen whose header, content and footer each animate on their own
curve does not read as one screen moving, it reads as three things arriving at
slightly different times, which is what the "sliding into place" wobble was.
Every token checks `Motion.reduced` in one place; `flourish` and `shake` return
`nil` under Reduce Motion so the caller SKIPS the effect rather than performing
a faster version of it, and `ConfettiBurst` is suppressed by it too.

**Every accent lightens in dark mode**, because most uses are ink and icons on
a dark surface. A filled button is the opposite case: the label is always
white, so a light accent lands near 2.3:1. `PrimaryCTAStyle` darkens its own
fill by 0.45 in dark mode, which is measured to hold the lightest accent above
5:1. Anything else that paints a solid accent behind white text must use
`Theme.voltageFill` / `Theme.copperFill`, not the base token. Adding a new
accent means adding its dark-mode check too.
