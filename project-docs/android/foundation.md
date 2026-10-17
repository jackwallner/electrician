# Android calculation foundation

The port compiles the original pure Swift models, content and generator files
with a small exporter. Candidate enums come directly from the pure prefix of
`CandidateProfile.swift`; the exporter does not substitute their definitions.
The iOS source is unchanged.

`python3 scripts/sync-android-content.py` writes:

- The six rooms, 125 authored items, article guide, primer, candidate choices,
  jurisdictions and numeric tables into main resources.
- 640 generated problems (all ten shapes), 1,944 ampacity results, shared-day
  challenge cases, random streams/draws and decimal-format references into test
  resources. These are expected results, not a finite replacement for native
  endless practice.
- A source-hash manifest. `--check` regenerates and compares the bytes.

The source's verified-through value remains 2023 and the table citation basis
remains 2023 NEC. Existing human-readable em dashes are normalized to commas in
the Android export, as required by the shared writing convention. No code-book
text or new edition claim was added.

Native models load the exported content and tables. The Kotlin core includes
the two seeded streams, matching Swift integer/Boolean/Double draws and answer
shuffles, and the eight field calculators. Ohm's law keeps contradictory input
warnings; voltage drop retains its assumptions and recommendation wording.

## Verification, 2026-10-17

Twenty-seven JUnit methods passed with zero failures, errors or skips in a JVM-only
Gradle 9.7.0 / Kotlin 2.4.20 harness using JDK 17 and this repository's source,
test and resource directories. These include all 1,944 Swift ampacity cases,
random draws, decimal rounding, authored-item identities/choices, the room paid
boundary and the original iOS field-tool examples. Export regeneration matched.

This verifies the foundation. It does not establish native generator parity,
working Android screens, billing or a release artifact. Those remain required
before the port is called build ready. No Android emulator ran on the Air.
