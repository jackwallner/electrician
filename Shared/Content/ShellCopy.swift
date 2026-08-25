import Foundation

/// Player-facing strings that live in the shell rather than in a drill. The
/// content-validity suite reads these the same way it reads quiz copy, so a
/// leftover word from the app this was ported from cannot hide in a
/// notification or a tour page.
enum ShellCopy {
    enum DailyReminder {
        static let title = "Time for a quick drill"
        static let body = "Five minutes on a calc you keep missing beats another hour of highlighting."
    }

    enum ExamWarmupReminder {
        static let title = "Your warm-up is ready"
        static let body = "Five targeted minutes now makes the exam feel slower later."
    }

    enum Tour {
        static let roomsBody = "Home is the lobby. Each room holds its own drills: how the book is built, how to read ampacity, how to work the numbers, how grounding actually works. The two beginner rooms are free, forever."
        static let proLockedBody = "Code Minute gives every member the same daily challenge, Exam Warm-Up targets your weak spots before you sit, and Endless Practice never runs out. Nothing you have now goes away. Unlock any time from Home or Settings."
    }

    enum DrillComplete {
        static let flashcardsSubhead = "All the cards down. They'll stick a little better every pass."
        static let scoredSubhead = "Every calculation you work here is one you'll work faster on the exam."
    }

    enum Onboarding {
        static let freeRoomsBenefit = "Two full rooms, free forever"
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
