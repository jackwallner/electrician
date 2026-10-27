package com.jackwallner.electrician.model

import java.time.Instant

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

import com.jackwallner.electrician.content.*

class GeneratorParityTest {
    private val fixture by lazy { JSONObject(checkNotNull(javaClass.getResourceAsStream("/electrician-parity.json")).bufferedReader().use { it.readText() }) }

    @Test fun allTenNativeGeneratorsMatch640SequentialSwiftProblems() {
        var checked = 0
        fixture.getJSONArray("generated").objects().forEach { group ->
            val skill = PracticeSkill.valueOf(group.getString("skill"))
            val rng = SeededGenerator(group.getString("seed").toULong())
            group.getJSONArray("items").objects().forEach { row ->
                val expected = ElectricianContent.scenario(row)
                val actual = EndlessPractice.scenario(skill, rng).copy(id = expected.id)
                assertEquals("${skill.name} seed ${group.getString("seed")} case $checked", expected, actual)
                checked++
            }
        }
        assertEquals(640, checked)
        assertEquals(ElectricianContent.raw.getJSONArray("skills").objects().map { it.getString("id") }, PracticeSkill.entries.map { it.name })
    }

    @Test fun fourThousandGeneratedQuestionsKeepFourDistinctChoicesAndNumberedWorking() {
        val rng = SeededGenerator(42uL)
        PracticeSkill.entries.forEach { skill -> repeat(400) { iteration ->
            val scenario = EndlessPractice.scenario(skill, rng)
            val context = "${skill.name} #$iteration"
            assertEquals(context, 4, scenario.choices.size)
            assertEquals(context, 4, scenario.choices.toSet().size)
            assertTrue(context, scenario.answerIndex in scenario.choices.indices)
            assertTrue(context, scenario.steps.isNotEmpty())
            assertTrue(context, scenario.givens.isNotEmpty())
            assertTrue(context, scenario.citation.isNotBlank())
            assertFalse(context, scenario.steps.any { '\u2014' in it })
            val answer = scenario.choices[scenario.answerIndex]
            assertFalse(context, answer.startsWith("0 "))
            assertFalse(context, answer.contains("nan", ignoreCase = true))
        } }
    }

    @Test fun namedMistakesStayOnVisibleDistractorsAndEveryCatalogEntryOccurs() {
        val rng = SeededGenerator(2024uL)
        val named = mutableSetOf<String>()
        PracticeSkill.entries.forEach { skill ->
            var questionsWithMistakes = 0
            repeat(200) { iteration ->
                val scenario = EndlessPractice.scenario(skill, rng)
                val context = "${skill.name} #$iteration"
                assertNull(context, scenario.mistakes[scenario.choices[scenario.answerIndex]])
                scenario.mistakes.forEach { (label, pattern) ->
                    assertTrue("$context $label", label in scenario.choices)
                    assertEquals(context, CandidateMistake.pattern(pattern.id), pattern)
                    assertTrue(context, PracticeSkill.entries.any { it.name == pattern.skill })
                    assertTrue(context, pattern.summary.isNotBlank())
                    assertFalse(context, '\u2014' in pattern.summary)
                    named += pattern.id
                }
                if (scenario.mistakes.isNotEmpty()) questionsWithMistakes++
            }
            assertTrue("${skill.name} names too few mistakes: $questionsWithMistakes", questionsWithMistakes > 100)
        }
        assertEquals(CandidateMistake.all.map { it.id }.toSet(), named)
        assertEquals(CandidateMistake.all.size, CandidateMistake.all.map { it.id }.toSet().size)
    }

    @Test fun targetedPracticeResetsEveryRequestedTrapWithFreshQuestionIDs() {
        CandidateMistake.all.forEachIndexed { index, pattern ->
            val skill = PracticeSkill.valueOf(pattern.skill)
            val items = EndlessPractice.targetedItems(listOf(pattern), 4, SeededGenerator(2026uL + index.toULong()))
            assertEquals(pattern.id, 4, items.size)
            assertTrue(pattern.id, items.any { pattern in it.mistakes.values })
            assertEquals(4, items.map { it.id }.toSet().size)
            items.forEach {
                assertEquals(pattern.id, skill.roomID, it.roomID)
                assertTrue(pattern.id, it.steps.size > 1)
                assertEquals("Targeted Practice", it.sourceLabel)
                assertFalse(it.isReviewable)
                assertEquals(skill, PracticeSkill.skillForItemID(it.id))
            }
        }
        assertTrue(EndlessPractice.targetedItems(emptyList(), 5).isEmpty())
        assertTrue(EndlessPractice.targetedItems(CandidateMistake.all, 0).isEmpty())
    }

    @Test fun generatedAmpacityNeverExceedsTerminationLimit() {
        val rng = SeededGenerator(7uL)
        repeat(300) {
            val scenario = CalcGenerator.ampacityProblem(rng)
            val size = scenario.givens.first { it.label == "Conductor" }.value.split(" ").take(2).joinToString(" ")
            val material = if (scenario.givens.first { it.label == "Material" }.value == "Copper") ConductorMaterial.copper else ConductorMaterial.aluminum
            val terminal = checkNotNull(NECTables.ampacity(size, material, TemperatureRating.c75))
            val answer = scenario.choices[scenario.answerIndex].removeSuffix(" A").toDouble()
            assertTrue("$size $material $answer > $terminal", answer <= terminal + 0.5)
        }
    }

    @Test fun generatedProtectionRespectsSmallConductorCap() {
        val rng = SeededGenerator(99uL)
        repeat(300) {
            val scenario = CalcGenerator.ocpdProblem(rng)
            val size = scenario.givens.first { it.label == "Conductor" }.value.split(" ").take(2).joinToString(" ")
            val material = if (scenario.givens.first { it.label == "Material" }.value == "Copper") ConductorMaterial.copper else ConductorMaterial.aluminum
            NECTables.smallConductorCeiling(size, material)?.let { cap ->
                val answer = scenario.choices[scenario.answerIndex].removeSuffix(" A").toInt()
                assertTrue("$size $material $answer > $cap", answer <= cap)
            }
        }
    }

    @Test fun generatedConduitAlwaysFitsAndNextSmallerSizeDoesNot() {
        val rng = SeededGenerator(1234uL)
        repeat(300) {
            val scenario = CalcGenerator.conduitFillProblem(rng)
            val size = scenario.givens.first { it.label == "Conductor" }.value.split(" ").take(2).joinToString(" ")
            val count = scenario.givens.first { it.label == "Quantity" }.value.toInt()
            val bundle = NECTables.thhnArea.getValue(size) * count
            val factor = NECTables.fillPercent(count)
            val answer = scenario.choices[scenario.answerIndex]
            assertTrue("$count x $size does not fit $answer", NECTables.emtArea.getValue(answer) * factor >= bundle)
            val index = NECTables.emtTradeSizes.indexOf(answer)
            if (index > 0) assertTrue("Oversized $answer", NECTables.emtArea.getValue(NECTables.emtTradeSizes[index - 1]) * factor < bundle)
        }
    }

    @Test fun dailyFiveMatchesSwiftIncludingPacificDateBoundaryAndDst() {
        fixture.getJSONArray("daily").objects().forEach { day ->
            val actual = CodeMinuteContent.challenge(Instant.parse(day.getString("at")))
            assertEquals(day.getString("key"), actual.dayKey)
            assertEquals(5, actual.questions.size)
            day.getJSONArray("questions").objects().zip(actual.questions).forEach { (expected, question) ->
                assertEquals(expected.getString("category"), question.category.name)
                assertEquals(quickItem(expected.getJSONObject("item")), question.item)
            }
            assertEquals(listOf("code-minute-rollup", "code-minute-rollup"), actual.items.take(2).map { it.trackingID })
        }
    }

    @Test fun preparationPreservesCorrectAnswerAndMistakeLabels() {
        val rng = SeededGenerator(77uL)
        PracticeSkill.entries.forEach { skill -> repeat(50) {
            val item = EndlessPractice.item(skill, rng)
            val prepared = SessionBuilder.prepared(item)
            assertEquals(item.choices.toSet(), prepared.choices.toSet())
            assertEquals(item.choices[item.answerIndex], prepared.choices[prepared.answerIndex])
            assertEquals(item.steps, prepared.steps)
            assertEquals(item.trackingID, prepared.trackingID)
            item.mistakes.forEach { (label, pattern) -> assertEquals(pattern, prepared.mistake(prepared.choices.indexOf(label))) }
            assertNull(prepared.mistake(prepared.answerIndex))
        } }
    }

    @Test fun quickSessionPrioritizesMissesThenUnseenAndNeverLeaksLockedContent() {
        val freePool = SessionBuilder.choicePool(false)
        val fullPool = SessionBuilder.choicePool(true)
        assertTrue(fullPool.size > freePool.size)
        assertEquals(freePool.size, freePool.map { it.id }.toSet().size)
        freePool.forEach { item ->
            assertTrue(ElectricianContent.room(item.roomID)!!.isFree)
            assertTrue(item.answerIndex in item.choices.indices)
            assertTrue(item.explanation.isNotBlank())
        }
        val missed = freePool.last().id
        val unseen = freePool.first().id
        val seen = freePool.map { it.id }.filter { it != unseen }.toSet()
        val items = SessionBuilder.quickSession(10, seen, setOf(missed), false, SeededGenerator(5uL))
        assertEquals(missed, items[0].id)
        assertEquals(unseen, items[1].id)
        assertTrue(items.all { item -> freePool.any { it.id == item.id } })
        assertEquals(listOf(missed, unseen), SessionBuilder.reviewSession(listOf("absent", missed, unseen), false).map { it.id })
    }

    private fun quickItem(row: JSONObject): QuickItem {
        val mistakes = row.getJSONObject("mistakes")
        return QuickItem(row.getString("id"), row.getString("prompt"), ElectricianContent.givens(row), row.getJSONArray("choices").strings(), row.getInt("answerIndex"),
            row.getString("explanation"), row.getJSONArray("steps").strings(), row.stringOrNull("citation"), row.getString("sourceLabel"), row.getString("roomID"),
            row.getString("trackingID"), row.getBoolean("isReviewable"), mistakes.keys().asSequence().associateWith { label ->
                mistakes.getJSONObject(label).let { MistakePattern(it.getString("id"), it.getString("skill"), it.getString("summary")) }
            })
    }
}
