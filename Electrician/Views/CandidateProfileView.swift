import SwiftUI

struct CandidateProfileView: View {
    @EnvironmentObject private var profile: CandidateProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CandidateProfileFields()
                } header: {
                    Text("Your exam target")
                } footer: {
                    Text("Electrician uses \(NECTables.edition) values, unchanged across the \(NECTables.coverageLabel). A different edition or local amendment can change an answer, so verify against the code in force where you work.")
                }

                if let record = profile.jurisdictionRecord {
                    Section {
                        JurisdictionFactsCard(record: record)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    } header: {
                        Text("What we know about \(record.name)")
                    }
                }

                Section("How your edition lines up") {
                    Text(profile.editionAdvice)
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                    NavigationLink {
                        EditionView()
                    } label: {
                        Label("What changes between editions", systemImage: "books.vertical")
                    }
                }

                Section("What this app covers") {
                    Text("Code navigation, conductors and ampacity, installation rules, grounding and motors, dwelling service and load calculations, and \(PracticeSkill.allCases.count) generated calculation shapes. Special occupancies, hazardous locations and the low-voltage chapters are not covered yet.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                    Text(profile.licenseTrack.emphasis)
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.voltage)
            .navigationTitle("Exam Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        profile.completeSetup()
                        dismiss()
                    }
                    .disabled(!profile.canCompleteSetup)
                }
            }
        }
    }
}

struct CandidateProfileFields: View {
    @EnvironmentObject private var profile: CandidateProfile

    var body: some View {
        // A menu, not a segmented control. Five licence tracks will not fit
        // across a 375pt phone, and a segmented control with clipped labels is
        // worse than a picker row.
        Picker("Licence", selection: Binding(
            get: { profile.licenseTrack },
            set: { profile.selectTrack($0) }
        )) {
            ForEach(LicenseTrack.allCases) { track in
                Text(track.displayName).tag(track)
            }
        }

        NavigationLink {
            JurisdictionPickerView()
        } label: {
            LabeledContent("State or jurisdiction") {
                Text(profile.trimmedJurisdiction.isEmpty ? "Choose" : profile.trimmedJurisdiction)
                    .foregroundStyle(profile.trimmedJurisdiction.isEmpty ? Theme.inkTertiary : Theme.inkSecondary)
            }
        }

        Picker("Code edition", selection: $profile.edition) {
            ForEach(CandidateEdition.allCases) { edition in
                Text(editionLabel(edition)).tag(edition)
            }
        }

        Toggle("I know my exam date", isOn: Binding(
            get: { profile.examDate != nil },
            set: { enabled in
                profile.examDate = enabled ? Calendar.current.date(byAdding: .day, value: 30, to: Date()) : nil
            }
        ))
        .tint(Theme.voltage)

        if profile.examDate != nil {
            DatePicker(
                "Exam date",
                selection: Binding(
                    get: { profile.examDate ?? Date() },
                    set: { profile.examDate = $0 }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            if let countdown = profile.examCountdownSummary {
                LabeledContent(countdown) {
                    Text("\(profile.suggestedDailyQuestions) questions a day")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }

        Stepper(value: $profile.dailyGoal, in: 5...100, step: 5) {
            LabeledContent("Daily goal") {
                Text("\(profile.dailyGoal) questions")
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    /// The "not sure" row names the edition it will actually use, so the
    /// collapsed picker row never reads as an unanswered question.
    private func editionLabel(_ edition: CandidateEdition) -> String {
        guard edition == .unsure, let suggested = profile.suggestedEdition else {
            return edition.displayName
        }
        return "Not sure, use \(suggested.displayName)"
    }
}

/// The searchable state list, shared by onboarding's step and Exam Target.
struct JurisdictionPickerView: View {
    @EnvironmentObject private var profile: CandidateProfile
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        List {
            if let record = profile.jurisdictionRecord {
                Section {
                    JurisdictionFactsCard(record: record)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                ForEach(Jurisdictions.matching(query)) { record in
                    Button {
                        profile.selectJurisdiction(record)
                        dismiss()
                    } label: {
                        HStack {
                            Text(record.name)
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(record.editionLabel)
                                .font(.caption)
                                .foregroundStyle(Theme.inkTertiary)
                            if profile.trimmedJurisdiction.caseInsensitiveCompare(record.name) == .orderedSame {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.voltage)
                            }
                        }
                    }
                }
            } footer: {
                Text("Editions and exam vendors were checked \(Jurisdictions.reviewed). Confirm with your own board.")
            }
        }
        .searchable(text: $query, prompt: "Search states")
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Jurisdiction")
        .navigationBarTitleDisplayMode(.inline)
    }
}
