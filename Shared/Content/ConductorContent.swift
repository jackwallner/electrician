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
            backTitle: "The column is the insulation's rating, not the circuit's",
            backBody: "The column you read is set by the conductor's insulation. The column you are allowed to finish in is set by whatever the conductor lands on: the breaker lugs, the terminal block, the equipment. Most equipment is rated 75°C, so most answers finish in the 75°C column no matter what the wire is rated.",
            citation: "310.16, 110.14(C)"
        ),
        Flashcard(
            id: "cond-ninety-start",
            frontTitle: "So what is the 90°C column for?",
            frontSubtitle: "If you can never terminate there",
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
            citation: "310.15(B)(1)"
        ),
        Flashcard(
            id: "cond-bundling",
            frontTitle: "More than three in a raceway",
            frontSubtitle: "Current-carrying, not total",
            backTitle: "Four or more current-carrying conductors adjust down",
            backBody: "Count current-carrying conductors only. An equipment grounding conductor never counts. A neutral that carries only the unbalanced current of a balanced multiwire circuit does not count either, but a neutral on a circuit feeding nonlinear loads does. Getting the count wrong changes the factor and therefore the answer.",
            citation: "310.15(C)(1), 310.15(E)"
        ),
        Flashcard(
            id: "cond-240-4-d",
            frontTitle: "14, 12 and 10 AWG copper",
            frontSubtitle: "The rule that overrides the table",
            backTitle: "15, 20 and 30 amps, regardless",
            backBody: "The ampacity table says 14 AWG copper is good for 20 A in the 75°C column and 25 A at 90°C. It does not matter. Small conductors are capped at 15, 20 and 30 amps for 14, 12 and 10 AWG copper. Aluminum 12 and 10 cap at 15 and 25. This single rule accounts for more wrong answers than any other in the article.",
            citation: "240.4(D)"
        ),
        Flashcard(
            id: "cond-next-size-up",
            frontTitle: "The next-size-up rule",
            frontSubtitle: "And when you do not get it",
            backTitle: "Only when the calculation lands between standard sizes",
            backBody: "If the conductor's ampacity does not match a standard rating, you may go up to the next standard size, but only at 800 A or below and only where the circuit does not supply receptacles for cord-and-plug-connected portable loads. Small conductors under 240.4(D) never get it, because their cap is not an ampacity.",
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
            prompt: "Same raceway, but the load is now electronic ballasts and switching power supplies. How many current-carrying conductors?",
            givens: [Given("Load", "nonlinear"), Given("In raceway", "3 phase + 1 neutral + 1 EGC")],
            choices: ["4", "3", "5", "2"],
            answerIndex: 0,
            explanation: "Nonlinear loads put harmonic current on the neutral, so the neutral now counts. Four current-carrying conductors means the adjustment factor drops to 80%. The wire did not change; the load did.",
            citation: "310.15(E)(3)"
        ),
        QuizQuestion(
            id: "cond-q-nextsize",
            prompt: "A feeder conductor calculates to 88 A of required ampacity and the load is not continuous. What standard overcurrent device is permitted?",
            givens: [.load(88)],
            choices: ["90 A", "80 A", "100 A", "88 A"],
            answerIndex: 0,
            explanation: "88 A is not a standard rating. The next standard size up is 90 A, and at 800 A or below with no portable cord-and-plug receptacle loads that is permitted. 88 A is not on the standard list at all.",
            citation: "240.4(B), 240.6(A)"
        ),
    ]
}
