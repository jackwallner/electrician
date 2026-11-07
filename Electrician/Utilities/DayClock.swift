import Combine
import Foundation
import UIKit

/// Home's source of "now". Only tests replace it, to move Home across midnight.
enum AppClock {
    nonisolated(unsafe) static var now: @Sendable () -> Date = { Date() }
}

/// Publishes the start of the current day and changes it only when the date
/// rolls over. Home reads `Date()` in its body for "done today", the streak,
/// the exam countdown and the Code Minute badge; observing this is what makes
/// it redraw when the day turns, whether the app stayed open across midnight
/// or was suspended and resumed the next morning.
@MainActor
final class DayClock: ObservableObject {
    @Published private(set) var today: Date

    private let now: () -> Date
    private var subscription: AnyCancellable?

    init(center: NotificationCenter = .default, now: @escaping () -> Date = { AppClock.now() }) {
        self.now = now
        today = Calendar.current.startOfDay(for: now())
        let names: [Notification.Name] = [
            .NSCalendarDayChanged,
            UIApplication.significantTimeChangeNotification,
            UIApplication.willEnterForegroundNotification,
        ]
        subscription = Publishers.MergeMany(names.map { center.publisher(for: $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
    }

    func refresh() {
        let day = Calendar.current.startOfDay(for: now())
        if day != today { today = day }
    }
}
