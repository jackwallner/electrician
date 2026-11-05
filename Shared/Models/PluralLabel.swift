import Foundation

/// Count labels drawn beside a separately rendered number ("46" over "days").
///
/// Xcode rejects plural variants that omit the number, so a bare noun cannot be
/// a plural key. The catalog's `"%lld plural category"` key answers with the
/// CLDR category for the active language, and each label then picks one whole
/// key per category. Languages that need `few` or `many` give those keys their
/// own wording; English carries the plural form in them so it never shows a key.
enum PluralLabel {
    enum Category: String, Sendable {
        case zero, one, two, few, many, other
    }

    static func category(_ count: Int) -> Category {
        let answer = String(localized: "\(count) plural category")
        let word = answer.split(separator: " ").first.map(String.init) ?? ""
        // Without a catalog (a script that compiles the Shared sources alone)
        // the key comes back verbatim, so fall back to the English rule.
        return Category(rawValue: word) ?? (count == 1 ? .one : .other)
    }

    static func conductors(_ count: Int) -> String {
        switch category(count) {
        case .one: return String(localized: "conductor")
        case .few: return String(localized: "conductors (few)")
        case .many: return String(localized: "conductors (many)")
        default: return String(localized: "conductors")
        }
    }

    static func wires(_ count: Int) -> String {
        switch category(count) {
        case .one: return String(localized: "wire")
        case .few: return String(localized: "wires (few)")
        case .many: return String(localized: "wires (many)")
        default: return String(localized: "wires")
        }
    }

    static func yokes(_ count: Int) -> String {
        switch category(count) {
        case .one: return String(localized: "yoke")
        case .few: return String(localized: "yokes (few)")
        case .many: return String(localized: "yokes (many)")
        default: return String(localized: "yokes")
        }
    }

    static func days(_ count: Int) -> String {
        switch category(count) {
        case .one: return String(localized: "day")
        case .few: return String(localized: "days (few)")
        case .many: return String(localized: "days (many)")
        default: return String(localized: "days")
        }
    }

    static func daysOut(_ count: Int) -> String {
        switch category(count) {
        case .one: return String(localized: "Day out")
        case .few: return String(localized: "Days out (few)")
        case .many: return String(localized: "Days out (many)")
        default: return String(localized: "Days out")
        }
    }
}
