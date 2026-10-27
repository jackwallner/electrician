package com.jackwallner.electrician.content

import java.util.UUID
import kotlin.math.abs

import com.jackwallner.electrician.model.*

private data class GeneratedMotor(val rating: MotorRating, val supply: MotorSupply, val tableFLC: Double, val nameplateFLA: Double)

private fun rollMotor(rng: RandomSource): GeneratedMotor? {
    val supply = MotorSupply.entries.toList().pick(rng)
    val rating = NECTables.motorRatings(supply).randomElement(rng) ?: return null
    val flc = NECTables.motorFLC(rating.label, supply) ?: return null
    val drift = rng.nextDouble(0.08..0.22) * if (rng.nextBoolean()) 1 else -1
    val nameplate = (flc * (1 + drift) * 10).roundedAway / 10
    if (nameplate <= 0 || abs(nameplate - flc) <= 0.05) return null
    return GeneratedMotor(rating, supply, flc, nameplate)
}

fun CalcGenerator.motorConductorProblem(rng: RandomSource): CalcScenario {
    val padRng = SeededGenerator(rng.next())
    val motor = rollMotor(rng) ?: return ampacityProblem(rng)
    val answer = motor.tableFLC * NECTables.motorConductorFactor
    val fromNameplate = motor.nameplateFLA * NECTables.motorConductorFactor
    val forgot125 = motor.tableFLC
    val otherSupply = MotorSupply.entries.firstOrNull { it != motor.supply && it.phase == motor.supply.phase && NECTables.motorFLC(motor.rating.label, it) != null }
    val wrongRow = otherSupply?.let { NECTables.motorFLC(motor.rating.label, it) }?.let { it * NECTables.motorConductorFactor } ?: answer
    val format: (Double) -> String = { "${it.roundedAmpsText} A" }
    val choices = uniqueChoices(listOf(answer, fromNameplate, forgot125, wrongRow), answer, rng, pad = { it * padRng.nextDouble(0.75..1.3) }, format = format)
    val steps = listOf(
        "The nameplate is not the number here. Branch-circuit conductors for a single motor are sized from the full-load current in Table ${if (motor.supply.phase == Phase.single) "430.248" else "430.250"}, which for a ${motor.rating.label} motor at ${motor.supply.displayName} is ${motor.tableFLC.factorText} A.",
        "430.22 puts the conductors at 125% of that: ${motor.tableFLC.factorText} × 1.25 = ${answer.roundedAmpsText} A.",
        "That ${answer.roundedAmpsText} A is the minimum ampacity the conductors must have after any correction and adjustment, which is then read back into Table 310.16.",
        "The nameplate ${motor.nameplateFLA.factorText} A is still used, but only for the separate overload device under 430.32.",
    )
    val mistakes = mistakeMap(format(answer), listOf(format(fromNameplate) to CandidateMistake.motorUsedNameplateForConductors,
        format(forgot125) to CandidateMistake.motorForgot125, format(wrongRow) to CandidateMistake.motorWrongVoltageRow), choices.labels)
    return CalcScenario("gen-motorConductor-${UUID.randomUUID()}", "What minimum ampacity must the branch-circuit conductors for this single continuous-duty motor have?",
        listOf(Given("Motor", motor.rating.label), Given("Supply", motor.supply.displayName), Given("Nameplate", motor.nameplateFLA.factorText, "A")), choices.labels, choices.answerIndex, steps,
        "430.22, ${motor.supply.citation}, 430.6(A)(1)", mistakes)
}

fun CalcGenerator.motorProtectionProblem(rng: RandomSource): CalcScenario {
    val padRng = SeededGenerator(rng.next())
    val motor = rollMotor(rng) ?: return ocpdProblem(rng)
    val protection = MotorProtection.entries.toList().pick(rng)
    val calculated = motor.tableFLC * protection.percent
    val answer = NECTables.motorBranchOCPD(motor.tableFLC, protection) ?: return ocpdProblem(rng)
    val down = NECTables.nextStandardOCPDAtMost(calculated) ?: return ocpdProblem(rng)
    val otherDevice = MotorProtection.entries.first { it != protection }
    val wrongPercent = NECTables.motorBranchOCPD(motor.tableFLC, otherDevice) ?: answer
    val overload = NECTables.nextStandardOCPDAtLeast(NECTables.motorOverloadTrip(motor.nameplateFLA, 1.15, null)) ?: answer
    val format: (Double) -> String = { "${it.toInt()} A" }
    val choices = uniqueChoices(listOf(answer.toDouble(), down.toDouble(), wrongPercent.toDouble(), overload.toDouble()), answer.toDouble(), rng, pad = { value ->
        val index = NECTables.standardOCPD.indexOfFirst { it >= value }.takeIf { it >= 0 } ?: 0
        val offset = padRng.nextInt(1..3) * if (padRng.nextBoolean()) 1 else -1
        NECTables.standardOCPD[(index + offset).coerceIn(0, NECTables.standardOCPD.lastIndex)].toDouble()
    }, format = format)
    val steps = mutableListOf(
        "Short-circuit and ground-fault protection is sized from the TABLE full-load current, not the nameplate: ${motor.rating.label} at ${motor.supply.displayName} is ${motor.tableFLC.factorText} A in Table ${if (motor.supply.phase == Phase.single) "430.248" else "430.250"}.",
        "Table 430.52 allows a ${protection.displayName.lowercase()} up to ${protection.percentLabel} of that: ${motor.tableFLC.factorText} × ${protection.percent.factorText} = ${calculated.roundedAmpsText} A.",
    )
    steps += if (answer > calculated) "${calculated.roundedAmpsText} A is not a standard rating. This is the one calculation in the book that rounds UP: 430.52(C)(1) Exception 1 permits the next standard size, so $answer A."
        else "${calculated.roundedAmpsText} A is itself a standard rating in 240.6(A), so $answer A is the answer with no rounding needed."
    steps += "This device does not protect against overload. That is a separate device sized from the nameplate ${motor.nameplateFLA.factorText} A under 430.32."
    val mistakes = mistakeMap(format(answer.toDouble()), listOf(format(down.toDouble()) to CandidateMistake.motorRoundedOCPDDown,
        format(wrongPercent.toDouble()) to CandidateMistake.motorWrongDevicePercent, format(overload.toDouble()) to CandidateMistake.motorUsedOverloadPercent), choices.labels)
    return CalcScenario("gen-motorProtection-${UUID.randomUUID()}", "What is the largest standard device permitted for branch-circuit short-circuit and ground-fault protection of this motor?",
        listOf(Given("Motor", motor.rating.label), Given("Supply", motor.supply.displayName), Given("Nameplate", motor.nameplateFLA.factorText, "A"), Given("Device", protection.displayName)),
        choices.labels, choices.answerIndex, steps, "430.52, Table 430.52, 430.52(C)(1) Ex. 1, 240.6(A)", mistakes)
}
