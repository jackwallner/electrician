import Foundation

/// The extra sets inside otherwise-free rooms. Same mechanics as the free
/// drills, more original questions, locked behind Electrician+.
///
/// Nothing that was ever free became paid. These are additions.
enum PlusContent {

    static let basicsExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "plus-basics-annexc",
            prompt: "Annex C gives conduit fill directly, with no area math. When can you use it?",
            choices: [
                "Only when every conductor is the same size and insulation",
                "Any time, it is a shortcut for all fills",
                "Only for EMT",
                "Only for three or fewer conductors",
            ],
            answerIndex: 0,
            explanation: "Annex C is built on a single conductor size and type per raceway. Mixed sizes have to go back through the Chapter 9 area tables. It is also informative rather than a requirement, though using it correctly produces the same answer.",
            citation: "Annex C, Ch. 9 Table 1"
        ),
        QuizQuestion(
            id: "plus-basics-90-2",
            prompt: "Which of these is outside the scope of the code entirely?",
            choices: [
                "Utility-owned service drops and metering",
                "A detached garage on a residential lot",
                "A carnival ride's temporary wiring",
                "A floating building's feeder",
            ],
            answerIndex: 0,
            explanation: "Installations under the exclusive control of a utility for generation, transmission, distribution and metering are outside the scope. The other three are all specifically covered, two of them by their own Chapter 5 or 6 articles.",
            citation: "90.2"
        ),
        QuizQuestion(
            id: "plus-basics-125-twice",
            prompt: "A 30 A continuous load is on a branch circuit. What must be at least 37.5 A?",
            givens: [.load(30), Given("Duty", "continuous")],
            choices: [
                "Both the conductor ampacity and the overcurrent device",
                "Only the conductor ampacity",
                "Only the overcurrent device",
                "Neither, 30 A is sufficient",
            ],
            answerIndex: 0,
            explanation: "The 125% applies in two separate places: 210.19(A) for the conductor and 210.20(A) for the device. Applying it to only one gives you a conductor its own breaker will not protect, or a breaker that nuisance-trips.",
            citation: "210.19(A), 210.20(A)"
        ),
        QuizQuestion(
            id: "plus-basics-accessible",
            prompt: "Equipment is mounted above a suspended ceiling with lift-out panels. It is:",
            choices: [
                "Accessible but not readily accessible",
                "Readily accessible",
                "Neither",
                "Concealed",
            ],
            answerIndex: 0,
            explanation: "Lift-out ceiling panels do not make something inaccessible, but reaching it means moving a panel and probably a ladder, so it is not readily accessible. Where the code demands readily accessible, that installation fails.",
            citation: "Art. 100"
        ),
    ]

    static let conductorExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "plus-cond-both-factors",
            prompt: "When both ambient correction and bundling adjustment apply, how are they combined?",
            choices: [
                "Multiply both against the same starting ampacity",
                "Apply only the smaller factor",
                "Add the two reductions together",
                "Apply only the ambient factor",
            ],
            answerIndex: 0,
            explanation: "They multiply. A 0.87 correction and a 0.80 adjustment give 0.696 of the starting value, not 0.80 and not a 33% reduction. Taking only the worse of the two is a common shortcut and it produces an unsafe answer.",
            citation: "310.15(B)(1), 310.15(C)(1)"
        ),
        QuizQuestion(
            id: "plus-cond-parallel",
            prompt: "What is the smallest conductor generally permitted to be run in parallel?",
            choices: ["1/0 AWG", "2 AWG", "4/0 AWG", "250 kcmil"],
            answerIndex: 0,
            explanation: "1/0 AWG is the general floor for paralleling, and the paralleled conductors have to match each other in length, material, size, insulation and termination. There are narrow exceptions for specific applications, but the general rule is 1/0.",
            citation: "310.10(G)"
        ),
        QuizQuestion(
            id: "plus-cond-neutral-count",
            prompt: "A three-wire single-phase circuit has two ungrounded conductors and one neutral carrying only the unbalanced current. How many are current-carrying?",
            choices: ["2", "3", "1", "0"],
            answerIndex: 0,
            explanation: "The neutral of a multiwire circuit that carries only unbalanced current is not counted. Two current-carrying conductors means no adjustment applies. The neutral is still a circuit conductor; it just does not count for this purpose.",
            citation: "310.15(E)(1)"
        ),
        QuizQuestion(
            id: "plus-cond-10awg-alum",
            prompt: "What is the maximum overcurrent device on 10 AWG aluminum?",
            givens: [.conductor("10 AWG", "THWN-2"), .material(.aluminum)],
            choices: ["25 A", "30 A", "20 A", "35 A"],
            answerIndex: 0,
            explanation: "The small-conductor rule has separate aluminum values: 12 AWG aluminum caps at 15 A and 10 AWG aluminum at 25 A. Carrying the copper numbers over to aluminum is a fast way to miss this.",
            citation: "240.4(D)"
        ),
    ]

    static let articleExtras: [ArticleMatchQuestion] = [
        ArticleMatchQuestion(
            id: "plus-am-gfci",
            scenario: "You need to know whether a receptacle in a garage requires GFCI protection.",
            choices: [.branchCircuits, .grounding, .definitions, .overcurrent],
            answer: .branchCircuits,
            explanation: "GFCI requirements for personnel are placement rules and live in Article 210. Article 250 is grounding, which is related in the field and separate in the book."
        ),
        ArticleMatchQuestion(
            id: "plus-am-tap",
            scenario: "A 10-foot tap is made from a 400 A feeder and you need to know what size the tap conductors may be.",
            choices: [.overcurrent, .conductors, .loadCalculations, .branchCircuits],
            answer: .overcurrent,
            explanation: "Tap rules are an overcurrent-protection concept: they describe when a conductor may be smaller than the device ahead of it. They sit in Article 240, not with the conductors."
        ),
        ArticleMatchQuestion(
            id: "plus-am-support",
            scenario: "You need the maximum distance from a box to the first strap on a run of EMT.",
            choices: [.raceways, .boxes, .branchCircuits, .conductors],
            answer: .raceways,
            explanation: "Support spacing lives with the wiring method, in the EMT article itself. This one is the mirror of the fill question: installation in the article, math in Chapter 9."
        ),
    ]
}
