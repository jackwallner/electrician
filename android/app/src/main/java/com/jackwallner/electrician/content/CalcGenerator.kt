package com.jackwallner.electrician.content

import java.util.UUID
import kotlin.math.max
import kotlin.math.min

import com.jackwallner.electrician.model.*

data class Choices(val labels: List<String>, val answerIndex: Int)

object CalcGenerator {
    const val choiceCount = 4

    fun <T> uniqueChoices(candidates: List<T>, answer: T, rng: RandomSource, pad: (T) -> T, format: (T) -> String): Choices {
        val answerLabel = format(answer)
        val seen = mutableSetOf(answerLabel)
        val labels = mutableListOf(answerLabel)
        val values = mutableListOf(answer)
        candidates.forEach { candidate ->
            if (labels.size < choiceCount && seen.add(format(candidate))) {
                labels += format(candidate)
                values += candidate
            }
        }
        var attempts = 0
        while (labels.size < choiceCount && attempts < 400) {
            attempts++
            val candidate = pad(values.randomElement(rng) ?: answer)
            val label = format(candidate)
            if (seen.add(label)) { labels += label; values += candidate }
        }
        labels.shuffleSwift(rng)
        return Choices(labels, labels.indexOf(answerLabel).takeIf { it >= 0 } ?: 0)
    }

    fun mistakeMap(answerLabel: String, entries: List<Pair<String, MistakePattern>>, choices: List<String>? = null): Map<String, MistakePattern> {
        val map = linkedMapOf<String, MistakePattern>()
        entries.filter { it.first != answerLabel && (choices == null || it.first in choices) }.forEach { (label, pattern) -> map.putIfAbsent(label, pattern) }
        return map
    }

    fun ampacityProblem(rng: RandomSource): CalcScenario {
        val padRng = SeededGenerator(rng.next())
        val size = listOf("12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG", "1/0 AWG", "3/0 AWG").pick(rng)
        val material = ConductorMaterial.entries.toList().pick(rng)
        val ambient = listOf(30, 35, 40, 45, 50, 55).pick(rng)
        val ccc = listOf(3, 4, 5, 6, 7, 8, 10, 12).pick(rng)
        val base = (NECTables.ampacity(size, material, TemperatureRating.c90) ?: 0).toDouble()
        val correction = NECTables.ambientCorrection(ambient, TemperatureRating.c90) ?: 1.0
        val adjustment = NECTables.adjustmentFactor(ccc)
        val derated = base * correction * adjustment
        val terminal = (NECTables.ampacity(size, material, TemperatureRating.c75) ?: 0).toDouble()
        val answer = min(derated, terminal)
        val startedAt75 = terminal * correction * adjustment
        val forgotBundling = min(base * correction, terminal)
        val choices = uniqueChoices(listOf(answer, startedAt75, forgotBundling, derated), answer, rng,
            pad = { it * padRng.nextDouble(0.8..1.2) }, format = { "${it.roundedAmpsText} A" })
        val steps = mutableListOf(
            "Start in the 90°C column, because that is the conductor's own rating: $size ${material.displayName} is ${base.toInt()} A.",
            "Ambient $ambient°C corrects by ${correction.factorText}: ${base.toInt()} × ${correction.factorText} = ${(base * correction).roundedAmpsText} A.",
            "$ccc current-carrying conductors adjust by ${adjustment.factorText}: ${(base * correction).roundedAmpsText} × ${adjustment.factorText} = ${derated.roundedAmpsText} A.",
        )
        steps += if (answer < derated) "The 75°C termination limits it to ${terminal.toInt()} A, and the lower number wins, so the answer is ${answer.roundedAmpsText} A."
            else "That is still under the ${terminal.toInt()} A termination limit, so the derated value stands: ${answer.roundedAmpsText} A."
        val label: (Double) -> String = { "${it.roundedAmpsText} A" }
        return CalcScenario("gen-ampacity-${UUID.randomUUID()}", "Find the allowable ampacity of this conductor as installed.",
            listOf(Given.conductor(size, "THHN"), Given.material(material), Given.ambient(ambient), Given.currentCarrying(ccc), Given.terminals(TemperatureRating.c75)),
            choices.labels, choices.answerIndex, steps, "310.16, 310.15(B)(1), 310.15(C)(1), 110.14(C)",
            mistakeMap(label(answer), listOf(label(startedAt75) to CandidateMistake.derateFrom75, label(forgotBundling) to CandidateMistake.ignoredBundling, label(derated) to CandidateMistake.ignoredTerminationCap)))
    }

    fun ocpdProblem(rng: RandomSource): CalcScenario {
        val padRng = SeededGenerator(rng.next())
        val size = listOf("14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG").pick(rng)
        val material = if (size == "14 AWG") ConductorMaterial.copper else ConductorMaterial.entries.toList().pick(rng)
        val table = (NECTables.ampacity(size, material, TemperatureRating.c75) ?: 0).toDouble()
        val ceiling = NECTables.smallConductorCeiling(size, material)
        val usable = ceiling?.let { min(table, it.toDouble()) } ?: table
        val answer = (NECTables.nextStandardOCPDAtMost(usable) ?: 15).toDouble()
        val ignoredCeiling = (NECTables.nextStandardOCPDAtMost(table) ?: 15).toDouble()
        val roundedUp = (NECTables.nextStandardOCPDAtLeast(usable) ?: 15).toDouble()
        val usedNinety = (NECTables.nextStandardOCPDAtMost((NECTables.ampacity(size, material, TemperatureRating.c90) ?: 0).toDouble()) ?: 15).toDouble()
        val choices = uniqueChoices(listOf(answer, ignoredCeiling, roundedUp, usedNinety), answer, rng, pad = { value ->
            val index = NECTables.standardOCPD.indexOfFirst { it >= value }.takeIf { it >= 0 } ?: 0
            val offset = padRng.nextInt(1..3) * if (padRng.nextBoolean()) 1 else -1
            NECTables.standardOCPD[(index + offset).coerceIn(0, NECTables.standardOCPD.lastIndex)].toDouble()
        }, format = { "${it.toInt()} A" })
        val steps = mutableListOf("Terminations are 75°C, so read the 75°C column: $size ${material.displayName} is ${table.toInt()} A.")
        if (ceiling != null && ceiling < table) steps += "240.4(D) caps this size at $ceiling A regardless of the table. That cap is the number to protect at, not ${table.toInt()} A."
        steps += "The largest standard rating in 240.6(A) at or below ${usable.toInt()} A is ${answer.toInt()} A."
        val label: (Double) -> String = { "${it.toInt()} A" }
        return CalcScenario("gen-ocpd-${UUID.randomUUID()}", "Conductor protection only: the load is already settled and no next-size-up allowance applies. What is the largest standard overcurrent device this conductor may be protected at?",
            listOf(Given.conductor(size, "THWN-2"), Given.material(material), Given.terminals(TemperatureRating.c75)), choices.labels, choices.answerIndex, steps,
            "240.4, 240.4(D), 240.6(A), 110.14(C)", mistakeMap(label(answer), listOf(label(ignoredCeiling) to CandidateMistake.ignoredSmallConductorCap, label(roundedUp) to CandidateMistake.roundedOCPDUp, label(usedNinety) to CandidateMistake.sizedOCPDFrom90)))
    }

    fun conduitFillProblem(rng: RandomSource): CalcScenario {
        val padRng = SeededGenerator(rng.next())
        val size = listOf("12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG").pick(rng)
        val count = listOf(4, 6, 7, 9, 12).pick(rng)
        val area = NECTables.thhnArea[size] ?: 0.0
        val bundle = area * count
        val percent = NECTables.fillPercent(count)
        val answer = NECTables.emtTradeSizes.firstOrNull { (NECTables.emtArea[it] ?: 0.0) * percent >= bundle } ?: "4\""
        val smaller = NECTables.emtTradeSizes.takeWhile { it != answer }.lastOrNull() ?: "1/2\""
        val bigger = NECTables.emtTradeSizes.dropWhile { it != answer }.drop(1).firstOrNull() ?: "4\""
        val fiftyThree = NECTables.emtTradeSizes.firstOrNull { (NECTables.emtArea[it] ?: 0.0) * 0.53 >= bundle } ?: "4\""
        val choices = uniqueChoices(listOf(answer, smaller, bigger, fiftyThree), answer, rng, pad = { trade ->
            val index = NECTables.emtTradeSizes.indexOf(trade).takeIf { it >= 0 } ?: 0
            val offset = padRng.nextInt(1..2) * if (padRng.nextBoolean()) 1 else -1
            NECTables.emtTradeSizes[(index + offset).coerceIn(0, NECTables.emtTradeSizes.lastIndex)]
        }, format = { it })
        val allowance = (NECTables.emtArea[answer] ?: 0.0) * percent
        return CalcScenario("gen-conduitfill-${UUID.randomUUID()}", "Pick the smallest trade size of EMT that will carry these conductors.",
            listOf(Given.conductor(size, "THHN"), Given("Quantity", "$count", "conductors"), Given.raceway("EMT", "?")), choices.labels, choices.answerIndex,
            listOf("One $size THHN is ${area.areaText} in². $count of them is ${bundle.areaText} in².",
                "Over two conductors the allowance is ${(percent * 100).toInt()}%, not 53% or 31%.",
                "$answer EMT is ${(NECTables.emtArea[answer] ?: 0.0).areaText} in² interior, and ${(percent * 100).toInt()}% of that is ${allowance.areaText} in².",
                "${allowance.areaText} in² covers the ${bundle.areaText} in² bundle, and the next size down does not, so $answer is the answer."),
            "Ch. 9 Table 1, Table 4, Table 5", mistakeMap(answer, listOf(fiftyThree to CandidateMistake.usedFiftyThreePercentFill, smaller to CandidateMistake.racewayTooSmall, bigger to CandidateMistake.racewayOversized)))
    }

    fun boxFillProblem(rng: RandomSource): CalcScenario {
        val padRng = SeededGenerator(rng.next())
        val size = listOf("14 AWG", "12 AWG").pick(rng)
        val volume = NECTables.conductorVolume[size] ?: 2.0
        val conductors = listOf(4, 5, 6, 7, 8).pick(rng)
        val devices = listOf(1, 2).pick(rng)
        val clamp = rng.nextBoolean()
        val grounds = listOf(2, 3, 4).pick(rng)
        val deviceUnits = devices * 2
        val totalUnits = conductors + 1 + (if (clamp) 1 else 0) + deviceUnits
        val required = totalUnits * volume
        val individualGrounds = (totalUnits - 1 + grounds) * volume
        val forgotDevices = (totalUnits - deviceUnits) * volume
        val yokeAsOne = (totalUnits - devices) * volume
        val choices = uniqueChoices(listOf(required, individualGrounds, forgotDevices, yokeAsOne), required, rng,
            pad = { it + padRng.nextInt(1..4) * volume }, format = { "${it.volumeText} in³" })
        val givens = mutableListOf(Given.conductor(size, "THHN"), Given("Insulated", "$conductors", "conductors"), Given("Grounds", "$grounds", "wires"), Given("Devices", "$devices", if (devices == 1) "yoke" else "yokes"))
        if (clamp) givens += Given("Internal clamps", "yes")
        val steps = mutableListOf("Each allowance for $size is ${volume.volumeText} in³, so this is a counting problem first and a multiplication problem second.",
            "$conductors insulated conductors is $conductors allowances.", "The $grounds equipment grounds together count as ONE allowance, not $grounds.")
        if (clamp) steps += "Internal clamps count as one allowance no matter how many there are."
        steps += "Each device yoke counts as two, so $devices yoke${if (devices == 1) "" else "s"} is $deviceUnits."
        steps += "$totalUnits allowances × ${volume.volumeText} in³ = ${required.volumeText} in³."
        val label: (Double) -> String = { "${it.volumeText} in³" }
        return CalcScenario("gen-boxfill-${UUID.randomUUID()}", "Find the minimum box volume required.", givens, choices.labels, choices.answerIndex, steps, "314.16(B)",
            mistakeMap(label(required), listOf(label(individualGrounds) to CandidateMistake.countedGroundsIndividually, label(forgotDevices) to CandidateMistake.forgotDeviceYokes, label(yokeAsOne) to CandidateMistake.countedYokeAsOne)))
    }

    fun voltageDropProblem(rng: RandomSource): CalcScenario {
        val padRng = SeededGenerator(rng.next())
        val size = listOf("12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "2 AWG").pick(rng)
        val material = ConductorMaterial.entries.toList().pick(rng)
        val phase = Phase.entries.toList().pick(rng)
        val volts = (if (phase == Phase.single) listOf(120, 240) else listOf(208, 480)).pick(rng)
        val amps = listOf(12, 16, 20, 24, 30, 40).pick(rng).toDouble()
        val feet = listOf(80, 120, 150, 200, 250, 300).pick(rng)
        val cm = NECTables.circularMils[size] ?: 1.0
        val k = material.voltageDropK
        val drop = phase.voltageDropFactor * k * amps * feet / cm
        val wrongFactor = (if (phase == Phase.single) 1.732 else 2.0) * k * amps * feet / cm
        val forgotFactor = k * amps * feet / cm
        val otherMetal = phase.voltageDropFactor * (if (material == ConductorMaterial.copper) 21.2 else 12.9) * amps * feet / cm
        val choices = uniqueChoices(listOf(drop, wrongFactor, forgotFactor, otherMetal), drop, rng,
            pad = { it * padRng.nextDouble(0.6..1.5) }, format = { "${it.voltsText} V" })
        val percent = drop / volts * 100
        val label: (Double) -> String = { "${it.voltsText} V" }
        return CalcScenario("gen-vdrop-${UUID.randomUUID()}", "Find the voltage drop on this run.",
            listOf(Given.conductor(size, "THHN"), Given.material(material), Given.voltage(volts, phase), Given.load(amps), Given.length(feet)), choices.labels, choices.answerIndex,
            listOf("${if (phase == Phase.single) "Single-phase uses 2" else "Three-phase uses 1.732"} as the factor, because that is the path the current actually takes.",
                "K for ${material.displayName.lowercase()} is ${k.factorText}, and $size is ${cm.toInt()} circular mils.",
                "VD = ${phase.voltageDropFactor.factorText} × ${k.factorText} × ${amps.trimmedAmps} A × $feet ft ÷ ${cm.toInt()} cmil = ${drop.voltsText} V.",
                "That is ${percent.voltsText}% of $volts V, so it is ${if (percent <= 3) "within" else "past"} the 3% figure the informational note suggests for a branch circuit."),
            "210.19(A) Informational Note, Ch. 9 Table 8", mistakeMap(label(drop), listOf(label(wrongFactor) to CandidateMistake.wrongPhaseFactor, label(forgotFactor) to CandidateMistake.forgotPhaseFactor, label(otherMetal) to CandidateMistake.wrongMaterialK)))
    }
}

fun <T> List<T>.pick(rng: RandomSource): T = checkNotNull(randomElement(rng))
