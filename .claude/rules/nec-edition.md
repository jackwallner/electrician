---
paths:
  - "Shared/Models/NEC*Tables.swift"
  - "Electrician/Views/EditionView.swift"
  - "Electrician/Views/Tools/*.swift"
  - "Electrician/Views/SettingsView.swift"
  - "Electrician/Views/HomeView.swift"
  - "ElectricianTests/ContentValidityTests.swift"
  - "Shared/Models/Jurisdictions.swift"
  - "Electrician/Views/Components/QuestionUI.swift"
  - "Electrician/Views/Drills/FlashcardDrillView.swift"
  - "Electrician/Views/CandidateProfileView.swift"
  - "Shared/Services/CandidateProfile.swift"
  - "Shared/Services/ContentReport.swift"
  - "ElectricianTests/JurisdictionTests.swift"
---

# Electrician: the NEC edition

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

**Values follow the 2023 cycle**, and the app now says WHY rather than just
which. The edition is a user-visible fact, not a comment: `NECTables.edition`
is rendered on every citation line, in Field Tools, in Settings, on the Home
footer, on the website and in the store description, and `EditionView` is the
screen that answers "why does an app called 2026 quote 2023?".

Three constants carry that answer and they are not interchangeable.
`NECTables.edition` is the citation basis. `stableSince` is the oldest cycle
whose values match. **`verifiedThrough` is a claim about work someone actually
did**, and every "covers your edition" string is derived from it, so raising it
without checking the tables page by page against that edition's book turns the
study aid into a trap. Lowering it is always safe.
`testCoverageClaimIsSupportable` enforces that it is never older than
`NECEdition.app`. **To claim the 2026 cycle: check the tables against a 2026
book, then set `verifiedThrough = .nec2026`.** Nothing else changes; the
coverage label, the Home footer, Field Tools and `EditionView` all recompute.

What genuinely moves between cycles is coverage, not the tables, and
`EditionView` lists both sides of that. When a table does move, update
`NECTables` (including `edition`) and let the content tests catch the authored
content that drifted.
