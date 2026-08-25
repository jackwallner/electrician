import SwiftUI
import UIKit
import UserNotifications

enum AppDestination: Hashable {
    case examWarmUpSession
}

enum AppNotification {
    static let routeKey = "electrician.route"
    /// The VALUE stays as it is: notifications already scheduled on device
    /// carry this string in their userInfo, and changing it would make every
    /// pending reminder open Home instead of the warm-up it promised.
    static let examWarmUpValue = "game-night-prep"
}

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published private(set) var pendingDestination: AppDestination?

    func route(to destination: AppDestination) {
        pendingDestination = destination
    }

    func consumePendingDestination() -> AppDestination? {
        defer { pendingDestination = nil }
        return pendingDestination
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.userInfo[AppNotification.routeKey] as? String
            == AppNotification.examWarmUpValue {
            Task { @MainActor in
                AppRouter.shared.route(to: .examWarmUpSession)
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
