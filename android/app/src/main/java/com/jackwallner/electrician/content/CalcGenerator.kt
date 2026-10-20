package com.jackwallner.electrician.content

import java.util.UUID
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

import com.jackwallner.electrician.model.CalcScenario
import com.jackwallner.electrician.model.ConductorMaterial
import com.jackwallner.electrician.model.ElectrodeType
import com.jackwallner.electrician.model.Given
import com.jackwallner.electrician.model.MistakePattern
import com.jackwallner.electrician.model.MotorProtection
import com.jackwallner.electrician.model.MotorRating
import com.jackwallner.electrician.model.MotorSupply
import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.model.Phase
import com.jackwallner.electrician.model.RandomSource
import com.jackwallner.electrician.model.SeededGenerator
import com.jackwallner.electrician.model.TemperatureRating
import com.jackwallner.electrician.model.areaText
import com.jackwallner.electrician.model.factorText
import com.jackwallner.electrician.model.groupedText
import com.jackwallner.electrician.model.nextBoolean
import com.jackwallner.electrician.model.nextDouble
import com.jackwallner.electrician.model.nextInt
import com.jackwallner.electrician.model.randomElement
import com.jackwallner.electrician.model.roundedAmpsText
import com.jackwallner.electrician.model.roundedAway
import com.jackwallner.electrician.model.shuffleSwift
import com.jackwallner.electrician.model.shuffledSwift
import com.jackwallner.electrician.model.trimmedAmps
import com.jackwallner.electrician.model.voltsText
import com.jackwallner.electrician.model.volumeText

/**
 * The named mistakes the generator sets traps for. A port of iOS
 * `CandidateMistake`; `id` values are persisted, so never rename one.
 */
object CandidateMistake {
    private fun p(id: String, skill: PracticeSkill, summary: String) = MistakePattern(id, skill.name, summary)

    val derateFrom75 = p("ampacity-derate-from-75", PracticeSkill.ampacity, "You derated from the 75°C column. Corrections and adjustments start in the conductor's own insulation column, and 75°C only comes back at the end as the termination cap.")
    val ignoredBundling = p("ampacity-ignored-bundling", PracticeSkill.ampacity, "You applied the ambient correction but not the bundling adjustment. Four or more current-carrying conductors derate again, and the two factors multiply.")
    val ignoredTerminationCap = p("ampacity-ignored-termination", PracticeSkill.ampacity, "You derated correctly and then stopped. The result still has to be capped at the termination column, which is usually 75°C.")
    val ignoredSmallConductorCap = p("ocpd-ignored-240-4-d", PracticeSkill.overcurrent, "You protected at the ampacity table value and missed 240.4(D). For 14, 12 and 10 AWG the small-conductor ceiling overrides the table.")
    val roundedOCPDUp = p("ocpd-rounded-up", PracticeSkill.overcurrent, "You rounded up to the next standard rating. Without a next-size-up allowance the protection goes to the largest standard rating at or BELOW the conductor's usable ampacity.")
    val sizedOCPDFrom90 = p("ocpd-from-90", PracticeSkill.overcurrent, "You sized from the 90°C column. The 90°C value is a starting point for derating, never the number equipment terminations let you protect at.")
    val usedFiftyThreePercentFill = p("fill-used-53-percent", PracticeSkill.conduitFill, "You used 53% fill. That is the allowance for ONE conductor. Over two conductors the allowance is 40%.")
    val racewayTooSmall = p("fill-raceway-too-small", PracticeSkill.conduitFill, "That raceway does not hold the bundle. Compare the bundle area against the allowance for the trade size, not against the raceway's full interior area.")
    val racewayOversized = p("fill-raceway-oversized", PracticeSkill.conduitFill, "That size works but it is not the smallest that works. The question asks for the smallest trade size the bundle fits in.")
    val countedGroundsIndividually = p("boxfill-counted-grounds-individually", PracticeSkill.boxFill, "You counted each equipment ground separately. All the grounds in a box together are ONE allowance, however many there are.")
    val forgotDeviceYokes = p("boxfill-forgot-yokes", PracticeSkill.boxFill, "You left the devices out. Each device yoke takes volume in the box.")
    val countedYokeAsOne = p("boxfill-yoke-as-one", PracticeSkill.boxFill, "You counted each yoke as one allowance. A device yoke counts as TWO.")
    val wrongPhaseFactor = p("vdrop-wrong-phase-factor", PracticeSkill.voltageDrop, "You used the other phase's factor. Single-phase uses 2 because the current goes out and back; three-phase uses 1.732.")
    val forgotPhaseFactor = p("vdrop-forgot-phase-factor", PracticeSkill.voltageDrop, "You left the phase factor out entirely, so the drop is only the one-way figure.")
    val wrongMaterialK = p("vdrop-wrong-material-k", PracticeSkill.voltageDrop, "You used the other metal's K. Copper and aluminum have different resistivity constants and swapping them moves the answer by about 60%.")

    val usedGECTableForEGC = p("egc-used-250-66", PracticeSkill.egcSizing, "You sized this from Table 250.66. That table sizes the conductor to the electrode, and it is read from the service conductor. An equipment ground running with a circuit comes from Table 250.122, read from the overcurrent device.")
    val egcWrongMaterialColumn = p("egc-wrong-material-column", PracticeSkill.egcSizing, "You read the other metal's column. Aluminum needs more area than copper for the same job, so the two columns are never the same size on a row.")
    val egcReadRowBelow = p("egc-read-row-below", PracticeSkill.egcSizing, "You dropped to the row below. Table 250.122 is a set of not-exceeding bands: a rating between two rows reads the row ABOVE it, so a 45 A device takes the 60 A row.")
    val egcUsedCircuitConductor = p("egc-used-circuit-conductor", PracticeSkill.egcSizing, "That is the circuit conductor size, not the equipment ground. The ground is sized independently from the device rating and is almost always smaller.")
    val usedEGCTableForGEC = p("gec-used-250-122", PracticeSkill.gecSizing, "You sized this from Table 250.122, which is read from the overcurrent device and sizes an equipment ground. The conductor to the electrode comes from Table 250.66, read from the largest ungrounded service conductor.")
    val gecIgnoredElectrodeCeiling = p("gec-ignored-electrode-ceiling", PracticeSkill.gecSizing, "That is the table value, but the electrode caps it. A rod, pipe or plate never requires more than 6 AWG copper, a concrete-encased electrode more than 4 AWG, and a ground ring more than the ring conductor itself.")
    val gecWrongServiceColumn = p("gec-wrong-service-column", PracticeSkill.gecSizing, "You read the copper service bands for an aluminum service, or the reverse. Table 250.66 has a separate set of bands for each service metal, and they do not line up.")
    val gecMissedParallelSet = p("gec-missed-parallel-set", PracticeSkill.gecSizing, "You read the table on one conductor of the parallel set. The table is entered on the EQUIVALENT area of the whole set: two 250 kcmil in parallel is read as 500 kcmil.")

    val motorUsedNameplateForConductors = p("motor-nameplate-for-conductors", PracticeSkill.motorConductor, "You sized from the nameplate current. Branch-circuit conductors come off the full-load current in Table 430.248 or 430.250, whatever the nameplate says. The nameplate is only used for the overload device.")
    val motorForgot125 = p("motor-forgot-125", PracticeSkill.motorConductor, "You used the full-load current straight. 430.22 puts branch-circuit conductors for a single continuous-duty motor at 125% of it.")
    val motorWrongVoltageRow = p("motor-wrong-voltage-row", PracticeSkill.motorConductor, "You read the wrong voltage column. The same horsepower draws roughly half the current at twice the voltage, so picking the wrong column is a 2x error, not a rounding one.")
    val motorRoundedOCPDDown = p("motor-rounded-ocpd-down", PracticeSkill.motorProtection, "You rounded down to the next standard rating. Motor branch-circuit protection is the exception: 430.52(C)(1) Exception 1 lets you go UP to the next standard size when the percentage does not land on one, because the device has to survive starting current.")
    val motorWrongDevicePercent = p("motor-wrong-device-percent", PracticeSkill.motorProtection, "You used another device's percentage. Table 430.52 gives each type its own ceiling: 300% for a nontime-delay fuse, 175% for a dual-element fuse, 250% for an inverse-time breaker, 800% for an instantaneous-trip breaker.")
    val motorUsedOverloadPercent = p("motor-used-overload-percent", PracticeSkill.motorProtection, "That is an overload calculation, not short-circuit protection. The two are separate devices with separate rules: overload runs at 115% or 125% of the NAMEPLATE, while the branch-circuit device runs at the Table 430.52 percentage of the TABLE current.")

    val loadForgotLightingDemand = p("load-forgot-lighting-demand", PracticeSkill.dwellingLoad, "You carried the general lighting at 100%. Only the first 3000 VA stays whole; the rest of it up to 120,000 VA comes in at 35%. That demand factor is most of the difference between a 200 A service and a 400 A one.")
    val loadForgotSmallAppliance = p("load-forgot-small-appliance", PracticeSkill.dwellingLoad, "You left out the small-appliance and laundry circuits. A dwelling carries two 1500 VA small-appliance circuits and a 1500 VA laundry circuit, and they go INSIDE the general lighting total before the demand factor, not after it.")
    val loadUsedRangeNameplate = p("load-used-range-nameplate", PracticeSkill.dwellingLoad, "You used the range nameplate. A household range has its own demand table: one range not over 12 kW is taken at 8 kW, however big the nameplate says it is.")
    val loadAddedHeatAndCooling = p("load-added-heat-and-cooling", PracticeSkill.dwellingLoad, "You added the heating and the air conditioning together. 220.60 calls them noncoincident: they cannot run at once, so only the larger of the two goes into the calculation.")
    val loadForgotApplianceDemand = p("load-forgot-appliance-demand", PracticeSkill.dwellingLoad, "You carried the fastened-in-place appliances at 100%. Four or more of them on the same service come in at 75% under 220.53, and the range, dryer, heating and air conditioning are not part of that count.")

    /** The registry Fix My Mistakes and the tally look patterns up in. */
    val all: List<MistakePattern> by lazy {
        listOf(
            derateFrom75, ignoredBundling, ignoredTerminationCap,
            ignoredSmallConductorCap, roundedOCPDUp, sizedOCPDFrom90,
            usedFiftyThreePercentFill, racewayTooSmall, racewayOversized,
            countedGroundsIndividually, forgotDeviceYokes, countedYokeAsOne,
            wrongPhaseFactor, forgotPhaseFactor, wrongMaterialK,
            usedGECTableForEGC, egcWrongMaterialColumn, egcReadRowBelow, egcUsedCircuitConductor,
            usedEGCTableForGEC, gecIgnoredElectrodeCeiling, gecWrongServiceColumn, gecMissedParallelSet,
            motorUsedNameplateForConductors, motorForgot125, motorWrongVoltageRow,
            motorRoundedOCPDDown, motorWrongDevicePercent, motorUsedOverloadPercent,
            loadForgotLightingDemand, loadForgotSmallAppliance, loadUsedRangeNameplate,
            loadAddedHeatAndCooling, loadForgotApplianceDemand,
        )
    }

    fun pattern(id: String): MistakePattern? = all.firstOrNull { it.id == id }
}

/**
 * Generates code calculations forever. A line-for-line port of the iOS
 * `CalcGenerator` (all four files): same parameter lists, same draw order from
 * the stream, same distractors, so a seeded stream produces the same problem on
 * both platforms. Every distractor is the number one named mistake produces.
 */
object CalcGenerator {
    const val choiceCount = 4

    data class Choices(val labels: List<String>, val answerIndex: Int)

    private fun newID(prefix: String) = "gen-$prefix-${UUID.randomUUID().toString().uppercase()}"
    private fun Double.swiftInt(): Int = toInt()
    private fun signedOffset(pad: RandomSource, range: IntRange): Int {
        val magnitude = pad.nextInt(range)
        return magnitude * if (pad.nextBoolean()) 1 else -1
    }

    // Ampacity after correction and adjustment.
    fun ampacityProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val size = listOf("12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG", "1/0 AWG", "3/0 AWG").randomElement(rng)!!
        val material = ConductorMaterial.entries.randomElement(rng)!!
        // 30°C and three conductors are here on purpose, so the 75°C cap can bind.
        val ambient = listOf(30, 35, 40, 45, 50, 55).randomElement(rng)!!
        val ccc = listOf(3, 4, 5, 6, 7, 8, 10, 12).randomElement(rng)!!

        val base = (NECTables.ampacity(size, material, TemperatureRating.c90) ?: 0).toDouble()
        val correction = NECTables.ambientCorrection(ambient, TemperatureRating.c90) ?: 1.0
        val adjustment = NECTables.adjustmentFactor(ccc)
        val derated = base * correction * adjustment
        val terminalLimit = (NECTables.ampacity(size, material, TemperatureRating.c75) ?: 0).toDouble()
        val answer = min(derated, terminalLimit)

        val startedAt75 = terminalLimit * correction * adjustment
        val forgotBundling = min(base * correction, terminalLimit)
        val forgotTerminals = derated

        val amps: (Double) -> String = { "${it.roundedAmpsText} A" }
        val choices = uniqueChoices(listOf(answer, startedAt75, forgotBundling, forgotTerminals), answer, rng,
            pad = { it * padRNG.nextDouble(0.8..1.2) }, format = amps)

        val steps = mutableListOf(
            "Start in the 90°C column, because that is the conductor's own rating: $size ${material.displayName} is ${base.swiftInt()} A.",
            "Ambient ${ambient}°C corrects by ${correction.factorText}: ${base.swiftInt()} × ${correction.factorText} = ${(base * correction).roundedAmpsText} A.",
            "$ccc current-carrying conductors adjust by ${adjustment.factorText}: ${(base * correction).roundedAmpsText} × ${adjustment.factorText} = ${derated.roundedAmpsText} A.",
        )
        if (answer < derated) {
            steps += "The 75°C termination limits it to ${terminalLimit.swiftInt()} A, and the lower number wins, so the answer is ${answer.roundedAmpsText} A."
        } else {
            steps += "That is still under the ${terminalLimit.swiftInt()} A termination limit, so the derated value stands: ${answer.roundedAmpsText} A."
        }
        val mistakes = mistakeMap(amps(answer), listOf(
            amps(startedAt75) to CandidateMistake.derateFrom75,
            amps(forgotBundling) to CandidateMistake.ignoredBundling,
            amps(forgotTerminals) to CandidateMistake.ignoredTerminationCap,
        ))
        return CalcScenario(newID("ampacity"), "Find the allowable ampacity of this conductor as installed.",
            listOf(Given.conductor(size, "THHN"), Given.material(material), Given.ambient(ambient), Given.currentCarrying(ccc), Given.terminals(TemperatureRating.c75)),
            choices.labels, choices.answerIndex, steps, "310.16, 310.15(B)(1), 310.15(C)(1), 110.14(C)", mistakes)
    }

    // Overcurrent protection sizing, where 240.4(D) beats the table.
    fun ocpdProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val size = listOf("14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG").randomElement(rng)!!
        val material = if (size == "14 AWG") ConductorMaterial.copper else ConductorMaterial.entries.randomElement(rng)!!

        val tableAmpacity = (NECTables.ampacity(size, material, TemperatureRating.c75) ?: 0).toDouble()
        val ceiling = NECTables.smallConductorCeiling(size, material)
        val usable = ceiling?.let { min(tableAmpacity, it.toDouble()) } ?: tableAmpacity
        val answer = (NECTables.nextStandardOCPDAtMost(usable) ?: 15).toDouble()
        val ignoredCeiling = (NECTables.nextStandardOCPDAtMost(tableAmpacity) ?: 15).toDouble()
        val roundedUp = (NECTables.nextStandardOCPDAtLeast(usable) ?: 15).toDouble()
        val usedNinety = (NECTables.nextStandardOCPDAtMost((NECTables.ampacity(size, material, TemperatureRating.c90) ?: 0).toDouble()) ?: 15).toDouble()

        val label: (Double) -> String = { "${it.swiftInt()} A" }
        val choices = uniqueChoices(listOf(answer, ignoredCeiling, roundedUp, usedNinety), answer, rng,
            pad = { standardNeighbour(it, padRNG, 1..3) }, format = label)

        val steps = mutableListOf("Terminations are 75°C, so read the 75°C column: $size ${material.displayName} is ${tableAmpacity.swiftInt()} A.")
        if (ceiling != null && ceiling.toDouble() < tableAmpacity) {
            steps += "240.4(D) caps this size at $ceiling A regardless of the table. That cap is the number to protect at, not ${tableAmpacity.swiftInt()} A."
        }
        steps += "The largest standard rating in 240.6(A) at or below ${usable.swiftInt()} A is ${answer.swiftInt()} A."
        val mistakes = mistakeMap(label(answer), listOf(
            label(ignoredCeiling) to CandidateMistake.ignoredSmallConductorCap,
            label(roundedUp) to CandidateMistake.roundedOCPDUp,
            label(usedNinety) to CandidateMistake.sizedOCPDFrom90,
        ))
        return CalcScenario(newID("ocpd"),
            "Conductor protection only: the load is already settled and no next-size-up allowance applies. What is the largest standard overcurrent device this conductor may be protected at?",
            listOf(Given.conductor(size, "THWN-2"), Given.material(material), Given.terminals(TemperatureRating.c75)),
            choices.labels, choices.answerIndex, steps, "240.4, 240.4(D), 240.6(A), 110.14(C)", mistakes)
    }

    // Raceway fill.
    fun conduitFillProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val size = listOf("12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG").randomElement(rng)!!
        val count = listOf(4, 6, 7, 9, 12).randomElement(rng)!!
        val area = NECTables.thhnArea[size] ?: 0.0
        val bundle = area * count
        val percent = NECTables.fillPercent(count)
        val trades = NECTables.emtTradeSizes

        val answerTrade = trades.firstOrNull { (NECTables.emtArea[it] ?: 0.0) * percent >= bundle } ?: "4\""
        val oneSmaller = trades.takeWhile { it != answerTrade }.lastOrNull() ?: "1/2\""
        val oneBigger = trades.dropWhile { it != answerTrade }.drop(1).firstOrNull() ?: "4\""
        val usedFiftyThree = trades.firstOrNull { (NECTables.emtArea[it] ?: 0.0) * 0.53 >= bundle } ?: "4\""

        val choices = uniqueChoices(listOf(answerTrade, oneSmaller, oneBigger, usedFiftyThree), answerTrade, rng,
            pad = { trade ->
                val index = trades.indexOf(trade).let { if (it < 0) 0 else it }
                val offset = signedOffset(padRNG, 1..2)
                trades[min(max(index + offset, 0), trades.size - 1)]
            }, format = { it })

        val interior = NECTables.emtArea[answerTrade] ?: 0.0
        val allowance = interior * percent
        val pct = (percent * 100).swiftInt()
        val mistakes = mistakeMap(answerTrade, listOf(
            usedFiftyThree to CandidateMistake.usedFiftyThreePercentFill,
            oneSmaller to CandidateMistake.racewayTooSmall,
            oneBigger to CandidateMistake.racewayOversized,
        ))
        return CalcScenario(newID("conduitfill"), "Pick the smallest trade size of EMT that will carry these conductors.",
            listOf(Given.conductor(size, "THHN"), Given("Quantity", "$count", "conductors"), Given.raceway("EMT", "?")),
            choices.labels, choices.answerIndex,
            listOf(
                "One $size THHN is ${area.areaText} in². $count of them is ${bundle.areaText} in².",
                "Over two conductors the allowance is $pct%, not 53% or 31%.",
                "$answerTrade EMT is ${interior.areaText} in² interior, and $pct% of that is ${allowance.areaText} in².",
                "${allowance.areaText} in² covers the ${bundle.areaText} in² bundle, and the next size down does not, so $answerTrade is the answer.",
            ), "Ch. 9 Table 1, Table 4, Table 5", mistakes)
    }

    // Box fill.
    fun boxFillProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val size = listOf("14 AWG", "12 AWG").randomElement(rng)!!
        val volume = NECTables.conductorVolume[size] ?: 2.0
        val currentCarrying = listOf(4, 5, 6, 7, 8).randomElement(rng)!!
        val devices = listOf(1, 2).randomElement(rng)!!
        val hasClamp = rng.nextBoolean()
        val groundCount = listOf(2, 3, 4).randomElement(rng)!!

        val deviceUnits = devices * 2
        val totalUnits = currentCarrying + 1 + (if (hasClamp) 1 else 0) + deviceUnits
        val required = totalUnits * volume
        val groundsIndividually = (totalUnits - 1 + groundCount) * volume
        val forgotDevices = (totalUnits - deviceUnits) * volume
        val yokeAsOne = (totalUnits - devices) * volume

        val label: (Double) -> String = { "${it.volumeText} in³" }
        val choices = uniqueChoices(listOf(required, groundsIndividually, forgotDevices, yokeAsOne), required, rng,
            pad = { it + padRNG.nextInt(1..4).toDouble() * volume }, format = label)

        val givens = mutableListOf(
            Given.conductor(size, "THHN"),
            Given("Insulated", "$currentCarrying", "conductors"),
            Given("Grounds", "$groundCount", "wires"),
            Given("Devices", "$devices", if (devices == 1) "yoke" else "yokes"),
        )
        if (hasClamp) givens += Given("Internal clamps", "yes")
        val steps = mutableListOf(
            "Each allowance for $size is ${volume.volumeText} in³, so this is a counting problem first and a multiplication problem second.",
            "$currentCarrying insulated conductors is $currentCarrying allowances.",
            "The $groundCount equipment grounds together count as ONE allowance, not $groundCount.",
        )
        if (hasClamp) steps += "Internal clamps count as one allowance no matter how many there are."
        steps += "Each device yoke counts as two, so $devices yoke${if (devices == 1) "" else "s"} is $deviceUnits."
        steps += "$totalUnits allowances × ${volume.volumeText} in³ = ${required.volumeText} in³."
        val mistakes = mistakeMap(label(required), listOf(
            label(groundsIndividually) to CandidateMistake.countedGroundsIndividually,
            label(forgotDevices) to CandidateMistake.forgotDeviceYokes,
            label(yokeAsOne) to CandidateMistake.countedYokeAsOne,
        ))
        return CalcScenario(newID("boxfill"), "Find the minimum box volume required.", givens,
            choices.labels, choices.answerIndex, steps, "314.16(B)", mistakes)
    }

    // Voltage drop.
    fun voltageDropProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val size = listOf("12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG").randomElement(rng)!!
        val material = ConductorMaterial.entries.randomElement(rng)!!
        val phase = Phase.entries.randomElement(rng)!!
        val volts = if (phase == Phase.single) listOf(120, 240).randomElement(rng)!! else listOf(208, 480).randomElement(rng)!!
        val amps = listOf(12, 16, 20, 24, 30, 40).randomElement(rng)!!.toDouble()
        val feet = listOf(80, 120, 150, 200, 250, 300).randomElement(rng)!!

        val cm = NECTables.circularMils[size] ?: 1.0
        val k = material.voltageDropK
        val drop = phase.voltageDropFactor * k * amps * feet.toDouble() / cm
        val usedWrongFactor = (if (phase == Phase.single) 1.732 else 2.0) * k * amps * feet.toDouble() / cm
        val forgotFactor = k * amps * feet.toDouble() / cm
        val usedOtherMetal = phase.voltageDropFactor * (if (material == ConductorMaterial.copper) 21.2 else 12.9) * amps * feet.toDouble() / cm

        val label: (Double) -> String = { "${it.voltsText} V" }
        val choices = uniqueChoices(listOf(drop, usedWrongFactor, forgotFactor, usedOtherMetal), drop, rng,
            pad = { it * padRNG.nextDouble(0.6..1.5) }, format = label)
        val percent = drop / volts.toDouble() * 100
        val mistakes = mistakeMap(label(drop), listOf(
            label(usedWrongFactor) to CandidateMistake.wrongPhaseFactor,
            label(forgotFactor) to CandidateMistake.forgotPhaseFactor,
            label(usedOtherMetal) to CandidateMistake.wrongMaterialK,
        ))
        return CalcScenario(newID("vdrop"), "Find the voltage drop on this run.",
            listOf(Given.conductor(size, "THHN"), Given.material(material), Given.voltage(volts, phase), Given.load(amps), Given.length(feet)),
            choices.labels, choices.answerIndex,
            listOf(
                "${if (phase == Phase.single) "Single-phase uses 2" else "Three-phase uses 1.732"} as the factor, because that is the path the current actually takes.",
                "K for ${material.displayName.lowercase()} is ${k.factorText}, and $size is ${cm.swiftInt()} circular mils.",
                "VD = ${phase.voltageDropFactor.factorText} × ${k.factorText} × ${amps.trimmedAmps} A × $feet ft ÷ ${cm.swiftInt()} cmil = ${drop.voltsText} V.",
                "That is ${percent.voltsText}% of $volts V, so it is ${if (percent <= 3) "within" else "past"} the 3% figure the informational note suggests for a branch circuit.",
            ), "210.19(A) Informational Note, Ch. 9 Table 8", mistakes)
    }

    // Equipment grounding conductor, Table 250.122.
    fun egcProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val ocpd = listOf(15, 20, 30, 40, 45, 50, 60, 70, 90, 100, 110, 125, 150, 175, 200, 225, 300, 400).randomElement(rng)!!
        val material = ConductorMaterial.entries.randomElement(rng)!!
        val answer = NECTables.equipmentGroundingConductor(ocpd, material)
        val band = NECTables.equipmentGroundingRow(ocpd)
        if (answer == null || band == null) return ocpdProblem(rng)

        val other = if (material == ConductorMaterial.copper) ConductorMaterial.aluminum else ConductorMaterial.copper
        val wrongColumn = NECTables.equipmentGroundingConductor(ocpd, other) ?: answer
        val rowIndex = NECTables.egcRows.indexOfFirst { it.ocpdUpTo == band }.let { if (it < 0) 0 else it }
        val below = NECTables.egcRows[max(0, rowIndex - 1)]
        val rowBelow = if (material == ConductorMaterial.copper) below.copper else below.aluminum
        val asService = NECTables.conductorSizes.firstOrNull { (NECTables.ampacity(it, material, TemperatureRating.c75) ?: 0) >= ocpd } ?: "4/0 AWG"
        val fromGECTable = NECTables.groundingElectrodeConductor(asService, material, material) ?: answer

        val distractors = listOf(fromGECTable, wrongColumn, rowBelow, asService).shuffledSwift(rng)
        val choices = uniqueChoices(listOf(answer) + distractors, answer, rng,
            pad = { conductorNeighbour(it, padRNG) }, format = { it })

        val steps = mutableListOf("The equipment grounding conductor is sized from the rating of the overcurrent device ahead of the circuit, not from the circuit conductors. That rating is $ocpd A.")
        steps += if (ocpd == band) "Table 250.122 has a row at $band A, so read it directly."
        else "Table 250.122 has no $ocpd A row. The rows are not-exceeding bands, so $ocpd A reads the $band A row."
        steps += "In the ${material.displayName.lowercase()} column that row calls for $answer."
        steps += "Nothing about the circuit conductor size changes this. An equipment ground is sized from the device, and it only grows with the conductors when they are increased for voltage drop, under 250.122(B)."
        val mistakes = mistakeMap(answer, choices.labels, listOf(
            fromGECTable to CandidateMistake.usedGECTableForEGC,
            wrongColumn to CandidateMistake.egcWrongMaterialColumn,
            rowBelow to CandidateMistake.egcReadRowBelow,
            asService to CandidateMistake.egcUsedCircuitConductor,
        ))
        return CalcScenario(newID("egcSizing"), "What is the minimum size equipment grounding conductor for this circuit?",
            listOf(Given("Protected at", "$ocpd", "A"), Given.material(material), Given("Conductor", "Run in a raceway")),
            choices.labels, choices.answerIndex, steps, "250.122, Table 250.122, 250.122(B)", mistakes)
    }

    // Grounding electrode conductor, Table 250.66.
    fun gecProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val serviceSize = listOf("4 AWG", "2 AWG", "1/0 AWG", "2/0 AWG", "3/0 AWG", "4/0 AWG", "250 kcmil", "350 kcmil", "500 kcmil").randomElement(rng)!!
        val serviceMaterial = ConductorMaterial.entries.randomElement(rng)!!
        val sets = listOf(1, 1, 1, 2).randomElement(rng)!!
        val electrode = ElectrodeType.entries.randomElement(rng)!!
        val fromTable = NECTables.groundingElectrodeConductor(serviceSize, serviceMaterial, ConductorMaterial.copper, sets) ?: return egcProblem(rng)

        var answer = fromTable
        val ceiling = electrode.copperCeiling
        val ceilingMils = ceiling?.let { NECTables.circularMilsExtended[it] }
        val tableMils = NECTables.circularMilsExtended[fromTable]
        if (ceiling != null && ceilingMils != null && tableMils != null && tableMils > ceilingMils) answer = ceiling

        val other = if (serviceMaterial == ConductorMaterial.copper) ConductorMaterial.aluminum else ConductorMaterial.copper
        val wrongBands = NECTables.groundingElectrodeConductor(serviceSize, other, ConductorMaterial.copper, sets) ?: fromTable
        val oneConductorOnly = NECTables.groundingElectrodeConductor(serviceSize, serviceMaterial, ConductorMaterial.copper, 1) ?: fromTable
        val serviceAmps = NECTables.ampacity(serviceSize, serviceMaterial, TemperatureRating.c75) ?: 100
        val fromEGCTable = NECTables.equipmentGroundingConductor(NECTables.nextStandardOCPDAtMost((serviceAmps * sets).toDouble()) ?: 100, ConductorMaterial.copper) ?: answer

        val distractors = listOf(fromEGCTable, fromTable, wrongBands, oneConductorOnly).shuffledSwift(rng)
        val choices = uniqueChoices(listOf(answer) + distractors, answer, rng,
            pad = { conductorNeighbour(it, padRNG) }, format = { it })

        val steps = mutableListOf<String>()
        if (sets > 1) steps += "Parallel sets are read on the equivalent area of the whole set, not on one conductor: $sets × $serviceSize."
        steps += "Table 250.66 is entered on the largest ungrounded SERVICE conductor, and the ${serviceMaterial.displayName.lowercase()} service bands are their own set of rows."
        steps += "Those bands call for $fromTable copper."
        val electrodeName = electrode.displayName.lowercase()
        steps += when {
            answer != fromTable -> "${electrode.citation} then caps it: a $electrodeName electrode never requires more than ${ceiling ?: fromTable} copper, so the run to it is $answer."
            ceiling != null -> "${electrode.citation} caps a $electrodeName electrode at $ceiling copper, and the table value is already at or below that, so $answer stands."
            else -> "A metal water pipe electrode has no ceiling of its own, so the table value stands: $answer."
        }
        val mistakes = mistakeMap(answer, choices.labels, listOf(
            fromEGCTable to CandidateMistake.usedEGCTableForGEC,
            fromTable to CandidateMistake.gecIgnoredElectrodeCeiling,
            wrongBands to CandidateMistake.gecWrongServiceColumn,
            oneConductorOnly to CandidateMistake.gecMissedParallelSet,
        ))
        return CalcScenario(newID("gecSizing"), "What is the minimum size copper grounding electrode conductor for this service?",
            listOf(
                Given("Service conductor", if (sets > 1) "$sets × $serviceSize" else serviceSize),
                Given.material(serviceMaterial),
                Given("Electrode", electrode.displayName),
                Given("Electrode conductor", "Copper"),
            ), choices.labels, choices.answerIndex, steps, "250.66, Table 250.66, ${electrode.citation}", mistakes)
    }

    // Motors: table current, never the nameplate.
    private data class GeneratedMotor(val rating: MotorRating, val supply: MotorSupply, val tableFLC: Double, val nameplateFLA: Double)

    private fun rollMotor(rng: RandomSource): GeneratedMotor? {
        val supply = MotorSupply.entries.randomElement(rng)!!
        val rating = NECTables.motorRatings(supply).randomElement(rng) ?: return null
        val flc = NECTables.motorFLC(rating.label, supply) ?: return null
        val magnitude = rng.nextDouble(0.08..0.22)
        val drift = magnitude * if (rng.nextBoolean()) 1 else -1
        val nameplate = ((flc * (1 + drift)) * 10).roundedAway / 10
        if (nameplate <= 0 || abs(nameplate - flc) <= 0.05) return null
        return GeneratedMotor(rating, supply, flc, nameplate)
    }

    private fun MotorSupply.flcTable() = if (phase == Phase.single) "430.248" else "430.250"

    fun motorConductorProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val motor = rollMotor(rng) ?: return ampacityProblem(rng)
        val answer = motor.tableFLC * NECTables.motorConductorFactor
        val fromNameplate = motor.nameplateFLA * NECTables.motorConductorFactor
        val forgot125 = motor.tableFLC
        val otherSupply = MotorSupply.entries.firstOrNull {
            it != motor.supply && it.phase == motor.supply.phase && NECTables.motorFLC(motor.rating.label, it) != null
        }
        val wrongRow = otherSupply?.let { NECTables.motorFLC(motor.rating.label, it) }?.let { it * NECTables.motorConductorFactor } ?: answer

        val format: (Double) -> String = { "${it.roundedAmpsText} A" }
        val choices = uniqueChoices(listOf(answer, fromNameplate, forgot125, wrongRow), answer, rng,
            pad = { it * padRNG.nextDouble(0.75..1.3) }, format = format)
        val steps = listOf(
            "The nameplate is not the number here. Branch-circuit conductors for a single motor are sized from the full-load current in Table ${motor.supply.flcTable()}, which for a ${motor.rating.label} motor at ${motor.supply.displayName} is ${motor.tableFLC.factorText} A.",
            "430.22 puts the conductors at 125% of that: ${motor.tableFLC.factorText} × 1.25 = ${answer.roundedAmpsText} A.",
            "That ${answer.roundedAmpsText} A is the minimum ampacity the conductors must have after any correction and adjustment, which is then read back into Table 310.16.",
            "The nameplate ${motor.nameplateFLA.factorText} A is still used, but only for the separate overload device under 430.32.",
        )
        val mistakes = mistakeMap(format(answer), choices.labels, listOf(
            format(fromNameplate) to CandidateMistake.motorUsedNameplateForConductors,
            format(forgot125) to CandidateMistake.motorForgot125,
            format(wrongRow) to CandidateMistake.motorWrongVoltageRow,
        ))
        return CalcScenario(newID("motorConductor"), "What minimum ampacity must the branch-circuit conductors for this single continuous-duty motor have?",
            listOf(Given("Motor", motor.rating.label), Given("Supply", motor.supply.displayName), Given("Nameplate", motor.nameplateFLA.factorText, "A")),
            choices.labels, choices.answerIndex, steps, "430.22, ${motor.supply.citation}, 430.6(A)(1)", mistakes)
    }

    fun motorProtectionProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val motor = rollMotor(rng) ?: return ocpdProblem(rng)
        val protection = MotorProtection.entries.randomElement(rng)!!
        val calculated = motor.tableFLC * protection.percent
        val answer = NECTables.motorBranchOCPD(motor.tableFLC, protection)
        val roundedDown = NECTables.nextStandardOCPDAtMost(calculated)
        if (answer == null || roundedDown == null) return ocpdProblem(rng)
        val otherDevice = MotorProtection.entries.first { it != protection }
        val wrongPercent = NECTables.motorBranchOCPD(motor.tableFLC, otherDevice) ?: answer
        val overloadNumber = NECTables.nextStandardOCPDAtLeast(NECTables.motorOverloadTrip(motor.nameplateFLA, 1.15, null)) ?: answer

        val format: (Double) -> String = { "${it.swiftInt()} A" }
        val choices = uniqueChoices(listOf(answer.toDouble(), roundedDown.toDouble(), wrongPercent.toDouble(), overloadNumber.toDouble()), answer.toDouble(), rng,
            pad = { standardNeighbour(it, padRNG, 1..3) }, format = format)
        val steps = mutableListOf(
            "Short-circuit and ground-fault protection is sized from the TABLE full-load current, not the nameplate: ${motor.rating.label} at ${motor.supply.displayName} is ${motor.tableFLC.factorText} A in Table ${motor.supply.flcTable()}.",
            "Table 430.52 allows a ${protection.displayName.lowercase()} up to ${protection.percentLabel} of that: ${motor.tableFLC.factorText} × ${protection.percent.factorText} = ${calculated.roundedAmpsText} A.",
        )
        steps += if (answer.toDouble() > calculated) {
            "${calculated.roundedAmpsText} A is not a standard rating. This is the one calculation in the book that rounds UP: 430.52(C)(1) Exception 1 permits the next standard size, so $answer A."
        } else {
            "${calculated.roundedAmpsText} A is itself a standard rating in 240.6(A), so $answer A is the answer with no rounding needed."
        }
        steps += "This device does not protect against overload. That is a separate device sized from the nameplate ${motor.nameplateFLA.factorText} A under 430.32."
        val mistakes = mistakeMap(format(answer.toDouble()), choices.labels, listOf(
            format(roundedDown.toDouble()) to CandidateMistake.motorRoundedOCPDDown,
            format(wrongPercent.toDouble()) to CandidateMistake.motorWrongDevicePercent,
            format(overloadNumber.toDouble()) to CandidateMistake.motorUsedOverloadPercent,
        ))
        return CalcScenario(newID("motorProtection"), "What is the largest standard device permitted for branch-circuit short-circuit and ground-fault protection of this motor?",
            listOf(Given("Motor", motor.rating.label), Given("Supply", motor.supply.displayName), Given("Nameplate", motor.nameplateFLA.factorText, "A"), Given("Device", protection.displayName)),
            choices.labels, choices.answerIndex, steps, "430.52, Table 430.52, 430.52(C)(1) Ex. 1, 240.6(A)", mistakes)
    }

    // Dwelling service, standard method.
    fun dwellingLoadProblem(rng: RandomSource): CalcScenario {
        val padRNG = SeededGenerator(rng.next())
        val area = listOf(1500, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 3400, 3800).randomElement(rng)!!.toDouble()
        val rangeKW = listOf(8.0, 10.0, 12.0, 14.0, 16.0).randomElement(rng)!!
        val dryerNameplate = listOf(4000.0, 4500.0, 5000.0, 5500.0, 6000.0, 7200.0).randomElement(rng)!!
        val waterHeater = listOf(3500.0, 4500.0, 5500.0).randomElement(rng)!!
        val dishwasher = listOf(1000.0, 1200.0, 1400.0).randomElement(rng)!!
        val disposal = listOf(700.0, 900.0, 1000.0).randomElement(rng)!!
        val compactor = listOf(800.0, 1000.0).randomElement(rng)!!
        val coolingVA = listOf(4000.0, 5000.0, 6000.0, 7000.0).randomElement(rng)!!
        val heatingVA = listOf(9000.0, 10000.0, 12000.0, 15000.0).randomElement(rng)!!

        val lighting = area * NECTables.dwellingLightingVAPerSqFt
        val circuits = NECTables.smallApplianceCircuitVA * NECTables.minimumSmallApplianceCircuits + NECTables.laundryCircuitVA
        val generalTotal = lighting + circuits
        val generalDemand = NECTables.generalLightingDemand(generalTotal)
        val rangeVA = (NECTables.rangeDemandKW(1, rangeKW) ?: 8.0) * 1000
        val dryerVA = max(dryerNameplate, NECTables.minimumDryerVA)
        val appliances = listOf(waterHeater, dishwasher, disposal, compactor)
        val applianceTotal = appliances.fold(0.0) { a, b -> a + b }
        val applianceDemand = NECTables.fastenedApplianceDemand(applianceTotal, appliances.size)
        val climate = NECTables.noncoincident(coolingVA, heatingVA)

        val total = generalDemand + rangeVA + dryerVA + applianceDemand + climate
        val amps = NECTables.serviceAmps(total)
        val rating = NECTables.dwellingServiceRating(amps) ?: return ampacityProblem(rng)

        val noLightingDemandVA = generalTotal + rangeVA + dryerVA + applianceDemand + climate
        val noCircuitsVA = NECTables.generalLightingDemand(lighting) + rangeVA + dryerVA + applianceDemand + climate
        val rangeAtNameplateVA = generalDemand + rangeKW * 1000 + dryerVA + applianceDemand + climate
        val bothClimateVA = generalDemand + rangeVA + dryerVA + applianceDemand + coolingVA + heatingVA
        val appliancesWholeVA = generalDemand + rangeVA + dryerVA + applianceTotal + climate

        // Half ask for the load, half for the service: the service form
        // quantises small mistakes away, the VA form separates all five.
        val asksForService = rng.nextBoolean()
        val answerValue = if (asksForService) rating.toDouble() else total.roundedAway
        val alternatives = listOf(noLightingDemandVA, bothClimateVA, rangeAtNameplateVA, appliancesWholeVA, noCircuitsVA).map {
            if (asksForService) (NECTables.dwellingServiceRating(NECTables.serviceAmps(it)) ?: rating).toDouble() else it.roundedAway
        }
        val order = alternatives.indices.toList().shuffledSwift(rng)

        val format: (Double) -> String = { if (asksForService) "${it.swiftInt()} A" else "${it.swiftInt().groupedText} VA" }
        val choices = uniqueChoices(listOf(answerValue) + order.map { alternatives[it] }, answerValue, rng,
            pad = { value ->
                if (!asksForService) {
                    val step = padRNG.nextInt(2..9).toDouble() * 500
                    (value + if (padRNG.nextBoolean()) step else -step).roundedAway
                } else {
                    val index = NECTables.standardOCPD.indexOfFirst { it.toDouble() >= value }.let { if (it < 0) 0 else it }
                    val offset = signedOffset(padRNG, 1..2)
                    val clamped = min(max(index + offset, 0), NECTables.standardOCPD.size - 1)
                    max(NECTables.minimumDwellingServiceAmps, NECTables.standardOCPD[clamped]).toDouble()
                }
            }, format = format)

        val g = { v: Double -> v.swiftInt().groupedText }
        val steps = mutableListOf(
            "General lighting and general-use receptacles: ${area.swiftInt()} ft² × 3 VA = ${g(lighting)} VA.",
            "Add the circuits that belong inside that total: two small-appliance circuits at 1500 VA and one laundry circuit at 1500 VA, so ${g(lighting)} + ${g(circuits)} = ${g(generalTotal)} VA.",
            "Apply the demand factor to that subtotal only: the first 3000 VA at 100%, the remaining ${g(generalTotal - 3000)} VA at 35%, giving ${g(generalDemand.roundedAway)} VA.",
            "The range has its own table. ${rangeKW.factorText} kW${if (rangeKW > 12) ", which is over 12 kW, so column C's 8 kW rises 5% per kW above 12" else " is not over 12 kW, so column C reads 8 kW flat"}: ${g(rangeVA)} VA.",
            "The dryer is the greater of its nameplate and 5000 VA: ${g(dryerNameplate)} against 5000, so ${g(dryerVA)} VA.",
            "Four fastened-in-place appliances (${waterHeater.swiftInt()} + ${dishwasher.swiftInt()} + ${disposal.swiftInt()} + ${compactor.swiftInt()} = ${g(applianceTotal)} VA) reach the four-appliance threshold, so 220.53 takes them at 75%: ${g(applianceDemand.roundedAway)} VA.",
            "Heat and air conditioning cannot run together, so 220.60 counts only the larger: ${g(climate)} VA.",
            "Total ${g(generalDemand.roundedAway)} + ${g(rangeVA)} + ${g(dryerVA)} + ${g(applianceDemand.roundedAway)} + ${g(climate)} = ${g(total.roundedAway)} VA.",
        )
        if (asksForService) steps += "${g(total.roundedAway)} VA ÷ 240 V = ${amps.roundedAmpsText} A, and the smallest standard rating that carries it is $rating A."
        val mistakes = mistakeMap(format(answerValue), choices.labels, listOf(
            format(alternatives[0]) to CandidateMistake.loadForgotLightingDemand,
            format(alternatives[1]) to CandidateMistake.loadAddedHeatAndCooling,
            format(alternatives[2]) to CandidateMistake.loadUsedRangeNameplate,
            format(alternatives[3]) to CandidateMistake.loadForgotApplianceDemand,
            format(alternatives[4]) to CandidateMistake.loadForgotSmallAppliance,
        ))
        val prefix = "Standard method, single-family dwelling on a 120/240 V single-phase service."
        return CalcScenario(newID("dwellingLoad"),
            if (asksForService) "$prefix What is the minimum standard service rating?" else "$prefix What is the calculated load?",
            listOf(
                Given("Floor area", "${area.swiftInt()}", "ft²"),
                Given("Range", rangeKW.factorText, "kW"),
                Given("Dryer", "${dryerNameplate.swiftInt()}", "VA"),
                Given("Water heater", "${waterHeater.swiftInt()}", "VA"),
                Given("Dishwasher", "${dishwasher.swiftInt()}", "VA"),
                Given("Disposal", "${disposal.swiftInt()}", "VA"),
                Given("Compactor", "${compactor.swiftInt()}", "VA"),
                Given("Air conditioning", "${coolingVA.swiftInt()}", "VA"),
                Given("Electric heat", "${heatingVA.swiftInt()}", "VA"),
            ), choices.labels, choices.answerIndex, steps,
            "220.41, Table 220.45, 220.52, 220.53, 220.54, Table 220.55, 220.60, 230.79(C)", mistakes)
    }

    private fun standardNeighbour(value: Double, pad: RandomSource, range: IntRange): Double {
        val ratings = NECTables.standardOCPD
        val index = ratings.indexOfFirst { it.toDouble() >= value }.let { if (it < 0) 0 else it }
        val offset = signedOffset(pad, range)
        return ratings[min(max(index + offset, 0), ratings.size - 1)].toDouble()
    }

    private fun conductorNeighbour(size: String, pad: RandomSource): String {
        val all = NECTables.conductorSizes
        val index = all.indexOf(size).let { if (it < 0) 0 else it }
        val offset = signedOffset(pad, 1..3)
        return all[min(max(index + offset, 0), all.size - 1)]
    }

    /** First writer wins; a distractor equal to the answer is never named. */
    fun mistakeMap(answerLabel: String, entries: List<Pair<String, MistakePattern>>): Map<String, MistakePattern> {
        val map = LinkedHashMap<String, MistakePattern>()
        for ((label, pattern) in entries) if (label != answerLabel && label !in map) map[label] = pattern
        return map
    }

    /** The same, filtered to the choices that actually shipped. */
    fun mistakeMap(answerLabel: String, choices: List<String>, entries: List<Pair<String, MistakePattern>>): Map<String, MistakePattern> {
        val shown = choices.toSet()
        return mistakeMap(answerLabel, entries.filter { it.first in shown })
    }

    /** De-duplicated, padded to exactly four, shuffled from the main stream. */
    fun <T> uniqueChoices(candidates: List<T>, answer: T, rng: RandomSource, pad: (T) -> T, format: (T) -> String): Choices {
        val answerLabel = format(answer)
        val seen = mutableSetOf(answerLabel)
        val labels = mutableListOf(answerLabel)
        val values = mutableListOf(answer)
        for (candidate in candidates) {
            if (labels.size >= choiceCount) break
            val label = format(candidate)
            if (seen.add(label)) { labels += label; values += candidate }
        }
        var attempts = 0
        while (labels.size < choiceCount && attempts < 400) {
            attempts += 1
            val seed = values.randomElement(rng) ?: answer
            val candidate = pad(seed)
            val label = format(candidate)
            if (seen.add(label)) { labels += label; values += candidate }
        }
        labels.shuffleSwift(rng)
        return Choices(labels, labels.indexOf(answerLabel).let { if (it < 0) 0 else it })
    }
}
