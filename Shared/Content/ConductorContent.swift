import Foundation

/// Conductors, ampacity and overcurrent protection: the material the exam
/// leans on hardest and the material candidates most often half-learn.
///
/// Original wording throughout, article numbers cited for lookup.
enum ConductorContent {

    static let ampacityCards: [Flashcard] = [
        Flashcard(
            id: "cond-three-columns",
            frontTitle: "Why the table has three columns",
            frontSubtitle: "60°C, 75°C, 90°C",
            backTitle: "Insulation sets the starting column; terminations limit the result",
            backBody: "Use the insulation rating for correction and adjustment, then respect the termination limit. Unless equipment is listed and identified otherwise, circuits rated 100 A or less with 14 through 1 AWG conductors use the 60°C termination basis. Larger circuits or conductors use 75°C. A question must supply the ratings needed to choose the column.",
            citation: "310.16, 110.14(C)"
        ),
        Flashcard(
            id: "cond-ninety-start",
            frontTitle: "So what is the 90°C column for?",
            frontSubtitle: "With 75°C equipment terminations",
            backTitle: "It is the starting point for derating",
            backBody: "You may begin correction and adjustment from the 90°C ampacity of a 90°C-rated conductor, then compare the result against the termination limit. That is the whole trick: derate from 90, terminate at 75, take the lower number. Starting the derate from the 75°C value is the most common way to get a right-looking wrong answer.",
            citation: "110.14(C), 310.15",
            choice: CardChoice("Terminate there", "Start derating there", answerIndex: 1)
        ),
        Flashcard(
            id: "cond-ambient",
            frontTitle: "Ambient correction",
            frontSubtitle: "The table assumes 30°C",
            backTitle: "Hotter air, smaller number",
            backBody: "Table 310.16 is built for a 30°C ambient. Anything hotter multiplies the ampacity down, and the factor depends on which column you started in: the 90°C column loses less to heat than the 60°C column does, which is exactly why installers pay for 90°C insulation.",
            citation: "310.15(B)(1)(1)"
        ),
        Flashcard(
            id: "cond-bundling",
            frontTitle: "More than three in a raceway",
            frontSubtitle: "Current-carrying, not total",
            backTitle: "Four or more current-carrying conductors adjust down",
            backBody: "For a raceway longer than 24 inches, count current-carrying conductors. Equipment grounds do not count. A neutral carrying only imbalance from the other conductors of the same circuit need not count. In a four-wire, three-phase wye circuit whose major load is nonlinear, the neutral does count. Check the exceptions before applying an adjustment.",
            citation: "310.15(C)(1), 310.15(E)"
        ),
        Flashcard(
            id: "cond-240-4-d",
            frontTitle: "14, 12 and 10 AWG copper",
            frontSubtitle: "The rule that overrides the table",
            backTitle: "Normally 15, 20 and 30 amps for general-purpose protection",
            backBody: "For ordinary general-purpose circuits, 240.4(D) limits 14, 12 and 10 AWG copper protection to 15, 20 and 30 A. Aluminum 12 and 10 AWG are limited to 15 and 25 A. Correction and adjustment can require still smaller protection. Specific permissions in 240.4(E) and (G), including motor circuits, can change these limits.",
            citation: "240.4(D)"
        ),
        Flashcard(
            id: "cond-next-size-up",
            frontTitle: "The next-size-up rule",
            frontSubtitle: "And when you do not get it",
            backTitle: "Only when the calculation lands between standard sizes",
            backBody: "240.4(B) permits the next higher standard rating when the conductor ampacity lies between standard ratings, the selected device does not exceed 800 A, and the conductors are not part of a branch circuit supplying more than one receptacle for portable cord-and-plug loads. The load must still fit the conductor. This permission does not override a 240.4(D) small-conductor limit.",
            citation: "240.4(B), 240.4(C), 240.6(A)"
        ),
    ]

    static let ampacityQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "cond-q-terminal",
            prompt: "A 90°C THHN conductor lands on a breaker with 75°C-rated lugs. Which column finishes the calculation?",
            givens: [.conductor("6 AWG", "THHN"), .terminals(.c75)],
            choices: ["75°C", "90°C", "60°C", "Whichever is larger"],
            answerIndex: 0,
            explanation: "The termination is the weak point, so it sets the ceiling. You may derate from the 90°C value, but the final answer can never exceed the 75°C ampacity of that conductor.",
            citation: "110.14(C)"
        ),
        QuizQuestion(
            id: "cond-q-14awg",
            prompt: "What is the largest overcurrent device permitted on 14 AWG copper feeding a general lighting branch circuit?",
            givens: [.conductor("14 AWG", "THHN"), .material(.copper)],
            choices: ["15 A", "20 A", "25 A", "30 A"],
            answerIndex: 0,
            explanation: "The 75°C column shows 20 A and the 90°C column shows 25 A, and both are irrelevant here. 240.4(D) caps 14 AWG copper at 15 A. If you answered 20 or 25 you read the table and stopped one rule short.",
            citation: "240.4(D), 310.16"
        ),
        QuizQuestion(
            id: "cond-q-egc-count",
            prompt: "A raceway holds three phase conductors, one neutral on a balanced three-phase linear load, and one equipment grounding conductor. How many count as current-carrying?",
            givens: [Given("In raceway", "3 phase + 1 neutral + 1 EGC")],
            choices: ["3", "4", "5", "2"],
            answerIndex: 0,
            explanation: "The EGC never counts. That neutral carries only unbalanced current on a balanced linear load, so it does not count either. Three current-carrying conductors means no adjustment factor applies at all.",
            citation: "310.15(E), 310.15(C)(1)"
        ),
        QuizQuestion(
            id: "cond-q-harmonic-neutral",
            prompt: "A four-wire, three-phase wye circuit's major load is nonlinear electronic equipment. Three phase conductors, its neutral and an EGC share a raceway longer than 24 inches. How many count as current-carrying?",
            givens: [Given("Load", "nonlinear"), Given("In raceway", "3 phase + 1 neutral + 1 EGC")],
            choices: ["4", "3", "5", "2"],
            answerIndex: 0,
            explanation: "Nonlinear loads put harmonic current on the neutral, so the neutral now counts. Four current-carrying conductors means the adjustment factor drops to 80%. The wire did not change; the load did.",
            citation: "310.15(E)(3)"
        ),
        QuizQuestion(
            id: "cond-q-nextsize",
            prompt: "A feeder conductor has 88 A of allowable ampacity after all limits. Its noncontinuous load is 80 A, and all conditions of 240.4(B) are met. What is the largest standard overcurrent rating permitted?",
            givens: [Given("Allowable ampacity", "88", unit: "A"), .load(80)],
            choices: ["90 A", "80 A", "100 A", "88 A"],
            answerIndex: 0,
            explanation: "The conductor can carry the 80 A load. Its 88 A allowable ampacity falls between standard ratings, and the stated 240.4(B) conditions permit the next rating, 90 A. Required load ampacity alone would not establish the conductor protection limit.",
            citation: "240.4(B), 240.6(A)"
        ),
    ]
}
