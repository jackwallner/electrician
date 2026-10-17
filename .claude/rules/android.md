---
paths:
  - "android/**"
  - "scripts/sync-android-content.py"
  - "scripts/android-export/**"
---

# Electrician Android

Package and namespace: `com.jackwallner.electrician`. Membership brand:
Electrician+, entitlement `electrician_pro`. Product IDs:
`com.jackwallner.electrician.monthly`, `com.jackwallner.electrician.yearly`,
`com.jackwallner.electrician.lifetime`. Reuse RevenueCat project `projfc676ce9`.

The Swift app is the spec. Run `python3 scripts/sync-android-content.py`
after source content/table/generator changes; `--check` validates existing
exports. Authored content and numeric tables live in the main resource export;
generator/calculation references live in test resources. Do not replace native
endless generators with the finite reference cases.

There are two different random streams. `SeededGenerator` takes a UInt64 seed
and uses xorshift12/25/27; `StableSeededGenerator` hashes a string with FNV-1a
and uses xorshift13/7/17. Swift integer/Boolean/closed-Double draws and shuffles
are reproduced by `SeededRandom.kt`. Numeric labels use C-compatible decimal
rounding, independently from Swift's away-from-zero integral rounding.

Three rooms are free (basics, conductors, installation), with some paid extra
drills. Endless practice, Code Minute, timed challenge and Fix My Mistakes are
paid. All eight Field Tools are free. Keep the twelve-stage onboarding and
candidate-specific study pace, edition and jurisdiction disclosures.

Keep the 2023 table basis and verified-through claim. No new 2026 coverage
claim without the book verification required by `nec-edition.md`.

Current scope is builds and testing, no Play Console or uploads. Emulator and
ADB work belongs only on the MacBook Pro at `192.168.4.25`. See the shared
`android-dev` skill and fleet-port reference for build/signing/test conventions.

Port status and evidence: [Android project notes](../../project-docs/android/README.md).
