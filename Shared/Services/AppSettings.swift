import SwiftUI
import UserNotifications

/// User-configurable app settings, persisted in UserDefaults.
/// Appearance defaults to the warm light theme regardless of the device style.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum Appearance: String, CaseIterable, Identifiable {
        case light, dark, system

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "Match Device"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }

    enum ExamWarmUpDay: Int, CaseIterable, Identifiable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let haptics = "settings.haptics"
        static let sound = "settings.sound"
        static let celebrations = "settings.celebrations"
        static let reminderEnabled = "settings.reminderEnabled"
        static let reminderHour = "settings.reminderHour"
        static let reminderMinute = "settings.reminderMinute"
        // The `gameNight` spelling in these four VALUES is deliberate and must
        // not be tidied to match the renamed symbols. They are the UserDefaults
        // keys already written on every install; changing a key does not
        // migrate a setting, it silently forgets it, so someone with a Thursday
        // 5pm reminder would find it switched off after an update. The Swift
        // names are the part that was safe to rename.
        static let examWarmUpReminderEnabled = "settings.gameNightReminderEnabled"
        static let examWarmUpDay = "settings.gameNightDay"
        static let examWarmUpHour = "settings.gameNightHour"
        static let examWarmUpMinute = "settings.gameNightMinute"
    }

    private static let reminderID = "electrician.dailyReminder"
    /// Same rule as the keys above: this identifier matches notification
    /// requests already scheduled on device, and renaming it would leave those
    /// pending forever with nothing able to cancel them.
    private static let examWarmUpReminderID = "electrician.gameNightReminder"

    @Published var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }

    /// Confetti, the full-screen flash, and the streak banners.
    ///
    /// On by default, because the habit loop is real and it works. Off is here
    /// because this audience is not the audience the shell was built for: a
    /// working electrician studying at 10pm before a 6am start does not
    /// necessarily want the screen to flash green every time they are right,
    /// and "this app is for kids" is a thing a professional says about a
    /// product once and never revisits. Haptics and sound keep their own
    /// switches; this one is only the visual celebration.
    @Published var celebrationsEnabled: Bool {
        didSet { defaults.set(celebrationsEnabled, forKey: Keys.celebrations) }
    }

    @Published var reminderEnabled: Bool {
        didSet {
            defaults.set(reminderEnabled, forKey: Keys.reminderEnabled)
            if reminderEnabled {
                requestPermissionAndSchedule()
            } else {
                cancelReminder()
            }
        }
    }

    /// True when the player asked for a reminder but iOS notifications are off
    /// for the app. Without this the toggle just silently flips back, which
    /// looks like the app is broken.
    @Published var reminderPermissionDenied = false

    @Published var reminderTime: Date {
        didSet {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            defaults.set(parts.hour ?? 9, forKey: Keys.reminderHour)
            defaults.set(parts.minute ?? 0, forKey: Keys.reminderMinute)
            if reminderEnabled { scheduleReminder() }
        }
    }

    @Published var examWarmUpReminderEnabled: Bool {
        didSet {
            defaults.set(examWarmUpReminderEnabled, forKey: Keys.examWarmUpReminderEnabled)
            if examWarmUpReminderEnabled {
                requestPermissionAndScheduleExamWarmUp()
            } else {
                cancelExamWarmUpReminder()
            }
        }
    }

    @Published var examWarmUpDay: ExamWarmUpDay {
        didSet {
            defaults.set(examWarmUpDay.rawValue, forKey: Keys.examWarmUpDay)
            if examWarmUpReminderEnabled { scheduleExamWarmUpReminder() }
        }
    }

    @Published var examWarmUpReminderTime: Date {
        didSet {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: examWarmUpReminderTime)
            defaults.set(parts.hour ?? 17, forKey: Keys.examWarmUpHour)
            defaults.set(parts.minute ?? 0, forKey: Keys.examWarmUpMinute)
            if examWarmUpReminderEnabled { scheduleExamWarmUpReminder() }
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .light
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        celebrationsEnabled = defaults.object(forKey: Keys.celebrations) as? Bool ?? true
        reminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)
        let hour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        let minute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0
        reminderTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        examWarmUpReminderEnabled = defaults.bool(forKey: Keys.examWarmUpReminderEnabled)
        let savedDay = defaults.integer(forKey: Keys.examWarmUpDay)
        examWarmUpDay = ExamWarmUpDay(rawValue: savedDay) ?? .thursday
        let warmUpHour = defaults.object(forKey: Keys.examWarmUpHour) as? Int ?? 17
        let warmUpMinute = defaults.object(forKey: Keys.examWarmUpMinute) as? Int ?? 0
        examWarmUpReminderTime = Calendar.current.date(
            from: DateComponents(hour: warmUpHour, minute: warmUpMinute)
        ) ?? Date()
    }

    // MARK: - Daily reminder

    private func requestPermissionAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                if granted {
                    self.scheduleReminder()
                } else {
                    self.reminderEnabled = false
                    self.reminderPermissionDenied = true
                }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])

        let content = UNMutableNotificationContent()
        content.title = ShellCopy.DailyReminder.title
        content.body = ShellCopy.DailyReminder.body
        content.sound = .default

        var parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        parts.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
    }

    // MARK: - Exam warm-up reminder

    private func requestPermissionAndScheduleExamWarmUp() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                if granted {
                    self.scheduleExamWarmUpReminder()
                } else {
                    self.examWarmUpReminderEnabled = false
                    self.reminderPermissionDenied = true
                }
            }
        }
    }

    private func scheduleExamWarmUpReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.examWarmUpReminderID])

        let content = UNMutableNotificationContent()
        content.title = ShellCopy.ExamWarmupReminder.title
        content.body = ShellCopy.ExamWarmupReminder.body
        content.sound = .default
        content.userInfo = [AppNotification.routeKey: AppNotification.examWarmUpValue]

        let time = Calendar.current.dateComponents([.hour, .minute], from: examWarmUpReminderTime)
        var parts = DateComponents()
        parts.weekday = examWarmUpDay.rawValue
        parts.hour = time.hour
        parts.minute = time.minute
        parts.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.examWarmUpReminderID, content: content, trigger: trigger))
    }

    func cancelExamWarmUpReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.examWarmUpReminderID])
    }
}
