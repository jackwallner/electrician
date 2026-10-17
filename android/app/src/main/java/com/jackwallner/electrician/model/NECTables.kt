package com.jackwallner.electrician.model

import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

import org.json.JSONObject

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.objects
import com.jackwallner.electrician.content.strings

data class GECRow(val serviceUpTo: Double, val copper: String, val aluminum: String)
data class EGCRow(val ocpdUpTo: Int, val copper: String, val aluminum: String)
data class MotorRating(val label: String, val hp: Double)
data class BoxSize(val name: String, val cubicInches: Double)

enum class ElectrodeType(val displayName: String, val copperCeiling: String?, val citation: String) {
    rodPipePlate("Rod, pipe or plate", "6 AWG", "250.66(A)"),
    concreteEncased("Concrete-encased", "4 AWG", "250.66(B)"),
    groundRing("Ground ring", "2 AWG", "250.66(C)"),
    waterPipe("Metal water pipe", null, "250.66"),
}
enum class MotorSupply(val displayName: String, val volts: Int, val phase: Phase) {
    single115("115V 1Ø", 115, Phase.single), single230("230V 1Ø", 230, Phase.single),
    three208("208V 3Ø", 208, Phase.three), three230("230V 3Ø", 230, Phase.three), three460("460V 3Ø", 460, Phase.three);
    val citation: String get() = if (phase == Phase.single) "430.248" else "430.250"
}
enum class MotorProtection(val displayName: String, val percent: Double) {
    nonTimeDelayFuse("Nontime-delay fuse", 3.0), dualElementFuse("Dual-element (time-delay) fuse", 1.75),
    instantaneousTrip("Instantaneous-trip breaker", 8.0), inverseTimeBreaker("Inverse-time breaker", 2.5);
    val percentLabel: String get() = "${(percent * 100).toInt()}%"
}

object NECTables {
    private val raw: JSONObject get() = ElectricianContent.raw.getJSONObject("tables")
    val edition: String get() = raw.getString("edition")
    val stableSince: Int get() = raw.getInt("stableSince")
    val verifiedThrough: Int get() = raw.getInt("verifiedThrough")
    val coverageLabel: String get() = raw.getString("coverageLabel")
    val editionNote: String get() = raw.getString("editionNote")
    val coverageNote: String get() = raw.getString("coverageNote")
    val conductorSizes: List<String> by lazy { raw.getJSONArray("conductorSizes").strings() }
    val circularMils: Map<String, Double> by lazy { numbers("circularMils") }
    val circularMilsExtended: Map<String, Double> by lazy { numbers("circularMilsExtended") }
    val conductorVolume: Map<String, Double> by lazy { numbers("conductorVolume") }
    val emtArea: Map<String, Double> by lazy { numbers("emtArea") }
    val thhnArea: Map<String, Double> by lazy { numbers("thhnArea") }
    val emtTradeSizes: List<String> by lazy { raw.getJSONArray("emtTradeSizes").strings() }
    val standardOCPD: List<Int> by lazy { raw.getJSONArray("standardOCPD").let { rows -> (0 until rows.length()).map(rows::getInt) } }
    val gecCopperService: List<GECRow> by lazy { gecRows("gecCopperService") }
    val gecAluminumService: List<GECRow> by lazy { gecRows("gecAluminumService") }
    val egcRows: List<EGCRow> by lazy { raw.getJSONArray("egcRows").objects().map { EGCRow(it.getInt("ocpdUpTo"), it.getString("copper"), it.getString("aluminum")) } }
    val motorRatings: List<MotorRating> by lazy { raw.getJSONArray("motorRatings").objects().map { MotorRating(it.getString("label"), it.getDouble("hp")) } }
    val boxSizes: List<BoxSize> by lazy { raw.getJSONArray("boxSizes").objects().map { BoxSize(it.getString("name"), it.getDouble("cubicInches")) } }

    fun ampacity(size: String, material: ConductorMaterial, column: TemperatureRating): Int? =
        raw.getJSONObject(if (material == ConductorMaterial.copper) "copperAmpacity" else "aluminumAmpacity")
            .optJSONObject(size)?.nullableDouble(column.value.toString())?.toInt()

    fun ambientCorrection(celsius: Int, column: TemperatureRating): Double? {
        if (celsius <= 25) return 1.0
        return raw.getJSONArray("ambient").objects().firstOrNull { it.getInt("celsius") == celsius }
            ?.getJSONObject("columns")?.nullableDouble(column.value.toString())
    }

    fun adjustmentFactor(currentCarrying: Int): Double = when {
        currentCarrying <= 3 -> 1.0
        currentCarrying <= 6 -> 0.8
        currentCarrying <= 9 -> 0.7
        currentCarrying <= 20 -> 0.5
        currentCarrying <= 30 -> 0.45
        currentCarrying <= 40 -> 0.4
        else -> 0.35
    }
    fun nextStandardOCPDAtLeast(amps: Double): Int? = standardOCPD.firstOrNull { it >= amps - 0.0001 }
    fun nextStandardOCPDAtMost(amps: Double): Int? = standardOCPD.lastOrNull { it <= amps + 0.0001 }
    fun smallConductorCeiling(size: String, material: ConductorMaterial): Int? =
        raw.getJSONObject("smallConductorLimit").optJSONObject(size)?.nullableDouble(material.name)?.toInt()
    fun fillPercent(conductorCount: Int): Double = when (conductorCount) { 1 -> 0.53; 2 -> 0.31; else -> 0.4 }

    fun groundingElectrodeConductor(serviceSize: String, serviceMaterial: ConductorMaterial, gecMaterial: ConductorMaterial, parallelSets: Int = 1): String? {
        val one = circularMilsExtended[serviceSize] ?: return null
        if (parallelSets < 1) return null
        val rows = if (serviceMaterial == ConductorMaterial.copper) gecCopperService else gecAluminumService
        val row = rows.firstOrNull { one * parallelSets <= it.serviceUpTo + 0.5 } ?: return null
        return if (gecMaterial == ConductorMaterial.copper) row.copper else row.aluminum
    }
    fun groundingElectrodeConductor(serviceSize: String, serviceMaterial: ConductorMaterial, electrode: ElectrodeType): Pair<String, String>? {
        val table = groundingElectrodeConductor(serviceSize, serviceMaterial, ConductorMaterial.copper) ?: return null
        val ceiling = electrode.copperCeiling ?: return table to table
        return table to if (checkNotNull(circularMilsExtended[table]) > checkNotNull(circularMilsExtended[ceiling])) ceiling else table
    }
    fun equipmentGroundingConductor(ocpd: Int, material: ConductorMaterial): String? = egcRows.firstOrNull { ocpd <= it.ocpdUpTo }?.let { if (material == ConductorMaterial.copper) it.copper else it.aluminum }
    fun equipmentGroundingRow(ocpd: Int): Int? = egcRows.firstOrNull { ocpd <= it.ocpdUpTo }?.ocpdUpTo
    fun mainBondingJumperMils(serviceMils: Double, serviceMaterial: ConductorMaterial): Double? {
        val limit = if (serviceMaterial == ConductorMaterial.copper) 1_100_000.0 else 1_750_000.0
        if (serviceMils > limit) return serviceMils * 0.125
        val rows = if (serviceMaterial == ConductorMaterial.copper) gecCopperService else gecAluminumService
        val row = rows.firstOrNull { serviceMils <= it.serviceUpTo + 0.5 } ?: return null
        return circularMilsExtended[if (serviceMaterial == ConductorMaterial.copper) row.copper else row.aluminum]
    }

    fun motorFLC(hp: String, supply: MotorSupply): Double? = raw.getJSONObject(if (supply.phase == Phase.single) "singlePhaseFLC" else "threePhaseFLC").optJSONObject(hp)?.nullableDouble(supply.name)
    fun motorRatings(supply: MotorSupply): List<MotorRating> = motorRatings.filter { motorFLC(it.label, supply) != null }
    const val motorConductorFactor = 1.25
    fun motorBranchOCPD(flc: Double, protection: MotorProtection): Int? = standardOCPD.firstOrNull { abs(it - flc * protection.percent) < 0.0001 } ?: nextStandardOCPDAtLeast(flc * protection.percent)
    fun motorOverloadTrip(nameplateFLA: Double, serviceFactor: Double, tempRiseC: Double?): Double = nameplateFLA * if (serviceFactor >= 1.15 || tempRiseC != null && tempRiseC <= 40) 1.25 else 1.15
    fun motorFeederAmpacity(flcs: List<Double>): Double? = flcs.maxOrNull()?.let { it * motorConductorFactor + (flcs.sum() - it) }
    fun motorFeederOCPD(largestBranchOCPD: Int, otherFLCs: List<Double>): Int? = nextStandardOCPDAtMost(largestBranchOCPD + otherFLCs.sum())

    fun generalLightingDemand(totalVA: Double): Double {
        var remaining = totalVA
        val first = min(remaining, 3000.0)
        remaining -= first
        val second = min(remaining, 117_000.0)
        remaining -= second
        return first + second * 0.35 + remaining * 0.25
    }
    fun rangeDemandKW(count: Int, eachKW: Double): Double? {
        if (count < 1) return null
        val base = raw.getJSONObject("rangeColumnC").nullableDouble(count.toString()) ?: return null
        if (eachKW <= 12) return base
        val over = eachKW - 12
        val steps = if (over - floor(over) >= 0.5) floor(over) + 1 else floor(over)
        return base * (1 + 0.05 * max(0.0, steps))
    }
    fun fastenedApplianceDemand(totalVA: Double, count: Int): Double = if (count >= 4) totalVA * 0.75 else totalVA
    fun noncoincident(a: Double, b: Double): Double = max(a, b)
    fun serviceAmps(va: Double, volts: Double = 240.0, phase: Phase = Phase.single): Double = va / (volts * if (phase == Phase.single) 1.0 else 1.732)
    const val minimumDwellingServiceAmps = 100
    fun dwellingServiceRating(amps: Double): Int? = nextStandardOCPDAtLeast(amps)?.let { max(it, minimumDwellingServiceAmps) }
    fun optionalMethodGeneralLoad(totalVA: Double): Double = min(totalVA, 10_000.0) + max(0.0, totalVA - 10_000) * 0.4
    fun optionalMethodHVAC(coolingVA: Double, heatingVA: Double, heatingUnits: Int): Double = max(coolingVA, heatingVA * if (heatingUnits >= 4) 0.4 else 0.65)
    fun smallestBox(required: Double): BoxSize? = boxSizes.sortedBy { it.cubicInches }.firstOrNull { it.cubicInches >= required - 0.0001 }
    fun terminationColumn(circuitAmps: Double, conductorSize: String): TemperatureRating = if (circuitAmps > 100 || (circularMilsExtended[conductorSize] ?: 0.0) > (circularMilsExtended["1 AWG"] ?: 0.0)) TemperatureRating.c75 else TemperatureRating.c60
    const val continuousLoadFactor = 1.25
    const val continuousLoadHours = 3

    private fun numbers(key: String): Map<String, Double> = raw.getJSONObject(key).let { rows -> rows.keys().asSequence().associateWith(rows::getDouble) }
    private fun gecRows(key: String): List<GECRow> = raw.getJSONArray(key).objects().map { GECRow(it.getDouble("serviceUpTo"), it.getString("copper"), it.getString("aluminum")) }
    private fun JSONObject.nullableDouble(key: String): Double? = if (!has(key) || isNull(key)) null else getDouble(key)
}
