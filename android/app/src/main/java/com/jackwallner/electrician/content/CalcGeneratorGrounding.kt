package com.jackwallner.electrician.content

import java.util.UUID

import com.jackwallner.electrician.model.*

fun CalcGenerator.egcProblem(rng: RandomSource): CalcScenario {
    val padRng = SeededGenerator(rng.next())
    val ocpd = listOf(15, 20, 30, 40, 45, 50, 60, 70, 90, 100, 110, 125, 150, 175, 200, 225, 300, 400).pick(rng)
    val material = ConductorMaterial.entries.toList().pick(rng)
    val answer = NECTables.equipmentGroundingConductor(ocpd, material) ?: return ocpdProblem(rng)
    val band = NECTables.equipmentGroundingRow(ocpd) ?: return ocpdProblem(rng)
    val otherMaterial = if (material == ConductorMaterial.copper) ConductorMaterial.aluminum else ConductorMaterial.copper
    val wrongColumn = NECTables.equipmentGroundingConductor(ocpd, otherMaterial) ?: answer
    val rowIndex = NECTables.egcRows.indexOfFirst { it.ocpdUpTo == band }.takeIf { it >= 0 } ?: 0
    val below = NECTables.egcRows[maxOf(0, rowIndex - 1)]
    val rowBelow = if (material == ConductorMaterial.copper) below.copper else below.aluminum
    val asService = NECTables.conductorSizes.firstOrNull { (NECTables.ampacity(it, material, TemperatureRating.c75) ?: 0) >= ocpd } ?: "4/0 AWG"
    val fromGec = NECTables.groundingElectrodeConductor(asService, material, material) ?: answer
    val distractors = listOf(fromGec, wrongColumn, rowBelow, asService).shuffledSwift(rng)
    val choices = uniqueChoices(listOf(answer) + distractors, answer, rng, pad = { size ->
        val all = NECTables.conductorSizes
        val index = all.indexOf(size).takeIf { it >= 0 } ?: 0
        val offset = padRng.nextInt(1..3) * if (padRng.nextBoolean()) 1 else -1
        all[(index + offset).coerceIn(0, all.lastIndex)]
    }, format = { it })
    val steps = mutableListOf("The equipment grounding conductor is sized from the rating of the overcurrent device ahead of the circuit, not from the circuit conductors. That rating is $ocpd A.")
    steps += if (ocpd == band) "Table 250.122 has a row at $band A, so read it directly."
        else "Table 250.122 has no $ocpd A row. The rows are not-exceeding bands, so $ocpd A reads the $band A row."
    steps += "In the ${material.displayName.lowercase()} column that row calls for $answer."
    steps += "Nothing about the circuit conductor size changes this. An equipment ground is sized from the device, and it only grows with the conductors when they are increased for voltage drop, under 250.122(B)."
    val mistakes = mistakeMap(answer, listOf(fromGec to CandidateMistake.usedGECTableForEGC, wrongColumn to CandidateMistake.egcWrongMaterialColumn,
        rowBelow to CandidateMistake.egcReadRowBelow, asService to CandidateMistake.egcUsedCircuitConductor), choices.labels)
    return CalcScenario("gen-egcSizing-${UUID.randomUUID()}", "What is the minimum size equipment grounding conductor for this circuit?",
        listOf(Given("Protected at", "$ocpd", "A"), Given.material(material), Given("Conductor", "Run in a raceway")), choices.labels, choices.answerIndex, steps,
        "250.122, Table 250.122, 250.122(B)", mistakes)
}

fun CalcGenerator.gecProblem(rng: RandomSource): CalcScenario {
    val padRng = SeededGenerator(rng.next())
    val serviceSize = listOf("4 AWG", "2 AWG", "1/0 AWG", "2/0 AWG", "3/0 AWG", "4/0 AWG", "250 kcmil", "350 kcmil", "500 kcmil").pick(rng)
    val material = ConductorMaterial.entries.toList().pick(rng)
    val sets = listOf(1, 1, 1, 2).pick(rng)
    val electrode = ElectrodeType.entries.toList().pick(rng)
    val fromTable = NECTables.groundingElectrodeConductor(serviceSize, material, ConductorMaterial.copper, sets) ?: return egcProblem(rng)
    val ceiling = electrode.copperCeiling
    val answer = if (ceiling != null && checkNotNull(NECTables.circularMilsExtended[fromTable]) > checkNotNull(NECTables.circularMilsExtended[ceiling])) ceiling else fromTable
    val otherMaterial = if (material == ConductorMaterial.copper) ConductorMaterial.aluminum else ConductorMaterial.copper
    val wrongBands = NECTables.groundingElectrodeConductor(serviceSize, otherMaterial, ConductorMaterial.copper, sets) ?: fromTable
    val oneOnly = NECTables.groundingElectrodeConductor(serviceSize, material, ConductorMaterial.copper, 1) ?: fromTable
    val serviceAmps = NECTables.ampacity(serviceSize, material, TemperatureRating.c75) ?: 100
    val fromEgc = NECTables.equipmentGroundingConductor(NECTables.nextStandardOCPDAtMost((serviceAmps * sets).toDouble()) ?: 100, ConductorMaterial.copper) ?: answer
    val distractors = listOf(fromEgc, fromTable, wrongBands, oneOnly).shuffledSwift(rng)
    val choices = uniqueChoices(listOf(answer) + distractors, answer, rng, pad = { size ->
        val all = NECTables.conductorSizes
        val index = all.indexOf(size).takeIf { it >= 0 } ?: 0
        val offset = padRng.nextInt(1..3) * if (padRng.nextBoolean()) 1 else -1
        all[(index + offset).coerceIn(0, all.lastIndex)]
    }, format = { it })
    val steps = mutableListOf<String>()
    if (sets > 1) steps += "Parallel sets are read on the equivalent area of the whole set, not on one conductor: $sets × $serviceSize."
    steps += "Table 250.66 is entered on the largest ungrounded SERVICE conductor, and the ${material.displayName.lowercase()} service bands are their own set of rows."
    steps += "Those bands call for $fromTable copper."
    steps += when {
        answer != fromTable -> "${electrode.citation} then caps it: a ${electrode.displayName.lowercase()} electrode never requires more than ${electrode.copperCeiling ?: fromTable} copper, so the run to it is $answer."
        ceiling != null -> "${electrode.citation} caps a ${electrode.displayName.lowercase()} electrode at $ceiling copper, and the table value is already at or below that, so $answer stands."
        else -> "A metal water pipe electrode has no ceiling of its own, so the table value stands: $answer."
    }
    val mistakes = mistakeMap(answer, listOf(fromEgc to CandidateMistake.usedEGCTableForGEC, fromTable to CandidateMistake.gecIgnoredElectrodeCeiling,
        wrongBands to CandidateMistake.gecWrongServiceColumn, oneOnly to CandidateMistake.gecMissedParallelSet), choices.labels)
    return CalcScenario("gen-gecSizing-${UUID.randomUUID()}", "What is the minimum size copper grounding electrode conductor for this service?",
        listOf(Given("Service conductor", if (sets > 1) "$sets × $serviceSize" else serviceSize), Given.material(material), Given("Electrode", electrode.displayName), Given("Electrode conductor", "Copper")),
        choices.labels, choices.answerIndex, steps, "250.66, Table 250.66, ${electrode.citation}", mistakes)
}
