import Foundation

/// Electrician+ content: grounding and motors.
///
/// These two articles are where the exam separates people. Grounding fails on
/// vocabulary, because four terms that sound alike mean different things.
/// Motors fail on structure, because every quantity comes from a different
/// place than the one before it.
///
/// Original wording, article numbers cited for lookup.
enum ProContent {

    // MARK: - Grounding and bonding

    static let groundingCards: [Flashcard] = [
        Flashcard(
            id: "gnd-grounded-vs-grounding",
            frontTitle: "Grounded conductor vs. grounding conductor",
            frontSubtitle: "One letter, opposite jobs",
            backTitle: "One carries current by design, one does not",
            backBody: "A grounded conductor is intentionally grounded and can carry normal load current. In common dwelling systems it is the neutral, but a grounded conductor is not always a neutral. The equipment grounding conductor bonds exposed metal and provides a fault-current path; it is not intended to carry normal load current.",
            citation: "Art. 100, 250.24"
        ),
        Flashcard(
            id: "gnd-gec-vs-egc",
            frontTitle: "Grounding electrode conductor vs. equipment grounding conductor",
            frontSubtitle: "Sized from completely different things",
            backTitle: "One from the service conductors, one from the breaker",
            backBody: "The grounding electrode conductor connects the system to earth and is sized from the service-entrance conductors. The equipment grounding conductor bonds metal parts back to the source and is sized from the rating of the overcurrent device ahead of it. Using the wrong table is the classic way to miss both questions in a pair.",
            citation: "250.66, 250.122"
        ),
        Flashcard(
            id: "gnd-rod-ceiling",
            frontTitle: "The conductor to a ground rod",
            frontSubtitle: "However big the service is",
            backTitle: "Never required to be larger than 6 AWG copper",
            backBody: "For a conductor connecting only to a rod, pipe or plate electrode, 250.66(A) does not require more than 6 AWG copper. This is a sizing permission, not a physical current limit of the electrode. The corresponding copper limit for a concrete-encased electrode is 4 AWG. For a ground ring it is the ring conductor's actual size.",
            citation: "250.66(A), 250.66(B), 250.66(C)"
        ),
        Flashcard(
            id: "gnd-neutral-bond",
            frontTitle: "Bonding the neutral downstream",
            frontSubtitle: "In a subpanel",
            backTitle: "Not permitted past the service disconnect",
            backBody: "Keep the neutral isolated from equipment grounding conductors and bonded metal on the load side of the service disconnect, except where a specific rule permits otherwise. Bonding again in an ordinary feeder subpanel creates a parallel path for normal current. Supply-side service bonding and separately derived systems have their own rules, so the whole system need not have only one physical bond.",
            citation: "250.24(A)(5), 250.30",
            choice: CardChoice("Required", "Not permitted", answerIndex: 1)
        ),
        Flashcard(
            id: "gnd-supplemental",
            frontTitle: "One ground rod, 30 ohms measured",
            frontSubtitle: "Now what",
            backTitle: "Add one more electrode",
            backBody: "A single rod, pipe or plate electrode that does not measure 25 ohms or less has to be supplemented by one additional electrode. One more, not however many it takes to hit 25. Once the second one is installed the requirement is satisfied whatever the reading says. Supplemental rods sit at least 6 feet apart.",
            citation: "250.53(A)(2), 250.53(A)(3)"
        ),
    ]

    static let groundingQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "gnd-q-egc-200",
            prompt: "An ordinary feeder is protected at 200 A, with conductors not increased in size and no parallel raceways. What is the minimum copper wire equipment grounding conductor from Table 250.122?",
            givens: [Given("OCPD", "200", unit: "A"), .material(.copper)],
            choices: ["6 AWG", "4 AWG", "8 AWG", "3 AWG"],
            answerIndex: 0,
            explanation: "The equipment grounding conductor comes from the overcurrent device rating in Table 250.122, and 200 A calls for 6 AWG copper. The conductor's own ampacity has nothing to do with it.",
            citation: "250.122"
        ),
        QuizQuestion(
            id: "gnd-q-rod-cap",
            prompt: "Table 250.66 calls for 1/0 AWG copper for a service. A conductor connects only to a driven rod and does not continue to another electrode. What minimum copper size does 250.66(A) permit?",
            givens: [Given("Table GEC", "1/0 AWG copper"), Given("Electrode", "ground rod")],
            choices: ["6 AWG", "1/0 AWG", "4 AWG", "2 AWG"],
            answerIndex: 0,
            explanation: "The size from the service conductors would be much larger, but the rod exception caps it: a conductor to a rod, pipe or plate electrode is never required to be larger than 6 AWG copper.",
            citation: "250.66(A)"
        ),
        QuizQuestion(
            id: "gnd-q-supplemental",
            prompt: "A single driven rod measures 40 ohms to earth. What does the code require?",
            givens: [Given("Measured", "40", unit: "Ω")],
            choices: [
                "One additional electrode",
                "Rods until 25 Ω is reached",
                "Nothing, 40 Ω is acceptable",
                "A concrete-encased electrode",
            ],
            answerIndex: 0,
            explanation: "Over 25 ohms, the rod gets supplemented by exactly one more electrode. Adding rods until the meter reads 25 is a field habit, not the requirement, and answering that way on an exam loses the point.",
            citation: "250.53(A)(2)"
        ),
    ]

    // MARK: - Motors

    static let motorCards: [Flashcard] = [
        Flashcard(
            id: "mtr-table-not-nameplate",
            frontTitle: "The nameplate says 28 amps",
            frontSubtitle: "So size the conductors for 28?",
            backTitle: "No. Conductors come from the code tables",
            backBody: "For an ordinary single-speed motor of usual speed and torque characteristics, conductors and branch-circuit short-circuit protection use the code-table full-load current. Separate overload protection uses nameplate current. Low-speed, high-torque, multispeed and other specifically excepted motors require their own treatment under 430.6(A)(1).",
            citation: "430.6(A)(1), 430.32",
            choice: CardChoice("Use the nameplate", "Use the table", answerIndex: 1)
        ),
        Flashcard(
            id: "mtr-125",
            frontTitle: "Single motor, continuous duty",
            frontSubtitle: "Conductor sizing",
            backTitle: "125% of the table full-load current",
            backBody: "430.22(A) requires conductors for a single continuous-duty motor to have at least 125% of the applicable full-load current. This is the motor rule for this duty class. Short-time, intermittent, periodic and varying-duty motors have other provisions; do not assume every motor is a continuous load.",
            citation: "430.22"
        ),
        Flashcard(
            id: "mtr-three-protections",
            frontTitle: "A motor circuit has three separate protections",
            frontSubtitle: "And three separate calculations",
            backTitle: "Overload, short circuit, and ground fault",
            backBody: "Overload protects the motor from working too hard and is sized from the nameplate. Short-circuit and ground-fault protection guards the circuit against a fault and is sized from the table, at a much higher percentage. They are different devices doing different jobs, and an exam question will tell you which one it wants.",
            citation: "430.32, 430.52"
        ),
        Flashcard(
            id: "mtr-overload-percent",
            frontTitle: "Overload sizing",
            frontSubtitle: "Read the nameplate first",
            backTitle: "125% or 115%, depending on the nameplate",
            backBody: "A motor with a marked service factor of 1.15 or higher, or a marked temperature rise of 40°C or less, gets overload protection at 125% of the nameplate full-load current. Everything else gets 115%. The question always gives you the service factor, and it gives it to you because it matters.",
            citation: "430.32(A)(1)"
        ),
    ]

    static let motorQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "mtr-q-conductor",
            prompt: "A single ordinary continuous-duty motor has an applicable table full-load current of 28 A. What minimum branch-circuit conductor ampacity does 430.22(A) require?",
            givens: [Given("Table FLC", "28", unit: "A"), Given("Duty", "continuous")],
            choices: ["35 A", "28 A", "32.2 A", "70 A"],
            answerIndex: 0,
            explanation: "430.22(A) gives 28 × 1.25 = 35 A for this single continuous-duty motor. 32.2 A is 115%, an overload-protection percentage rather than this conductor-sizing factor. Other motor duty classes have separate provisions.",
            citation: "430.22"
        ),
        QuizQuestion(
            id: "mtr-q-overload-source",
            prompt: "For an ordinary continuous-duty motor over 1 hp using a separate current-responsive overload device under 430.32(A)(1), which current is the starting value?",
            choices: [
                "The motor nameplate full-load current",
                "The table full-load current",
                "The larger of the two",
                "The branch-circuit conductor ampacity",
            ],
            answerIndex: 0,
            explanation: "Overload protects the specific motor in front of you, so it uses that motor's nameplate. The tables are for conductors and for short-circuit protection. This single reversal is what most motor questions are really testing.",
            citation: "430.32"
        ),
        QuizQuestion(
            id: "mtr-q-service-factor",
            prompt: "A continuous-duty motor over 1 hp has a nameplate current of 34 A and a marked service factor of 1.15. Under 430.32(A)(1), before any allowance for failure to start, what is the maximum separate overload-device rating or setting?",
            givens: [Given("Nameplate FLA", "34", unit: "A"), Given("Service factor", "1.15")],
            choices: ["42.5 A", "39.1 A", "34 A", "85 A"],
            answerIndex: 0,
            explanation: "A service factor of 1.15 or more earns the 125% figure: 34 × 1.25 = 42.5 A. 39.1 A is 115%, which is what a motor without that marking would get.",
            citation: "430.32(A)(1)"
        ),
    ]
}
