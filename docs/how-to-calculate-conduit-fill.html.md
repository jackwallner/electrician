# How to Calculate Conduit Fill (NEC Chapter 9) | Electrician

> How to calculate conduit fill under NEC Chapter 9: Table 1 fill limits, Table 4 conduit areas, Table 5 wire areas, and four worked examples in EMT.

Web page: https://jackwallner.com/ios/electrician/how-to-calculate-conduit-fill.html

## How to Calculate Conduit Fill (NEC Chapter 9)

By Jack Wallner · Last updated October 19, 2026 · Based on the 2023 NEC

To calculate conduit fill, add the cross-sectional area of every conductor (NEC Chapter 9, Table 5) and compare the total with the allowed area for the conduit (Chapter 9, Table 4). The limit is 53% of the conduit's interior for one conductor, 31% for two, and 40% for three or more (Table 1). Choose the smallest trade size whose limit is at least the total.

## How do you calculate conduit fill?

Conduit fill is an area comparison that checks whether the conductors fit in a conduit. You add up the cross-section of every conductor and check that the total stays under a percentage of the conduit's interior area. Three tables in Chapter 9 of the 2023 NEC supply every number.

1. **Find the area of each conductor.** Chapter 9, Table 5 lists the cross-section of insulated conductors by size and insulation type. This includes the insulation, which is why a 12 AWG THHN wire (0.0133 sq in) is bigger than the copper alone.
2. **Add them up and pick the fill limit.** Chapter 9, Table 1 sets the maximum fill by conductor count: 53% for one conductor, 31% for two, and 40% for three or more.
3. **Pick a conduit.** Chapter 9, Table 4 gives the interior area of each conduit type and trade size, with the 53%, 31% and 40% areas already worked out. Choose the smallest size whose limit is at least your total.

Equipment grounding conductors count toward the total when they are installed. An insulated green ground uses its Table 5 area, and a bare one uses its Table 8 area.

## What are the EMT and THHN numbers for conduit fill?

Most exam and field problems use THHN/THWN-2 conductors in EMT, covered by Article 358. These values come from Table 4 and Table 5 and are facts you can check in your own code book.

| EMT trade size | Interior area (sq in) | 40% limit (sq in) |
| --- | --- | --- |
| 1/2 in | 0.304 | 0.122 |
| 3/4 in | 0.533 | 0.213 |
| 1 in | 0.864 | 0.346 |
| 1-1/4 in | 1.496 | 0.598 |
| 1-1/2 in | 2.036 | 0.814 |
| 2 in | 3.356 | 1.342 |

| THHN/THWN-2 size | Area each (sq in) |
| --- | --- |
| 14 AWG | 0.0097 |
| 12 AWG | 0.0133 |
| 10 AWG | 0.0211 |
| 8 AWG | 0.0366 |
| 6 AWG | 0.0507 |
| 4 AWG | 0.0824 |
| 1/0 AWG | 0.1855 |

## What size EMT do six 12 AWG wires need?

Two circuits sharing a raceway: six 12 AWG THHN conductors, including grounds.

- Total area: 6 × 0.0133 = 0.0798 sq in.
- Six conductors means the 40% limit applies. The 1/2 in EMT limit is 0.122 sq in, which is larger than 0.0798.

**Answer: 1/2 in EMT**, filled to 0.0798 / 0.304 = 26.3%.

## What size EMT do nine 10 AWG wires need?

Nine 10 AWG THHN wires need 3/4 inch EMT, which they fill to 35.6%. Here is the math.

- Total area: 9 × 0.0211 = 0.1899 sq in.
- 1/2 in EMT allows 0.122, which is too small (the wires would fill 62.5% of the conduit).
- 3/4 in EMT allows 0.213, which is enough.

**Answer: 3/4 in EMT**, at 0.1899 / 0.533 = 35.6% fill.

## How do you calculate fill with mixed wire sizes?

A feeder of three 1/0 AWG THHN conductors plus a 6 AWG THHN insulated equipment ground.

- Total area: 3 × 0.1855 + 0.0507 = 0.6072 sq in.
- 1-1/4 in EMT allows 0.598 sq in. The bundle is over by 0.009, so it fails at 40.6% fill.
- 1-1/2 in EMT allows 0.814 sq in.

**Answer: 1-1/2 in EMT**, at 29.8% fill. The ground wire is what pushed this past the smaller size, which is why you count it.

## How does the fill limit change with two conductors?

Two 8 AWG THHN conductors in 1/2 in EMT.

- Total area: 2 × 0.0366 = 0.0732 sq in.
- Two conductors use the 31% limit: 0.304 × 0.31 = 0.094 sq in.

**It fits**, at 24.1% fill. The lower percentage matters because two wires can sit side by side and jam, so a tight pull is more likely at this count.

## How many wires fit in a conduit?

Divide the 40% area by the area of one conductor. For 3/4 in EMT and 12 AWG THHN: 0.213 / 0.0133 = 16.0, so **16 conductors**. A seventeenth takes the fill to 42.4%. When the answer has a decimal of 0.8 or more, Chapter 9 Note 7 lets you round up to the next whole conductor. Annex C lists the maximum counts for same-size conductors, so you can skip the arithmetic in that case.

## What special cases change conduit fill?

Short nipples, mixed wire sizes, other conduit types, different insulation and multiconductor cables all change the calculation.

- **Short nipples.** A raceway nipple no longer than 24 inches may be filled to 60% (Chapter 9 Note 4).
- **Mixed sizes.** Annex C only works for conductors of one size and type. For anything mixed, use Tables 4 and 5 as above.
- **Other conduit types.** RMC, IMC, PVC, FMC and the rest have their own interior areas in Table 4. The 40% rule is the same, but the areas are not. Each wiring method article has a number-of-conductors section that sends you to these tables, for example 358.22 for EMT.
- **Different insulation.** XHHW and THW are not the same area as THHN. Use the right column of Table 5 for the wire you are pulling.
- **Conductors in a cable.** A multiconductor cable is handled as one oval, not as separate wires. Check Chapter 9 Note 9.

## What are the common conduit fill mistakes?

Most fill mistakes come from the wrong count, the wrong percentage or the wrong table column.

- Leaving the ground out of the count.
- Using 40% for a two-conductor run.
- Pulling the THW area when the wire is THHN.
- Using the total interior area, not the 40% column, as the limit.
- Counting current-carrying conductors for fill, then forgetting that ampacity derating is a separate step.

## How does Electrician Exam Practice help?

[Electrician Exam Practice 2026](https://jackwallner.com/ios/electrician/) is an iPhone and iPad app for journeyman and master exam candidates. It generates raceway fill, ampacity, box fill and voltage drop problems that do not repeat, and every miss comes with numbered working steps. It also has free field calculators, including one for conduit fill, so the same tables are in your pocket on the job. The app uses the 2023 NEC cycle, cites article and table numbers, and does not reproduce code text. Comparing apps? See the [best journeyman electrician test prep app](https://jackwallner.com/ios/electrician/best-journeyman-electrician-test-prep-app.html) comparison.

## Practice raceway fill and the rest of the exam math

Electrician Exam Practice 2026 generates NEC calculation problems that do not repeat and shows numbered steps for every miss. Free to start on iPhone and iPad.

[See the app](https://jackwallner.com/ios/electrician/)

## Questions

### What is the NEC conduit fill limit?

40% of the conduit's interior area for three or more conductors, 31% for two and 53% for one, set by NEC Chapter 9, Table 1. Nipples no longer than 24 inches may go to 60%.

### How do you calculate conduit fill?

Add up the cross-sectional area of every conductor from Chapter 9, Table 5, then compare the total with the 40% area (or 31% or 53%) for the conduit in Table 4. Pick the smallest trade size whose limit is at least your total.

### Does the ground wire count in conduit fill?

Yes. Equipment grounding conductors count when they are installed. Use the Table 5 area for an insulated ground and the Table 8 area for a bare one.

### How many 12 AWG wires fit in 3/4 inch EMT?

Sixteen THHN conductors. The 40% area of 3/4 inch EMT is 0.213 square inches, and each 12 AWG THHN is 0.0133 square inches, so 0.213 / 0.0133 = 16.

### Is conduit fill the same as ampacity derating?

No. Conduit fill is a physical space limit. Ampacity derating is a separate calculation based on the number of current-carrying conductors and the ambient temperature, so a conduit can pass the fill check and still need larger wire.

## Sources

- [NFPA: NFPA 70, National Electrical Code](https://www.nfpa.org/codes-and-standards/nfpa-70-standard-development/70)
- [ExpertCE: Conduit fill calculations, a guide to NEC Chapter 9 tables](https://expertce.com/learn-articles/conduit-fill-calculations-nec-guide/)
- [ExpertCE: How to use NEC Chapter 9, Table 1 for percent conduit fill](https://expertce.com/learn-articles/nec-chapter-9-table-1-conduit-fill/)
- [EngiCalcsHub: Conduit fill guide](https://engicalchub.com/guides/conduit-fill-guide/)

Values follow the 2023 NEC. Your jurisdiction may have adopted a different edition or amended it, so check the book your authority having jurisdiction enforces. This guide cites article and table numbers and does not reproduce NEC text. It is not a substitute for the code. Electrician Exam Practice 2026 is an independent app and is not affiliated with NFPA.
