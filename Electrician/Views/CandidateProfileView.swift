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
                    Text("Electrician uses \(NECTables.edition) values. A different edition or local amendment can change an answer, so verify against the code in force where you work.")
                }

                Section("What this app covers") {
                    Text("Code navigation, conductors and ampacity, grounding and motors, and five generated calculation shapes. Services, feeders, wiring methods, and special occupancy chapters are not covered yet.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.jade)
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
    @FocusState private var jurisdictionFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Who are you preparing for?")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Picker("License", selection: Binding(
                get: { profile.licenseTrack },
                set: { profile.selectTrack($0) }
            )) {
                ForEach(LicenseTrack.allCases) { track in
                    Text(track.displayName).tag(track)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 6) {
                Text("State or jurisdiction")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                TextField("For example, Texas", text: $profile.jurisdiction)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($jurisdictionFocused)
                    .submitLabel(.done)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Theme.well, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Code edition")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Picker("Code edition", selection: $profile.edition) {
                    ForEach(CandidateEdition.allCases) { edition in
                        Text(edition.displayName).tag(edition)
                    }
                }
                .pickerStyle(.menu)
                Text(profile.edition.note)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }

            Toggle("I know my exam date", isOn: Binding(
                get: { profile.examDate != nil },
                set: { enabled in
                    profile.examDate = enabled ? Calendar.current.date(byAdding: .day, value: 30, to: Date()) : nil
                }
            ))
            .tint(Theme.jade)

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
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    jurisdictionFocused = false
                }
            }
        }
    }
}
