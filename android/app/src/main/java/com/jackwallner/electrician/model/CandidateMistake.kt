package com.jackwallner.electrician.model

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.objects

// Generated from the Swift catalog by scripts/sync-android-content.py.
object CandidateMistake {
    val all: List<MistakePattern> by lazy {
        ElectricianContent.raw.getJSONArray("mistakePatterns").objects().map {
            MistakePattern(it.getString("id"), it.getString("skill"), it.getString("summary"))
        }
    }
    private val byID: Map<String, MistakePattern> by lazy { all.associateBy { it.id } }
    fun pattern(id: String): MistakePattern? = byID[id]
    private fun required(id: String): MistakePattern = checkNotNull(pattern(id))
    val countedGroundsIndividually: MistakePattern get() = required("boxfill-counted-grounds-individually")
    val countedYokeAsOne: MistakePattern get() = required("boxfill-yoke-as-one")
    val derateFrom75: MistakePattern get() = required("ampacity-derate-from-75")
    val egcReadRowBelow: MistakePattern get() = required("egc-read-row-below")
    val egcUsedCircuitConductor: MistakePattern get() = required("egc-used-circuit-conductor")
    val egcWrongMaterialColumn: MistakePattern get() = required("egc-wrong-material-column")
    val forgotDeviceYokes: MistakePattern get() = required("boxfill-forgot-yokes")
    val forgotPhaseFactor: MistakePattern get() = required("vdrop-forgot-phase-factor")
    val gecIgnoredElectrodeCeiling: MistakePattern get() = required("gec-ignored-electrode-ceiling")
    val gecMissedParallelSet: MistakePattern get() = required("gec-missed-parallel-set")
    val gecWrongServiceColumn: MistakePattern get() = required("gec-wrong-service-column")
    val ignoredBundling: MistakePattern get() = required("ampacity-ignored-bundling")
    val ignoredSmallConductorCap: MistakePattern get() = required("ocpd-ignored-240-4-d")
    val ignoredTerminationCap: MistakePattern get() = required("ampacity-ignored-termination")
    val loadAddedHeatAndCooling: MistakePattern get() = required("load-added-heat-and-cooling")
    val loadForgotApplianceDemand: MistakePattern get() = required("load-forgot-appliance-demand")
    val loadForgotLightingDemand: MistakePattern get() = required("load-forgot-lighting-demand")
    val loadForgotSmallAppliance: MistakePattern get() = required("load-forgot-small-appliance")
    val loadUsedRangeNameplate: MistakePattern get() = required("load-used-range-nameplate")
    val motorForgot125: MistakePattern get() = required("motor-forgot-125")
    val motorRoundedOCPDDown: MistakePattern get() = required("motor-rounded-ocpd-down")
    val motorUsedNameplateForConductors: MistakePattern get() = required("motor-nameplate-for-conductors")
    val motorUsedOverloadPercent: MistakePattern get() = required("motor-used-overload-percent")
    val motorWrongDevicePercent: MistakePattern get() = required("motor-wrong-device-percent")
    val motorWrongVoltageRow: MistakePattern get() = required("motor-wrong-voltage-row")
    val racewayOversized: MistakePattern get() = required("fill-raceway-oversized")
    val racewayTooSmall: MistakePattern get() = required("fill-raceway-too-small")
    val roundedOCPDUp: MistakePattern get() = required("ocpd-rounded-up")
    val sizedOCPDFrom90: MistakePattern get() = required("ocpd-from-90")
    val usedEGCTableForGEC: MistakePattern get() = required("gec-used-250-122")
    val usedFiftyThreePercentFill: MistakePattern get() = required("fill-used-53-percent")
    val usedGECTableForEGC: MistakePattern get() = required("egc-used-250-66")
    val wrongMaterialK: MistakePattern get() = required("vdrop-wrong-material-k")
    val wrongPhaseFactor: MistakePattern get() = required("vdrop-wrong-phase-factor")
}
