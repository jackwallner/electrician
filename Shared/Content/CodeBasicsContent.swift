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
            frontTitle: "How the book is arranged",
            frontSubtitle: "Nine chapters, and the order is the point",
            backTitle: "Chapters 1-4 are general, 5-7 are exceptions",
            backBody: "Chapters 1 through 4 apply to everything. Chapters 5, 6 and 7 cover special occupancies, equipment and conditions, and they amend the first four. Chapter 8 is communications and stands mostly alone. Chapter 9 is nothing but tables. When a special-occupancy rule and a general rule disagree, the special one wins.",
            citation: "90.3"
        ),
        Flashcard(
            id: "basics-shall",
            frontTitle: "Shall, shall not, and shall be permitted",
            frontSubtitle: "Three phrases that decide test questions",
            backTitle: "Requirement, prohibition, permission",
            backBody: "\"Shall\" is mandatory. \"Shall not\" is prohibited. \"Shall be permitted\" means allowed but not required, and that third one is where candidates lose points: an answer that says something is required when the code only permits it is wrong even though the practice is common.",
            citation: "90.5",
            choice: CardChoice("Required", "Allowed but not required", answerIndex: 1)
        ),
        Flashcard(
            id: "basics-informational-note",
            frontTitle: "Informational notes",
            frontSubtitle: "Printed right there in the book",
            backTitle: "Explanatory, not enforceable",
            backBody: "An informational note explains or points elsewhere. It is not a requirement and cannot be cited as one. The 3% branch-circuit voltage-drop figure everyone quotes lives in a note, which is why a design can exceed it and still pass inspection.",
            citation: "90.5(C)",
            choice: CardChoice("Enforceable", "Explanatory only", answerIndex: 1)
        ),
        Flashcard(
            id: "basics-readily-accessible",
            frontTitle: "Accessible vs. readily accessible",
            frontSubtitle: "Two terms, one word apart",
            backTitle: "One may need tools, the other may not",
            backBody: "Accessible means you can get to it, possibly by removing a panel or climbing. Readily accessible means you can reach it quickly without tools, without a ladder, and without moving obstacles. A disconnect required to be readily accessible cannot be behind a locked panel you need a screwdriver to open.",
            citation: "Art. 100"
        ),
        Flashcard(
            id: "basics-continuous-load",
            frontTitle: "Continuous load",
            frontSubtitle: "Three hours is the line",
            backTitle: "Maximum current for 3 hours or more",
            backBody: "A load is continuous if its maximum current is expected to run for three hours or more. It matters because the branch circuit and its overcurrent device get sized at 125% of the continuous portion. Lighting in a store is the standard example; a household clothes dryer is not.",
            citation: "Art. 100, 210.19(A), 210.20(A)"
        ),
        Flashcard(
            id: "basics-ampacity-def",
            frontTitle: "Ampacity",
            frontSubtitle: "Not simply \"how much it can carry\"",
            backTitle: "Current a conductor can carry continuously without exceeding its temperature rating",
            backBody: "The definition carries its own conditions: continuously, and under the conditions of use. That is why the same conductor has different ampacities in a hot attic and in a cool basement, and why bundling changes the number without changing the wire.",
            citation: "Art. 100, 310.14"
        ),
    ]

    static let navigationQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "basics-q-chapter9",
            prompt: "You need the interior area of a trade size of conduit to check fill. Where do you look?",
            choices: [
                "Chapter 9 tables",
                "Article 358, EMT",
                "Article 300, wiring methods",
                "Annex C",
            ],
            answerIndex: 0,
            explanation: "The raceway articles tell you how to install the pipe. They do not carry the fill math. Every conductor area, raceway area and fill percentage sits in Chapter 9. Annex C is the shortcut table for conductors that are all the same size, and it is informative rather than required.",
            citation: "Ch. 9 Tables 1, 4, 5"
        ),
        QuizQuestion(
            id: "basics-q-special",
            prompt: "A Chapter 5 rule for a hazardous location conflicts with a general rule in Chapter 3. Which applies?",
            choices: [
                "The Chapter 5 rule",
                "The Chapter 3 rule",
                "Whichever is more restrictive",
                "Neither, the authority decides",
            ],
            answerIndex: 0,
            explanation: "Chapters 5 through 7 supplement or modify the first four. The special rule wins, and it does so whether it is more restrictive or less. Reaching for \"whichever is more restrictive\" is a habit from the field, not a rule in the book.",
            citation: "90.3"
        ),
        QuizQuestion(
            id: "basics-q-continuous",
            prompt: "A 40 A continuous load is fed by a branch circuit. What is the minimum conductor ampacity before any derating?",
            givens: [.load(40), Given("Duty", "continuous")],
            choices: ["50 A", "40 A", "45 A", "32 A"],
            answerIndex: 0,
            explanation: "A continuous load is sized at 125%: 40 × 1.25 = 50 A. The same 125% applies to the overcurrent device. Candidates who multiply by 1.25 once and forget the second application get a conductor that its own breaker overloads.",
            citation: "210.19(A), 210.20(A)"
        ),
        QuizQuestion(
            id: "basics-q-definitions",
            prompt: "An exam question turns on whether an enclosure counts as a \"cabinet\" or a \"cutout box.\" Where is that settled?",
            choices: [
                "Article 100",
                "Article 312",
                "Article 314",
                "Article 110",
            ],
            answerIndex: 0,
            explanation: "Definitions used in more than one article live in Article 100. Article 312 is where the installation requirements for those enclosures are, but the meaning of the word itself is settled in the definitions and nowhere else.",
            citation: "Art. 100, Art. 312"
        ),
    ]
}
