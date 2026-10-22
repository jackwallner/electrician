package com.jackwallner.electrician.model

import java.math.BigDecimal
import java.math.RoundingMode

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.EndlessPractice
import com.jackwallner.electrician.content.PracticeSkill
import com.jackwallner.electrician.content.objects
import com.jackwallner.electrician.content.strings

class QuestionBankAuditTest {
    private fun resource(name: String) = JSONObject(checkNotNull(javaClass.getResourceAsStream("/$name")).bufferedReader().use { it.readText() })
    private val audit = resource("nec2023-bank-audit.json")
    private val tables = audit.getJSONObject("tables")

    private fun normalized(value: String): String {
        val compact = value.lowercase().filterNot { it.isWhitespace() || it == ',' }
        val number = compact.takeWhile { it in "0123456789.+-" }
        val numeric = number.toDoubleOrNull() ?: return compact
        val unit = compact.drop(number.length)
        if (unit in listOf("in.", "in", "ft")) return "${if (unit == "ft") numeric * 12 else numeric}in"
        return "$numeric$unit"
    }

    private fun check(id: String, choices: List<String>, key: Int, answer: String, citation: String?) {
        assertTrue(id, key in choices.indices)
        val matching = choices.indices.filter { normalized(choices[it]) == normalized(answer) }
        assertEquals("$id: expected one $answer in $choices", 1, matching.size)
        assertEquals("$id: incorrect key", key, matching.single())
        assertEquals("$id: equivalent options", choices.size, choices.map(::normalized).toSet().size)
        assertFalse("$id: missing code citation", citation.isNullOrBlank())
    }

    @Test fun everyAuthoredItemHasOneReviewedAnswerAndItsReviewedCitation() {
        assertEquals(2023, audit.getInt("edition"))
        val expected = audit.getJSONArray("items").objects().associateBy { it.getString("id") }
        val seen = mutableSetOf<String>()
        fun validate(id: String, options: List<String>, key: Int, citation: String?) {
            val row = checkNotNull(expected[id]) { "Unreviewed item $id" }
            assertTrue(id, seen.add(id))
            assertEquals(id, "choice", row.getString("mode"))
            assertEquals(id, row.getString("citation"), citation)
            check(id, options, key, row.getString("answer"), citation)
        }
        ElectricianContent.rooms.flatMap { it.drills }.forEach { drill ->
            when (val kind = drill.kind) {
                is DrillKind.Quiz -> kind.questions.forEach { validate(it.id, it.choices, it.answerIndex, it.citation) }
                is DrillKind.Calc -> kind.scenarios.forEach { validate(it.id, it.choices, it.answerIndex, it.citation) }
                is DrillKind.Flashcards -> kind.cards.forEach { card ->
                    val choice = card.choice
                    if (choice != null) validate(card.id, choice.options, choice.answerIndex, card.citation)
                    else {
                        val row = checkNotNull(expected[card.id]) { "Unreviewed reference ${card.id}" }
                        assertTrue(card.id, seen.add(card.id))
                        assertEquals("reference", row.getString("mode"))
                        assertEquals(card.id, row.getString("answer"), card.backTitle)
                        assertEquals(card.id, row.getString("citation"), card.citation)
                        assertFalse(card.citation.isNullOrBlank())
                    }
                }
            }
        }
        assertEquals(expected.keys, seen)
    }

    @Test fun everyExportedGeneratedQuestionHasExactlyOneIndependentlyCalculatedOption() {
        val groups = resource("electrician-parity.json").getJSONArray("generated").objects()
        assertEquals(10, groups.map { it.getString("skill") }.toSet().size)
        var count = 0
        groups.forEach { group ->
            group.getJSONArray("items").objects().forEach { row ->
                val q = ElectricianContent.scenario(row)
                assertEquals(q.id, 4, q.choices.size)
                check(q.id, q.choices, q.answerIndex, solve(q, group.getString("skill")), q.citation)
                count++
            }
        }
        assertEquals(640, count)
    }

    private fun solve(q: CalcScenario, skill: String): String {
        fun given(label: String) = checkNotNull(q.givens.firstOrNull { it.label == label }) { "${q.id}: missing $label" }.value
        fun number(label: String) = given(label).replace(",", "").toDouble()
        fun conductor() = given("Conductor").split(' ').take(2).joinToString(" ")
        fun format(value: Double, digits: Int, unit: String) = "${BigDecimal(value).setScale(digits, RoundingMode.HALF_EVEN).toPlainString()} $unit"
        fun values(key: String) = tables.getJSONObject(key)
        fun standards() = tables.getJSONArray("standardOCPD").let { rows -> (0 until rows.length()).map(rows::getInt) }
        fun flc(): Double {
            val supply = given("Supply")
            val key = checkNotNull(mapOf("115V 1Ø" to "single115", "230V 1Ø" to "single230", "208V 3Ø" to "three208", "230V 3Ø" to "three230", "460V 3Ø" to "three460")[supply])
            return values(if ("1Ø" in supply) "singlePhaseFLC" else "threePhaseFLC").getJSONObject(given("Motor")).getDouble(key)
        }
        return when (skill) {
            "ampacity", "overcurrent" -> {
                val copper = given("Material") == "Copper"
                val row = values(if (copper) "copperAmpacity" else "aluminumAmpacity").getJSONObject(conductor())
                val terminal = row.getDouble("75")
                if (skill == "overcurrent") {
                    val cap = values("smallConductorLimit").optJSONObject(conductor())?.optDouble(if (copper) "copper" else "aluminum", terminal) ?: terminal
                    "${standards().last { it <= minOf(cap, terminal) }} A"
                } else {
                    val correction = values("ambient").getJSONObject(given("Ambient")).getDouble("90")
                    val count = number("Current-carrying")
                    val factor = when { count <= 3 -> 1.0; count <= 6 -> 0.8; count <= 9 -> 0.7; else -> 0.5 }
                    format(minOf(row.getDouble("90") * correction * factor, terminal), 1, "A")
                }
            }
            "conduitFill" -> {
                val area = values("thhnArea").getDouble(conductor()) * number("Quantity")
                tables.getJSONArray("emtTradeSizes").strings().first { values("emtArea").getDouble(it) * 0.4 >= area }
            }
            "boxFill" -> {
                val grounds = number("Grounds")
                val groundUnits = if (grounds > 0) 1 + maxOf(0.0, grounds - 4) / 4 else 0.0
                val clamps = if (q.givens.any { it.label == "Internal clamps" }) 1 else 0
                val units = number("Insulated") + 2 * number("Devices") + groundUnits + clamps
                format(units * values("conductorVolume").getDouble(conductor()), 2, "in³")
            }
            "voltageDrop" -> {
                val k = if (given("Material") == "Copper") 12.9 else 21.2
                val phase = if ("1Ø" in given("System")) 2.0 else 1.732
                format(phase * k * number("Load") * number("One-way length") / values("circularMils").getDouble(conductor()), 1, "V")
            }
            "egcSizing" -> {
                val row = tables.getJSONArray("egcRows").objects().first { it.getInt("ocpdUpTo") >= number("Protected at") }
                row.getString(if (given("Material") == "Copper") "copper" else "aluminum")
            }
            "gecSizing" -> {
                val parts = given("Service conductor").split(" × ")
                val area = values("circularMils").getDouble(parts.last()) * if (parts.size > 1) parts.first().toDouble() else 1.0
                val tableSize = tables.getJSONArray(if (given("Material") == "Copper") "gecCopperService" else "gecAluminumService").objects().first { it.getDouble("serviceUpTo") >= area }.getString("copper")
                val cap = mapOf("Rod, pipe or plate" to "6 AWG", "Concrete-encased" to "4 AWG", "Ground ring" to "2 AWG")[given("Electrode")]
                if (cap != null && values("circularMils").getDouble(tableSize) > values("circularMils").getDouble(cap)) cap else tableSize
            }
            "motorConductor" -> format(flc() * 1.25, 1, "A")
            "motorProtection" -> {
                val device = given("Device")
                val factor = checkNotNull(mapOf("Nontime-delay fuse" to 3.0, "Dual-element fuse (not Class CC)" to 1.75, "Inverse-time breaker" to 2.5)[device])
                val fuse = "fuse" in device
                val ratings = if (fuse) (standards() + listOf(1, 3, 6, 601)).sorted() else standards()
                val rating = ratings.first { it >= flc() * factor - 0.0001 }
                "${if (fuse) rating else maxOf(15, rating)} A"
            }
            "dwellingLoad" -> {
                val general = number("Floor area") * 3 + 4500
                val lighting = 3000 + (general - 3000) * 0.35
                val range = 8000 * (1 + maxOf(0.0, number("Range") - 12) * 0.05)
                val appliances = listOf("Water heater", "Dishwasher", "Disposal", "Compactor").sumOf(::number) * 0.75
                val heat = number("Electric heat")
                assertTrue(q.id, heat > number("Air conditioning") * 1.25)
                val total = lighting + range + maxOf(5000.0, number("Dryer")) + appliances + heat + number("Disposal") * 0.25
                if ("service rating" in q.situation) "${standards().first { it >= total / 240 }} A" else "${total.toLong()} VA"
            }
            else -> error("Unreviewed generator $skill")
        }
    }

    @Test fun everyNativeGeneratedShapeHasOneIndependentlyCalculatedOption() {
        val rng = SeededGenerator(20231022uL)
        PracticeSkill.entries.forEach { skill -> repeat(500) {
            val q = EndlessPractice.scenario(skill, rng)
            check(q.id, q.choices, q.answerIndex, solve(q, skill.name), q.citation)
        } }
    }

    @Test fun storedAmpacitiesAndMotorCurrentsMatchReviewedTableFacts() {
        listOf(ConductorMaterial.copper to "copperAmpacity", ConductorMaterial.aluminum to "aluminumAmpacity").forEach { (material, key) ->
            val rows = tables.getJSONObject(key)
            rows.keys().forEach { size -> TemperatureRating.entries.forEach { column ->
                assertEquals(size, rows.getJSONObject(size).getInt(column.value.toString()), NECTables.ampacity(size, material, column))
            } }
        }
        listOf("singlePhaseFLC", "threePhaseFLC").forEach { key ->
            val rows = tables.getJSONObject(key)
            rows.keys().forEach { hp ->
                val columns = rows.getJSONObject(hp)
                columns.keys().forEach { supply ->
                    assertEquals(hp, columns.getDouble(supply), checkNotNull(NECTables.motorFLC(hp, MotorSupply.valueOf(supply))), 1e-12)
                }
            }
        }
    }

    @Test fun correctedBoundaryRulesAreEnforced() {
        assertEquals(10, NECTables.standardOCPD.first())
        assertEquals(1.08, checkNotNull(NECTables.ambientCorrection(20, TemperatureRating.c90)), 1e-12)
        assertEquals(0.65, checkNotNull(NECTables.ambientCorrection(65, TemperatureRating.c90)), 1e-12)
        assertEquals(0.29, checkNotNull(NECTables.ambientCorrection(85, TemperatureRating.c90)), 1e-12)
        assertNull(NECTables.ambientCorrection(86, TemperatureRating.c90))
        listOf(0 to 0.0, 1 to 1.0, 4 to 1.0, 5 to 1.25, 9 to 2.25).forEach { (count, expected) ->
            assertEquals(expected, NECTables.groundFillAllowances(count), 1e-12)
        }
        assertEquals(3, NECTables.motorBranchOCPD(1.1, MotorProtection.dualElementFuse))
        assertEquals(15, NECTables.motorBranchOCPD(1.1, MotorProtection.inverseTimeBreaker))
        assertEquals(normalized("3 ft"), normalized("36 in."))
        assertEquals(normalized("55.0 A"), normalized("55 A"))
    }
}
