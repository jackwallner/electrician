---
paths:
  - "Electrician/Views/OnboardingView.swift"
  - "Electrician/Views/PaywallView.swift"
  - "Electrician/Views/HomeView.swift"
  - "Electrician/Views/CandidateProfileView.swift"
  - "Electrician/Views/Components/StudyPaceCard.swift"
  - "Shared/Services/CandidateProfile.swift"
  - "Shared/Models/Jurisdictions.swift"
  - "Shared/Content/DrillLibrary.swift"
  - "ElectricianTests/CandidateProfileTests.swift"
  - "ElectricianTests/JurisdictionTests.swift"
  - "ElectricianTests/ContentValidityTests.swift"
  - "Shared/Content/HowToPlayContent.swift"
---

# Electrician: onboarding and the pitch

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Onboarding

Twelve steps: three value pages, seven setup questions, a plan recap, then the
trial. It is a **step machine, not a paged `TabView`**, and that is not a style
choice. A page view cannot refuse a swipe, so the old version let a candidate
swipe past a disabled Continue into the paywall with no jurisdiction set; a
`ScrollView` with a `TextField` inside a horizontal pager fought both the swipe
and the keyboard; and the footer reserved purchase chrome on every page. Driving
one `step` with `canAdvance` gating it fixes all three. Do not reintroduce a
pager here.

`Jurisdictions` (all 50 states, DC, PR, plus a "Not listed" sentinel) is what
makes **"I'm not sure" a usable answer**: it carries the commonly adopted NEC
edition, the licensing authority, the licence route (state vs. contractor-only
vs. local) and the exam vendor, and `CandidateProfile.resolvedEdition` falls
back to the state's edition while the answer is `.unsure`. Adoption and vendors
move, so every surface labels the value "commonly adopted", stamps
`Jurisdictions.reviewed`, and names the authority to confirm with. Re-check the
table against the NFPA adoption map when that date goes stale; it is a
suggestion the candidate ratifies, never an assertion.

**Persisted keys that must not be renamed.** `LicenseTrack.journeyman`/`.master`
and `CandidateEdition.nec2023`/`.different` keep their original raw values
because they are already written to `candidate.licenseTrack` and
`candidate.edition`; the added cases are new spellings only. The three original
`electrician.skillLevel` values (`new`, `apprentice`, `working`) are switched on
by Home's primer card and `HowToPlayContent.recommendedRoom`. `CandidateProfile`
resolves an ABSENT `candidate.edition` to this app's own edition, not to
`.unsure`, because installs that answered the old two-option picker chose from a
list whose default was that; onboarding overrides it to `.unsure` for a fresh
install only.

**The exam date sets a PACE, not just a countdown.** `StudyPace` (cram, sprint,
build, foundation, undated) is derived from `daysUntilExam`, never stored, and
it is what makes the app useful to a candidate sitting the exam tomorrow. The
date presets start at "Tomorrow" for that reason: the shortest option used to be
two weeks out, so the most motivated reader the app will ever get either lied to
the setup or skipped it. `suggestedDailyQuestions` branches on the pace rather
than dividing a fixed total by the days left, which used to tell someone with
one day to do 600 and someone with a year to do ten. `StudyPaceCard` renders the
plan in onboarding, in the recap, and on Home while `pace.isUrgent`.

Setup answers have to keep paying off after onboarding or the seven questions
are a toll booth: the exam date drives Home's countdown card, the pace and
`suggestedDailyQuestions`; the licence track titles Home's header; and
`focusAreas` orders the rooms on Home (an ordering, never a filter).

**The `Electrician+` pitch is an argument, not a feature list.** Both purchase
surfaces compute it from `DrillLibrary.freeItemCount` and the reader's own daily
target: the free rooms hold N questions, at M a day that is D days, and the exam
is further away than that. Those counters are computed from the library so the
claim cannot rot, and `testContentCountsAreQuotable` stops a zero reaching the
paywall. The benefit ORDER also follows the pace: "targets the errors you
repeat" is a nice-to-have in March and the entire product on Thursday night.
