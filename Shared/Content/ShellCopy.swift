import Foundation

/// Player-facing strings that live in the shell rather than in a drill. The
/// content-validity suite reads these the same way it reads quiz copy, so a
/// leftover word from the app this was ported from cannot hide in a
/// notification or a tour page.
enum ShellCopy {
    enum DailyReminder {
        static let title = String(localized: "Time for a quick drill")
        static let body = String(localized: "Five minutes on a calc you keep missing beats another hour of highlighting.")
    }

    enum ExamWarmupReminder {
        static let title = String(localized: "Your warm-up is ready")
        static let body = String(localized: "Five targeted minutes now makes the exam feel slower later.")
    }

    enum Tour {
        static let roomsBody = String(localized: "Each room holds its own drills: how the book is built, how to read ampacity, the installation rules you look up on site, how to work the numbers, how grounding and motors actually work. The three opening rooms are free, forever.")
        static let proLockedBody = String(localized: "Code Minute gives every member the same daily challenge, Exam Warm-Up targets your weak spots before you sit, and Endless Practice never runs out. Nothing you have now goes away. Unlock any time from Home or Settings.")
    }

    enum DrillComplete {
        static let flashcardsSubhead = String(localized: "Every term reviewed. They stick a little better every pass.")
        static let scoredSubhead = String(localized: "Every calculation you work here is one you'll work faster on the exam.")
    }

    enum Onboarding {
        static let freeRoomsBenefit = String(localized: "Three full rooms, free forever")
    }

    static var all: [String] {
        [
            DailyReminder.title, DailyReminder.body,
            ExamWarmupReminder.title, ExamWarmupReminder.body,
            Tour.roomsBody, Tour.proLockedBody,
            DrillComplete.flashcardsSubhead, DrillComplete.scoredSubhead,
            Onboarding.freeRoomsBenefit,
        ]
    }
}
