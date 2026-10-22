package com.jackwallner.electrician.content

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import java.util.UUID

import com.jackwallner.electrician.model.CalcScenario
import com.jackwallner.electrician.model.ChoiceShuffle
import com.jackwallner.electrician.model.Drill
import com.jackwallner.electrician.model.DrillKind
import com.jackwallner.electrician.model.Given
import com.jackwallner.electrician.model.MistakePattern
import com.jackwallner.electrician.model.RandomSource
import com.jackwallner.electrician.model.SeededGenerator
import com.jackwallner.electrician.model.SystemRandomSource

/** The generated-practice catalogue. Raw names are persisted inside item ids. */
enum class PracticeSkill(val title: String, val subtitle: String, val roomID: String, val icon: String) {
    ampacity("Derate the Conductor", "Heat and bundling, unlimited reps", "conductors-room", "thermometer.medium"),
    overcurrent("Size the Breaker", "Where 240.4(D) beats the table", "conductors-room", "bolt.shield.fill"),
    conduitFill("Fill the Pipe", "Smallest raceway that works", "calc-room", "cylinder.fill"),
    boxFill("Fill the Box", "Counting allowances, not wires", "calc-room", "shippingbox.fill"),
    voltageDrop("Drop the Voltage", "The field calculation, drilled", "calc-room", "chart.line.downtrend.xyaxis"),
    egcSizing("Size the Ground", "Table 250.122, read from the breaker", "grounding-room", "leaf.fill"),
    gecSizing("Reach the Electrode", "Table 250.66, and the rod's own ceiling", "grounding-room", "arrow.down.to.line"),
    motorConductor("Feed the Motor", "Table current for ordinary motors", "grounding-room", "fan.fill"),
    motorProtection("Protect the Motor", "Device percentages and standard ratings", "grounding-room", "gearshape.2.fill"),
    dwellingLoad("Size the Service", "The full dwelling calculation", "loads-room", "house.fill");

    val itemPrefix: String get() = "gen-$name-"
    val raw: String get() = name

    companion object {
        fun forItemID(id: String): PracticeSkill? = entries.firstOrNull { id.startsWith(it.itemPrefix) }
        fun of(raw: String): PracticeSkill? = entries.firstOrNull { it.name == raw }
        fun fromRaw(raw: String): PracticeSkill? = of(raw)
        fun skill(itemID: String): PracticeSkill? = forItemID(itemID)
        val endlessCases: List<PracticeSkill> get() = entries
    }
}

/** One choice-gradeable question, authored or generated. */
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
    fun mistake(forChoiceAt: Int): MistakePattern? = choices.getOrNull(forChoiceAt)?.let { mistakes[it] }

    /** What a wrong pick did, when the generator named that mistake. */
    fun note(forPick: Int): String? = mistake(forPick)?.summary
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

    /** Worked steps stay a list: a miss is one skipped step, and a paragraph hides which. */
    fun item(scenario: CalcScenario, skill: PracticeSkill, sourceLabel: String = "Endless Practice") = QuickItem(
        id = skill.itemPrefix + UUID.randomUUID().toString().uppercase(),
        prompt = scenario.situation, givens = scenario.givens, choices = scenario.choices,
        answerIndex = scenario.answerIndex, explanation = scenario.steps.firstOrNull().orEmpty(),
        steps = scenario.steps, citation = scenario.citation, sourceLabel = sourceLabel,
        roomID = skill.roomID, isReviewable = false, mistakes = scenario.mistakes,
    )

    fun item(skill: PracticeSkill, rng: RandomSource = SystemRandomSource, sourceLabel: String = "Endless Practice") =
        item(scenario(skill, rng), skill, sourceLabel)

    fun items(skill: PracticeSkill, count: Int): List<QuickItem> = List(count) { item(skill) }

    /** A mixed batch across every skill, for the timed challenge. */
    fun mixedItems(count: Int): List<QuickItem> {
        val perSkill = maxOf(1, count / PracticeSkill.entries.size + 1)
        return PracticeSkill.entries.flatMap { items(it, perSkill) }.shuffled().take(count)
    }

    /** New problems that set the traps this candidate keeps walking into. */
    fun targetedItems(patterns: List<MistakePattern>, count: Int, rng: RandomSource = SystemRandomSource): List<QuickItem> {
        if (patterns.isEmpty() || count <= 0) return emptyList()
        val items = mutableListOf<QuickItem>()
        for (index in 0 until count) {
            val pattern = patterns[index % patterns.size]
            val skill = PracticeSkill.of(pattern.skill) ?: continue
            var made: QuickItem? = null
            repeat(24) {
                if (made != null) return@repeat
                val candidate = scenario(skill, rng)
                if (pattern in candidate.mistakes.values) made = item(candidate, skill, "Targeted Practice")
            }
            items += made ?: item(skill, rng, "Targeted Practice")
        }
        return items
    }
}

/** Quick Session, Fix My Mistakes and the warm-up, built from the authored rooms. */
object SessionBuilder {
    val sessionDrill = Drill("quick-session", "Quick Session", "A short mix of what you need next", DrillKind.Flashcards(emptyList()))
    val reviewDrill = Drill("review-session", "Fix My Mistakes", "The questions you keep getting wrong", DrillKind.Flashcards(emptyList()))
    // The id keys completion counts already on device; it keeps the inherited spelling.
    val examWarmUpDrill = Drill("game-night-prep", "Exam Warm-Up", "A short targeted mix before the exam", DrillKind.Flashcards(emptyList()))

    fun quickSession(count: Int = 10, seen: Set<String>, missed: Set<String>, includePro: Boolean): List<QuickItem> {
        fun tier(item: QuickItem) = when { item.id in missed -> 0; item.id !in seen -> 1; else -> 2 }
        return choicePool(includePro).shuffled().groupBy(::tier).toSortedMap().values.flatten().take(count).map(::prepared)
    }

    fun reviewableIDs(includePro: Boolean): Set<String> = if (includePro) memberReviewable else freeReviewable
    private val freeReviewable by lazy { choicePool(false).map { it.id }.toSet() }
    private val memberReviewable by lazy { choicePool(true).map { it.id }.toSet() }

    fun gameNightPrep(count: Int = 10, seen: Set<String>, missed: Set<String>, dueIDs: List<String>, weakestRoomID: String?) =
        examWarmUp(count, seen, missed, dueIDs, weakestRoomID)

    fun reviewSession(ids: List<String>, includePro: Boolean): List<QuickItem> {
        val pool = choicePool(includePro).associateBy { it.id }
        return ids.mapNotNull { pool[it] }.map(::prepared)
    }

    fun examWarmUp(count: Int = 10, seen: Set<String>, missed: Set<String>, dueIDs: List<String>, weakestRoomID: String?): List<QuickItem> {
        val due = dueIDs.toSet()
        fun tier(item: QuickItem) = when {
            item.id in due -> 0; item.id in missed -> 1; item.roomID == weakestRoomID -> 2; item.id !in seen -> 3; else -> 4
        }
        return choicePool(true).shuffled().groupBy(::tier).toSortedMap().values.flatten().take(count).map(::prepared)
    }

    /** Answer-position variety, stable per item id. Mistakes are keyed by label, so they survive. */
    fun prepared(item: QuickItem): QuickItem {
        val perm = ChoiceShuffle.permutation(item.choices.size, item.id)
        val labels = perm.map { item.choices[it] }
        val answer = perm.indexOf(item.answerIndex).let { if (it < 0) item.answerIndex else it }
        return item.copy(choices = labels, answerIndex = answer)
    }

    fun choicePool(includePro: Boolean): List<QuickItem> {
        val pool = mutableListOf<QuickItem>()
        for (room in ElectricianContent.rooms) {
            if (!room.isFree && !includePro) continue
            for (drill in room.drills) {
                if (room.isLocked(drill, includePro)) continue
                when (val kind = drill.kind) {
                    is DrillKind.Quiz -> kind.questions.forEach {
                        pool += QuickItem(it.id, it.prompt, it.givens, it.choices, it.answerIndex, it.explanation, citation = it.citation, sourceLabel = room.name, roomID = room.id)
                    }
                    is DrillKind.Flashcards -> kind.cards.forEach { card ->
                        val choice = card.choice ?: return@forEach
                        val prompt = card.frontTitle + (card.frontSubtitle?.let { "\n$it" } ?: "")
                        pool += QuickItem(card.id, prompt, card.givens, choice.options, choice.answerIndex, card.backBody, citation = card.citation, sourceLabel = room.name, roomID = room.id)
                    }
                    is DrillKind.Calc -> Unit // Worked calculations get their own runner.
                }
            }
        }
        return pool
    }
}

enum class CodeMinuteCategory(val title: String, val icon: String) {
    navigation("Navigation", "book.closed.fill"), ampacity("Ampacity", "cable.connector"), calculation("Calculation", "function");
    val raw: String get() = name
}
data class CodeMinuteQuestion(val category: CodeMinuteCategory, val item: QuickItem)
data class CodeMinuteChallenge(val dayKey: String, val shortDate: String, val questions: List<CodeMinuteQuestion>) {
    val items: List<QuickItem> get() = questions.map { it.item }
}

/** One shared five-question set per US Pacific day, identical to iOS. */
object CodeMinuteContent {
    const val questionCount = 5
    val zone: ZoneId = ZoneId.of("America/Los_Angeles")
    val drill = Drill("code-minute", "Code Minute", "Today's shared five-question challenge", DrillKind.Quiz(emptyList()), isPlus = true)

    fun key(at: Instant): String = DateTimeFormatter.ofPattern("yyyy-MM-dd", Locale.US).withZone(zone).format(at)
    fun key(day: java.time.LocalDate): String = String.format(Locale.US, "%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)

    /** The challenge for a Pacific calendar day (archive replays). */
    fun challenge(day: java.time.LocalDate): CodeMinuteChallenge = challenge(day.atTime(12, 0).atZone(zone).toInstant())

    fun challenge(at: Instant = Instant.now()): CodeMinuteChallenge {
        val dayKey = key(at)
        val rng = SeededGenerator(seed(dayKey))
        val questions = mutableListOf<CodeMinuteQuestion>()
        val shapes = listOf<Pair<CodeMinuteCategory, (RandomSource) -> CalcScenario>>(
            CodeMinuteCategory.ampacity to CalcGenerator::ampacityProblem,
            CodeMinuteCategory.calculation to CalcGenerator::conduitFillProblem,
        )
        shapes.forEachIndexed { index, (category, make) ->
            val scenario = make(rng)
            questions += CodeMinuteQuestion(category, QuickItem(
                id = "minute-$dayKey-gen-$index", prompt = scenario.situation, givens = scenario.givens,
                choices = scenario.choices, answerIndex = scenario.answerIndex,
                explanation = scenario.steps.firstOrNull().orEmpty(), steps = scenario.steps, citation = scenario.citation,
                sourceLabel = "Code Minute", roomID = if (category == CodeMinuteCategory.ampacity) "conductors-room" else "calc-room",
                trackingID = "code-minute-rollup", isReviewable = false, mistakes = scenario.mistakes,
            ))
        }
        val pool = SessionBuilder.choicePool(true).sortedWith { a, b -> swiftCompare(a.id, b.id) }
        if (pool.isNotEmpty()) {
            val used = mutableSetOf<String>()
            var attempts = 0
            while (questions.size < questionCount && attempts < pool.size * 4) {
                attempts += 1
                val picked = pool[(rng.next() % pool.size.toULong()).toInt()]
                if (!used.add(picked.id)) continue
                questions += CodeMinuteQuestion(category(picked.roomID), SessionBuilder.prepared(picked))
            }
        }
        val short = DateTimeFormatter.ofPattern("MMM d", Locale.US).withZone(zone).format(at)
        return CodeMinuteChallenge(dayKey, short, questions)
    }

    private fun category(roomID: String) = when (roomID) {
        "conductors-room" -> CodeMinuteCategory.ampacity
        "calc-room", "loads-room" -> CodeMinuteCategory.calculation
        else -> CodeMinuteCategory.navigation
    }

    private fun seed(dayKey: String): ULong {
        var hash = 0xcbf29ce484222325uL
        for (byte in dayKey.toByteArray(Charsets.UTF_8)) {
            hash = hash xor byte.toUByte().toULong()
            hash *= 0x100000001b3uL
        }
        return hash
    }

    /** Swift `String <` compares by unicode scalars; ids are ASCII, so code units agree. */
    private fun swiftCompare(a: String, b: String): Int = a.compareTo(b)
}

