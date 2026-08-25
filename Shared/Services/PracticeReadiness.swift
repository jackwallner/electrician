import Foundation

struct PracticeReadinessMetrics: Equatable, Sendable {
    enum Level: Equatable, Sendable {
        case notStarted
        case building
        case consistent
    }

    let attempts: Int
    let correct: Int
    let practicedRooms: Int
    let availableRooms: Int

    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correct) / Double(attempts)
    }

    var coverage: Double {
        guard availableRooms > 0 else { return 0 }
        return min(1, Double(practicedRooms) / Double(availableRooms))
    }

    var level: Level {
        guard attempts > 0 else { return .notStarted }
        guard attempts >= 30, accuracy >= 0.8, coverage >= 0.75 else { return .building }
        return .consistent
    }

    var title: String {
        switch level {
        case .notStarted: return "Set a baseline"
        case .building: return "Build consistency"
        case .consistent: return "Consistent practice"
        }
    }

    var message: String {
        switch level {
        case .notStarted:
            return "Answer ten questions to see where you stand."
        case .building:
            return "Keep rotating through the available rooms until your weak spots settle down."
        case .consistent:
            return "Your recent practice is consistent across the rooms you have opened."
        }
    }

    var accuracyText: String {
        "\(Int((accuracy * 100).rounded()))%"
    }

    var coverageText: String {
        "\(practicedRooms) of \(availableRooms) rooms"
    }
}
