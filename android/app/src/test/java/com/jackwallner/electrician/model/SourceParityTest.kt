package com.jackwallner.electrician.model

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.objects
import com.jackwallner.electrician.content.strings

class SourceParityTest {
    private val fixture = JSONObject(checkNotNull(javaClass.getResourceAsStream("/electrician-parity.json")).bufferedReader().use { it.readText() })

    @Test fun rawGeneratorStreamsMatchSwiftIncludingZeroAndUnsignedMaximumSeeds() {
        fixture.getJSONArray("streams").objects().forEach {
            val generator = SeededGenerator(it.getString("seed").toULong())
            it.getJSONArray("values").strings().forEach { expected -> assertEquals(expected, generator.next().toString()) }
        }
    }

    @Test fun boundedIntegerBooleanAndClosedDoubleDrawsMatchSwift() {
        fixture.getJSONArray("draws").objects().forEach { row ->
            val generator = SeededGenerator(row.getString("seed").toULong())
            row.getJSONArray("draws").objects().forEach {
                assertEquals(it.getInt("integer"), generator.nextInt(-7..15))
                assertEquals(it.getBoolean("boolean"), generator.nextBoolean())
                assertEquals(it.getDouble("double"), generator.nextDouble(0.8..1.2), 1e-15)
            }
        }
    }

    @Test fun deterministicChoicePermutationsMatchSwift() {
        fixture.getJSONArray("permutations").objects().forEach { row ->
            val reference = row.getJSONArray("indices")
            assertEquals((0 until reference.length()).map(reference::getInt), ChoiceShuffle.permutation(4, row.getString("seed")))
        }
    }

    @Test fun numericalLabelsMatchSwiftRoundingAndDecimalFormatting() {
        fixture.getJSONArray("formatting").objects().forEach {
            val value = it.getDouble("value")
            assertEquals(it.toString(), it.getString("roundedAmpsText"), value.roundedAmpsText)
            assertEquals(it.getInt("roundedAmps"), value.roundedAmps)
            assertEquals(it.getString("factorText"), value.factorText)
            assertEquals(it.getString("areaText"), value.areaText)
            assertEquals(it.getString("volumeText"), value.volumeText)
            assertEquals(it.getString("trimmedAmps"), value.trimmedAmps)
        }
    }

    @Test fun nearestAwayIntegralRoundingPreservesValuesEitherSideOfHalf() {
        val cases = listOf(
            0.5 to 1.0, Math.nextDown(0.5) to 0.0, Math.nextUp(0.5) to 1.0,
            -0.5 to -1.0, Math.nextUp(-0.5) to 0.0, Math.nextDown(-0.5) to -1.0,
            1.5 to 2.0, -1.5 to -2.0, Math.nextDown(1.5) to 1.0, Math.nextUp(-1.5) to -1.0,
        )
        cases.forEach { (value, expected) -> assertEquals(value.toString(), expected, value.roundedAway, 0.0) }
    }

    @Test fun exportedCountsMatchNativeLibraryWithoutDuplicatedOrLostDrills() {
        val rooms = ElectricianContent.rooms
        assertEquals(6, rooms.size)
        assertEquals(126, rooms.sumOf { it.drills.sumOf { drill -> drill.kind.itemCount } })
        assertEquals(ElectricianContent.raw.getInt("freeItemCount"), ElectricianContent.freeItemCount)
        assertEquals(ElectricianContent.raw.getInt("membershipItemCount"), ElectricianContent.membershipItemCount)
        assertEquals(ElectricianContent.raw.getInt("membershipDrillCount"), ElectricianContent.membershipDrillCount)
        assertEquals(rooms.flatMap { it.drills }.size, rooms.flatMap { it.drills }.map { it.id }.toSet().size)
    }

    @Test fun freeAndPaidBoundariesMatchEveryExportedDrill() {
        val freeRooms = ElectricianContent.rooms.filter { it.isFree }.map { it.id }.toSet()
        assertEquals(setOf("basics-room", "conductors-room", "install-room"), freeRooms)
        ElectricianContent.rooms.forEach { room -> room.drills.forEach {
            assertEquals(!room.isFree || it.isPlus, room.isLocked(it, false))
            assertFalse(room.isLocked(it, true))
        } }
    }

    @Test fun everyAuthoredQuestionRetainsItsIdentityChoicesAndWorking() {
        val ids = mutableListOf<String>()
        ElectricianContent.rooms.flatMap { it.drills }.forEach { drill ->
            when (val kind = drill.kind) {
                is DrillKind.Flashcards -> kind.cards.forEach { card ->
                    ids += card.id
                    assertTrue(card.frontTitle.isNotBlank())
                    assertTrue(card.backBody.isNotBlank())
                    card.choice?.let { assertEquals(2, it.options.size); assertTrue(it.answerIndex in it.options.indices) }
                }
                is DrillKind.Quiz -> kind.questions.forEach { question ->
                    ids += question.id
                    assertTrue(question.prompt.isNotBlank())
                    assertEquals(question.choices.size, question.choices.toSet().size)
                    assertTrue(question.answerIndex in question.choices.indices)
                    assertTrue(question.explanation.isNotBlank())
                }
                is DrillKind.Calc -> kind.scenarios.forEach {
                    ids += it.id
                    assertEquals(4, it.choices.size)
                    assertEquals(4, it.choices.toSet().size)
                    assertTrue(it.answerIndex in it.choices.indices)
                    assertTrue(it.steps.isNotEmpty())
                    assertTrue(it.citation.isNotBlank())
                }
            }
        }
        assertEquals(126, ids.size)
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test fun all1944AmpacityResultsMatchOriginalSwiftFieldCalculator() {
        val rows = fixture.getJSONArray("ampacity").objects()
        assertEquals(1944, rows.size)
        rows.forEach { row ->
            val actual = FieldCalculators.ampacity(row.getString("size"), ConductorMaterial.valueOf(row.getString("material")),
                TemperatureRating.entries.first { it.value == row.getInt("insulation") },
                TemperatureRating.entries.first { it.value == row.getInt("termination") }, row.getInt("ambient"), row.getInt("count"))
            if (row.isNull("result")) assertNull(row.toString(), actual)
            else {
                checkNotNull(actual)
                val expected = row.getJSONObject("result")
                assertEquals(expected.getInt("tableAmps"), actual.tableAmps)
                assertEquals(expected.getDouble("ambientFactor"), actual.ambientFactor, 1e-12)
                assertEquals(expected.getDouble("adjustment"), actual.adjustment, 1e-12)
                assertEquals(expected.getDouble("afterDerate"), actual.afterDerate, 1e-9)
                assertEquals(expected.getInt("terminationCap"), actual.terminationCap)
                assertEquals(expected.getDouble("allowable"), actual.allowable, 1e-9)
                assertEquals(expected.getDouble("ocpdCeiling"), actual.ocpdCeiling, 1e-9)
                if (expected.isNull("smallConductorCeiling")) assertNull(actual.smallConductorCeiling)
                else assertEquals(expected.getInt("smallConductorCeiling"), actual.smallConductorCeiling)
                assertEquals(expected.getString("citation"), actual.citation)
            }
        }
    }

    @Test fun sourceEditionClaimIsPreservedWithoutClaiming2026Verification() {
        assertEquals("2023 NEC", NECTables.edition)
        assertEquals(2023, NECTables.stableSince)
        assertEquals(2023, NECTables.verifiedThrough)
        assertEquals("2023 NEC", NECTables.coverageLabel)
    }

    @Test fun exportedGeneratedFixturesCarryFourChoicesAndNamedMistakes() {
        val cases = fixture.getJSONArray("generated").objects()
        assertEquals(80, cases.size)
        assertEquals(10, cases.map { it.getString("skill") }.toSet().size)
        cases.forEach { row -> row.getJSONArray("items").objects().map(ElectricianContent::scenario).forEach {
            assertEquals(4, it.choices.size)
            assertEquals(4, it.choices.toSet().size)
            assertTrue(it.answerIndex in 0..3)
            assertTrue(it.steps.isNotEmpty())
            assertFalse(it.mistakes.containsKey(it.choices[it.answerIndex]))
        } }
    }
}
