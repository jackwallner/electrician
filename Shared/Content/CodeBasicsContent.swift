import Foundation

/// The vocabulary and navigation content: what the code book is, how it is
/// arranged, and the handful of definitions that decide questions on their own.
///
/// Every explanation here is written from scratch. Article numbers are cited so
/// a reader can look the rule up in their own code book, which is the habit the
/// exam actually tests. Nothing quotes NEC text.
enum CodeBasicsContent {

    static let meetTheCode: [Flashcard] = [
        Flashcard(
            id: "basics-chapters",
            frontTitle: String(localized: "How the book is arranged"),
            frontSubtitle: String(localized: "Nine chapters, and the order is the point"),
            backTitle: String(localized: "Chapters 1-4 are general, 5-7 are exceptions"),
            backBody: String(localized: "Chapters 1 through 4 apply to everything. Chapters 5, 6 and 7 cover special occupancies, equipment and conditions, and they amend the first four. Chapter 8 is communications and stands mostly alone. Chapter 9 is nothing but tables. When a special-occupancy rule and a general rule disagree, the special one wins."),
            citation: "90.3"
        ),
        Flashcard(
            id: "basics-shall",
            frontTitle: String(localized: "What does \"shall be permitted\" mean?"),
            frontSubtitle: String(localized: "Three phrases that decide test questions"),
            backTitle: String(localized: "Requirement, prohibition, permission"),
            backBody: String(localized: "\"Shall\" is mandatory. \"Shall not\" is prohibited. \"Shall be permitted\" means allowed but not required, and that third one is where candidates lose points: an answer that says something is required when the code only permits it is wrong even though the practice is common."),
            citation: "90.5",
            choice: CardChoice(String(localized: "Required"), String(localized: "Allowed but not required"), answerIndex: 1)
        ),
        Flashcard(
            id: "basics-informational-note",
            frontTitle: String(localized: "Informational notes"),
            frontSubtitle: String(localized: "Printed right there in the book"),
            backTitle: String(localized: "Explanatory, not enforceable"),
            backBody: String(localized: "An informational note explains or points elsewhere; it does not impose a requirement. The general 3% branch-circuit voltage-drop recommendation is in a note. Some specific applications have mandatory voltage-drop limits, so the note does not settle every installation."),
            citation: "90.5(C)",
            choice: CardChoice(String(localized: "Enforceable"), String(localized: "Explanatory only"), answerIndex: 1)
        ),
        Flashcard(
            id: "basics-readily-accessible",
            frontTitle: String(localized: "Accessible vs. readily accessible"),
            frontSubtitle: String(localized: "Two terms, one word apart"),
            backTitle: String(localized: "One may need tools, the other may not"),
            backBody: String(localized: "Accessible equipment can be approached for service or operation. Readily accessible equipment must be reachable quickly without portable ladders, removing obstacles, or using tools other than keys. A key-operated lock alone does not disqualify it; a cover requiring a screwdriver does. Accessibility of wiring methods has its own definition."),
            citation: String(localized: "Art. 100")
        ),
        Flashcard(
            id: "basics-continuous-load",
            frontTitle: String(localized: "Continuous load"),
            frontSubtitle: String(localized: "Three hours is the line"),
            backTitle: String(localized: "Maximum current for 3 hours or more"),
            backBody: String(localized: "A load is continuous if its maximum current is expected for three hours or more. Ordinary branch-circuit conductors and protection are sized for the noncontinuous load plus 125% of the continuous load. A listed assembly rated for continuous operation at 100% can qualify for an exception; check the equipment and the applicable rule."),
            citation: String(localized: "Art. 100, 210.19(A), 210.20(A)")
        ),
        Flashcard(
            id: "basics-ampacity-def",
            frontTitle: String(localized: "Ampacity"),
            frontSubtitle: String(localized: "Not simply \"how much it can carry\""),
            backTitle: String(localized: "Current a conductor can carry continuously without exceeding its temperature rating"),
            backBody: String(localized: "The definition carries its own conditions: continuously, and under the conditions of use. That is why the same conductor has different ampacities in a hot attic and in a cool basement, and why bundling changes the number without changing the wire."),
            citation: String(localized: "Art. 100, 310.14")
        ),
    ]

    static let navigationQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "basics-q-chapter9",
            prompt: String(localized: "You need the interior area of a trade size of conduit to check fill. Where do you look?"),
            choices: [
                String(localized: "Chapter 9 tables"),
                String(localized: "Article 358, EMT"),
                String(localized: "Article 300, wiring methods"),
                String(localized: "Annex C"),
            ],
            answerIndex: 0,
            explanation: String(localized: "The raceway articles tell you how to install the pipe. They do not carry the fill math. Every conductor area, raceway area and fill percentage sits in Chapter 9. Annex C is the shortcut table for conductors that are all the same size, and it is informative rather than required."),
            citation: String(localized: "Ch. 9 Tables 1, 4, 5")
        ),
        QuizQuestion(
            id: "basics-q-special",
            prompt: String(localized: "A Chapter 5 rule for a hazardous location conflicts with a general rule in Chapter 3. Which applies?"),
            choices: [
                String(localized: "The Chapter 5 rule"),
                String(localized: "The Chapter 3 rule"),
                String(localized: "Whichever is more restrictive"),
                String(localized: "Neither, the authority decides"),
            ],
            answerIndex: 0,
            explanation: String(localized: "Chapters 5 through 7 supplement or modify the first four. The special rule wins, and it does so whether it is more restrictive or less. Reaching for \"whichever is more restrictive\" is a habit from the field, not a rule in the book."),
            citation: "90.3"
        ),
        QuizQuestion(
            id: "basics-q-continuous",
            prompt: String(localized: "An ordinary branch circuit, without the listed 100%-rated assembly exception, supplies a 40 A continuous load. What is the minimum conductor ampacity before correction and adjustment?"),
            givens: [.load(40), Given(String(localized: "Duty"), String(localized: "continuous"))],
            choices: ["50 A", "40 A", "45 A", "32 A"],
            answerIndex: 0,
            explanation: String(localized: "40 × 1.25 = 50 A. The conductor and the overcurrent device are each checked against this 50 A minimum. Apply 125% once to the load for each check, rather than multiplying the result by 125% again."),
            citation: "210.19(A), 210.20(A)"
        ),
        QuizQuestion(
            id: "basics-q-definitions",
            prompt: String(localized: "An exam question turns on whether an enclosure counts as a \"cabinet\" or a \"cutout box.\" Where is that settled?"),
            choices: [
                String(localized: "Article 100"),
                String(localized: "Article 312"),
                String(localized: "Article 314"),
                String(localized: "Article 110"),
            ],
            answerIndex: 0,
            explanation: String(localized: "Definitions used in more than one article live in Article 100. Article 312 is where the installation requirements for those enclosures are, but the meaning of the word itself is settled in the definitions and nowhere else."),
            citation: String(localized: "Art. 100, Art. 312")
        ),
    ]
}
