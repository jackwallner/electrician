import SwiftUI

/// Picks which generated shape to drill.
///
/// It was a flat list, which was right at five shapes and wrong at ten: ten
/// undifferentiated rows is a menu to be scanned rather than a choice to be
/// made. Grouping them under the room each one belongs to gives the list the
/// same structure Home already has, and carrying the room's accent onto the
/// cards means a reader who knows Conductors is copper can find the derating
/// drill without reading a word.
///
/// Still one tap from here to the first problem. This is not another lobby.
struct EndlessPickerView: View {
    @StateObject private var records = PracticeRecordStore.shared

    /// Skills in room order, so the grouping matches Home's room order rather
    /// than the declaration order of the enum.
    private var groups: [(room: Room, skills: [PracticeSkill])] {
        DrillLibrary.rooms.compactMap { room in
            let skills = PracticeSkill.allCases.filter { $0.roomID == room.id }
            return skills.isEmpty ? nil : (room, skills)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                intro
                ForEach(groups, id: \.room.id) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.room.name.uppercased())
                            .font(Theme.eyebrow)
                            .kerning(Theme.eyebrowKerning)
                            .foregroundStyle(group.room.accent)
                            .padding(.horizontal, 4)
                        ForEach(group.skills) { skill in
                            NavigationLink {
                                PracticeRunView(mode: .endless(skill))
                            } label: {
                                PracticeSkillCard(skill: skill, accent: group.room.accent, record: records.records[skill.rawValue])
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Endless Practice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "infinity")
                .foregroundStyle(Theme.voltage)
            Text("\(PracticeSkill.allCases.count) shapes, and every problem is generated the moment you see it, so you can practise for as long as you like without repeating a question.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.voltage.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, 12)
    }
}

/// One generated shape as a card: its icon in the room's accent, what it
/// drills and, once answered, how it is going. Shared by the picker and the
/// room it belongs to. Locked shows the membership lock instead of the
/// chevron; the caller decides what a tap does.
struct PracticeSkillCard: View {
    let skill: PracticeSkill
    let accent: Color
    var record: PracticeRecord?
    var locked = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: skill.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(locked ? accent.opacity(0.55) : accent)
                .frame(width: 48, height: 48)
                .background(accent.opacity(locked ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.title)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.ink)
                Text(skill.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let record, record.attempts > 0 {
                    Text("\(Int((record.accuracy * 100).rounded()))% across \(record.attempts) answered")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(locked ? Theme.brass : Theme.inkTertiary)
        }
        .padding(14)
        .themedCard()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }
}
