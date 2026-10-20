package com.jackwallner.electrician.content

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

import com.jackwallner.electrician.model.CalcScenario
import com.jackwallner.electrician.model.SeededGenerator

/**
 * Every Swift-generated reference problem (ten shapes, eight seeds, eight in a
 * row per stream) must come out of the native generator byte for byte: same
 * givens, choices, answer, working, citation and named mistakes.
 */
class GeneratorParityTest {
    private val fixture = JSONObject(checkNotNull(javaClass.getResourceAsStream("/electrician-parity.json")).bufferedReader().use { it.readText() })

    private fun assertMatches(context: String, expected: JSONObject, actual: CalcScenario) {
        val reference = ElectricianContent.scenario(expected)
        assertEquals("$context situation", reference.situation, actual.situation)
        assertEquals("$context givens", reference.givens, actual.givens)
        assertEquals("$context choices", reference.choices, actual.choices)
        assertEquals("$context answer", reference.answerIndex, actual.answerIndex)
        assertEquals("$context steps", reference.steps, actual.steps)
        assertEquals("$context citation", reference.citation, actual.citation)
        assertEquals("$context mistakes", reference.mistakes, actual.mistakes)
    }

    @Test fun allTenShapesReproduceSwiftForEverySeed() {
        val rows = fixture.getJSONArray("generated").objects()
        assertEquals(PracticeSkill.entries.size * 8, rows.size)
        var compared = 0
        for (row in rows) {
            val skill = checkNotNull(PracticeSkill.of(row.getString("skill")))
            val rng = SeededGenerator(row.getString("seed").toULong())
            row.getJSONArray("items").objects().forEachIndexed { index, expected ->
                assertMatches("${skill.name} seed ${row.getString("seed")} #$index", expected, EndlessPractice.scenario(skill, rng))
                compared += 1
            }
        }
        assertEquals(640, compared)
    }

    @Test fun codeMinuteMatchesSwiftAcrossPacificMidnight() {
        for (row in fixture.getJSONArray("daily").objects()) {
            val challenge = CodeMinuteContent.challenge(java.time.Instant.parse(row.getString("at")))
            assertEquals(row.getString("key"), challenge.dayKey)
            val expected = row.getJSONArray("questions").objects()
            assertEquals(expected.size, challenge.questions.size)
            expected.zip(challenge.questions).forEach { (reference, actual) ->
                val item = reference.getJSONObject("item")
                assertEquals(reference.getString("category"), actual.category.name)
                assertEquals(item.getString("id"), actual.item.id)
                assertEquals(item.getJSONArray("choices").strings(), actual.item.choices)
                assertEquals(item.getInt("answerIndex"), actual.item.answerIndex)
                assertEquals(item.getString("prompt"), actual.item.prompt)
            }
        }
    }

    @Test fun skillCatalogueMatchesExport() {
        val exported = ElectricianContent.raw.getJSONArray("skills").objects()
        assertEquals(exported.map { it.getString("id") }, PracticeSkill.entries.map { it.name })
        exported.zip(PracticeSkill.entries).forEach { (row, skill) ->
            assertEquals(row.getString("title"), skill.title)
            assertEquals(row.getString("subtitle"), skill.subtitle)
            assertEquals(row.getString("roomID"), skill.roomID)
        }
        assertTrue(CandidateMistake.all.map { it.id }.toSet().size == CandidateMistake.all.size)
    }
}
