import XCTest
import UserNotifications
@testable import Electrician

/// A reminder toggle has to match what iOS will actually deliver. Pending
/// requests do not come back with a restored backup, and notifications can be
/// turned off in iOS Settings, while the toggles kept reading on.
@MainActor
final class ReminderRefreshTests: XCTestCase {
    private var suite: UserDefaults!
    private var suiteName = ""

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "reminder.refresh.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)!
        suite.set(true, forKey: "settings.reminderEnabled")
        suite.set(true, forKey: "settings.gameNightReminderEnabled")
    }

    override func tearDown() async throws {
        suite.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    func testRefusedNotificationsTurnBothTogglesOffAndSayWhy() {
        let settings = AppSettings(defaults: suite)
        XCTAssertTrue(settings.reminderEnabled, "precondition: restored on")
        XCTAssertTrue(settings.examWarmUpReminderEnabled, "precondition: restored on")

        settings.refreshReminders(status: .denied)

        XCTAssertFalse(settings.reminderEnabled)
        XCTAssertFalse(settings.examWarmUpReminderEnabled)
        XCTAssertFalse(suite.bool(forKey: "settings.reminderEnabled"))
        XCTAssertFalse(suite.bool(forKey: "settings.gameNightReminderEnabled"))
        XCTAssertTrue(settings.reminderPermissionDenied, "the existing Notifications are off message shows")
    }

    /// Turned back on in iOS Settings, the daily reminder resumes like the
    /// onboarding refusal does.
    func testRefusedDailyReminderResumesWhenPermissionReturns() {
        let settings = AppSettings(defaults: suite)
        settings.refreshReminders(status: .denied)
        settings.resumeDailyReminder(authorized: true)
        XCTAssertTrue(settings.reminderEnabled)
    }

    func testAllowedNotificationsKeepBothToggles() {
        let settings = AppSettings(defaults: suite)
        settings.refreshReminders(status: .authorized)
        XCTAssertTrue(settings.reminderEnabled)
        XCTAssertTrue(settings.examWarmUpReminderEnabled)
        XCTAssertFalse(settings.reminderPermissionDenied)
    }

    func testTogglesOffAskNothing() {
        suite.set(false, forKey: "settings.reminderEnabled")
        suite.set(false, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: suite)
        settings.refreshReminders(status: .denied)
        XCTAssertFalse(settings.reminderPermissionDenied, "nothing was asked for, so nothing to warn about")
    }
}
