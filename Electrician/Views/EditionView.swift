import SwiftUI

/// Explains the app's 2023 table basis and the limits of edition coverage.
/// Numeric values and section references can both change between cycles.
struct EditionView: View {
    @EnvironmentObject private var profile: CandidateProfile

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Built on the \(NECTables.edition)")
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.ink)
                    Text(NECTables.coverageNote)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 4))
            }

            Section("Your exam") {
                LabeledContent("Your edition", value: profile.editionSummary)
                Text(profile.editionAdvice)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !profile.editionMatchesApp {
                    // No link back to the picker from here: Exam Target
                    // presents itself in its own navigation stack, and pushing
                    // that inside this one gives the reader two navigation
                    // bars and a Done button that dismisses the wrong screen.
                    Text("Change it under Exam Target, in Settings or from the countdown card on Home.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }

            Section("Tables used in this app") {
                ForEach(stableTables, id: \.title) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(Theme.cardTitle)
                            .foregroundStyle(Theme.ink)
                        Text(entry.detail)
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("What does change") {
                Text("These requirements can also change between editions. Confirm their scope, exceptions and local amendments in the book named by your exam board.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(movingAreas, id: \.self) { area in
                    Label(area, systemImage: "arrow.triangle.branch")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                }
            }

            Section("How far this has been checked") {
                LabeledContent("Values unchanged since", value: NECTables.stableSince.displayName)
                LabeledContent("Verified against", value: NECTables.verifiedThrough.displayName)
                Text("Verified means checked page by page against that edition's book, not assumed. For any other exam cycle, confirm the values, references and applicable rules in that edition before relying on an answer.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Text("A study aid, not a code book. Not affiliated with, endorsed by, or connected to the NFPA. Concepts and calculations are written in original wording, with article numbers so every value can be verified in the code in force where you work.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Code Editions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct StableTable {
        let title: String
        let detail: String
    }

    private var stableTables: [StableTable] {
        [
            StableTable(title: "310.16 allowable ampacity",
                        detail: "The three temperature columns for copper and aluminum. The table this app derates from, and the one an exam question hands you a conductor and asks about."),
            StableTable(title: "310.15(B)(1)(1) and 310.15(C)(1)",
                        detail: "Ambient correction and current-carrying conductor adjustment. In 2020, the 30°C-basis ambient table is 310.15(B)(1)."),
            StableTable(title: "240.6(A) standard ratings, and 240.4(D)",
                        detail: "Standard fuse and breaker sizes, including the 10 A standard breaker rating added in 2023, and ordinary small-conductor protection limits."),
            StableTable(title: "Chapter 9 Tables 1, 4 and 5",
                        detail: "Raceway fill percentages, raceway interior areas and conductor areas."),
            StableTable(title: "314.16(A) and 314.16(B)",
                        detail: "Box volumes and the volume allowance each conductor, clamp, yoke and ground takes."),
            StableTable(title: "Tables 430.248 and 430.250",
                        detail: "Motor full-load current, which is what a motor circuit is sized from rather than the nameplate."),
            StableTable(title: "Tables 250.66 and 250.122",
                        detail: "Grounding electrode conductor sizing from the service conductor, and equipment grounding conductor sizing from the overcurrent device."),
            StableTable(title: "Article 220 dwelling demand factors",
                        detail: "3 VA per square foot, the 3000 VA and 35% bands, the range and dryer tables, and the 75% appliance factor. Article 220 was renumbered for the 2023 cycle; the values did not change, and both section numbers are cited."),
        ]
    }

    private var movingAreas: [String] {
        [
            "GFCI protection: which locations and what ratings",
            "AFCI protection: which rooms and which circuits",
            "Surge protection at dwelling services",
            "Emergency and outdoor equipment disconnects",
            "Receptacle placement at islands and peninsulas",
            "Electric vehicle supply equipment",
            "Reconditioned equipment and listing requirements",
        ]
    }
}
