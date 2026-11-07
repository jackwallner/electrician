# Project documentation

Developer notes and historical audits for this repository. The published site remains in the docs directory.

## Audits

- [NEC 2023 question-bank audit](audits/nec2023-question-bank-2026-10-22.md): item register, corrections, citations and cross-platform validation
- [State machine audit 2026-11-06](audits/state-machines-2026-11-06.md): 7 state bugs (2 proved by test, 5 code path), machines and transition tables
- [State machine audit review 2026-11-06](audits/state-machines-2026-11-06-review.md): independent review, 1 confirmed, 4 minor, 1 not a bug, 1 unverified; the audit's machines section is from another app
- [State machine audit fixes 2026-11-06](audits/state-machines-2026-11-06-fixes.md): 6 of 7 in-scope claims fixed (B1 to B5, B7), R1 backed out and held for Jack, regression tests and run ids
- [State machine fixes verification 2026-11-06](audits/state-machines-2026-11-06-verify.md): PASS, B1 to B5 and B7 work, B1/B2/B3/B5 fail with their fix reverted, B4 proved in the UI against the base, 212/212 on HEAD, one pre-existing Exam Target navigation bug found

- [aso827.md](audits/aso827.md): Electrician ASO Audit
- [audit824.md](audits/audit824.md): Electrician end-to-end product audit

## Android

- [Android port notes](android/README.md): native content, calculations and verification status
