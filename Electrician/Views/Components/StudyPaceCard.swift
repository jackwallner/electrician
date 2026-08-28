import SwiftUI

/// The plan the exam date implies, as a numbered order of work.
///
/// Onboarding asks for a date, so it owes the candidate something in return for
/// it, and a countdown alone is not that: a number that goes down on its own is
/// pressure without instruction. What a candidate three days out actually needs
/// is permission to skip things, in a specific order, which is what this card
/// is. It is shown the moment the date is set, and again on Home for as long as
/// the date is close.
struct StudyPaceCard: View {
    let pace: StudyPace
    let daily: Int
    /// Home shows a trimmed version; onboarding shows the whole list.
    var maximumPriorities: Int = .max

    private var tint: Color {
        pace.isUrgent ? Theme.copper : Theme.voltage
    }

    private var icon: String {
        switch pace {
        case .cram: return "exclamationmark.triangle.fill"
        case .sprint: return "hare.fill"
        case .build: return "calendar"
        case .foundation, .undated: return "book.closed.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(pace.title)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                Text("\(daily)/day")
                    .font(Theme.numeric(.footnote, weight: .bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint.opacity(0.12), in: Capsule())
                    .accessibilityLabel("\(daily) questions a day")
            }

            Text(pace.summary)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(pace.priorities.prefix(maximumPriorities).enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 9) {
                        Text("\(index + 1)")
                            .font(Theme.numeric(.caption2, weight: .bold))
                            .foregroundStyle(tint)
                            .frame(width: 18, height: 18)
                            .background(tint.opacity(0.14), in: Circle())
                            .accessibilityHidden(true)
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step \(index + 1). \(line)")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        )
    }
}
