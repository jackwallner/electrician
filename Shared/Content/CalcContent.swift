import Foundation

/// Authored worked calculations, one per shape.
///
/// The generator can produce these forever, but a reader meeting a shape for
/// the first time needs a fixed example with the steps spelled out. These are
/// that example. Every number is checked by `ContentValidityTests` against the
/// same tables the generator uses, so an authored answer can never drift from
/// a generated one.
enum CalcContent {

    static let workedExamples: [CalcScenario] = [
        CalcScenario(
            id: "calc-ampacity-1",
            situation: "Six current-carrying 6 AWG THHN copper conductors run through a 45°C space and land on 75°C terminals. Find the usable ampacity.",
            givens: [
                .conductor("6 AWG", "THHN"),
                .material(.copper),
                .ambient(45),
                .currentCarrying(6),
                .terminals(.c75),
            ],
            choices: ["52.2 A", "65 A", "45.2 A", "60 A"],
            answerIndex: 0,
            steps: [
                "Start at 90°C because the conductor is rated 90°C: 6 AWG copper is 75 A.",
                "45°C ambient corrects the 90°C column by 0.87: 75 × 0.87 = 65.25 A.",
                "Six current-carrying conductors adjust by 0.80: 65.25 × 0.80 = 52.2 A.",
                "The 75°C termination allows 65 A, which is higher, so the derated 52.2 A is the limit.",
            ],
            citation: "310.16, 310.15(B)(1), 310.15(C)(1), 110.14(C)"
        ),
        CalcScenario(
            id: "calc-ocpd-1",
            situation: "Size the maximum overcurrent device for 12 AWG copper on a general-purpose branch circuit with 75°C terminations.",
            givens: [
                .conductor("12 AWG", "THWN-2"),
                .material(.copper),
                .terminals(.c75),
            ],
            choices: ["20 A", "25 A", "30 A", "15 A"],
            answerIndex: 0,
            steps: [
                "The 75°C column gives 12 AWG copper as 25 A.",
                "240.4(D) then caps 12 AWG copper at 20 A no matter what the table says.",
                "20 A is itself a standard rating, so no rounding is needed.",
                "If you answered 25 A you used the table and missed the cap, which is the most common error in this article.",
            ],
            citation: "310.16, 240.4(D), 240.6(A)"
        ),
        CalcScenario(
            id: "calc-conduitfill-1",
            situation: "Nine 10 AWG THHN conductors need to run in EMT. Pick the smallest trade size.",
            givens: [
                .conductor("10 AWG", "THHN"),
                Given("Quantity", "9", unit: "conductors"),
                .raceway("EMT", "?"),
            ],
            choices: ["3/4\"", "1/2\"", "1\"", "1-1/4\""],
            answerIndex: 0,
            steps: [
                "One 10 AWG THHN is 0.0211 in². Nine of them is 0.19 in².",
                "More than two conductors means the allowance is 40%.",
                "1/2\" EMT is 0.304 in² interior; 40% of that is 0.12 in², which is not enough.",
                "3/4\" EMT is 0.533 in²; 40% is 0.21 in², which covers 0.19 in². 3/4\" is the answer.",
            ],
            citation: "Ch. 9 Table 1, Table 4, Table 5"
        ),
        CalcScenario(
            id: "calc-boxfill-1",
            situation: "A box holds six 12 AWG insulated conductors, three equipment grounds, internal cable clamps, and one device yoke. Find the minimum volume.",
            givens: [
                .conductor("12 AWG", "THHN"),
                Given("Insulated", "6", unit: "conductors"),
                Given("Grounds", "3", unit: "wires"),
                Given("Internal clamps", "yes"),
                Given("Devices", "1", unit: "yoke"),
            ],
            choices: ["22.5 in³", "20.25 in³", "27 in³", "18 in³"],
            answerIndex: 0,
            steps: [
                "Each allowance for 12 AWG is 2.25 in³.",
                "Six insulated conductors is six allowances.",
                "All three grounds together count as one allowance, not three.",
                "Internal clamps count as one allowance no matter how many.",
                "The device yoke counts as two.",
                "6 + 1 + 1 + 2 = 10 allowances. 10 × 2.25 = 22.5 in³.",
            ],
            citation: "314.16(B)"
        ),
        CalcScenario(
            id: "calc-vdrop-1",
            situation: "A 120 V single-phase branch circuit carries 16 A on 10 AWG copper for 100 feet one way. Find the voltage drop.",
            givens: [
                .conductor("10 AWG", "THHN"),
                .material(.copper),
                .voltage(120, phase: .single),
                .load(16),
                .length(100),
            ],
            choices: ["4.0 V", "2.0 V", "3.4 V", "6.5 V"],
            answerIndex: 0,
            steps: [
                "Single-phase uses 2 as the factor, because the current goes out and comes back.",
                "K for copper is 12.9 and 10 AWG is 10,380 circular mils.",
                "VD = 2 × 12.9 × 16 × 100 ÷ 10,380 = 4.0 V.",
                "4.0 V on 120 V is 3.3%, which is past the 3% figure the informational note suggests. It is a note, not a requirement, but an exam question asking whether it is acceptable wants you to notice.",
            ],
            citation: "210.19(A) Informational Note, Ch. 9 Table 8"
        ),
    ]
}
