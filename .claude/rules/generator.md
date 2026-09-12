---
paths:
  - "Shared/Content/CalcGenerator*.swift"
  - "Shared/Content/CalcContent.swift"
  - "Shared/Content/EndlessPractice.swift"
  - "Shared/Models/SeededGenerator.swift"
  - "Shared/Services/PracticeRecordStore.swift"
  - "Electrician/Views/Drills/CalcDrillView.swift"
  - "ElectricianTests/ContentValidityTests.swift"
  - "ElectricianTests/PracticeRecordStoreTests.swift"
  - "Shared/Models/Drill.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Electrician/Views/Drills/QuickSessionView.swift"
  - "Electrician/Views/StatsView.swift"
---

# Electrician: the generator

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

**The generator is the moat.** `CalcGenerator` emits ten problem shapes as
pure functions with exactly one correct answer, so the paid tier never runs
out. Unlike mahj's `RackGenerator` there is no ambiguity-rejection loop, because
a code calculation cannot be ambiguous. **Every distractor is the number you get
from one specific common mistake** (started the derate at 75°C, ignored
240.4(D), used 53% fill, counted grounds individually, sized a motor off the
nameplate, read Table 250.66 where 250.122 was wanted). Keep it that way: random
wrong numbers teach nothing.

The shapes are split across four files for readability and are one generator:
`CalcGenerator` (ampacity, OCPD, conduit fill, box fill, voltage drop),
`CalcGeneratorGrounding` (EGC and GEC sizing), `CalcGeneratorMotors` (motor
conductors, motor protection) and `CalcGeneratorLoads` (the dwelling service
calculation). The extension files must use `uniqueChoices` and `mistakeMap`
from the base file rather than rolling their own; the filtered
`mistakeMap(answerLabel:choices:_:)` overload exists because a shape with more
named mistakes than choice slots would otherwise map labels nobody can tap.
**Where a shape has more named mistakes than distractor slots, shuffle the
distractors from the problem's own stream.** A fixed order starves the last
ones, and a trap the generator never sets is one Fix My Mistakes can never
re-set: `testTargetedPracticeSetsTheRequestedTrap` fails the build for it.

Both generator suites iterate `PracticeSkill.allCases` through
`EndlessPractice.scenario`, not a hand-written list of makers, so adding a case
opts the new shape into every invariant automatically.

Those mistakes are **named**, not just implied: `CandidateMistake` holds the
catalogue and each generator attaches a `MistakePattern` to the distractor it
produces. Three things depend on it, so do not let a new shape ship without
one: a miss tells the reader what they actually did, `PracticeRecordStore`
tallies which errors they repeat, and Fix My Mistakes generates a NEW problem
that sets the same trap (a generated question is a one-off and can never come
back as itself). `MistakePattern.id` is persisted, so renaming one resets that
tally. Four choices is a hard invariant, enforced by test.

Generator parameter ranges are load-bearing, not decoration. The ampacity
shape draws ambient from 30°C up and current-carrying from 3 up **so the 75°C
termination cap sometimes binds**; with the old 35°C/4-conductor floors the
derated figure was always below the cap, so the app's own headline rule never
appeared as a wrong answer. If you narrow a range, check the mistake catalogue
still fires.
