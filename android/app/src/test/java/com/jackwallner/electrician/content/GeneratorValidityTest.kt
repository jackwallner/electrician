package com.jackwallner.electrician.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

import com.jackwallner.electrician.model.CalcScenario
import com.jackwallner.electrician.model.ConductorMaterial
import com.jackwallner.electrician.model.DrillKind
import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.model.Phase
import com.jackwallner.electrician.model.SeededGenerator
import com.jackwallner.electrician.model.TemperatureRating

/** Ports of the iOS `ContentValidityTests` generator and authored-calculation invariants. */
class GeneratorValidityTest {
    private fun CalcScenario.given(label: String) = checkNotNull(givens.firstOrNull { it.label == label }) { "$label missing" }.value
    private fun CalcScenario.size() = given("Conductor").split(" ").take(2).joinToString(" ")
    private fun CalcScenario.material() = if (given("Material") == "Copper") ConductorMaterial.copper else ConductorMaterial.aluminum
    private val CalcScenario.answer get() = choices[answerIndex]

    private val authoredCalc: List<CalcScenario> by lazy {
        ElectricianContent.rooms.flatMap { it.drills }.mapNotNull { it.kind as? DrillKind.Calc }.flatMap { it.scenarios }
    }

    @Test fun everyShapeEmitsFourDistinctNamedChoices() {
        val rng = SeededGenerator(42uL)
        var checked = 0
        for (skill in PracticeSkill.entries) repeat(400) { iteration ->
            val scenario = EndlessPractice.scenario(skill, rng)
            val context = "${skill.name} #$iteration"
            assertEquals(context, 4, scenario.choices.size)
            assertEquals(context, 4, scenario.choices.toSet().size)
            assertTrue(context, scenario.answerIndex in scenario.choices.indices)
            assertTrue(context, scenario.steps.isNotEmpty() && scenario.citation.isNotEmpty() && scenario.givens.isNotEmpty())
            scenario.steps.forEach { assertFalse("Em dash in $context", it.contains("—")) }
            assertFalse(context, scenario.answer.startsWith("0 ") || scenario.answer.contains("nan"))
            // Every named mistake points at a shown, wrong choice.
            scenario.mistakes.keys.forEach { label ->
                assertTrue("$context names an unshown $label", label in scenario.choices)
                assertTrue("$context names the answer", label != scenario.answer)
            }
            checked += 1
        }
        assertEquals(4000, checked)
    }

    @Test fun derivedAmpacityNeverExceedsTheTerminationLimit() {
        val rng = SeededGenerator(7uL)
        repeat(300) {
            val scenario = CalcGenerator.ampacityProblem(rng)
            val terminal = checkNotNull(NECTables.ampacity(scenario.size(), scenario.material(), TemperatureRating.c75))
            val value = scenario.answer.removeSuffix(" A").toDouble()
            assertTrue("${scenario.answer} over $terminal A", value <= terminal + 0.5)
        }
    }

    @Test fun overcurrentNeverBreaksTheSmallConductorCap() {
        val rng = SeededGenerator(99uL)
        var capped = 0
        repeat(300) {
            val scenario = CalcGenerator.ocpdProblem(rng)
            val cap = NECTables.smallConductorCeiling(scenario.size(), scenario.material()) ?: return@repeat
            capped += 1
            assertTrue("${scenario.answer} over $cap", scenario.answer.removeSuffix(" A").toInt() <= cap)
        }
        assertTrue(capped > 0)
    }

    @Test fun conduitFillFitsAndTheNextSizeDownDoesNot() {
        val rng = SeededGenerator(1234uL)
        repeat(300) {
            val scenario = CalcGenerator.conduitFillProblem(rng)
            val count = scenario.given("Quantity").toInt()
            val bundle = checkNotNull(NECTables.thhnArea[scenario.size()]) * count
            val percent = NECTables.fillPercent(count)
            val answer = scenario.answer
            assertTrue(checkNotNull(NECTables.emtArea[answer]) * percent >= bundle)
            val index = NECTables.emtTradeSizes.indexOf(answer)
            if (index > 0) assertTrue(checkNotNull(NECTables.emtArea[NECTables.emtTradeSizes[index - 1]]) * percent < bundle)
        }
    }

    @Test fun everyMistakeInTheCatalogueIsSetAndTargetedPracticeSetsIt() {
        val rng = SeededGenerator(2026uL)
        val seen = mutableSetOf<String>()
        for (skill in PracticeSkill.entries) repeat(600) { seen += EndlessPractice.scenario(skill, rng).mistakes.values.map { it.id } }
        assertEquals(CandidateMistake.all.map { it.id }.toSet(), seen)
        for (pattern in CandidateMistake.all) {
            val items = EndlessPractice.targetedItems(listOf(pattern), 3, SeededGenerator(pattern.id.hashCode().toULong()))
            assertEquals(3, items.size)
            assertTrue(pattern.id, items.any { pattern in it.mistakes.values })
            items.forEach { assertTrue(it.id.startsWith(PracticeSkill.of(pattern.skill)!!.itemPrefix)) }
        }
        assertTrue(EndlessPractice.targetedItems(emptyList(), 5).isEmpty())
    }

    @Test fun shufflingPreservesMistakeLabels() {
        val item = EndlessPractice.item(PracticeSkill.ampacity, SeededGenerator(5uL))
        val prepared = SessionBuilder.prepared(item)
        assertEquals(item.choices[item.answerIndex], prepared.choices[prepared.answerIndex])
        prepared.choices.forEachIndexed { index, label -> assertEquals(item.mistakes[label], prepared.mistake(index)) }
    }

    @Test fun authoredCalculationsRecomputeFromTheTables() {
        fun scenario(id: String) = checkNotNull(authoredCalc.firstOrNull { it.id == id }) { id }
        val base = checkNotNull(NECTables.ampacity("6 AWG", ConductorMaterial.copper, TemperatureRating.c90))
        val derated = base * checkNotNull(NECTables.ambientCorrection(45, TemperatureRating.c90)) * NECTables.adjustmentFactor(6)
        val ampacity = minOf(derated, checkNotNull(NECTables.ampacity("6 AWG", ConductorMaterial.copper, TemperatureRating.c75)).toDouble())
        assertEquals(52.2, ampacity, 0.05)
        assertEquals("52.2 A", scenario("calc-ampacity-1").answer)

        val ocpd = NECTables.nextStandardOCPDAtMost(minOf(25, 20).toDouble())
        assertEquals(25, NECTables.ampacity("12 AWG", ConductorMaterial.copper, TemperatureRating.c75))
        assertEquals(20, NECTables.smallConductorCeiling("12 AWG", ConductorMaterial.copper))
        assertEquals("$ocpd A", scenario("calc-ocpd-1").answer)

        val bundle = checkNotNull(NECTables.thhnArea["10 AWG"]) * 9
        val trade = NECTables.emtTradeSizes.first { checkNotNull(NECTables.emtArea[it]) * 0.40 >= bundle }
        assertEquals("3/4\"", trade)
        assertEquals(trade, scenario("calc-conduitfill-1").answer)

        assertEquals(22.5, (6 + 1 + 1 + 2) * checkNotNull(NECTables.conductorVolume["12 AWG"]), 0.001)
        assertEquals("22.5 in³", scenario("calc-boxfill-1").answer)

        val drop = Phase.single.voltageDropFactor * ConductorMaterial.copper.voltageDropK * 16 * 100 / checkNotNull(NECTables.circularMils["10 AWG"])
        assertEquals(3.977, drop, 0.01)
        assertEquals("4.0 V", scenario("calc-vdrop-1").answer)

        val general = NECTables.generalLightingDemand(2000 * NECTables.dwellingLightingVAPerSqFt + 4500)
        assertEquals(5625.0, general, 0.001)
        val total = general + 8000 + 5500 + NECTables.fastenedApplianceDemand(7600.0, 4) + 10_000
        assertEquals(34_825.0, total, 0.5)
        assertEquals(150, NECTables.dwellingServiceRating(NECTables.serviceAmps(total)))
        assertEquals("150 A", scenario("load-calc-standard-dwelling").answer)
        val optional = NECTables.optionalMethodGeneralLoad(2000 * 3.0 + 4500 + 12_000 + 5500 + 7600) + NECTables.optionalMethodHVAC(5000.0, 10_000.0, 1)
        assertEquals("${NECTables.dwellingServiceRating(NECTables.serviceAmps(optional))} A", scenario("load-calc-optional-dwelling").answer)
        assertEquals("125 A", scenario("load-calc-optional-dwelling").answer)
        assertEquals("15.4 kW", scenario("load-calc-three-ranges").answer)
    }

    @Test fun everyAuthoredItemIsAnswerableWithUniqueChoices() {
        val pool = SessionBuilder.choicePool(true)
        assertTrue(pool.size > 50)
        pool.forEach { item ->
            assertTrue(item.id, item.answerIndex in item.choices.indices)
            assertEquals(item.id, item.choices.size, item.choices.toSet().size)
        }
        authoredCalc.forEach { assertTrue(it.id, it.answerIndex in it.choices.indices) }
        assertNotNull(CodeMinuteContent.challenge().questions.takeIf { it.size == CodeMinuteContent.questionCount })
        // Free users never see paid content in their pool.
        val free = SessionBuilder.choicePool(false).map { it.roomID }.toSet()
        assertFalse(free.any { it in setOf("calc-room", "loads-room", "grounding-room") })
    }
}
