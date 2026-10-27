package com.jackwallner.electrician.content

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

import com.jackwallner.electrician.model.*

enum class CodeMinuteCategory(val title: String) { navigation("Navigation"), ampacity("Ampacity"), calculation("Calculation") }
data class CodeMinuteQuestion(val category: CodeMinuteCategory, val item: QuickItem)
data class CodeMinuteChallenge(val dayKey: String, val shortDate: String, val questions: List<CodeMinuteQuestion>) {
    val items: List<QuickItem> get() = questions.map { it.item }
}

object CodeMinuteContent {
    const val questionCount = 5
    val dayZone: ZoneId = ZoneId.of("America/Los_Angeles")
    val drill = Drill("code-minute", "Code Minute", "Today's shared five-question challenge", DrillKind.Quiz(emptyList()), isPlus = true)

    fun key(day: Instant = Instant.now()): String = day.atZone(dayZone).toLocalDate().toString()

    fun challenge(day: Instant = Instant.now()): CodeMinuteChallenge {
        val dayKey = key(day)
        var hash = 0xcbf29ce484222325uL
        dayKey.toByteArray(Charsets.UTF_8).forEach { hash = (hash xor it.toUByte().toULong()) * 0x100000001b3uL }
        val rng = SeededGenerator(hash)
        val shapes = listOf(CodeMinuteCategory.ampacity to CalcGenerator::ampacityProblem, CodeMinuteCategory.calculation to CalcGenerator::conduitFillProblem)
        val questions = shapes.mapIndexed { index, (category, maker) ->
            val scenario = maker(rng)
            CodeMinuteQuestion(category, QuickItem("minute-$dayKey-gen-$index", scenario.situation, scenario.givens, scenario.choices, scenario.answerIndex,
                scenario.steps.firstOrNull().orEmpty(), scenario.steps, scenario.citation, "Code Minute",
                if (category == CodeMinuteCategory.ampacity) "conductors-room" else "calc-room",
                trackingID = "code-minute-rollup", isReviewable = false, mistakes = scenario.mistakes))
        }.toMutableList()
        val pool = SessionBuilder.choicePool(true).sortedBy { it.id }
        val used = mutableSetOf<String>()
        var attempts = 0
        while (pool.isNotEmpty() && questions.size < questionCount && attempts < pool.size * 4) {
            attempts++
            val picked = pool[(rng.next() % pool.size.toULong()).toInt()]
            if (used.add(picked.id)) questions += CodeMinuteQuestion(category(picked.roomID), SessionBuilder.prepared(picked))
        }
        return CodeMinuteChallenge(dayKey, DateTimeFormatter.ofPattern("MMM d", Locale.US).format(day.atZone(dayZone)), questions)
    }

    private fun category(roomID: String): CodeMinuteCategory = when (roomID) {
        "conductors-room" -> CodeMinuteCategory.ampacity
        "calc-room", "loads-room" -> CodeMinuteCategory.calculation
        "basics-room", "install-room", "grounding-room" -> CodeMinuteCategory.navigation
        else -> CodeMinuteCategory.navigation
    }
}
