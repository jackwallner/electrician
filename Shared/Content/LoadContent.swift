import Foundation

/// Article 220: the dwelling service and feeder calculation, worked.
///
/// This is the longest question on a journeyman paper. It is also the one most
/// candidates leave blank, because eight steps in the wrong order produce a
/// wrong answer with no way to tell where it went wrong. So the whole room is
/// built around the ORDER: what goes into the demand table, what has its own
/// table, what gets discounted, and what is left out because it cannot run at
/// the same time as something else.
///
/// Section numbers follow the 2023 arrangement, where Article 220 was
/// reorganised. A 2020 book puts general lighting at 220.12 and the lighting
/// demand table at 220.42; the values are the same, so both are cited wherever
/// a candidate on an older cycle would otherwise be sent to the wrong page.
enum LoadContent {

    // MARK: - Flashcards

    static let loadCards: [Flashcard] = [
        Flashcard(
            id: "load-card-va-per-sqft",
            frontTitle: "What is the general lighting load for a dwelling, per square foot?",
            givens: [Given("Occupancy", "Dwelling unit")],
            frontSubtitle: "And what area is it measured over",
            backTitle: "Three volt-amperes per square foot, over the outside dimensions",
            backBody: "The area is computed from the outside dimensions of the dwelling, and it excludes open porches, garages and unfinished spaces not adaptable for future use. An unfinished basement that could be finished is IN. That last part is where the square footage a question gives you and the square footage you should use diverge, and it is deliberate.",
            citation: "220.41 (220.12 in 2020)",
            choice: CardChoice("3 VA/ft²", "1.5 VA/ft²", answerIndex: 0)
        ),
        Flashcard(
            id: "load-card-small-appliance",
            frontTitle: "How much do the small-appliance and laundry circuits add?",
            backTitle: "1500 VA for each small-appliance circuit, and 1500 VA for the laundry circuit",
            backBody: "A dwelling has at least two small-appliance branch circuits, so at minimum that is 3000 VA plus 1500 for laundry. The figure is per CIRCUIT, not per receptacle, so a kitchen with fourteen receptacles on two circuits still counts 3000 VA. The part that decides the whole calculation is where they go: inside the general lighting total, before the demand factor, not added after it.",
            citation: "220.52"
        ),
        Flashcard(
            id: "load-card-demand-bands",
            frontTitle: "What demand factor applies to the general lighting total?",
            frontSubtitle: "And to which loads",
            backTitle: "The first 3000 VA at 100%, the rest up to 120,000 VA at 35%",
            backBody: "Only three things go through this table: general lighting, the small-appliance circuits, and the laundry circuit. The range, the dryer, the fastened-in-place appliances, the heating and the air conditioning all have their own rules and are added after. Pushing a dryer through the 35% band is the single most expensive error in the calculation, because it looks reasonable and shifts the answer by a whole service size.",
            citation: "Table 220.45 (Table 220.42 in 2020)"
        ),
        Flashcard(
            id: "load-card-range",
            frontTitle: "A single 11 kW household range. What goes into the calculation?",
            givens: [Given("Range", "11", unit: "kW"), Given("Quantity", "1")],
            backTitle: "8 kW, from column C",
            backBody: "One range not over 12 kW is 8 kW, whatever the nameplate says: 8.5, 10 and 12 kW ranges all come in at 8. Above 12 kW the column C figure rises 5% for each kilowatt, or major fraction of one, over 12. The nameplate is almost never the number, which is the same lesson Article 430 teaches about motors.",
            citation: "Table 220.55",
            choice: CardChoice("8 kW", "11 kW", answerIndex: 0)
        ),
        Flashcard(
            id: "load-card-dryer",
            frontTitle: "A dryer nameplate reads 4200 VA. What goes into the calculation?",
            givens: [Given("Dryer nameplate", "4200", unit: "VA")],
            backTitle: "5000 VA",
            backBody: "The dryer load is 5000 VA or the nameplate, whichever is LARGER, so a small dryer is carried at 5000 and a 7200 VA dryer is carried at 7200. Reading it as a maximum rather than a minimum is the usual mistake, and it is one of the few places in Article 220 where the code rounds a load up rather than discounting it.",
            citation: "220.54",
            choice: CardChoice("5000 VA", "4200 VA", answerIndex: 0)
        ),
        Flashcard(
            id: "load-card-fastened",
            frontTitle: "When may fastened-in-place appliances be taken at 75%?",
            backTitle: "When there are four or more of them on the same feeder or service",
            backBody: "The count excludes the ranges, dryers, space heating and air conditioning that have rules of their own, so a house with a range, a dryer, a water heater and a dishwasher has TWO appliances for this purpose, not four, and gets no discount. Counting the excluded ones into the group is what makes a candidate discount loads that should have stayed whole.",
            citation: "220.53"
        ),
        Flashcard(
            id: "load-card-noncoincident",
            frontTitle: "Electric heat at 12 kW and air conditioning at 5 kW. What goes in?",
            givens: [Given("Heat", "12", unit: "kW"), Given("Cooling", "5", unit: "kW")],
            backTitle: "The larger one only, so 12 kW",
            backBody: "Loads that cannot run at the same time are noncoincident, and only the largest of them is counted. Heat and air conditioning are the pair every exam uses. Adding them is the mistake; picking the smaller one because it looked like a discount is the other one.",
            citation: "220.60",
            choice: CardChoice("12 kW", "17 kW", answerIndex: 0)
        ),
        Flashcard(
            id: "load-card-optional",
            frontTitle: "What does the optional method for a one-family dwelling do differently?",
            backTitle: "It piles every general load together and takes the first 10 kVA at 100% and the rest at 40%",
            backBody: "The optional calculation puts the general lighting, the small-appliance and laundry circuits, and the NAMEPLATE ratings of the range, dryer and every fastened-in-place appliance into one total, then applies one pair of percentages. Heating and air conditioning are added afterward at their own percentages. It usually lands on a smaller service than the standard method, which is why answering a question that names the optional method with a standard-method result is wrong rather than merely conservative.",
            citation: "220.82"
        ),
        Flashcard(
            id: "load-card-service-minimum",
            frontTitle: "A dwelling calculation comes out at 78 amperes. What service is required?",
            givens: [Given("Calculated", "78", unit: "A")],
            backTitle: "100 amperes",
            backBody: "A one-family dwelling's service disconnecting means has a floor of 100 amperes regardless of what the calculation produces. So a small, all-gas house does not get a 90 ampere service, and the calculation's job in that case is to prove the minimum is enough rather than to size the service.",
            citation: "230.79(C)",
            choice: CardChoice("100 A", "90 A", answerIndex: 0)
        ),
        Flashcard(
            id: "load-card-neutral",
            frontTitle: "Which loads do NOT count toward the neutral?",
            backTitle: "Anything that is purely line to line",
            backBody: "The feeder or service neutral carries the maximum unbalance, so a straight 240 volt load with no neutral connection, such as a water heater or a resistance heater, contributes nothing to it. A range or a dryer has both 240 volt elements and 120 volt controls, so it counts at 70% of its calculated load. That 70% is the number to remember here.",
            citation: "220.61"
        ),
    ]

    // MARK: - Quiz

    static let loadQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "load-quiz-general-lighting",
            prompt: "A dwelling measures 1800 square feet. What is the general lighting and general-use receptacle load before any demand factor?",
            givens: [Given("Floor area", "1800", unit: "ft²")],
            choices: ["5400 VA", "2700 VA", "9000 VA", "1800 VA"],
            answerIndex: 0,
            explanation: "1800 × 3 VA = 5400 VA. The 3 VA per square foot covers the lighting AND the general-use receptacle outlets together, which is why a dwelling calculation never counts living-room receptacles individually.",
            citation: "220.41 (220.12 in 2020)"
        ),
        QuizQuestion(
            id: "load-quiz-demand",
            prompt: "General lighting, small-appliance and laundry circuits total 11,000 VA. What is the load after the demand factor?",
            givens: [Given("Subtotal", "11,000", unit: "VA")],
            choices: ["5800 VA", "11,000 VA", "3850 VA", "8000 VA"],
            answerIndex: 0,
            explanation: "The first 3000 VA stays whole and the remaining 8000 VA comes in at 35%: 3000 + 2800 = 5800 VA. Taking 35% of the whole 11,000 gives 3850, which is the answer you get by skipping the first band, and it is the second choice most people reach for.",
            citation: "Table 220.45 (Table 220.42 in 2020)"
        ),
        QuizQuestion(
            id: "load-quiz-range-over-12",
            prompt: "One household range rated 16 kW. What is its demand load?",
            givens: [Given("Range", "16", unit: "kW"), Given("Quantity", "1")],
            choices: ["9.6 kW", "8 kW", "16 kW", "11.2 kW"],
            answerIndex: 0,
            explanation: "Column C starts at 8 kW for one range and rises 5% for each kilowatt over 12. Sixteen is four over, so 8 × 1.20 = 9.6 kW. Answering 8 kW ignores the increase and answering 16 ignores the table altogether.",
            citation: "Table 220.55"
        ),
        QuizQuestion(
            id: "load-quiz-appliance-count",
            prompt: "A house has a range, a dryer, a water heater, a dishwasher and a disposal. How many appliances count toward the 75% demand factor for fastened-in-place appliances?",
            choices: ["3", "5", "4", "2"],
            answerIndex: 0,
            explanation: "The range and the dryer are excluded because they have their own tables, leaving the water heater, dishwasher and disposal: three. Three is fewer than four, so no discount applies and all three go in whole. Counting the range and dryer to reach five is exactly the error the exclusion exists to catch.",
            citation: "220.53"
        ),
        QuizQuestion(
            id: "load-quiz-optional-vs-standard",
            prompt: "A question specifies the optional calculation method. You work it the standard way and get a larger service. Is that acceptable?",
            choices: [
                "No, the method named is the answer being asked for",
                "Yes, a larger service is always acceptable",
                "Yes, the two methods must agree",
                "Only if the difference is one standard size",
            ],
            answerIndex: 0,
            explanation: "The exam is testing whether you can work the method it named, not whether you can produce a safe installation. The two methods routinely disagree by a full service size, and the optional one is usually smaller, so the standard-method result is a wrong answer on that question even though it would be a legal installation.",
            citation: "220.82, 220.40"
        ),
        QuizQuestion(
            id: "load-quiz-noncoincident",
            prompt: "A dwelling has 9 kW of electric space heating and a 4 kW air conditioner. What goes into the service calculation?",
            givens: [Given("Heat", "9", unit: "kW"), Given("Cooling", "4", unit: "kW")],
            choices: ["9 kW", "13 kW", "4 kW", "6.5 kW"],
            answerIndex: 0,
            explanation: "Noncoincident loads count once, at the larger value: 9 kW. The 13 kW answer adds them, and the 6.5 kW answer applies the optional method's 65% heating factor in a standard-method calculation, where it does not belong.",
            citation: "220.60"
        ),
        QuizQuestion(
            id: "load-quiz-neutral",
            prompt: "A dwelling's calculated range load is 8000 VA. What does the range contribute to the neutral load?",
            givens: [Given("Range demand", "8000", unit: "VA")],
            choices: ["5600 VA", "8000 VA", "4000 VA", "0 VA"],
            answerIndex: 0,
            explanation: "A range is taken at 70% of its calculated load for the neutral, so 8000 × 0.70 = 5600 VA. It is not zero, because the range has 120 volt controls and elements; it is not the full 8000, because the bulk of it is line to line.",
            citation: "220.61(B)"
        ),
        QuizQuestion(
            id: "load-quiz-service-minimum",
            prompt: "A one-family dwelling calculates to 21,600 VA on a 120/240 V service. What is the minimum service rating?",
            givens: [Given("Calculated", "21,600", unit: "VA"), Given("System", "120/240V")],
            choices: ["100 A", "90 A", "125 A", "150 A"],
            answerIndex: 0,
            explanation: "21,600 ÷ 240 = 90 A, and 90 is a standard rating, but a one-family dwelling service has a 100 ampere floor. The calculation tells you the minimum is not exceeded; the floor tells you what to install.",
            citation: "230.79(C), 240.6(A)"
        ),
        QuizQuestion(
            id: "load-quiz-where-circuits-go",
            prompt: "In the standard method, where do the two small-appliance circuits belong?",
            choices: [
                "Inside the general lighting subtotal, before the demand factor",
                "Added after the demand factor, at 100%",
                "Inside the fastened-in-place appliance group",
                "They are covered by the 3 VA per square foot",
            ],
            answerIndex: 0,
            explanation: "They go into the subtotal that the demand table then discounts, alongside the general lighting and the laundry circuit. Adding them afterward at 100% inflates the service by roughly 2900 VA, which is enough to move the answer up a standard size on a small house.",
            citation: "220.52, Table 220.45"
        ),
    ]

    // MARK: - Worked calculations

    /// Two versions of the same house, one worked each way. Running the
    /// standard and optional methods on identical inputs is the fastest way to
    /// show that the methods genuinely disagree, which is the fact that makes
    /// "the question named a method" matter.
    static let workedExamples: [CalcScenario] = [
        CalcScenario(
            id: "load-calc-standard-dwelling",
            situation: "Standard method. A 2000 square foot single-family dwelling on a 120/240 V single-phase service. What is the minimum standard service rating?",
            givens: [
                Given("Floor area", "2000", unit: "ft²"),
                Given("Range", "12", unit: "kW"),
                Given("Dryer", "5500", unit: "VA"),
                Given("Water heater", "4500", unit: "VA"),
                Given("Dishwasher", "1200", unit: "VA"),
                Given("Disposal", "900", unit: "VA"),
                Given("Compactor", "1000", unit: "VA"),
                Given("Air conditioning", "5000", unit: "VA"),
                Given("Electric heat", "10,000", unit: "VA"),
            ],
            choices: ["100 A", "125 A", "150 A", "175 A"],
            answerIndex: 2,
            steps: [
                "General lighting: 2000 ft² × 3 VA = 6000 VA.",
                "Add the circuits that belong inside it: two small-appliance circuits at 1500 VA each plus a 1500 VA laundry circuit = 4500 VA. Subtotal 10,500 VA.",
                "Demand factor on that subtotal only: 3000 VA at 100%, the remaining 7500 VA at 35% = 2625 VA. Net general load 5625 VA.",
                "Range: one unit not over 12 kW reads column C flat at 8 kW = 8000 VA.",
                "Dryer: the greater of nameplate and 5000 VA, so 5500 VA.",
                "Fastened-in-place appliances: water heater, dishwasher, disposal and compactor total 7600 VA. That is four appliances, so 220.53 takes them at 75% = 5700 VA.",
                "Heat against cooling: they cannot run together, so only the larger counts. 10,000 VA.",
                "Total 5625 + 8000 + 5500 + 5700 + 10,000 = 34,825 VA. Divided by 240 V that is 145.1 A, and the smallest standard rating that carries it is 150 A.",
            ],
            citation: "220.41, Table 220.45, 220.52, 220.53, 220.54, Table 220.55, 220.60, 240.6(A)"
        ),
        CalcScenario(
            id: "load-calc-optional-dwelling",
            situation: "The same house, worked by the optional method for a one-family dwelling. What is the minimum standard service rating?",
            givens: [
                Given("Floor area", "2000", unit: "ft²"),
                Given("Range", "12", unit: "kW"),
                Given("Dryer", "5500", unit: "VA"),
                Given("Appliances", "7600", unit: "VA"),
                Given("Air conditioning", "5000", unit: "VA"),
                Given("Electric heat", "10,000", unit: "VA"),
                Given("Method", "Optional"),
            ],
            choices: ["100 A", "125 A", "150 A", "200 A"],
            answerIndex: 1,
            steps: [
                "The optional method puts every general load in one pile, and it uses NAMEPLATE ratings: no column C for the range and no separate dryer minimum.",
                "General lighting 6000 VA, plus small-appliance and laundry 4500 VA = 10,500 VA.",
                "Add the nameplates: range 12,000 + dryer 5500 + appliances 7600 = 25,100 VA. Pile total 35,600 VA.",
                "First 10,000 VA at 100%, the remaining 25,600 VA at 40% = 10,240 VA. General total 20,240 VA.",
                "Heating and air conditioning are added separately at their own percentages: air conditioning at 100% is 5000 VA, electric heat with fewer than four separately controlled units at 65% is 6500 VA. The larger is 6500 VA.",
                "Total 20,240 + 6500 = 26,740 VA. Divided by 240 V that is 111.4 A, so a 125 A service.",
                "The standard method put the same house at 150 A. Both are correct calculations; only the one the question asked for is the right answer.",
            ],
            citation: "220.82, 220.82(B), 220.82(C), 240.6(A)"
        ),
        CalcScenario(
            id: "load-calc-three-ranges",
            situation: "Three identical household ranges, each rated 14 kW, on one feeder. What is the demand load?",
            givens: [
                Given("Ranges", "3"),
                Given("Each rated", "14", unit: "kW"),
            ],
            choices: ["14 kW", "15.4 kW", "42 kW", "24 kW"],
            answerIndex: 1,
            steps: [
                "Column C of Table 220.55 gives 14 kW for three ranges. That is the starting figure, and it already assumes each range is not over 12 kW.",
                "These are 14 kW, which is 2 kW over. Column C rises 5% for each kilowatt or major fraction above 12, so 2 kW is a 10% increase.",
                "14 kW × 1.10 = 15.4 kW.",
                "Answering 14 kW stops before the increase; answering 42 kW ignores the table and adds nameplates.",
            ],
            citation: "Table 220.55"
        ),
    ]
}
