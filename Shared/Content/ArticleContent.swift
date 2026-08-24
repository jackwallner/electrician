import Foundation

/// "Which article governs this?"
///
/// The licensing exam is open book and timed. Candidates rarely fail because
/// they do not know a rule; they fail because they burn four minutes finding
/// it. This drill practises the lookup itself: read a scenario, name the
/// article, before opening anything.
enum ArticleContent {

    static let articleCards: [Flashcard] = CodeArticle.allCases.map { article in
        Flashcard(
            id: "article-\(article.rawValue)",
            frontTitle: article.displayName,
            frontSubtitle: article.citation,
            backTitle: "When to go here",
            backBody: article.howToSpot,
            citation: article.citation
        )
    }

    static let articleMatch: [ArticleMatchQuestion] = [
        ArticleMatchQuestion(
            id: "am-receptacle-spacing",
            scenario: "A dwelling-unit wall is 14 feet long with no doorway. You need to know how many receptacle outlets are required and where they go.",
            choices: [.branchCircuits, .loadCalculations, .boxes, .definitions],
            answer: .branchCircuits,
            explanation: "Outlet placement and what a branch circuit must serve is Article 210. Load calculations would come later if you were sizing the service, but the spacing rule itself is a branch-circuit requirement."
        ),
        ArticleMatchQuestion(
            id: "am-derate-attic",
            scenario: "Eight current-carrying conductors share a raceway in an attic that reaches 48°C. You need the usable ampacity.",
            choices: [.conductors, .overcurrent, .raceways, .branchCircuits],
            answer: .conductors,
            explanation: "Correction for heat and adjustment for bundling are both conductor rules in Article 310. Article 240 would only come in afterwards, when you protect whatever ampacity you ended up with."
        ),
        ArticleMatchQuestion(
            id: "am-emt-size",
            scenario: "Nine 8 AWG THHN conductors need to run in EMT and you have to pick the trade size.",
            choices: [.raceways, .conductors, .boxes, .branchCircuits],
            answer: .raceways,
            explanation: "Fill percentages and the area tables are all in Chapter 9. Article 358 covers how EMT gets installed and supported but does not carry the fill math, which is the part people look for in the wrong place."
        ),
        ArticleMatchQuestion(
            id: "am-box-volume",
            scenario: "A device box holds six 12 AWG conductors, three grounds, internal clamps and two yokes. You need the minimum volume.",
            choices: [.boxes, .raceways, .conductors, .definitions],
            answer: .boxes,
            explanation: "Box fill is 314.16(B). The counting rules there are what the question is really testing: grounds together are one allowance, clamps together are one, each yoke is two."
        ),
        ArticleMatchQuestion(
            id: "am-electrode",
            scenario: "You need to know whether a metal underground water pipe qualifies as a grounding electrode and how much of it must be in contact with earth.",
            choices: [.grounding, .definitions, .branchCircuits, .conductors],
            answer: .grounding,
            explanation: "Electrodes, bonding and every grounding conductor live in Article 250. It is the longest article in the book and the one most worth being able to navigate by heart."
        ),
        ArticleMatchQuestion(
            id: "am-motor-conductor",
            scenario: "A 10 hp three-phase motor needs branch-circuit conductors sized. The nameplate reads 28 amps.",
            choices: [.motors, .conductors, .overcurrent, .loadCalculations],
            answer: .motors,
            explanation: "Motors are the exception to almost everything. Article 430 sends you to its own full-load current tables and tells you to size conductors from the table rather than the nameplate, which is exactly the trap in the scenario."
        ),
        ArticleMatchQuestion(
            id: "am-dwelling-service",
            scenario: "A 2,400 square foot dwelling with a range, a dryer and a water heater needs a service size.",
            choices: [.loadCalculations, .branchCircuits, .overcurrent, .conductors],
            answer: .loadCalculations,
            explanation: "Square footage plus a list of appliances is the signature of a load calculation. Article 220 has both the standard method and the optional method, and the two give different answers on purpose."
        ),
        ArticleMatchQuestion(
            id: "am-breaker-standard",
            scenario: "A calculation gives 138 amps and you need to know what breaker is permitted.",
            choices: [.overcurrent, .conductors, .loadCalculations, .definitions],
            answer: .overcurrent,
            explanation: "The standard ratings list and the rules about rounding to it are Article 240. Whether you may round up at all depends on what the circuit serves, which is also in 240."
        ),
        ArticleMatchQuestion(
            id: "am-readily-accessible",
            scenario: "An inspector says a disconnect is not \"readily accessible.\" You want to check exactly what that phrase requires.",
            choices: [.definitions, .branchCircuits, .grounding, .overcurrent],
            answer: .definitions,
            explanation: "When a dispute is about what a term means rather than what a number is, it is settled in Article 100. Accessible and readily accessible are separately defined and the difference decides the argument."
        ),
        ArticleMatchQuestion(
            id: "am-egc-size",
            scenario: "A 200 A feeder needs an equipment grounding conductor sized.",
            choices: [.grounding, .conductors, .overcurrent, .loadCalculations],
            answer: .grounding,
            explanation: "Equipment grounding conductors are sized from the rating of the overcurrent device ahead of them, using the table in Article 250. Article 310 sizes conductors for ampacity, which is a different question."
        ),
    ]
}
