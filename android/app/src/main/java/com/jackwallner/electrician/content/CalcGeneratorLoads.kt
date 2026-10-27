package com.jackwallner.electrician.content

import java.util.UUID
import kotlin.math.max

import com.jackwallner.electrician.model.*

fun CalcGenerator.dwellingLoadProblem(rng: RandomSource): CalcScenario {
    val padRng = SeededGenerator(rng.next())
    val area = listOf(1500, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 3400, 3800).pick(rng).toDouble()
    val rangeKW = listOf(8.0, 10.0, 12.0, 14.0, 16.0).pick(rng)
    val dryerNameplate = listOf(4000.0, 4500.0, 5000.0, 5500.0, 6000.0, 7200.0).pick(rng)
    val waterHeater = listOf(3500.0, 4500.0, 5500.0).pick(rng)
    val dishwasher = listOf(1000.0, 1200.0, 1400.0).pick(rng)
    val disposal = listOf(700.0, 900.0, 1000.0).pick(rng)
    val compactor = listOf(800.0, 1000.0).pick(rng)
    val cooling = listOf(4000.0, 5000.0, 6000.0, 7000.0).pick(rng)
    val heating = listOf(9000.0, 10000.0, 12000.0, 15000.0).pick(rng)
    val lighting = area * NECTables.dwellingLightingVAPerSqFt
    val circuits = NECTables.smallApplianceCircuitVA * NECTables.minimumSmallApplianceCircuits + NECTables.laundryCircuitVA
    val general = lighting + circuits
    val generalDemand = NECTables.generalLightingDemand(general)
    val rangeVA = (NECTables.rangeDemandKW(1, rangeKW) ?: 8.0) * 1000
    val dryer = max(dryerNameplate, NECTables.minimumDryerVA)
    val appliances = listOf(waterHeater, dishwasher, disposal, compactor)
    val applianceTotal = appliances.sum()
    val applianceDemand = NECTables.fastenedApplianceDemand(applianceTotal, appliances.size)
    val climate = NECTables.noncoincident(cooling, heating)
    val total = generalDemand + rangeVA + dryer + applianceDemand + climate
    val amps = NECTables.serviceAmps(total)
    val rating = NECTables.dwellingServiceRating(amps) ?: return ampacityProblem(rng)
    val noLighting = general + rangeVA + dryer + applianceDemand + climate
    val noCircuits = NECTables.generalLightingDemand(lighting) + rangeVA + dryer + applianceDemand + climate
    val rangeNameplate = generalDemand + rangeKW * 1000 + dryer + applianceDemand + climate
    val bothClimate = generalDemand + rangeVA + dryer + applianceDemand + cooling + heating
    val wholeAppliances = generalDemand + rangeVA + dryer + applianceTotal + climate
    val asksService = rng.nextBoolean()
    val answer = if (asksService) rating.toDouble() else total.roundedAway
    val alternatives = listOf(noLighting, bothClimate, rangeNameplate, wholeAppliances, noCircuits).map {
        if (asksService) (NECTables.dwellingServiceRating(NECTables.serviceAmps(it)) ?: rating).toDouble() else it.roundedAway
    }
    val order = alternatives.indices.toList().shuffledSwift(rng)
    val format: (Double) -> String = { if (asksService) "${it.toInt()} A" else "${it.toInt().groupedText} VA" }
    val choices = uniqueChoices(listOf(answer) + order.map { alternatives[it] }, answer, rng, pad = { value ->
        if (!asksService) {
            val step = padRng.nextInt(2..9) * 500.0
            (value + if (padRng.nextBoolean()) step else -step).roundedAway
        } else {
            val index = NECTables.standardOCPD.indexOfFirst { it >= value }.takeIf { it >= 0 } ?: 0
            val offset = padRng.nextInt(1..2) * if (padRng.nextBoolean()) 1 else -1
            max(NECTables.minimumDwellingServiceAmps, NECTables.standardOCPD[(index + offset).coerceIn(0, NECTables.standardOCPD.lastIndex)]).toDouble()
        }
    }, format = format)
    val steps = mutableListOf(
        "General lighting and general-use receptacles: ${area.toInt()} ft² × 3 VA = ${lighting.toInt().groupedText} VA.",
        "Add the circuits that belong inside that total: two small-appliance circuits at 1500 VA and one laundry circuit at 1500 VA, so ${lighting.toInt().groupedText} + ${circuits.toInt().groupedText} = ${general.toInt().groupedText} VA.",
        "Apply the demand factor to that subtotal only: the first 3000 VA at 100%, the remaining ${(general - 3000).toInt().groupedText} VA at 35%, giving ${generalDemand.roundedAmps.groupedText} VA.",
        "The range has its own table. ${rangeKW.factorText} kW${if (rangeKW > 12) ", which is over 12 kW, so column C's 8 kW rises 5% per kW above 12" else " is not over 12 kW, so column C reads 8 kW flat"}: ${rangeVA.toInt().groupedText} VA.",
        "The dryer is the greater of its nameplate and 5000 VA: ${dryerNameplate.toInt().groupedText} against 5000, so ${dryer.toInt().groupedText} VA.",
        "Four fastened-in-place appliances (${waterHeater.toInt()} + ${dishwasher.toInt()} + ${disposal.toInt()} + ${compactor.toInt()} = ${applianceTotal.toInt().groupedText} VA) reach the four-appliance threshold, so 220.53 takes them at 75%: ${applianceDemand.roundedAmps.groupedText} VA.",
        "Heat and air conditioning cannot run together, so 220.60 counts only the larger: ${climate.toInt().groupedText} VA.",
        "Total ${generalDemand.roundedAmps.groupedText} + ${rangeVA.toInt().groupedText} + ${dryer.toInt().groupedText} + ${applianceDemand.roundedAmps.groupedText} + ${climate.toInt().groupedText} = ${total.roundedAmps.groupedText} VA.",
    )
    if (asksService) steps += "${total.roundedAmps.groupedText} VA ÷ 240 V = ${amps.roundedAmpsText} A, and the smallest standard rating that carries it is $rating A."
    val mistakes = mistakeMap(format(answer), listOf(format(alternatives[0]) to CandidateMistake.loadForgotLightingDemand, format(alternatives[1]) to CandidateMistake.loadAddedHeatAndCooling,
        format(alternatives[2]) to CandidateMistake.loadUsedRangeNameplate, format(alternatives[3]) to CandidateMistake.loadForgotApplianceDemand, format(alternatives[4]) to CandidateMistake.loadForgotSmallAppliance), choices.labels)
    return CalcScenario("gen-dwellingLoad-${UUID.randomUUID()}", if (asksService) "Standard method, single-family dwelling on a 120/240 V single-phase service. What is the minimum standard service rating?"
        else "Standard method, single-family dwelling on a 120/240 V single-phase service. What is the calculated load?",
        listOf(Given("Floor area", "${area.toInt()}", "ft²"), Given("Range", rangeKW.factorText, "kW"), Given("Dryer", "${dryerNameplate.toInt()}", "VA"),
            Given("Water heater", "${waterHeater.toInt()}", "VA"), Given("Dishwasher", "${dishwasher.toInt()}", "VA"), Given("Disposal", "${disposal.toInt()}", "VA"),
            Given("Compactor", "${compactor.toInt()}", "VA"), Given("Air conditioning", "${cooling.toInt()}", "VA"), Given("Electric heat", "${heating.toInt()}", "VA")),
        choices.labels, choices.answerIndex, steps, "220.41, Table 220.45, 220.52, 220.53, 220.54, Table 220.55, 220.60, 230.79(C)", mistakes)
}
