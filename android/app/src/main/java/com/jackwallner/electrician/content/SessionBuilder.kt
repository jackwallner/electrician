package com.jackwallner.electrician.content

import com.jackwallner.electrician.model.*

data class QuickItem(
    val id: String,
    val prompt: String,
    val givens: List<Given>,
    val choices: List<String>,
    val answerIndex: Int,
    val explanation: String,
    val steps: List<String> = emptyList(),
    val citation: String? = null,
    val sourceLabel: String,
    val roomID: String,
    val trackingID: String = id,
    val isReviewable: Boolean = true,
    val mistakes: Map<String, MistakePattern> = emptyMap(),
) {
    fun mistake(index: Int): MistakePattern? = choices.getOrNull(index)?.let(mistakes::get)
}

object SessionBuilder {
    val sessionDrill = Drill("quick-session", "Quick Session", "A short mix of what you need next", DrillKind.Flashcards(emptyList()))
    val reviewDrill = Drill("review-session", "Fix My Mistakes", "The questions you keep getting wrong", DrillKind.Flashcards(emptyList()))
    val examWarmUpDrill = Drill("game-night-prep", "Exam Warm-Up", "A short targeted mix before the exam", DrillKind.Flashcards(emptyList()))

    fun choicePool(includePro: Boolean): List<QuickItem> = ElectricianContent.rooms
        .filter { it.isFree || includePro }.flatMap { room ->
            room.drills.filter { !room.isLocked(it, includePro) }.flatMap { drill ->
                when (val kind = drill.kind) {
                    is DrillKind.Quiz -> kind.questions.map { QuickItem(it.id, it.prompt, it.givens, it.choices, it.answerIndex, it.explanation, citation = it.citation, sourceLabel = room.name, roomID = room.id) }
                    is DrillKind.Flashcards -> kind.cards.mapNotNull { card ->
                        card.choice?.let { choice -> QuickItem(card.id, card.frontTitle + card.frontSubtitle?.let { "\n$it" }.orEmpty(), card.givens, choice.options, choice.answerIndex, card.backBody, citation = card.citation, sourceLabel = room.name, roomID = room.id) }
                    }
                    is DrillKind.Calc -> emptyList()
                }
            }
        }

    fun prepared(item: QuickItem): QuickItem {
        val indices = ChoiceShuffle.permutation(item.choices.size, item.id)
        return item.copy(choices = indices.map(item.choices::get), answerIndex = indices.indexOf(item.answerIndex))
    }

    fun quickSession(count: Int = 10, seen: Set<String>, missed: Set<String>, includePro: Boolean, rng: RandomSource = SystemRandomSource): List<QuickItem> =
        choicePool(includePro).shuffledSwift(rng).sortedBy {
            when (it.id) { in missed -> 0; !in seen -> 1; else -> 2 }
        }.take(count.coerceAtLeast(0)).map(::prepared)

    fun reviewSession(ids: List<String>, includePro: Boolean): List<QuickItem> {
        val pool = choicePool(includePro).associateBy { it.id }
        return ids.mapNotNull(pool::get).map(::prepared)
    }

    fun examWarmUp(count: Int = 10, seen: Set<String>, missed: Set<String>, dueIDs: List<String>, weakestRoomID: String?, rng: RandomSource = SystemRandomSource): List<QuickItem> =
        choicePool(true).shuffledSwift(rng).sortedBy {
            when { it.id in dueIDs -> 0; it.id in missed -> 1; it.roomID == weakestRoomID -> 2; it.id !in seen -> 3; else -> 4 }
        }.take(count.coerceAtLeast(0)).map(::prepared)
}
