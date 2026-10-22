import Foundation

func text(_ value: String) -> String {
    value.replacingOccurrences(of: " \u{2014} ", with: ", ")
        .replacingOccurrences(of: "\u{2014}", with: ", ")
}

func json(_ value: Any) -> Any {
    if let value = value as? String { return text(value) }
    if let value = value as? Date { return value.timeIntervalSince1970 }
    if let value = value as? any RawRepresentable { return json(value.rawValue) }
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .optional:
        return mirror.children.first.map { json($0.value) } ?? NSNull()
    case .collection:
        return mirror.children.map { json($0.value) }
    case .set:
        return mirror.children.map { json($0.value) }.sorted { String(describing: $0) < String(describing: $1) }
    case .dictionary:
        var result: [String: Any] = [:]
        for child in mirror.children {
            let pair = Array(Mirror(reflecting: child.value).children)
            precondition(pair.count == 2)
            result[String(describing: json(pair[0].value))] = json(pair[1].value)
        }
        return result
    case .struct, .tuple:
        return Dictionary(uniqueKeysWithValues: mirror.children.map {
            (String($0.label ?? ""), json($0.value))
        })
    default:
        if let number = value as? NSNumber { return number }
        if value is NSNull { return NSNull() }
        fatalError("Unsupported exported type: \(type(of: value))")
    }
}

func drill(_ value: Drill) -> [String: Any] {
    var result: [String: Any] = ["id": value.id, "title": value.title, "subtitle": value.subtitle, "isPlus": value.isPlus]
    switch value.kind {
    case let .flashcards(items): result["kind"] = "flashcards"; result["items"] = json(items)
    case let .quiz(items): result["kind"] = "quiz"; result["items"] = json(items)
    case let .articleMatch(items):
        result["kind"] = "quiz"; result["sourceKind"] = "articleMatch"
        result["items"] = json(items.map(\.asQuizQuestion))
    case let .calc(items): result["kind"] = "calc"; result["items"] = json(items)
    }
    return result
}

func tables() -> [String: Any] {
    [
        "edition": NECTables.edition, "stableSince": NECTables.stableSince.rawValue,
        "verifiedThrough": NECTables.verifiedThrough.rawValue, "coverageLabel": NECTables.coverageLabel,
        "editionNote": NECTables.editionNote, "coverageNote": NECTables.coverageNote,
        "conductorSizes": NECTables.conductorSizes, "circularMils": NECTables.circularMils,
        "circularMilsExtended": NECTables.circularMilsExtended, "copperAmpacity": NECTables.copperAmpacity,
        "aluminumAmpacity": NECTables.aluminumAmpacity, "standardOCPD": NECTables.standardOCPD,
        "smallConductorLimit": NECTables.smallConductorLimit, "conductorVolume": NECTables.conductorVolume,
        "emtArea": NECTables.emtArea, "emtTradeSizes": NECTables.emtTradeSizes, "thhnArea": NECTables.thhnArea,
        "gecCopperService": NECTables.gecCopperService, "gecAluminumService": NECTables.gecAluminumService,
        "egcRows": NECTables.egcRows, "motorRatings": NECTables.motorRatings,
        "singlePhaseFLC": NECTables.singlePhaseFLC, "threePhaseFLC": NECTables.threePhaseFLC,
        "rangeColumnC": NECTables.rangeColumnC, "boxSizes": NECTables.boxSizes, "supportRules": NECTables.supportRules,
        "ambient": (-10...85).map { celsius in
            ["celsius": celsius, "columns": Dictionary(uniqueKeysWithValues: TemperatureRating.allCases.map {
                (String($0.rawValue), json(NECTables.ambientCorrection(celsius: celsius, column: $0) as Any))
            })] as [String: Any]
        },
        "adjustment": (0...100).map { ["count": $0, "factor": NECTables.adjustmentFactor(currentCarrying: $0)] as [String: Any] },
        "fillPercent": (1...50).map { ["count": $0, "factor": NECTables.fillPercent(conductorCount: $0)] as [String: Any] },
    ]
}

func content() -> [String: Any] {
    [
        "schema": 1, "rooms": DrillLibrary.rooms.map {
            ["id": $0.id, "name": $0.name, "tagline": $0.tagline, "icon": $0.icon,
             "isFree": $0.isFree, "drills": $0.drills.map(drill)] as [String: Any]
        },
        "articles": CodeArticle.allCases.map {
            ["id": $0.rawValue, "citation": $0.citation, "displayName": $0.displayName, "shortName": $0.shortName, "howToSpot": $0.howToSpot]
        },
        "primer": json(HowToPlayContent.pages), "tables": json(tables()),
        "jurisdictions": json(Jurisdictions.all), "jurisdictionsReviewed": Jurisdictions.reviewed,
        "otherJurisdiction": json(Jurisdictions.other),
        "skills": PracticeSkill.allCases.map {
            ["id": $0.rawValue, "title": $0.title, "subtitle": $0.subtitle, "icon": $0.icon, "roomID": $0.roomID]
        },
        "licenseTracks": LicenseTrack.allCases.map {
            ["id": $0.rawValue, "name": $0.displayName, "shortName": $0.shortName, "detail": $0.detail, "emphasis": $0.emphasis]
        },
        "candidateEditions": CandidateEdition.allCases.map {
            ["id": $0.rawValue, "name": $0.displayName, "note": $0.note, "edition": json($0.edition as Any)] as [String: Any]
        },
        "experienceLevels": ExperienceLevel.allCases.map {
            ["id": $0.rawValue, "title": $0.title, "detail": $0.detail, "recommendedRoom": HowToPlayContent.recommendedRoom(forSkillLevel: $0.rawValue).id]
        },
        "studyPaces": StudyPace.allCases.map {
            ["id": $0.rawValue, "title": $0.title, "summary": $0.summary, "priorities": $0.priorities, "urgent": $0.isUrgent] as [String: Any]
        },
        "freeItemCount": DrillLibrary.freeItemCount, "membershipItemCount": DrillLibrary.membershipItemCount,
        "membershipDrillCount": DrillLibrary.membershipDrillCount,
    ]
}

func parity() -> [String: Any] {
    let seeds: [UInt64] = [0, 1, 2, 17, 65535, 20_261_017, 987_654_321, UInt64.max]
    var generated: [[String: Any]] = []
    for skill in PracticeSkill.allCases {
        for seed in seeds {
            var rng: RandomNumberGenerator = SeededGenerator(seed: seed)
            let items = (0..<8).map { index -> [String: Any] in
                let scenario = EndlessPractice.scenario(for: skill, using: &rng)
                var result = json(scenario) as! [String: Any]
                result["id"] = "fixture-\(skill.rawValue)-\(seed)-\(index)"
                return result
            }
            generated.append(["skill": skill.rawValue, "seed": String(seed), "items": items])
        }
    }
    var ampacity: [[String: Any]] = []
    for size in NECTables.conductorSizes {
        for material in ConductorMaterial.allCases {
            for rating in TemperatureRating.allCases {
                for ambient in [25, 30, 35, 45, 60, 65] {
                    for count in [3, 7, 21] {
                        ampacity.append(["size": size, "material": material.rawValue, "insulation": rating.rawValue,
                            "termination": 75, "ambient": ambient, "count": count,
                            "result": json(FieldCalculators.ampacity(size: size, material: material, insulation: rating,
                                termination: .c75, ambientCelsius: ambient, currentCarrying: count) as Any)])
                    }
                }
            }
        }
    }
    let dates = ["2026-03-08T07:59:00Z", "2026-03-08T08:00:00Z", "2026-10-17T07:00:00Z", "2026-11-01T08:00:00Z"]
    let daily = dates.map { value -> [String: Any] in
        let day = ISO8601DateFormatter().date(from: value)!
        let challenge = CodeMinuteContent.challenge(for: day)
        return ["at": value, "key": challenge.dayKey, "questions": json(challenge.questions)]
    }
    let permutations = ["", "alpha", "electrician-2026", "article-match-4"].map { seed in
        ["seed": seed, "indices": ChoiceShuffle.permutation(count: 4, seed: seed)] as [String: Any]
    }
    let streams = seeds.map { seed -> [String: Any] in
        var rng = SeededGenerator(seed: seed)
        return ["seed": String(seed), "values": (0..<8).map { _ in String(rng.next()) }]
    }
    let draws = seeds.map { seed -> [String: Any] in
        var rng = SeededGenerator(seed: seed)
        return ["seed": String(seed), "draws": (0..<10).map { _ in
            ["integer": Int.random(in: -7...15, using: &rng), "boolean": Bool.random(using: &rng),
             "double": Double.random(in: 0.8...1.2, using: &rng)] as [String: Any]
        }]
    }
    let formatting = [-2.25, -1.35, -1.25, -0.0, 0.0, 0.005, 0.00001, 0.0001234567, 0.45, 1.05, 1.25, 1.35, 1.005, 21.84, 22.5, 123.456789].map {
        ["value": $0, "roundedAmps": $0.roundedAmps, "roundedAmpsText": $0.roundedAmpsText,
         "factorText": $0.factorText, "areaText": $0.areaText, "volumeText": $0.volumeText,
         "trimmedAmps": $0.trimmedAmps] as [String: Any]
    }
    return ["schema": 1, "generated": generated, "ampacity": ampacity, "daily": daily,
            "permutations": permutations, "streams": streams, "draws": draws, "formatting": formatting]
}

precondition(CommandLine.arguments.count == 3, "Expected content and parity output paths")
for (value, path) in [(content(), CommandLine.arguments[1]), (parity(), CommandLine.arguments[2])] {
    var data = try JSONSerialization.data(withJSONObject: json(value), options: [.prettyPrinted, .sortedKeys])
    data.append(10)
    try data.write(to: URL(fileURLWithPath: path))
}
print("Exported \(DrillLibrary.rooms.count) rooms, \(DrillLibrary.freeItemCount + DrillLibrary.membershipItemCount) authored items, 640 generated cases and 1,944 ampacity references")
