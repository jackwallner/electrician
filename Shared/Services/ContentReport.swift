import Foundation

/// "Report a possible issue" on a graded question.
///
/// This app's biggest trust risk is not a crash, it is a number. A candidate
/// who believes an ampacity is wrong, or that a question is answering against a
/// different code edition than their jurisdiction adopted, currently has one
/// route: leave a one-star review saying so. That is the worst possible place
/// for that information to land, for them and for us.
///
/// So a miss gets a low-friction path to a real report, and the report carries
/// what makes it actionable without asking the reader to transcribe anything:
/// the item id, the citation, the edition the app computed against, the answer
/// it claimed, and what they picked. Everything else is their own words.
///
/// It goes out as a mailto draft for the same reason the feedback funnel does:
/// no account, no analytics endpoint, no practice data leaving the phone.
enum ContentReport {

    /// What the reader was looking at when they tapped Report.
    struct Context: Equatable, Sendable {
        let itemID: String
        let prompt: String
        let citation: String?
        let correctAnswer: String
        let selectedAnswer: String?

        init(itemID: String, prompt: String, citation: String?, correctAnswer: String, selectedAnswer: String?) {
            self.itemID = itemID
            self.prompt = prompt
            self.citation = citation
            self.correctAnswer = correctAnswer
            self.selectedAnswer = selectedAnswer
        }
    }

    /// The categories worth separating, because they route to different fixes:
    /// a wrong number is a content bug, an edition mismatch usually is not.
    enum Category: String, CaseIterable, Identifiable, Sendable {
        case wrongAnswer
        case unclearExplanation
        case editionMismatch
        case typo

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .wrongAnswer: return "The answer looks wrong"
            case .unclearExplanation: return "The explanation is unclear"
            case .editionMismatch: return "Wrong code edition for my area"
            case .typo: return "Typo or formatting"
            }
        }
    }

    static func mailURL(context: Context, category: Category, appVersion: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppStoreLinks.feedbackEmail

        var lines = [
            "",
            "",
            "----- please leave the details below -----",
            "Issue: \(category.displayName)",
            "Item: \(context.itemID)",
            "Edition: \(NECTables.edition)",
            "Citation: \(context.citation ?? "none")",
            "App reported: \(context.correctAnswer)",
        ]
        if let selected = context.selectedAnswer {
            lines.append("You picked: \(selected)")
        }
        lines.append("App version: \(appVersion)")
        lines.append("Question: \(context.prompt)")

        components.queryItems = [
            URLQueryItem(name: "subject", value: "Electrician content report: \(category.displayName)"),
            URLQueryItem(name: "body", value: lines.joined(separator: "\n")),
        ]
        return components.url
    }

    static var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(short) (\(build))"
    }
}
