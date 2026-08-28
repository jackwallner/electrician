import SwiftUI

/// Field tools. Free on purpose: the research says the calculators are the
/// thing that keeps the app in a pouch after the exam, and Southwire already
/// gives the same numbers away. Gating them would throw away the retention
/// without charging for anything the trade does not already have.
struct FieldToolsView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Study estimates from the same tables the drills use. Cite the article, then look it up in your own book.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                    // The supported domain, stated up front. Off-table
                    // combinations return nothing, which is the safe behaviour,
                    // but a blank result with no explanation reads as a bug.
                    Text("\(NECTables.edition) values, copper and aluminum, THHN/THWN in EMT. Other raceways, coatings and local amendments are not covered.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkTertiary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
            }
            Section("Calculators") {
                NavigationLink { AmpacityToolView() } label: {
                    toolRow("bolt.fill", "Ampacity", "Derate, then cap, then 240.4(D)")
                }
                NavigationLink { ConduitFillToolView() } label: {
                    toolRow("circle.hexagongrid.fill", "Conduit fill", "THHN in EMT, Chapter 9")
                }
                NavigationLink { VoltageDropToolView() } label: {
                    toolRow("waveform.path.ecg", "Voltage drop", "Resistive estimate, informational note")
                }
                NavigationLink { OhmsLawToolView() } label: {
                    toolRow("plus.forwardslash.minus", "Ohm's law", "Any two of V, I, R, P")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Field Tools")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toolRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.voltage)
                .frame(width: 36, height: 36)
                .background(Theme.voltage.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.ink)
                Text(subtitle).font(.caption).foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Ampacity

private struct AmpacityToolView: View {
    @State private var size = "12 AWG"
    @State private var material = ConductorMaterial.copper
    @State private var insulation = TemperatureRating.c90
    @State private var termination = TemperatureRating.c75
    @State private var ambient = 30
    @State private var currentCarrying = 3

    private var result: FieldCalculators.AmpacityResult? {
        FieldCalculators.ampacity(
            size: size,
            material: material,
            insulation: insulation,
            termination: termination,
            ambientCelsius: ambient,
            currentCarrying: currentCarrying
        )
    }

    var body: some View {
        Form {
            Section("Circuit") {
                Picker("Size", selection: $size) {
                    ForEach(NECTables.conductorSizes, id: \.self) { Text($0).tag($0) }
                }
                Picker("Material", selection: $material) {
                    ForEach(ConductorMaterial.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("Insulation", selection: $insulation) {
                    ForEach(TemperatureRating.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("Terminations", selection: $termination) {
                    ForEach(TemperatureRating.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("Ambient", selection: $ambient) {
                    ForEach([30, 35, 40, 45, 50, 55], id: \.self) { Text("\($0) C").tag($0) }
                }
                Stepper("Current-carrying: \(currentCarrying)", value: $currentCarrying, in: 1...40)
            }
            if let result {
                Section("Result") {
                    LabeledContent("Table", value: "\(result.tableAmps) A")
                    LabeledContent("After derate", value: "\(result.afterDerate.trimmedAmps) A")
                    LabeledContent("Allowable", value: "\(result.allowable.trimmedAmps) A")
                    LabeledContent("OCPD ceiling", value: "\(result.ocpdCeiling.trimmedAmps) A")
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            } else {
                Section {
                    Text("This combination is off the table for that column. The conductor cannot be used there.")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .navigationTitle("Ampacity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Conduit fill

private struct ConduitFillToolView: View {
    @State private var size = "12 AWG"
    @State private var count = 9
    @State private var trade = "1/2\""

    private var result: FieldCalculators.ConduitFillResult? {
        FieldCalculators.conduitFill(conductorSize: size, count: count, tradeSize: trade)
    }

    var body: some View {
        Form {
            Section("Pull") {
                Picker("THHN size", selection: $size) {
                    ForEach(NECTables.conductorSizes, id: \.self) { Text($0).tag($0) }
                }
                Stepper("Count: \(count)", value: $count, in: 1...40)
                Picker("EMT", selection: $trade) {
                    ForEach(NECTables.emtTradeSizes, id: \.self) { Text($0).tag($0) }
                }
            }
            if let result {
                Section("Result") {
                    LabeledContent("Fill", value: String(format: "%.0f%% of allowed %.0f%%", result.actualPercent * 100, result.allowedPercent * 100))
                    LabeledContent("This size", value: result.fits ? "Fits" : "Does not fit")
                    if let smallest = result.smallestFitting {
                        LabeledContent("Smallest EMT", value: smallest)
                    }
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            } else {
                Section {
                    Text("No Chapter 9 area is listed for that conductor size, so this combination cannot be computed.")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .navigationTitle("Conduit fill")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Voltage drop

private struct VoltageDropToolView: View {
    @State private var size = "10 AWG"
    @State private var material = ConductorMaterial.copper
    @State private var phase = Phase.single
    @State private var systemVolts = 120
    @State private var amps = 16.0
    @State private var feet = 100.0

    private var result: FieldCalculators.VoltageDropResult? {
        FieldCalculators.voltageDrop(
            size: size,
            material: material,
            phase: phase,
            systemVolts: Double(systemVolts),
            amps: amps,
            oneWayFeet: feet
        )
    }

    var body: some View {
        Form {
            Section("Run") {
                Picker("Size", selection: $size) {
                    ForEach(NECTables.conductorSizes, id: \.self) { Text($0).tag($0) }
                }
                Picker("Material", selection: $material) {
                    ForEach(ConductorMaterial.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("Phase", selection: $phase) {
                    ForEach(Phase.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("System", selection: $systemVolts) {
                    ForEach([120, 208, 240, 277, 480], id: \.self) { Text("\($0) V").tag($0) }
                }
                HStack {
                    Text("Load")
                    Spacer()
                    TextField("A", value: $amps, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("A").foregroundStyle(Theme.inkSecondary)
                }
                HStack {
                    Text("One-way")
                    Spacer()
                    TextField("ft", value: $feet, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("ft").foregroundStyle(Theme.inkSecondary)
                }
            }
            if let result {
                Section("Estimate") {
                    LabeledContent("Drop", value: String(format: "%.2f V (%.2f%%)", result.volts, result.percent))
                    LabeledContent("3% note", value: result.withinThreePercent ? "Within" : "Over")
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Section("What this leaves out") {
                    ForEach(FieldCalculators.VoltageDropResult.assumptions, id: \.self) { assumption in
                        Text(assumption)
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Text(FieldCalculators.VoltageDropResult.threePercentNote)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .navigationTitle("Voltage drop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ohm's law

private struct OhmsLawToolView: View {
    @State private var voltsText = "120"
    @State private var ampsText = "10"
    @State private var ohmsText = ""
    @State private var wattsText = ""

    private var result: FieldCalculators.OhmsLawResult? {
        FieldCalculators.ohmsLaw(
            volts: Double(voltsText),
            amps: Double(ampsText),
            ohms: Double(ohmsText),
            watts: Double(wattsText)
        )
    }

    var body: some View {
        Form {
            Section("Enter any two") {
                field("Volts", text: $voltsText)
                field("Amps", text: $ampsText)
                field("Ohms", text: $ohmsText)
                field("Watts", text: $wattsText)
            }
            if let result {
                Section("Result") {
                    LabeledContent("V", value: result.volts.trimmedAmps)
                    LabeledContent("I", value: result.amps.trimmedAmps)
                    LabeledContent("R", value: result.ohms.trimmedAmps)
                    LabeledContent("P", value: result.watts.trimmedAmps)
                    Text("Solved from \(result.basis).")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                if !result.isConsistent {
                    // The tool is allowed to solve from one pair; it is not
                    // allowed to drop the rest silently. An answer that looks
                    // like it validated the circuit, when half of what was
                    // typed described a different one, is the kind of thing an
                    // electrician finds out about at the panel.
                    Section("Check your inputs") {
                        Label(
                            "\(result.conflicts.joined(separator: ", ")) \(result.conflicts.count == 1 ? "does" : "do") not agree with \(result.basis). The result above is solved from \(result.basis); clear or correct the others.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(Theme.copper)
                    }
                }
            } else {
                Section {
                    Text("Fill in any two values. Zero and blanks are ignored.")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .navigationTitle("Ohm's law")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("optional", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
    }
}
