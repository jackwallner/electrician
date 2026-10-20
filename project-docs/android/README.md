# Android port

- [Calculation foundation](foundation.md): exported Swift content/reference data and native core checks

## State, 2026-10-20 (shift-android-electrician-1-1792520482, jmbp)

Native Kotlin/Compose app in `android/`, built on the mahj Android shell and
rewired to the electrician domain:

- All ten generator shapes ported line for line. 640 Swift reference problems
  and four Code Minute dailies (including either side of Pacific midnight)
  reproduce byte for byte. Generator invariants and the authored calculation
  recomputations from iOS `ContentValidityTests` are ported.
- Twelve-step onboarding (three value pages, seven setup questions with a
  searchable 53-jurisdiction list, plan recap, trial), candidate profile under
  the iOS `candidate.*` keys, study pace and daily target from the exam date.
- Home with licence-titled header, exam countdown, urgent pace card, Get
  Started, training tiles (Field Tools free; Endless Practice, Code Minute,
  Exam Warm-Up, Timed Challenge and Fix My Mistakes paid), rooms ordered by
  focus area.
- Six rooms: flashcards, quizzes (article match exported as quiz) and the
  worked-calculation drill with numbered working. A wrong pick that one named
  mistake produces says which mistake it was, and the tally drives Fix My
  Mistakes, which mints new problems that set the same trap.
- Eight free Field Tools, Code Edition screen, Settings, paywall on the
  RevenueCat `electrician_pro` entitlement, Play in-app review at positive
  moments with no question first.

Not ported (iOS-only or deliberately deferred): alternate app icons, the
`FeedbackSheet` content-report form (Send Feedback opens the mail draft),
`StatsView`'s readiness breakdown beyond the shell's stats screen.

Evidence, commands and screenshots: `~/fleet-evidence/shift-android-electrician-1-1792520482/`
on jmbp (`SHIFT_CHECKPOINT.md` there has the current state). Release and Play
steps: `.claude/rules/android.md`.
