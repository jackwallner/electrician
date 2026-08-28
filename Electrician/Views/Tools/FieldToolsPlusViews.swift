import SwiftUI

// MARK: - Grounding conductors

/// Both grounding conductors on one screen, each labelled with what it was
/// sized FROM.
///
/// The most common Article 250 error is not arithmetic, it is reaching for the
/// wrong table. Two separate calculators would let a reader make that error
/// here as easily as on the exam; showing the equipment ground and the
/// electrode conductor together, with their inputs beside them, makes the
/// distinction the subject of the screen instead of a footnote on it.
struct GroundingToolView: View {
    @State private var serviceSize = "2/0 AWG"
    @State private var serviceMaterial = ConductorMaterial.copper
    @State private var serviceOCPD = 200
    @State private var electrode = NECTables.ElectrodeType.rodPipePlate
    @State private var parallelSets = 1

    private var result: FieldCalculators.GroundingResult? {
        FieldCalculators.grounding(
            serviceSize: serviceSize,
            serviceMaterial: serviceMaterial,
            serviceOCPD: serviceOCPD,
            electrode: electrode,
            parallelSets: parallelSets
        )
    }

    var body: some View {
        Form {
            Section("Service") {
                Picker("Ungrounded conductor", selection: $serviceSize) {
                    ForEach(NECTables.conductorSizes, id: \.self) { Text($0).tag($0) }
                }
                Picker("Material", selection: $serviceMaterial) {
                    ForEach(ConductorMaterial.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Stepper("Parallel sets: \(parallelSets)", value: $parallelSets, in: 1...6)
                Picker("Electrode", selection: $electrode) {
                    ForEach(NECTables.ElectrodeType.allCases) { Text($0.displayName).tag($0) }
                }
            }
            Section("Circuit") {
                Picker("Overcurrent device", selection: $serviceOCPD) {
                    ForEach(NECTables.standardOCPD.filter { $0 <= 1200 }, id: \.self) { Text("\($0) A").tag($0) }
                }
            }
            if let result {
                Section("Equipment grounding conductor") {
                    LabeledContent("Copper", value: result.equipmentGround)
                    Text("Sized from the \(serviceOCPD) A device, not from the conductors. Table 250.122.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Section("Grounding electrode conductor") {
                    LabeledContent("Copper", value: result.electrodeConductor)
                    if result.cappedByElectrode {
                        LabeledContent("From the table", value: result.electrodeConductorFromTable)
                        Text("\(electrode.citation) caps a \(electrode.displayName.lowercased()) electrode, so the run to it is smaller than the table alone would say.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    } else {
                        Text("Sized from the service conductor, not from the device. Table 250.66.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                Section {
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkTertiary)
                }
            } else {
                Section {
                    Text("That combination is off the tables. Check the conductor size and the device rating.")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .navigationTitle("Grounding")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Motor circuit

struct MotorToolView: View {
    @State private var supply = NECTables.MotorSupply.three460
    @State private var hp = "10 hp"
    @State private var protection = NECTables.MotorProtection.inverseTimeBreaker
    @State private var nameplate = 13.0

    private var ratings: [NECTables.MotorRating] { NECTables.motorRatings(for: supply) }

    private var result: FieldCalculators.MotorResult? {
        FieldCalculators.motorCircuit(hp: hp, supply: supply, protection: protection, nameplateFLA: nameplate)
    }

    var body: some View {
        Form {
            Section("Motor") {
                Picker("Supply", selection: $supply) {
                    ForEach(NECTables.MotorSupply.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Horsepower", selection: $hp) {
                    ForEach(ratings, id: \.label) { Text($0.label).tag($0.label) }
                }
                Picker("Branch device", selection: $protection) {
                    ForEach(NECTables.MotorProtection.allCases) { Text($0.displayName).tag($0) }
                }
                Stepper("Nameplate: \(nameplate.factorText) A", value: $nameplate, in: 0.5...600, step: 0.5)
            }
            if let result {
                Section("From the table") {
                    LabeledContent("Full-load current", value: "\(result.tableFLC.factorText) A")
                    LabeledContent("Conductors, 125%", value: "\(result.conductorAmpacity.roundedAmpsText) A")
                    if let size = result.conductorSize {
                        LabeledContent("Copper, 75°C column", value: size)
                    }
                    LabeledContent("Branch device, \(result.branchOCPDPercent) max", value: "\(result.branchOCPD) A")
                    if let ground = result.equipmentGround {
                        LabeledContent("Equipment ground", value: ground)
                    }
                }
                Section("From the nameplate") {
                    LabeledContent("Overload, 125%", value: "\(result.overloadAt125.roundedAmpsText) A")
                    LabeledContent("Overload, 115%", value: "\(result.overloadAt115.roundedAmpsText) A")
                    Text("125% where the service factor is 1.15 or more, or the temperature rise is 40°C or less. 115% otherwise. This is the ONLY figure on this screen that comes from the nameplate.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Section {
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkTertiary)
                }
            } else {
                Section {
                    Text("The tables carry no value for that horsepower at that supply. Pick another combination.")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .navigationTitle("Motor circuit")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: supply) { _, _ in
            // A horsepower that exists at 460 V may not exist at 115 V, and a
            // stale selection would render an empty picker with a dead result.
            if !ratings.contains(where: { $0.label == hp }) {
                hp = ratings.first?.label ?? hp
            }
        }
    }
}

// MARK: - Box fill

struct BoxFillToolView: View {
    @State private var conductors = 6
    @State private var conductorSize = "12 AWG"
    @State private var devices = 1
    @State private var hasClamps = true
    @State private var grounds = 3

    private var sizes: [String] {
        ["18 AWG", "16 AWG", "14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG"]
    }

    private var result: FieldCalculators.BoxFillResult? {
        FieldCalculators.boxFill(
            conductors: conductors,
            conductorSize: conductorSize,
            devices: devices,
            hasClamps: hasClamps,
            grounds: grounds,
            groundSize: conductorSize
        )
    }

    var body: some View {
        Form {
            Section("In the box") {
                Picker("Conductor size", selection: $conductorSize) {
                    ForEach(sizes, id: \.self) { Text($0).tag($0) }
                }
                Stepper("Conductors: \(conductors)", value: $conductors, in: 0...40)
                Stepper("Device yokes: \(devices)", value: $devices, in: 0...6)
                Stepper("Equipment grounds: \(grounds)", value: $grounds, in: 0...20)
                Toggle("Internal cable clamps", isOn: $hasClamps)
            }
            if let result {
                Section("Allowances") {
                    LabeledContent("Conductors", value: "\(result.conductorVolume.volumeText) in³")
                    LabeledContent("Device yokes, 2 each", value: "\(result.deviceVolume.volumeText) in³")
                    LabeledContent("Clamps, 1 total", value: "\(result.clampVolume.volumeText) in³")
                    LabeledContent("Grounds, 1 total", value: "\(result.groundVolume.volumeText) in³")
                }
                Section("Result") {
                    LabeledContent("Minimum volume", value: "\(result.required.volumeText) in³")
                    if let box = result.smallestBox {
                        LabeledContent("Smallest listed box", value: box)
                    } else {
                        Text("Larger than every box in Table 314.16(A). Use a box with its volume marked on it.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Text("Grounds count as ONE allowance however many there are, and each yoke counts as TWO. Pigtails made up entirely inside the box are not counted at all.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .navigationTitle("Box fill")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Dwelling service load

struct DwellingLoadToolView: View {
    @State private var squareFeet = 2000.0
    @State private var smallAppliance = 2
    @State private var laundry = 1
    @State private var rangeKW = 12.0
    @State private var rangeCount = 1
    @State private var dryerVA = 5500.0
    @State private var applianceVA = 7600.0
    @State private var applianceCount = 4
    @State private var coolingVA = 5000.0
    @State private var heatingVA = 10000.0

    private var appliances: [Double] {
        guard applianceCount > 0 else { return [] }
        // Split evenly. The 220.53 discount turns on the COUNT and the total,
        // not on how the total is distributed, so an even split gives the same
        // answer as the real nameplates and keeps the input to two controls.
        return Array(repeating: applianceVA / Double(applianceCount), count: applianceCount)
    }

    private var result: FieldCalculators.DwellingLoadResult? {
        FieldCalculators.dwellingLoad(
            squareFeet: squareFeet,
            smallApplianceCircuits: smallAppliance,
            laundryCircuits: laundry,
            rangeKW: rangeKW,
            rangeCount: rangeCount,
            dryerNameplateVA: dryerVA,
            fastenedApplianceVA: appliances,
            coolingVA: coolingVA,
            heatingVA: heatingVA
        )
    }

    var body: some View {
        Form {
            Section("Dwelling") {
                Stepper("Floor area: \(Int(squareFeet)) ft²", value: $squareFeet, in: 400...12000, step: 100)
                Stepper("Small-appliance circuits: \(smallAppliance)", value: $smallAppliance, in: 0...8)
                Stepper("Laundry circuits: \(laundry)", value: $laundry, in: 0...4)
            }
            Section("Range and dryer") {
                Stepper("Ranges: \(rangeCount)", value: $rangeCount, in: 0...12)
                Stepper("Each rated: \(rangeKW.factorText) kW", value: $rangeKW, in: 1...30, step: 0.5)
                Stepper("Dryer nameplate: \(Int(dryerVA)) VA", value: $dryerVA, in: 0...15000, step: 250)
            }
            Section("Other loads") {
                Stepper("Fastened appliances: \(applianceCount)", value: $applianceCount, in: 0...12)
                Stepper("Their total: \(Int(applianceVA)) VA", value: $applianceVA, in: 0...40000, step: 250)
                Stepper("Air conditioning: \(Int(coolingVA)) VA", value: $coolingVA, in: 0...40000, step: 500)
                Stepper("Electric heat: \(Int(heatingVA)) VA", value: $heatingVA, in: 0...60000, step: 500)
            }
            if let result {
                Section("Working") {
                    LabeledContent("General lighting", value: "\(Int(result.generalLighting)) VA")
                    LabeledContent("Circuits", value: "\(Int(result.circuits)) VA")
                    LabeledContent("Subtotal", value: "\(Int(result.generalSubtotal)) VA")
                    LabeledContent("After demand factor", value: "\(Int(result.generalAfterDemand.rounded())) VA")
                    LabeledContent("Range", value: "\(Int(result.rangeDemand)) VA")
                    LabeledContent("Dryer", value: "\(Int(result.dryerDemand)) VA")
                    LabeledContent(
                        applianceCount >= 4 ? "Appliances, at 75%" : "Appliances, at 100%",
                        value: "\(Int(result.applianceAfterDemand.rounded())) VA"
                    )
                    LabeledContent("Heat or cooling, larger", value: "\(Int(result.climate)) VA")
                }
                Section("Result") {
                    LabeledContent("Total", value: "\(Int(result.totalVA.rounded())) VA")
                    LabeledContent("Current at 240 V", value: "\(result.amps.roundedAmpsText) A")
                    LabeledContent("Service", value: "\(result.serviceRating) A")
                    if result.floorApplied {
                        Text("The arithmetic came out below 100 A. A one-family dwelling service has a 100 A floor under 230.79(C), so that is the size.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Text("Standard method. The optional method in 220.82 usually produces a smaller service for the same house, and an exam question naming it wants that answer instead.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                    Text("\(result.citation) · \(NECTables.edition)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .navigationTitle("Dwelling load")
        .navigationBarTitleDisplayMode(.inline)
    }
}
