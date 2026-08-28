import Foundation

/// Installation rules: Article 110 working space, Article 300 cover and
/// support, and the branch-circuit requirements in Article 210 that are asked
/// as numbers rather than as calculations.
///
/// Why this room exists. Every other room in the app is a calculation, and a
/// calculation takes two minutes. These are the questions worth the most per
/// minute on the paper: a candidate who knows the number answers in fifteen
/// seconds, and a candidate who does not spends two minutes finding it, on a
/// paper where time is the binding constraint. They are also the rules a
/// working electrician is asked about on site for the rest of their career,
/// which is why this room is free.
///
/// Same discipline as everywhere else: numbers and article citations, written
/// in original wording. No code text.
enum InstallContent {

    // MARK: - Flashcards

    static let workingSpaceCards: [Flashcard] = [
        Flashcard(
            id: "install-card-depth",
            frontTitle: "How deep does the working space in front of a panel have to be?",
            givens: [Given("System", "120/240V"), Given("Condition", "1")],
            frontSubtitle: "Measured out from the live parts",
            backTitle: "Three feet, and at 120/240 V it is three feet whatever the condition",
            backBody: "The depth table is graded by condition: nothing live or grounded facing the equipment, grounded parts facing it, or live parts on both sides. Below 151 volts to ground all three land on the same three feet, so the grading only starts to bite on a 277/480 system, where the same three conditions run three, three and a half, and four feet. Candidates memorise the 480 volt row and then apply it to a house panel, which is the wrong direction to be wrong in.",
            citation: "110.26(A)(1)",
            choice: CardChoice("3 ft", "3.5 ft", answerIndex: 0)
        ),
        Flashcard(
            id: "install-card-width",
            frontTitle: "How wide does that space have to be?",
            frontSubtitle: "And what decides it",
            backTitle: "Thirty inches, or the width of the equipment, whichever is greater",
            backBody: "The thirty inches does not have to be centred on the equipment, and it may overlap the working space of adjacent equipment. What it may not do is be blocked by a door: the space has to allow any equipment door or hinged panel to open at least ninety degrees. A panel in a closet that only opens sixty degrees fails on the door, not on the thirty inches.",
            citation: "110.26(A)(2)",
            choice: CardChoice("30 in.", "36 in.", answerIndex: 0)
        ),
        Flashcard(
            id: "install-card-height",
            frontTitle: "How much headroom does a working space need?",
            backTitle: "Six and a half feet, or the height of the equipment where it is taller",
            backBody: "The headroom is clear space: piping, ducts and equipment foreign to the electrical installation are not allowed in it. The common exam framing is a ceiling at six feet, which fails, or a panel that is itself seven feet tall, where the equipment height governs and the answer is seven.",
            citation: "110.26(A)(3), 110.26(E)"
        ),
        Flashcard(
            id: "install-card-entrances",
            frontTitle: "When does a working space need an exit at each end?",
            givens: [Given("Equipment", "1200 A"), Given("Width", "Over 6 ft")],
            backTitle: "At 1200 amperes or more, and over six feet wide",
            backBody: "Both conditions have to be true. Big gear that is narrow, or wide gear that is small, takes one entrance. Where both apply, the space needs an entrance at each end, each at least twenty-four inches wide and six and a half feet high, so nobody is trapped past an arcing fault.",
            citation: "110.26(C)(2)"
        ),
        Flashcard(
            id: "install-card-dedicated",
            frontTitle: "What is the dedicated space above a panel, and how far up does it go?",
            backTitle: "The footprint of the equipment, from the floor to six feet above it or to the structural ceiling, whichever is lower",
            backBody: "This is a different rule from the working space and gets confused with it constantly. The working space is where a person stands, in front. The dedicated space is the column directly above and below the equipment footprint, and it is reserved from foreign systems: no plumbing, no ductwork, no leaks from above. Sprinkler protection is allowed, and a suspended ceiling does not count as a structural ceiling.",
            citation: "110.26(E)(1)"
        ),
    ]

    static let coverAndSupportCards: [Flashcard] = [
        Flashcard(
            id: "install-card-burial-direct",
            frontTitle: "Minimum cover over a direct-buried cable in a residential yard?",
            givens: [Given("Method", "Direct burial"), Given("Location", "Open trench")],
            backTitle: "Twenty-four inches",
            backBody: "Cover is measured from the top of the wiring method to the finished grade, not from the bottom of the trench. Twenty-four inches is the baseline for direct burial; putting the same conductors inside rigid or intermediate metal conduit drops it to six, and a nonmetallic raceway listed for the purpose sits between them at eighteen.",
            citation: "Table 300.5",
            choice: CardChoice("24 in.", "18 in.", answerIndex: 0)
        ),
        Flashcard(
            id: "install-card-burial-residential",
            frontTitle: "The 12-inch burial row: what has to be true to use it?",
            backTitle: "Residential branch circuit, 120 volts or less, 20 amperes or less, and GFCI protected",
            backBody: "Every one of the four conditions has to hold. This is the row that lets a homeowner's yard light go in at a foot, and it is the row candidates quote for a 240 volt circuit or a 30 ampere one, where it does not apply. Miss any condition and the run goes back to its own column.",
            citation: "Table 300.5"
        ),
        Flashcard(
            id: "install-card-burial-traffic",
            frontTitle: "What happens to cover under a driveway or a parking lot?",
            backTitle: "Everything goes to twenty-four inches",
            backBody: "Under a street, road, alley, driveway or parking lot the whole table collapses to one number, whatever the wiring method. That is worth remembering as a rule rather than as a row: it turns a five-column lookup into a single fact, and it is the version the exam usually asks for.",
            citation: "Table 300.5",
            choice: CardChoice("24 in.", "18 in.", answerIndex: 0)
        ),
        Flashcard(
            id: "install-card-support-emt",
            frontTitle: "How is EMT secured and supported?",
            backTitle: "Within three feet of each box, then every ten feet",
            backBody: "Raceway is measured in feet at both ends of that sentence. Cable is not: type NM is secured within twelve INCHES of a box and supported every four and a half feet. Mixing the two pairs is the most common way this question is missed, and the tell is the unit: inches means cable, feet means pipe.",
            citation: "358.30(A)",
            choice: CardChoice("10 ft", "8 ft", answerIndex: 0)
        ),
        Flashcard(
            id: "install-card-support-nm",
            frontTitle: "How is type NM cable secured and supported?",
            backTitle: "Within twelve inches of a box, then every four and a half feet",
            backBody: "The twelve inches is measured to the cable entry and assumes the box has a clamp. A single-gang nonmetallic box without a clamp gets its own allowance: the cable is secured within eight inches of the box instead, measured along the sheath, with a length of sheath inside the box.",
            citation: "334.30, 314.17(C)"
        ),
        Flashcard(
            id: "install-card-bends",
            frontTitle: "How many bends are allowed between pull points?",
            backTitle: "Three hundred and sixty degrees, in every raceway article that has the rule",
            backBody: "Four quarter bends, and offsets count. It is the same number for EMT, rigid, intermediate and PVC, which makes it one of the few facts in Chapter 3 that does not need to be looked up per method. The bends between pull points are what the rule counts, not the bends in the run, so adding a pull box resets the tally.",
            citation: "358.26, 344.26, 352.26",
            choice: CardChoice("360°", "270°", answerIndex: 0)
        ),
    ]

    // MARK: - Quiz

    static let installQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "install-quiz-depth-480",
            prompt: "A 277/480 V panelboard faces a grounded metal wall across the aisle. What is the minimum clear working depth?",
            givens: [Given("System", "277/480V"), Given("Opposite", "Grounded surface")],
            choices: ["3 ft", "3.5 ft", "4 ft", "4.5 ft"],
            answerIndex: 1,
            explanation: "Live parts on one side with grounded parts facing them is condition 2, and above 150 volts to ground condition 2 is three and a half feet. A grounded metal wall, concrete, or plaster and lath all count as the grounded side, which is what turns an ordinary three-foot answer into three and a half.",
            citation: "110.26(A)(1)"
        ),
        QuizQuestion(
            id: "install-quiz-depth-house",
            prompt: "The same panel is a 120/240 V loadcentre in a garage with a concrete wall opposite. Minimum working depth?",
            givens: [Given("System", "120/240V"), Given("Opposite", "Concrete wall")],
            choices: ["3 ft", "3.5 ft", "4 ft", "30 in."],
            answerIndex: 0,
            explanation: "Below 151 volts to ground the condition does not change the answer: all three conditions are three feet. The grading of conditions only produces different numbers above that, which is why the same physical arrangement gives a different answer at 480 volts than at 240.",
            citation: "110.26(A)(1)"
        ),
        QuizQuestion(
            id: "install-quiz-width-equipment",
            prompt: "A switchboard is 42 inches wide. What is the minimum width of the working space in front of it?",
            givens: [Given("Equipment width", "42", unit: "in.")],
            choices: ["30 in.", "36 in.", "42 in.", "48 in."],
            answerIndex: 2,
            explanation: "The width is thirty inches or the width of the equipment, whichever is greater, so equipment wider than thirty inches sets its own working space. The thirty inches is a floor, not the answer.",
            citation: "110.26(A)(2)"
        ),
        QuizQuestion(
            id: "install-quiz-cover-rmc",
            prompt: "A circuit is run in rigid metal conduit through an open field. What is the minimum cover?",
            givens: [Given("Raceway", "Rigid metal conduit")],
            choices: ["6 in.", "12 in.", "18 in.", "24 in."],
            answerIndex: 0,
            explanation: "Rigid and intermediate metal conduit have their own column at six inches, because the raceway itself is the physical protection the cover would otherwise be providing. The twenty-four inch figure people quote for everything is the direct-burial column.",
            citation: "Table 300.5"
        ),
        QuizQuestion(
            id: "install-quiz-cover-pvc",
            prompt: "The same run is in PVC listed for direct burial, still in an open field. Minimum cover?",
            givens: [Given("Raceway", "PVC, direct burial listed")],
            choices: ["6 in.", "12 in.", "18 in.", "24 in."],
            answerIndex: 2,
            explanation: "Nonmetallic raceways sit between the two: eighteen inches, because the raceway resists damage but not the way a steel one does. Reading the metal-conduit six inches for PVC is the mistake this pair is here to separate.",
            citation: "Table 300.5"
        ),
        QuizQuestion(
            id: "install-quiz-support-nm",
            prompt: "Type NM cable runs from a device box along the framing. Where does the first staple go, and how often after that?",
            choices: [
                "Within 12 in. of the box, then every 4.5 ft",
                "Within 3 ft of the box, then every 10 ft",
                "Within 12 in. of the box, then every 6 ft",
                "Within 8 in. of the box, then every 4.5 ft",
            ],
            answerIndex: 0,
            explanation: "Cable is measured in inches at the box and feet along the run: twelve inches, then four and a half feet. The eight-inch answer is the separate allowance for a single-gang nonmetallic box with no clamp, and the three-foot-then-ten-foot answer is EMT.",
            citation: "334.30"
        ),
        QuizQuestion(
            id: "install-quiz-receptacle-spacing",
            prompt: "In a dwelling living room, how far along the wall may a point be from the nearest receptacle outlet?",
            choices: ["4 ft", "6 ft", "8 ft", "12 ft"],
            answerIndex: 1,
            explanation: "No point measured horizontally along the floor line of any wall space may be more than six feet from a receptacle, which is why receptacles land about twelve feet apart: a cord can reach either way. The six-foot figure is the rule; the twelve-foot spacing is its consequence, and questions ask for whichever one you are less ready for.",
            citation: "210.52(A)(1)"
        ),
        QuizQuestion(
            id: "install-quiz-wall-space",
            prompt: "What is the narrowest section of wall that counts as a wall space needing its own receptacle?",
            choices: ["12 in.", "18 in.", "2 ft", "3 ft"],
            answerIndex: 2,
            explanation: "Two feet or more of wall, measured horizontally and including space measured around corners, is a wall space. Fixed panels in exterior walls and the space occupied by a fixed cabinet count too. Anything narrower than two feet is not a wall space and needs nothing.",
            citation: "210.52(A)(2)"
        ),
        QuizQuestion(
            id: "install-quiz-counter-spacing",
            prompt: "Along a kitchen countertop wall, how far may a point be from the nearest receptacle?",
            choices: ["12 in.", "24 in.", "4 ft", "6 ft"],
            answerIndex: 1,
            explanation: "Twenty-four inches from any point along the wall line, which puts receptacles about four feet apart. It is a different number from the six-foot general rule for a reason: an appliance cord on a counter is shorter than a lamp cord in a living room. A counter space twelve inches or wider is what triggers the requirement.",
            citation: "210.52(C)(1)"
        ),
        QuizQuestion(
            id: "install-quiz-bends",
            prompt: "A run of EMT leaves a panel, turns twice at 90 degrees, and takes two 45-degree offsets. How many more degrees of bend are allowed before a pull point?",
            givens: [Given("Bends so far", "90 + 90 + 45 + 45")],
            choices: ["0°", "90°", "180°", "270°"],
            answerIndex: 1,
            explanation: "Two ninety-degree bends and two forty-fives are 270 degrees, and the limit between pull points is 360, so ninety degrees remain. Offsets count toward the total, which is the part that catches people: it is the sum of all bends, not the number of elbows.",
            citation: "358.26"
        ),
        QuizQuestion(
            id: "install-quiz-continuous",
            prompt: "A 44 A continuous load feeds from a panel. What is the minimum branch-circuit conductor ampacity and device rating?",
            givens: [Given("Load", "44", unit: "A"), Given("Duty", "Continuous")],
            choices: ["44 A", "50 A", "55 A", "60 A"],
            answerIndex: 2,
            explanation: "A load expected to run three hours or more is taken at 125%, and the multiplier applies to the conductor and to the device ahead of it: 44 × 1.25 = 55 A. The 50 A answer is the next standard device below the load, which is what you get by protecting at the load itself.",
            citation: "210.19(A)(1), 210.20(A)"
        ),
        QuizQuestion(
            id: "install-quiz-dedicated-space",
            prompt: "A water pipe runs horizontally 30 inches above a panelboard, inside the panel's footprint. Is that permitted?",
            choices: [
                "No, it is in the dedicated space above the equipment",
                "Yes, the dedicated space is only 6 in. deep",
                "Yes, dedicated space applies only to switchboards",
                "No, it violates the working space depth",
            ],
            answerIndex: 0,
            explanation: "The dedicated space is the column directly above the equipment footprint, running to six feet above the equipment or to the structural ceiling, whichever is lower, and foreign systems are excluded from it. It is a separate rule from the working space in front, which is where the fourth answer goes wrong.",
            citation: "110.26(E)(1)"
        ),
    ]

    // MARK: - Which article

    static let installArticleMatch: [ArticleMatchQuestion] = [
        ArticleMatchQuestion(
            id: "install-match-workspace",
            scenario: "You need to know how much clear space has to be left in front of a 480 V switchboard.",
            choices: [.generalRequirements, .services, .wiringMethods, .branchCircuits],
            answer: .generalRequirements,
            explanation: "Working space, headroom, illumination and the dedicated space above equipment are all in Article 110, which is the general-requirements article and the first place to look for anything about access and clearance rather than about a specific wiring method."
        ),
        ArticleMatchQuestion(
            id: "install-match-cover",
            scenario: "A feeder is buried across a yard and you need the minimum depth of cover.",
            choices: [.wiringMethods, .conductors, .services, .grounding],
            answer: .wiringMethods,
            explanation: "Burial depth is in the general wiring-methods article, not in the article for whichever raceway is being buried. That is the pattern worth learning: Article 300 carries the rules that apply to every method, and the individual method articles carry only what is peculiar to that method."
        ),
        ArticleMatchQuestion(
            id: "install-match-service-disconnect",
            scenario: "You need to know how many disconnects a service is allowed and where they may be located.",
            choices: [.services, .overcurrent, .generalRequirements, .loadCalculations],
            answer: .services,
            explanation: "Everything from the utility connection to the service disconnecting means is Article 230: the number of disconnects, where they may be, clearances for overhead conductors, and what may be tapped ahead of them."
        ),
        ArticleMatchQuestion(
            id: "install-match-receptacle-spacing",
            scenario: "A dwelling living room wall is 14 feet long and you need to know how many receptacles it takes.",
            choices: [.branchCircuits, .boxes, .loadCalculations, .definitions],
            answer: .branchCircuits,
            explanation: "Where outlets have to be placed is Article 210. Article 220 tells you what those outlets are worth in volt-amperes once they exist, which is the distinction between the two articles and the one candidates blur."
        ),
        ArticleMatchQuestion(
            id: "install-match-support",
            scenario: "You need the maximum spacing between straps on a run of 1 inch EMT.",
            choices: [.wiringMethods, .generalRequirements, .raceways, .boxes],
            answer: .wiringMethods,
            explanation: "Support spacing for a raceway lives in that raceway's own article in Chapter 3, which is where the wiring-method articles are. Chapter 9 is only the tables, and it has nothing to say about how a pipe is fastened."
        ),
        ArticleMatchQuestion(
            id: "install-match-readily-accessible",
            scenario: "A disconnect has to be readily accessible, and you are arguing about whether one behind a locked door qualifies.",
            choices: [.definitions, .services, .generalRequirements, .overcurrent],
            answer: .definitions,
            explanation: "When the whole question turns on what a phrase means, the answer is in Article 100 and nowhere else. Readily accessible, accessible, in sight from, and dwelling unit are all defined terms, and an argument about one of them is settled by the definition rather than by the article using it."
        ),
    ]
}
