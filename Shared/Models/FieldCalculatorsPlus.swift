import Foundation

/// The calculators added alongside the new tables: grounding conductor sizing,
/// motor circuits, box fill, and the dwelling service load.
///
/// Same posture as the originals. These are study estimates built from the same
/// tables the drills compute against, they state their assumptions, and they
/// cite the article so the number can be checked in the reader's own book. They
/// are free for the same reason the first four are: the calculators are what
/// keeps the app in a pouch after the licence arrives, which is the retention
/// problem a question bank cannot solve.
extension FieldCalculators {

    // MARK: - Grounding conductors

    struct GroundingResult: Equatable {
        /// From Table 250.122, sized on the overcurrent device.
        let equipmentGround: String
        /// From Table 250.66, sized on the service conductor.
        let electrodeConductor: String
        /// What the table gave before the electrode's own ceiling applied.
        let electrodeConductorFromTable: String
        /// True where 250.66(A), (B) or (C) reduced the table value.
        let cappedByElectrode: Bool
        let citation: String
    }

    /// Both grounding conductors for one service, side by side.
    ///
    /// Deliberately one calculator and not two. The error this is here to stop
    /// is reaching for the wrong table, and two separate screens would let a
    /// reader make it twice; showing both answers, each labelled with what it
    /// was sized from, makes the difference the whole point of the screen.
    static func grounding(
        serviceSize: String,
        serviceMaterial: ConductorMaterial,
        serviceOCPD: Int,
        electrode: NECTables.ElectrodeType,
        parallelSets: Int = 1
    ) -> GroundingResult? {
        guard let egc = NECTables.equipmentGroundingConductor(ocpd: serviceOCPD, material: .copper),
              let fromTable = NECTables.groundingElectrodeConductor(
                serviceSize: serviceSize,
                serviceMaterial: serviceMaterial,
                gecMaterial: .copper,
                parallelSets: parallelSets
              )
        else { return nil }

        var required = fromTable
        if let ceiling = electrode.copperCeiling,
           let ceilingMils = NECTables.circularMilsExtended[ceiling],
           let tableMils = NECTables.circularMilsExtended[fromTable],
           tableMils > ceilingMils {
            required = ceiling
        }

        return GroundingResult(
            equipmentGround: egc,
            electrodeConductor: required,
            electrodeConductorFromTable: fromTable,
            cappedByElectrode: required != fromTable,
            citation: "Table 250.122, Table 250.66, \(electrode.citation)"
        )
    }

    // MARK: - Motor circuits

    struct MotorResult: Equatable {
        let tableFLC: Double
        /// 430.22: 125% of the table current.
        let conductorAmpacity: Double
        /// The smallest copper conductor with that ampacity in the 75°C column.
        let conductorSize: String?
        /// 430.52 maximum, after the round-up allowance.
        let branchOCPD: Int
        let branchOCPDPercent: String
        /// 430.32, from the NAMEPLATE, both service-factor cases.
        let overloadAt115: Double
        let overloadAt125: Double
        /// Table 250.122, read from the branch device.
        let equipmentGround: String?
        let citation: String
    }

    /// One motor's whole branch circuit: conductors, short-circuit protection,
    /// overload, and the ground that runs with it.
    ///
    /// The nameplate is an input and it is used exactly once, for the overload
    /// figures. Everything else is computed from the table, which is the rule
    /// this screen exists to make visible.
    static func motorCircuit(
        hp label: String,
        supply: NECTables.MotorSupply,
        protection: NECTables.MotorProtection,
        nameplateFLA: Double
    ) -> MotorResult? {
        guard let flc = NECTables.motorFLC(hp: label, supply: supply),
              let ocpd = NECTables.motorBranchOCPD(flc: flc, protection: protection)
        else { return nil }

        let ampacity = flc * NECTables.motorConductorFactor
        let size = NECTables.conductorSizes.first {
            Double(NECTables.ampacity(size: $0, material: .copper, column: .c75) ?? 0) >= ampacity
        }

        return MotorResult(
            tableFLC: flc,
            conductorAmpacity: ampacity,
            conductorSize: size,
            branchOCPD: ocpd,
            branchOCPDPercent: protection.percentLabel,
            overloadAt115: nameplateFLA * 1.15,
            overloadAt125: nameplateFLA * 1.25,
            equipmentGround: NECTables.equipmentGroundingConductor(ocpd: ocpd, material: .copper),
            citation: "430.22, \(supply.citation), 430.52, 430.32, Table 250.122"
        )
    }

    // MARK: - Box fill

    struct BoxFillResult: Equatable {
        let conductorVolume: Double
        let clampVolume: Double
        let deviceVolume: Double
        let groundVolume: Double
        let required: Double
        /// The smallest box in Table 314.16(A) that holds it.
        let smallestBox: String?
        let citation: String
    }

    /// Box fill from what is actually in the box, counted the way 314.16(B)
    /// counts it: every allowance sized on the largest conductor it belongs to,
    /// all the grounds together as one, and each device yoke as two.
    ///
    /// - Parameters:
    ///   - conductors: how many insulated conductors enter and terminate or
    ///     pass through. Pigtails made up entirely inside the box are not
    ///     counted and should not be included.
    ///   - conductorSize: the size those conductors are.
    ///   - devices: device or equipment yokes, each worth two allowances.
    ///   - hasClamps: whether there are internal cable clamps. However many,
    ///     they are one allowance together.
    ///   - grounds: how many equipment grounds. However many, they are one
    ///     allowance together, which is what the parameter is here to prove.
    static func boxFill(
        conductors: Int,
        conductorSize: String,
        devices: Int,
        hasClamps: Bool,
        grounds: Int,
        groundSize: String
    ) -> BoxFillResult? {
        guard conductors >= 0, devices >= 0, grounds >= 0,
              let unit = NECTables.conductorVolume[conductorSize],
              let groundUnit = NECTables.conductorVolume[groundSize]
        else { return nil }

        let conductorVolume = Double(conductors) * unit
        let clampVolume = hasClamps ? unit : 0
        let deviceVolume = Double(devices) * 2 * unit
        let groundVolume = grounds > 0 ? groundUnit : 0
        let required = conductorVolume + clampVolume + deviceVolume + groundVolume

        return BoxFillResult(
            conductorVolume: conductorVolume,
            clampVolume: clampVolume,
            deviceVolume: deviceVolume,
            groundVolume: groundVolume,
            required: required,
            smallestBox: NECTables.smallestBox(forCubicInches: required)?.name,
            citation: "314.16(A), 314.16(B)"
        )
    }

    // MARK: - Dwelling service load

    struct DwellingLoadResult: Equatable {
        let generalLighting: Double
        let circuits: Double
        let generalSubtotal: Double
        let generalAfterDemand: Double
        let rangeDemand: Double
        let dryerDemand: Double
        let applianceTotal: Double
        let applianceAfterDemand: Double
        let climate: Double
        let totalVA: Double
        let amps: Double
        let serviceRating: Int
        /// True when 230.79(C)'s 100 A floor, not the arithmetic, set the size.
        let floorApplied: Bool
        let citation: String
    }

    /// The standard-method dwelling calculation, step by step.
    ///
    /// Every intermediate figure is returned rather than just the answer,
    /// because on this calculation the answer alone is useless: a reader who
    /// disagrees with it needs to see which of the eight steps they and the app
    /// worked differently.
    static func dwellingLoad(
        squareFeet: Double,
        smallApplianceCircuits: Int,
        laundryCircuits: Int,
        rangeKW: Double,
        rangeCount: Int,
        dryerNameplateVA: Double,
        fastenedApplianceVA: [Double],
        coolingVA: Double,
        heatingVA: Double,
        volts: Double = 240
    ) -> DwellingLoadResult? {
        guard squareFeet > 0 else { return nil }

        let lighting = squareFeet * NECTables.dwellingLightingVAPerSqFt
        let circuits = Double(max(0, smallApplianceCircuits)) * NECTables.smallApplianceCircuitVA
            + Double(max(0, laundryCircuits)) * NECTables.laundryCircuitVA
        let subtotal = lighting + circuits
        let afterDemand = NECTables.generalLightingDemand(totalVA: subtotal)

        let range = rangeCount > 0
            ? (NECTables.rangeDemandKW(count: rangeCount, eachKW: rangeKW) ?? 0) * 1000
            : 0
        let dryer = dryerNameplateVA > 0 ? max(dryerNameplateVA, NECTables.minimumDryerVA) : 0

        let applianceTotal = fastenedApplianceVA.reduce(0, +)
        let applianceAfter = NECTables.fastenedApplianceDemand(
            totalVA: applianceTotal, count: fastenedApplianceVA.count
        )

        let climate = NECTables.noncoincident(coolingVA, heatingVA)
        let total = afterDemand + range + dryer + applianceAfter + climate
        let amps = NECTables.serviceAmps(va: total, volts: volts)
        guard let rating = NECTables.dwellingServiceRating(amps: amps),
              let unclamped = NECTables.nextStandardOCPD(atLeast: amps)
        else { return nil }

        return DwellingLoadResult(
            generalLighting: lighting,
            circuits: circuits,
            generalSubtotal: subtotal,
            generalAfterDemand: afterDemand,
            rangeDemand: range,
            dryerDemand: dryer,
            applianceTotal: applianceTotal,
            applianceAfterDemand: applianceAfter,
            climate: climate,
            totalVA: total,
            amps: amps,
            serviceRating: rating,
            floorApplied: rating > unclamped,
            citation: "220.41, Table 220.45, 220.52, 220.53, 220.54, Table 220.55, 220.60, 230.79(C)"
        )
    }
}
