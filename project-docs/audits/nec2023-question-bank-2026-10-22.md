# NEC 2023 question-bank audit, 2026-10-22

Reviewed every item in the six-room iOS library and its Android export: 125 original items, plus the new EMT reference card (126 total). There are 87 selectable questions/self-tests and 39 reference-only cards. Reference cards have a written answer and citation, not selectable options. All 10 generated shapes are included. No NEC prose is reproduced here or added to the app.

The audit began in an isolated checkout from `13a9255`, then was rebased onto `f0b49bf` from origin/main, which contains the completed Android app scaffolding. All ten native Android generators received the same corrections as Swift. The original local checkout, including its unrelated uncommitted Android generator, profile and exporter files, was left byte-for-byte unchanged.

The reviewed answer contract is `TestFixtures/nec2023-bank-audit.json`. It is intentionally separate from the production keys and must not be regenerated to silence a failed test. The iOS test recomputes 5,000 generated questions across all skills; Android independently recomputes another 5,000 native generated questions and all 640 exported generated cases, in addition to the existing byte-for-byte Swift/native parity suite. Both check exactly one matching correct option, the selected key, equivalent duplicate values and a citation. Reference cards are checked against their reviewed written answer and citation. Table checks cover all stored copper/aluminum ampacities and motor FLC entries. Existing generator, mistake-targeting, arithmetic and Ohm's-law tests remain enabled.

## Corrected authored items

| Item id | Problem | Correction | NEC 2023 citation |
|---|---|---|---|
| `basics-shall` | The front named three phrases but asked for one undefined choice. | Ask specifically what permission means. | 90.5 |
| `basics-informational-note` | Implied exceeding any voltage-drop figure is acceptable. | Distinguish the general recommendation from application-specific mandatory limits. | 90.5(C) |
| `basics-readily-accessible` | Omitted the key exception and conflated equipment with wiring accessibility. | Keys alone do not disqualify ready access; identify the applicable definition. | Art. 100 |
| `basics-continuous-load` | Presented 125% as unconditional. | Identify the listed 100%-rated assembly exception. | Art. 100, 210.19(A), 210.20(A) |
| `basics-q-continuous` | Omitted the 100%-rated exception; explanation suggested compounding 125%. | State the ordinary-circuit assumption; check conductor and protection separately at 50 A. | 210.19(A), 210.20(A) |
| `article-emt` | Neither article-match item offered the actual EMT installation article. | Add the Article 358 reference used by the corrected options. | 358.30; Art. 358 |
| `plus-basics-90-2` | Utility ownership alone does not establish exclusion from NEC scope. | Specify exclusive utility control for service drops and metering. | 90.2 |
| `plus-basics-125-twice` | Missing assembly exception and misleading double-multiplier explanation. | State ordinary circuit; 37.5 A is checked separately for conductor and device. | 210.19(A), 210.20(A) |
| `plus-basics-accessible` | Ceiling height and access equipment were unstated. | Specify that a portable ladder is necessary. | Art. 100 |
| `plus-am-support` | Key and citation selected Chapter 9 fill tables. | Select 358 EMT, installation support under 358.30. | 358.30; Art. 358 |
| `cond-three-columns` | Implied equipment usually allows 75°C without establishing its listing. | Teach the 60°C default for small circuits and identified higher ratings. | 310.16, 110.14(C) |
| `cond-ninety-start` | Claimed conductors can never terminate at 90°C. | Limit the example to identified 75°C terminations. | 110.14(C), 310.15 |
| `cond-ambient` | Citation used the older ambient-table number. | Use 310.15(B)(1)(1) for the 2023 30°C-basis table. | 310.15(B)(1)(1) |
| `cond-bundling` | Omitted short-raceway exceptions and generalized nonlinear-neutral counting. | State the over-24-inch case and four-wire wye major-nonlinear-load condition. | 310.15(C)(1), 310.15(E) |
| `cond-240-4-d` | Said small-conductor caps apply regardless of every other rule. | Qualify ordinary circuits, derating, and specific 240.4(E)/(G) permissions. | 240.4(D) |
| `cond-next-size-up` | Excluded all portable-load receptacle circuits. | Use the actual more-than-one-receptacle branch-circuit condition and load check. | 240.4(B), 240.4(C), 240.6(A) |
| `cond-q-harmonic-neutral` | Dependent wording left system topology and nonlinear proportion unstated. | Specify four-wire three-phase wye, major nonlinear load, and a long raceway. | 310.15(E)(3) |
| `cond-q-nextsize` | Required load ampacity was mistaken for installed conductor ampacity. | Give 88 A allowable ampacity, 80 A load, and qualifying conditions; maximum is 90 A. | 240.4(B), 240.6(A) |
| `plus-cond-both-factors` | Ambient-table reference was not the precise 2023 number. | Use 310.15(B)(1)(1). | 310.15(B)(1)(1), 310.15(C)(1) |
| `plus-cond-10awg-alum` | Unqualified maximum admitted special motor and other permissions. | Restrict to ordinary general-purpose protection with no adjustment or special permission. | 240.4(D) |
| `install-card-depth` | Suggested measuring every clearance from internal live parts. | Measure from exposed parts or the enclosure front as applicable. | 110.26(A)(1) |
| `install-card-width` | No equipment width was supplied; either option could be required. | Specify a 24-inch panel and ask its minimum working-space width: 30 inches. | 110.26(A)(2) |
| `install-card-height` | Presented ordinary headroom as universal and conflated dedicated space. | Name the existing-dwelling exception and separate the two clearances. | 110.26(A)(3), 110.26(E) |
| `install-card-entrances` | Omitted device scope and allowed single-entrance alternatives. | State the general trigger and the unobstructed-egress/double-depth alternatives. | 110.26(C)(2) |
| `install-card-burial-direct` | Residential 120 V GFCI exception could change the answer. | Specify 240 V, no traffic or concrete-cover row; retain 24 inches. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-card-burial-residential` | Burial-table citation omitted the 2023 subsection. | Use Table 300.5(A), with the 2020 table number noted. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-card-burial-traffic` | Claimed every driveway and every wiring method requires 24 inches. | Limit 24 inches to the general traffic row; explain dwelling-only driveway exceptions. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-card-support-emt` | Question asked securing and support but offered only interval values; citation covered securing only. | Ask the general maximum support interval and cite both securing and support provisions. | 358.30(A), (B) |
| `install-card-support-nm` | Used obsolete nonmetallic-box subsection 314.17(C). | Use 314.17(B)(2), applicable in both 2020 and 2023. | 334.30, 314.17(B)(2) |
| `install-quiz-cover-rmc` | Burial-table reference omitted the 2023 subsection. | Use Table 300.5(A), retain the ordinary-location 6-inch result. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-quiz-cover-pvc` | Burial-table reference omitted the 2023 subsection. | Use Table 300.5(A), retain the ordinary-location 18-inch result. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-quiz-support-nm` | Clamped and unclamped boxes give different securing limits. | Specify an internal clamp and ask maximum distances: 12 inches and 4.5 feet. | 334.30 |
| `install-quiz-wall-space` | Incorrectly counted fixed cabinets and demanded a dedicated receptacle per section. | State uninterrupted qualifying wall space and the actual 2-foot threshold. | 210.52(A)(2) |
| `install-quiz-bends` | Two 45-degree offsets normally mean four 45-degree bends. | Specify exactly two 45-degree bends; 270 degrees used leaves 90 degrees. | 358.26 |
| `install-quiz-continuous` | Keyed 55 A as a standard protective-device rating. | 44 × 1.25 = 55 A calculated minimum; select the 60 A standard breaker, option 4. | 210.20(A), Table 240.6(A) |
| `install-quiz-dedicated-space` | Structural-ceiling boundary was unstated. | Place the pipe below the structural ceiling inside the dedicated column. | 110.26(E)(1) |
| `install-match-support` | Key selected Article 300, which does not contain EMT strap spacing. | Select 358 EMT, specifically 358.30. | 358.30; Art. 358 |
| `calc-ampacity-1` | Ambient-table reference was imprecise for 2023. | Use 310.15(B)(1)(1); retain 52.2 A. | 310.16, 310.15(B)(1)(1), 310.15(C)(1), 110.14(C) |
| `calc-boxfill-1` | Ground size, entering conductors and yoke size were unstated. | Specify all as 12 AWG, entering conductors and a single-gang yoke; retain 22.5 in³. | 314.16(B) |
| `calc-vdrop-1` | Temperature/resistance model and rounding were unstated. | Specify K = 12.9, resistive approximation, one-way distance and 0.1 V rounding; retain 4.0 V. | 210.19(A) Informational Note, Ch. 9 Table 8 |
| `load-card-demand-bands` | The method was unstated. | Specify standard dwelling calculation. | Table 220.45 (Table 220.42 in 2020) |
| `load-card-range` | Optional and standard methods use different range inputs. | Specify standard method and column C: 8 kW. | Table 220.55 |
| `load-card-dryer` | Optional method uses nameplate rather than the standard-method minimum. | Specify standard method: one electric dryer at 5000 VA minimum. | 220.54 |
| `load-card-noncoincident` | Heat and cooling were assumed unable to run together. | Specify standard method and an interlock. | 220.60 |
| `load-card-service-minimum` | Dwelling type and whether the requested rating was a minimum were unstated. | Specify one-family dwelling and minimum service-disconnect rating. | 230.79(C) |
| `load-quiz-demand` | Demand factor depends on method and occupancy. | Specify standard dwelling method; retain 5800 VA. | Table 220.45 (Table 220.42 in 2020) |
| `load-quiz-range-over-12` | The method and table column were unstated. | Specify standard method, column C; retain 9.6 kW. | Table 220.55 |
| `load-quiz-noncoincident` | No interlock; explanation incorrectly attributed 6.5 kW to 65% of heating. | Specify interlocked standard-method HVAC; 6.5 kW is the arithmetic average, not a code demand. | 220.60 |
| `load-quiz-neutral` | A permitted reduction was described as a mandatory unique contribution. | Ask the minimum using the permitted 70% reduction on a 120/240 V range demand: 5600 VA. | 220.61(B) |
| `load-quiz-where-circuits-go` | Claimed a roughly 2900 VA error for two small-appliance circuits. | The excess is 3000 × (1 - 0.35) = 1950 VA. | 220.52, Table 220.45 |
| `load-calc-standard-dwelling` | Missing circuit counts, HVAC concurrency and largest-motor allowance. | Add the disclosed 900 VA retained motor allowance: 35,050 VA, 146.0 A; minimum remains 150 A. | 220.41, Table 220.45, 220.50, 430.24, 220.52, 220.53, 220.54, Table 220.55, 220.60, 240.6(A) |
| `load-calc-optional-dwelling` | Supply, circuit counts and number/type of heat units were missing. | Specify 120/240 V, two small-appliance circuits, one laundry and fewer than four resistance-heat units; retain 125 A. | 220.82, 220.82(B), 220.82(C), 240.6(A) |
| `load-calc-three-ranges` | Three-phase loading could change the range count used in the demand table. | Specify single-phase feeder, standard method, column C and Note 1; retain 15.4 kW. | Table 220.55 |
| `gnd-grounded-vs-grounding` | Equated every grounded conductor with a neutral and every EGC with zero current. | Distinguish intentional grounding, normal load current and the equipment fault path. | Art. 100, 250.24 |
| `gnd-rod-ceiling` | Gave a false physical-current explanation for the 6 AWG permission. | Explain the sizing permission for an electrode-only connection and actual ground-ring size. | 250.66(A), 250.66(B), 250.66(C) |
| `gnd-neutral-bond` | Claimed exactly one physical bond anywhere in the system. | Describe the ordinary load-side prohibition and separate supply-side/derived-system rules. | 250.24(A)(5), 250.30 |
| `gnd-q-egc-200` | Conductor increases and parallel raceways could change the EGC requirement. | Ask the ordinary Table 250.122 minimum with neither condition: 6 AWG copper. | 250.122 |
| `gnd-q-rod-cap` | Service amperes alone did not establish the table GEC, and sole-rod wording implied compliance. | Supply the 1/0 AWG table result and an electrode-only connection; permission reduces it to 6 AWG. | 250.66(A) |
| `mtr-table-not-nameplate` | Denied the specific motor exceptions to table FLC sizing. | Scope the rule to ordinary single-speed motors; explain exceptions. | 430.6(A)(1), 430.32 |
| `mtr-125` | Claimed every motor is a continuous load. | Apply 430.22(A) to single continuous-duty motors; identify other duty provisions. | 430.22 |
| `mtr-q-conductor` | Explanation generalized the continuous-duty multiplier to all motors. | Scope the 35 A result to the stated ordinary single continuous-duty motor. | 430.22 |
| `mtr-q-overload-source` | Did not specify the separate current-responsive overload arrangement. | Specify 430.32(A)(1), continuous duty and over 1 hp. | 430.32 |
| `mtr-q-service-factor` | Maximum setting could include starting-related increases; standard setting was undefined. | Ask the initial 430.32(A)(1) maximum before those allowances: 42.5 A. | 430.32(A)(1) |

## Generated items and shared numerical rules

| Item id or family | Problem | Correction | NEC 2023 citation |
|---|---|---|---|
| `gen-ampacity-*` | Raceway exceptions were unstated; ambient-table citation was old. | Specify dry location and raceway longer than 24 inches; cite the 30°C-basis table. | 310.16; 310.15(B)(1)(1); 310.15(C)(1); 110.14(C) |
| `gen-ocpd-*` | No numerical key error found within the stated ordinary-circuit assumptions. | Retain the explicit no-next-size-up condition and small-conductor limits. | 240.4(D); 240.6(A); 110.14(C) |
| `gen-conduitfill-*` | A short nipple can use different fill limits. | Specify a run longer than 24 inches and Table 5 areas. | Ch. 9 Table 1, Note 4; Tables 4 and 5 |
| `gen-boxfill-*` and box-fill calculators | Claimed any number of grounds takes one allowance. | One allowance through four entering grounds; add 0.25 per additional entering ground/jumper. Exercise 5, 6 and 9 grounds too. | 314.16(B)(5) |
| `gen-vdrop-*` | K, resistance model and rounding were unstated. | Specify copper 12.9/aluminum 21.2, one-way distance, resistive approximation and 0.1 V rounding. | 210.19(A) informational note; Ch. 9 Table 8 |
| `gen-egcSizing-*` | Implied conductor size never affects wire EGC sizing. | State ordinary nonparallel, non-increased conductors; explain proportional increase rule. | 250.122(A), (B) |
| `gen-gecSizing-*` | Assumed every ground ring is 2 AWG; allowed ordinary parallel service conductors below 1/0. | State actual 2 AWG ring, electrode-only connection and physical protection; prohibit the undersized ordinary parallel cases. | 250.66(A)-(C); 250.64(B); 310.10(G) |
| `gen-motorConductor-*` | Table-versus-nameplate rule was stated without motor-type scope. | Specify ordinary single-speed continuous-duty motors of usual speed and torque. | 430.6(A)(1); 430.22(A); Tables 430.248 and 430.250 |
| `gen-motorProtection-*` | Generic standard-rating selection included instantaneous-trip devices; fuse-only ratings were missing; references used 2020 numbering. | Generate fuses and nonadjustable inverse-time breakers, exclude Class CC from the 175% fuse case, include 1/3/6/601 A fuse ratings and the 15 A small-motor breaker permission. Exclude increased starting-current allowances. | Table 430.52(C)(1); 430.52(C)(1)(a); 240.6(A) |
| `gen-dwellingLoad-*` | Missing 25% largest retained motor allowance and concurrency assumptions. | State circuit counts, column C for the range, HVAC interlock and retained motor; add the motor allowance. Explicit column C avoids the alternative Note 3 demand permitted for an 8 kW range. | 220.50; 430.24; Table 220.55 Note 3; 220.52-.60 |
| `NECTables.standardOCPD` | Omitted the 10 A standard rating added in 2023. | Add 10 A and remove the claim that every shipped value is unchanged from 2020. | Table 240.6(A) |
| `NECTables.ambientCorrection` | Returned 1.0 for every ambient below 26°C and rejected valid rows above 60°C. | Restore cold-weather correction and valid 61-85°C rows, with unavailable columns remaining nil. | Table 310.15(B)(1)(1) |

The edition-reference screen also identifies the 2023 ambient-table number and the added 10 A breaker rating, and no longer labels every listed table unchanged between cycles.

The basic formulas checked are V = IR and P = VI for DC/resistive quantities; voltage-drop estimates use VD = 2KIL/CM for single phase and 1.732KIL/CM for balanced three phase. These estimates do not silently substitute for reactive AC calculations. Motor FLC numbers are read from the code tables, not reconstructed from horsepower divided by voltage.

## 2020 editions and adoption

The bank's answer basis is NEC 2023. State adoption and the edition named by an examination board are separate facts. The app no longer claims every shipped table is identical across 2020 and 2023. `verifiedThrough` remains 2023.

- The 2020 general-lighting references are 220.12 and Table 220.42; 2023 uses 220.41 and Table 220.45.
- Ambient correction uses Table 310.15(B)(1) in 2020 and Table 310.15(B)(1)(1) in 2023.
- Burial cover is Table 300.5 in 2020 and Table 300.5(A) in 2023.
- Motor protection uses Table 430.52 and 430.52(C)(1), Exception 1 in 2020; 2023 uses Table 430.52(C)(1) and 430.52(C)(1)(a).
- A 10 A inverse-time breaker became a standard rating in 2023. The added quarter allowance beyond four entering grounds already applies in 2020. The obsolete 314.17(C) cable-clamp citation predates both audited editions; use 314.17(B)(2) in both.

Confirmed current examples of continued 2020 adoption are [North Carolina's current-code listing](https://www.ncosfm.gov/codes/codes-current-and-past) and [Florida's current state-adopted code listing](https://panamacity.gov/836/Building-Process). North Carolina's residential/commercial applicability and local amendments must be checked separately. This is not a newly verified 50-state adoption directory; the August 2026 jurisdiction suggestions in the app were not silently re-certified.

## Sources and interpretation

- [NFPA NEC 2023 free-access publication](https://link.nfpa.org/free-access/publications/70/2023), the edition basis and lookup destination.
- [NFPA CMP-6, 2023-cycle second-draft record](https://docinfofiles.nfpa.org/files/AboutTheCodes/70/70_A2022_NEC_P06_SD_MeetingAgenda_10_21.pdf), ampacity/correction table facts and numbering.
- [NFPA CMP-2, 2023-cycle second revisions](https://www.nfpa.org/api/files?path=%2Ffiles%2FAboutTheCodes%2F70%2F70_A2022_NEC_P02_SD_SRStatements.pdf), load-calculation tables and references.
- [NFPA CMP-11, 2023-cycle second revisions](https://www.nfpa.org/api/files?path=%2Ffiles%2FAboutTheCodes%2F70%2F70_A2022_NEC_P11_SD_SRStatements.pdf), motor FLC tables.
- [NFPA CMP-11 record containing existing 2023 motor-protection text](https://docinfofiles.nfpa.org/files/AboutTheCodes/70/70_A2025_NEC_P11_FD_PIResponses.pdf), motor-protection ratings and 2023 subsection references. Proposed later-edition changes are not treated as adopted 2023 rules.
- [NFPA record explicitly identifying existing 2023 box-fill wording](https://docinfofiles.nfpa.org/files/AboutTheCodes/70/70_A2025_NEC_P08_FD_PIResponses.pdf), ground allowances and per-conductor volumes. The proposed four-allowance device change is not used.
- [NFPA CMP-9 cable-entry record](https://docinfofiles.nfpa.org/files/AboutTheCodes/70/70_A2022_NEC_P09_FD_PIResponses.pdf), confirming 314.17(B)(2) already existed in 2020.
- [NFPA Article 100 ready-access definition record](https://docinfofiles.nfpa.org/files/AboutTheCodes/70/70_A2025_NEC_P01_FD_PrelimFR.pdf), retaining the existing exception for keys.
- [Eaton's licensed NEC 2023 change guide](https://www.eaton.com/content/dam/eaton/products/electrical-circuit-protection/fuses/code-updates/bus-ele-br-11318-2023-NEC-code-changes.pdf), including the new 10 A standard rating.
- [SRNS/EFCOG technical evaluation of NEC 2020 versus 2023](https://efcog.org/wp-content/uploads/Wgs/Safety%20Working%20Group/Best%20Practices/Worker%20Safety%20-%20Health/Electrical%20Safety/BP260%20Adoption%20of%20NFPA%2070%20National%20Electrical%20Code%202023%20in%20place%20of%20NFPA%2070%202020%20Crosswalk.pdf), licensed side-by-side edition references, including Table 300.5(A).

NFPA's browser-only free reader was not machine-readable in this session. The audit uses the primary table/revision records and licensed comparisons above; it does not represent a page-by-page review of an entire NEC book or a jurisdiction-specific professional approval. Normative scope and question ambiguity were reviewed manually. Automated tests validate the independently reviewed answer contract and arithmetic; a range/uniqueness test alone cannot prove the meaning of natural-language alternatives.

## Complete authored-item register

Every original id appears below. “Verified” means retained after review; “Corrected” points to a finding above. The answer shown is the selected option, or the written answer for an ungraded reference card.

| Item id | Result | Reviewed answer | Code citation |
|---|---|---|---|
| `basics-chapters` | Verified | Chapters 1-4 are general, 5-7 are exceptions | 90.3 |
| `basics-shall` | Corrected | Allowed but not required | 90.5 |
| `basics-informational-note` | Corrected | Explanatory only | 90.5(C) |
| `basics-readily-accessible` | Corrected | One may need tools, the other may not | Art. 100 |
| `basics-continuous-load` | Corrected | Maximum current for 3 hours or more | Art. 100, 210.19(A), 210.20(A) |
| `basics-ampacity-def` | Verified | Current a conductor can carry continuously without exceeding its temperature rating | Art. 100, 310.14 |
| `basics-q-chapter9` | Verified | Chapter 9 tables | Ch. 9 Tables 1, 4, 5 |
| `basics-q-special` | Verified | The Chapter 5 rule | 90.3 |
| `basics-q-continuous` | Corrected | 50 A | 210.19(A), 210.20(A) |
| `basics-q-definitions` | Verified | Article 100 | Art. 100, Art. 312 |
| `article-definitions` | Verified | When to go here | Art. 100 |
| `article-generalRequirements` | Verified | When to go here | Art. 110 |
| `article-branchCircuits` | Verified | When to go here | Art. 210 |
| `article-loadCalculations` | Verified | When to go here | Art. 220 |
| `article-overcurrent` | Verified | When to go here | Art. 240 |
| `article-grounding` | Verified | When to go here | Art. 250 |
| `article-services` | Verified | When to go here | Art. 230 |
| `article-wiringMethods` | Verified | When to go here | Art. 300 |
| `article-conductors` | Verified | When to go here | Art. 310 |
| `article-boxes` | Verified | When to go here | Art. 314 |
| `article-raceways` | Verified | When to go here | Ch. 9 |
| `article-motors` | Verified | When to go here | Art. 430 |
| `article-emt` | Added | When to go here | Art. 358 |
| `am-receptacle-spacing` | Verified | 210 Branch Ckts | Art. 210 |
| `am-derate-attic` | Verified | 310 Conductors | Art. 310 |
| `am-emt-size` | Verified | Ch. 9 Fill | Ch. 9 |
| `am-box-volume` | Verified | 314 Boxes | Art. 314 |
| `am-electrode` | Verified | 250 Grounding | Art. 250 |
| `am-motor-conductor` | Verified | 430 Motors | Art. 430 |
| `am-dwelling-service` | Verified | 220 Load Calc | Art. 220 |
| `am-breaker-standard` | Verified | 240 Overcurrent | Art. 240 |
| `am-readily-accessible` | Verified | 100 Definitions | Art. 100 |
| `am-egc-size` | Verified | 250 Grounding | Art. 250 |
| `plus-basics-annexc` | Verified | Only when every conductor is the same size and insulation | Annex C, Ch. 9 Table 1 |
| `plus-basics-90-2` | Corrected | Service drops and metering under the exclusive control of an electric utility | 90.2 |
| `plus-basics-125-twice` | Corrected | Both the conductor ampacity and the overcurrent device | 210.19(A), 210.20(A) |
| `plus-basics-accessible` | Corrected | Accessible but not readily accessible | Art. 100 |
| `plus-am-gfci` | Verified | 210 Branch Ckts | Art. 210 |
| `plus-am-tap` | Verified | 240 Overcurrent | Art. 240 |
| `plus-am-support` | Corrected | 358 EMT | Art. 358 |
| `cond-three-columns` | Corrected | Insulation sets the starting column; terminations limit the result | 310.16, 110.14(C) |
| `cond-ninety-start` | Corrected | Start derating there | 110.14(C), 310.15 |
| `cond-ambient` | Corrected | Hotter air, smaller number | 310.15(B)(1)(1) |
| `cond-bundling` | Corrected | Four or more current-carrying conductors adjust down | 310.15(C)(1), 310.15(E) |
| `cond-240-4-d` | Corrected | Normally 15, 20 and 30 amps for general-purpose protection | 240.4(D) |
| `cond-next-size-up` | Corrected | Only when the calculation lands between standard sizes | 240.4(B), 240.4(C), 240.6(A) |
| `cond-q-terminal` | Verified | 75°C | 110.14(C) |
| `cond-q-14awg` | Verified | 15 A | 240.4(D), 310.16 |
| `cond-q-egc-count` | Verified | 3 | 310.15(E), 310.15(C)(1) |
| `cond-q-harmonic-neutral` | Corrected | 4 | 310.15(E)(3) |
| `cond-q-nextsize` | Corrected | 90 A | 240.4(B), 240.6(A) |
| `plus-cond-both-factors` | Corrected | Multiply both against the same starting ampacity | 310.15(B)(1)(1), 310.15(C)(1) |
| `plus-cond-parallel` | Verified | 1/0 AWG | 310.10(G) |
| `plus-cond-neutral-count` | Verified | 2 | 310.15(E)(1) |
| `plus-cond-10awg-alum` | Corrected | 25 A | 240.4(D) |
| `install-card-depth` | Corrected | 3 ft | 110.26(A)(1) |
| `install-card-width` | Corrected | 30 in. | 110.26(A)(2) |
| `install-card-height` | Corrected | Six and a half feet, or the height of the equipment where it is taller | 110.26(A)(3), 110.26(E) |
| `install-card-entrances` | Corrected | At 1200 amperes or more, and over six feet wide | 110.26(C)(2) |
| `install-card-dedicated` | Verified | The footprint of the equipment, from the floor to six feet above it or to the structural ceiling, whichever is lower | 110.26(E)(1) |
| `install-card-burial-direct` | Corrected | 24 in. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-card-burial-residential` | Corrected | Residential branch circuit, 120 volts or less, 20 amperes or less, and GFCI protected | Table 300.5(A) (Table 300.5 in 2020) |
| `install-card-burial-traffic` | Corrected | 24 in. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-card-support-emt` | Corrected | 10 ft | 358.30(A), (B) |
| `install-card-support-nm` | Corrected | Within twelve inches of a box, then every four and a half feet | 334.30, 314.17(B)(2) |
| `install-card-bends` | Verified | 360° | 358.26, 344.26, 352.26 |
| `install-quiz-depth-480` | Verified | 3.5 ft | 110.26(A)(1) |
| `install-quiz-depth-house` | Verified | 3 ft | 110.26(A)(1) |
| `install-quiz-width-equipment` | Verified | 42 in. | 110.26(A)(2) |
| `install-quiz-cover-rmc` | Corrected | 6 in. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-quiz-cover-pvc` | Corrected | 18 in. | Table 300.5(A) (Table 300.5 in 2020) |
| `install-quiz-support-nm` | Corrected | Within 12 in. of the box, then every 4.5 ft | 334.30 |
| `install-quiz-receptacle-spacing` | Verified | 6 ft | 210.52(A)(1) |
| `install-quiz-wall-space` | Corrected | 2 ft | 210.52(A)(2) |
| `install-quiz-counter-spacing` | Verified | 24 in. | 210.52(C)(1) |
| `install-quiz-bends` | Corrected | 90° | 358.26 |
| `install-quiz-continuous` | Corrected | 60 A | 210.20(A), Table 240.6(A) |
| `install-quiz-dedicated-space` | Corrected | No, it is in the dedicated space above the equipment | 110.26(E)(1) |
| `install-match-workspace` | Verified | 110 General | Art. 110 |
| `install-match-cover` | Verified | 300 Wiring | Art. 300 |
| `install-match-service-disconnect` | Verified | 230 Services | Art. 230 |
| `install-match-receptacle-spacing` | Verified | 210 Branch Ckts | Art. 210 |
| `install-match-support` | Corrected | 358 EMT | Art. 358 |
| `install-match-readily-accessible` | Verified | 100 Definitions | Art. 100 |
| `calc-ampacity-1` | Corrected | 52.2 A | 310.16, 310.15(B)(1)(1), 310.15(C)(1), 110.14(C) |
| `calc-ocpd-1` | Verified | 20 A | 310.16, 240.4(D), 240.6(A) |
| `calc-conduitfill-1` | Verified | 3/4" | Ch. 9 Table 1, Table 4, Table 5 |
| `calc-boxfill-1` | Corrected | 22.5 in³ | 314.16(B) |
| `calc-vdrop-1` | Corrected | 4.0 V | 210.19(A) Informational Note, Ch. 9 Table 8 |
| `load-card-va-per-sqft` | Verified | 3 VA/ft² | 220.41 (220.12 in 2020) |
| `load-card-small-appliance` | Verified | 1500 VA for each small-appliance circuit, and 1500 VA for the laundry circuit | 220.52 |
| `load-card-demand-bands` | Corrected | The first 3000 VA at 100%, the rest up to 120,000 VA at 35% | Table 220.45 (Table 220.42 in 2020) |
| `load-card-range` | Corrected | 8 kW | Table 220.55 |
| `load-card-dryer` | Corrected | 5000 VA | 220.54 |
| `load-card-fastened` | Verified | When there are four or more of them on the same feeder or service | 220.53 |
| `load-card-noncoincident` | Corrected | 12 kW | 220.60 |
| `load-card-optional` | Verified | It piles every general load together and takes the first 10 kVA at 100% and the rest at 40% | 220.82 |
| `load-card-service-minimum` | Corrected | 100 A | 230.79(C) |
| `load-card-neutral` | Verified | Anything that is purely line to line | 220.61 |
| `load-quiz-general-lighting` | Verified | 5400 VA | 220.41 (220.12 in 2020) |
| `load-quiz-demand` | Corrected | 5800 VA | Table 220.45 (Table 220.42 in 2020) |
| `load-quiz-range-over-12` | Corrected | 9.6 kW | Table 220.55 |
| `load-quiz-appliance-count` | Verified | 3 | 220.53 |
| `load-quiz-optional-vs-standard` | Verified | No, the method named is the answer being asked for | 220.82, 220.40 |
| `load-quiz-noncoincident` | Corrected | 9 kW | 220.60 |
| `load-quiz-neutral` | Corrected | 5600 VA | 220.61(B) |
| `load-quiz-service-minimum` | Verified | 100 A | 230.79(C), 240.6(A) |
| `load-quiz-where-circuits-go` | Corrected | Inside the general lighting subtotal, before the demand factor | 220.52, Table 220.45 |
| `load-calc-standard-dwelling` | Corrected | 150 A | 220.41, Table 220.45, 220.50, 430.24, 220.52, 220.53, 220.54, Table 220.55, 220.60, 240.6(A) |
| `load-calc-optional-dwelling` | Corrected | 125 A | 220.82, 220.82(B), 220.82(C), 240.6(A) |
| `load-calc-three-ranges` | Corrected | 15.4 kW | Table 220.55 |
| `gnd-grounded-vs-grounding` | Corrected | One carries current by design, one does not | Art. 100, 250.24 |
| `gnd-gec-vs-egc` | Verified | One from the service conductors, one from the breaker | 250.66, 250.122 |
| `gnd-rod-ceiling` | Corrected | Never required to be larger than 6 AWG copper | 250.66(A), 250.66(B), 250.66(C) |
| `gnd-neutral-bond` | Corrected | Not permitted | 250.24(A)(5), 250.30 |
| `gnd-supplemental` | Verified | Add one more electrode | 250.53(A)(2), 250.53(A)(3) |
| `gnd-q-egc-200` | Corrected | 6 AWG | 250.122 |
| `gnd-q-rod-cap` | Corrected | 6 AWG | 250.66(A) |
| `gnd-q-supplemental` | Verified | One additional electrode | 250.53(A)(2) |
| `mtr-table-not-nameplate` | Corrected | Use the table | 430.6(A)(1), 430.32 |
| `mtr-125` | Corrected | 125% of the table full-load current | 430.22 |
| `mtr-three-protections` | Verified | Overload, short circuit, and ground fault | 430.32, 430.52 |
| `mtr-overload-percent` | Verified | 125% or 115%, depending on the nameplate | 430.32(A)(1) |
| `mtr-q-conductor` | Corrected | 35 A | 430.22 |
| `mtr-q-overload-source` | Corrected | The motor nameplate full-load current | 430.32 |
| `mtr-q-service-factor` | Corrected | 42.5 A | 430.32(A)(1) |

## Verification

The four focused Swift audit tests passed on the host against the compiled original content module, including the 126 authored items, 5,000 generated questions and every stored ampacity/FLC value. The complete Android app passes all 73 unit tests with zero failures/errors/skips and builds its debug APK using `fm-gradle --local testDebugUnitTest assembleDebug` on clawd-mac. This includes 5,000 independently solved native questions, 640 independent exported cases, native/Swift parity and existing mistake-targeting/calculator tests. The final iOS 27 simulator suite passes all 155 tests with zero failures/skips (`build/NEC2023AuditFinal.xcresult`), including the final column-C and nonadjustable-breaker constraints. The pool lease was released immediately afterward. Gradle and Android tools were not run on this Mac.
