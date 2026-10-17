package com.jackwallner.electrician.model

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

data class AmpacityResult(val tableAmps: Int, val ambientFactor: Double, val adjustment: Double, val afterDerate: Double, val terminationCap: Int, val smallConductorCeiling: Int?, val allowable: Double, val ocpdCeiling: Double, val citation: String)
data class ConduitFillResult(val oneConductorArea: Double, val bundleArea: Double, val racewayArea: Double, val allowedPercent: Double, val allowedArea: Double, val actualPercent: Double, val fits: Boolean, val smallestFitting: String?, val citation: String)
data class VoltageDropResult(val volts: Double, val percent: Double, val withinThreePercent: Boolean, val citation: String) {
    companion object {
        val assumptions = listOf(
            "Resistive only: reactance and power factor are not included.",
            "Conductor at its table resistance, not at operating temperature.",
            "Uncoated conductor in a non-magnetic raceway.",
            "One-way length doubled (or × 1.732) by the phase factor, not a measured circuit path.",
        )
        const val threePercentNote = "3% is the figure the informational note suggests for a branch circuit. It is a recommendation, not a general requirement, though some jurisdictions do enforce it."
    }
}
data class OhmsLawResult(val volts: Double, val amps: Double, val ohms: Double, val watts: Double, val basis: String, val conflicts: List<String> = emptyList()) {
    val isConsistent: Boolean get() = conflicts.isEmpty()
}
data class GroundingResult(val equipmentGround: String, val electrodeConductor: String, val electrodeConductorFromTable: String, val cappedByElectrode: Boolean, val citation: String)
data class MotorResult(val tableFLC: Double, val conductorAmpacity: Double, val conductorSize: String?, val branchOCPD: Int, val branchOCPDPercent: String, val overloadAt115: Double, val overloadAt125: Double, val equipmentGround: String?, val citation: String)
data class BoxFillResult(val conductorVolume: Double, val clampVolume: Double, val deviceVolume: Double, val groundVolume: Double, val required: Double, val smallestBox: String?, val citation: String)
data class DwellingLoadResult(val generalLighting: Double, val circuits: Double, val generalSubtotal: Double, val generalAfterDemand: Double, val rangeDemand: Double, val dryerDemand: Double, val applianceTotal: Double, val applianceAfterDemand: Double, val climate: Double, val totalVA: Double, val amps: Double, val serviceRating: Int, val floorApplied: Boolean, val citation: String)

object FieldCalculators {
    fun ampacity(size: String, material: ConductorMaterial, insulation: TemperatureRating, termination: TemperatureRating, ambientCelsius: Int, currentCarrying: Int): AmpacityResult? {
        val table = NECTables.ampacity(size, material, insulation) ?: return null
        val ambient = NECTables.ambientCorrection(ambientCelsius, insulation) ?: return null
        val terminationCap = NECTables.ampacity(size, material, termination) ?: return null
        val adjustment = NECTables.adjustmentFactor(currentCarrying)
        val afterDerate = table * ambient * adjustment
        val allowable = min(afterDerate, terminationCap.toDouble())
        val ceiling = NECTables.smallConductorCeiling(size, material)
        return AmpacityResult(table, ambient, adjustment, afterDerate, terminationCap, ceiling, allowable, ceiling?.let { min(allowable, it.toDouble()) } ?: allowable,
            "310.16, 310.15(B)(1), 310.15(C)(1), 110.14(C), 240.4(D)")
    }

    fun conduitFill(conductorSize: String, count: Int, tradeSize: String): ConduitFillResult? {
        if (count < 1) return null
        val one = NECTables.thhnArea[conductorSize] ?: return null
        val raceway = NECTables.emtArea[tradeSize] ?: return null
        val allowedPercent = NECTables.fillPercent(count)
        val bundle = one * count
        val allowedArea = raceway * allowedPercent
        val smallest = NECTables.emtTradeSizes.firstOrNull { (NECTables.emtArea[it] ?: 0.0) * allowedPercent + 0.0000001 >= bundle }
        return ConduitFillResult(one, bundle, raceway, allowedPercent, allowedArea, bundle / raceway, bundle <= allowedArea + 0.0000001, smallest, "Ch. 9 Table 1, Table 4, Table 5")
    }

    fun voltageDrop(size: String, material: ConductorMaterial, phase: Phase, systemVolts: Double, amps: Double, oneWayFeet: Double): VoltageDropResult? {
        if (systemVolts <= 0 || amps <= 0 || oneWayFeet <= 0) return null
        val cmil = NECTables.circularMils[size] ?: return null
        val drop = phase.voltageDropFactor * material.voltageDropK * amps * oneWayFeet / cmil
        val percent = drop / systemVolts * 100
        return VoltageDropResult(drop, percent, percent <= 3.0001, "210.19(A) Informational Note, Ch. 9 Table 8")
    }

    fun ohmsLaw(volts: Double?, amps: Double?, ohms: Double?, watts: Double?): OhmsLawResult? {
        fun valid(value: Double?): Double? = value?.takeIf { it > 0 && it.isFinite() }
        val v = valid(volts)
        val i = valid(amps)
        val r = valid(ohms)
        val p = valid(watts)
        val result = when {
            v != null && i != null -> OhmsLawResult(v, i, v / i, v * i, "V and I")
            v != null && r != null -> OhmsLawResult(v, v / r, r, v * v / r, "V and R")
            i != null && r != null -> OhmsLawResult(i * r, i, r, i * i * r, "I and R")
            v != null && p != null -> OhmsLawResult(v, p / v, v * v / p, p, "V and P")
            i != null && p != null -> OhmsLawResult(p / i, i, p / (i * i), p, "I and P")
            r != null && p != null -> sqrt(p * r).let { OhmsLawResult(it, it / r, r, p, "R and P") }
            else -> return null
        }
        val supplied = listOf("V" to (v to result.volts), "I" to (i to result.amps), "R" to (r to result.ohms), "P" to (p to result.watts))
        val conflicts = supplied.filter { (_, pair) -> pair.first?.let { pair.second > 0 && abs(it - pair.second) / pair.second > 0.01 } == true }.map { it.first }
        return result.copy(conflicts = conflicts)
    }

    fun grounding(serviceSize: String, serviceMaterial: ConductorMaterial, serviceOCPD: Int, electrode: ElectrodeType, parallelSets: Int = 1): GroundingResult? {
        val egc = NECTables.equipmentGroundingConductor(serviceOCPD, ConductorMaterial.copper) ?: return null
        val fromTable = NECTables.groundingElectrodeConductor(serviceSize, serviceMaterial, ConductorMaterial.copper, parallelSets) ?: return null
        val ceiling = electrode.copperCeiling
        val required = if (ceiling != null && checkNotNull(NECTables.circularMilsExtended[fromTable]) > checkNotNull(NECTables.circularMilsExtended[ceiling])) ceiling else fromTable
        return GroundingResult(egc, required, fromTable, required != fromTable, "Table 250.122, Table 250.66, ${electrode.citation}")
    }

    fun motorCircuit(hp: String, supply: MotorSupply, protection: MotorProtection, nameplateFLA: Double): MotorResult? {
        val flc = NECTables.motorFLC(hp, supply) ?: return null
        val ocpd = NECTables.motorBranchOCPD(flc, protection) ?: return null
        val ampacity = flc * NECTables.motorConductorFactor
        val size = NECTables.conductorSizes.firstOrNull { (NECTables.ampacity(it, ConductorMaterial.copper, TemperatureRating.c75) ?: 0) >= ampacity }
        return MotorResult(flc, ampacity, size, ocpd, protection.percentLabel, nameplateFLA * 1.15, nameplateFLA * 1.25,
            NECTables.equipmentGroundingConductor(ocpd, ConductorMaterial.copper), "430.22, ${supply.citation}, 430.52, 430.32, Table 250.122")
    }

    fun boxFill(conductors: Int, conductorSize: String, devices: Int, hasClamps: Boolean, grounds: Int, groundSize: String): BoxFillResult? {
        if (conductors < 0 || devices < 0 || grounds < 0) return null
        val unit = NECTables.conductorVolume[conductorSize] ?: return null
        val groundUnit = NECTables.conductorVolume[groundSize] ?: return null
        val conductorVolume = conductors * unit
        val clampVolume = if (hasClamps) unit else 0.0
        val deviceVolume = devices * 2 * unit
        val groundVolume = if (grounds > 0) groundUnit else 0.0
        val required = conductorVolume + clampVolume + deviceVolume + groundVolume
        return BoxFillResult(conductorVolume, clampVolume, deviceVolume, groundVolume, required, NECTables.smallestBox(required)?.name, "314.16(A), 314.16(B)")
    }

    fun dwellingLoad(squareFeet: Double, smallApplianceCircuits: Int, laundryCircuits: Int, rangeKW: Double, rangeCount: Int, dryerNameplateVA: Double, fastenedApplianceVA: List<Double>, coolingVA: Double, heatingVA: Double, volts: Double = 240.0): DwellingLoadResult? {
        if (squareFeet <= 0) return null
        val lighting = squareFeet * 3
        val circuits = max(0, smallApplianceCircuits) * 1500.0 + max(0, laundryCircuits) * 1500.0
        val subtotal = lighting + circuits
        val afterDemand = NECTables.generalLightingDemand(subtotal)
        val range = if (rangeCount > 0) (NECTables.rangeDemandKW(rangeCount, rangeKW) ?: 0.0) * 1000 else 0.0
        val dryer = if (dryerNameplateVA > 0) max(dryerNameplateVA, 5000.0) else 0.0
        val applianceTotal = fastenedApplianceVA.sum()
        val applianceAfter = NECTables.fastenedApplianceDemand(applianceTotal, fastenedApplianceVA.size)
        val climate = NECTables.noncoincident(coolingVA, heatingVA)
        val total = afterDemand + range + dryer + applianceAfter + climate
        val amps = NECTables.serviceAmps(total, volts)
        val rating = NECTables.dwellingServiceRating(amps) ?: return null
        val unclamped = NECTables.nextStandardOCPDAtLeast(amps) ?: return null
        return DwellingLoadResult(lighting, circuits, subtotal, afterDemand, range, dryer, applianceTotal, applianceAfter, climate, total, amps, rating, rating > unclamped,
            "220.41, Table 220.45, 220.52, 220.53, 220.54, Table 220.55, 220.60, 230.79(C)")
    }
}
