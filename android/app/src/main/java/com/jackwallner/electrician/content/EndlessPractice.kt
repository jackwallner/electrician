package com.jackwallner.electrician.content

import java.util.UUID

import com.jackwallner.electrician.model.*

enum class PracticeSkill {
    ampacity, overcurrent, conduitFill, boxFill, voltageDrop,
    egcSizing, gecSizing, motorConductor, motorProtection, dwellingLoad;

    private val metadata get() = ElectricianContent.raw.getJSONArray("skills").objects().first { it.getString("id") == name }
    val title: String get() = metadata.getString("title")
    val subtitle: String get() = metadata.getString("subtitle")
    val icon: String get() = metadata.getString("icon")
    val roomID: String get() = metadata.getString("roomID")
    val itemPrefix: String get() = "gen-$name-"

    companion object {
        fun skillForItemID(id: String): PracticeSkill? = entries.firstOrNull { id.startsWith(it.itemPrefix) }
    }
}

object EndlessPractice {
    fun drill(skill: PracticeSkill) = Drill("endless-${skill.name}", skill.title, skill.subtitle, DrillKind.Quiz(emptyList()))
    val challengeDrill = Drill("timed-challenge", "Timed Challenge", "Beat the clock", DrillKind.Quiz(emptyList()))

    fun scenario(skill: PracticeSkill, rng: RandomSource): CalcScenario = when (skill) {
        PracticeSkill.ampacity -> CalcGenerator.ampacityProblem(rng)
        PracticeSkill.overcurrent -> CalcGenerator.ocpdProblem(rng)
        PracticeSkill.conduitFill -> CalcGenerator.conduitFillProblem(rng)
        PracticeSkill.boxFill -> CalcGenerator.boxFillProblem(rng)
        PracticeSkill.voltageDrop -> CalcGenerator.voltageDropProblem(rng)
        PracticeSkill.egcSizing -> CalcGenerator.egcProblem(rng)
        PracticeSkill.gecSizing -> CalcGenerator.gecProblem(rng)
        PracticeSkill.motorConductor -> CalcGenerator.motorConductorProblem(rng)
        PracticeSkill.motorProtection -> CalcGenerator.motorProtectionProblem(rng)
        PracticeSkill.dwellingLoad -> CalcGenerator.dwellingLoadProblem(rng)
    }

    fun item(scenario: CalcScenario, skill: PracticeSkill, sourceLabel: String = "Endless Practice") = QuickItem(
        id = skill.itemPrefix + UUID.randomUUID(), prompt = scenario.situation,
        givens = scenario.givens, choices = scenario.choices, answerIndex = scenario.answerIndex,
        explanation = scenario.steps.firstOrNull().orEmpty(), steps = scenario.steps,
        citation = scenario.citation, sourceLabel = sourceLabel, roomID = skill.roomID,
        isReviewable = false, mistakes = scenario.mistakes,
    )

    fun item(skill: PracticeSkill, rng: RandomSource = SystemRandomSource, sourceLabel: String = "Endless Practice"): QuickItem =
        item(scenario(skill, rng), skill, sourceLabel)

    fun items(skill: PracticeSkill, count: Int, rng: RandomSource = SystemRandomSource): List<QuickItem> =
        List(count.coerceAtLeast(0)) { item(skill, rng) }

    fun mixedItems(count: Int, rng: RandomSource = SystemRandomSource): List<QuickItem> {
        if (count <= 0) return emptyList()
        val perSkill = (count / PracticeSkill.entries.size + 1).coerceAtLeast(1)
        return PracticeSkill.entries.flatMap { items(it, perSkill, rng) }.shuffledSwift(rng).take(count)
    }

    fun targetedItems(patterns: List<MistakePattern>, count: Int, rng: RandomSource = SystemRandomSource): List<QuickItem> {
        if (patterns.isEmpty() || count <= 0) return emptyList()
        return (0 until count).mapNotNull { index ->
            val pattern = patterns[index % patterns.size]
            val skill = PracticeSkill.entries.firstOrNull { it.name == pattern.skill } ?: return@mapNotNull null
            var made: CalcScenario? = null
            for (attempt in 0 until 24) {
                val candidate = scenario(skill, rng)
                if (pattern in candidate.mistakes.values) { made = candidate; break }
            }
            item(made ?: scenario(skill, rng), skill, "Targeted Practice")
        }
    }
}
