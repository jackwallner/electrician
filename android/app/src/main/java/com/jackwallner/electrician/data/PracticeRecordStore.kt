package com.jackwallner.electrician.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.electrician.content.CandidateMistake
import com.jackwallner.electrician.content.DrillLibrary
import com.jackwallner.electrician.content.PracticeSkill
import com.jackwallner.electrician.model.DrillKind
import com.jackwallner.electrician.model.MistakePattern
import com.jackwallner.electrician.model.Room
import org.json.JSONObject

/** One item's answering history and its next review date. Times are epoch millis. */
data class PracticeRecord(
    val attempts: Int = 0,
    val correct: Int = 0,
    val streak: Int = 0,
    val lastAnswered: Long = 0,
    val dueDate: Long = 0,
    val intervalDays: Double = 0.0,
    val ease: Double = 2.5,
    val roomID: String = "",
    val reviewSuppressed: Boolean? = null,
) {
    val accuracy: Double get() = if (attempts == 0) 0.0 else correct.toDouble() / attempts

    fun isDue(now: Long): Boolean = dueDate <= now

    /** Missed at least once and not yet answered right twice running. */
    val needsReview: Boolean get() = reviewSuppressed != true && attempts > correct && streak < 2

    /** Known means answered right twice in a row and not yet a full interval past due. */
    fun isKnown(now: Long): Boolean {
        if (streak < 2) return false
        if (intervalDays <= 0) return true
        return now < dueDate + (intervalDays * DAY_MS).toLong()
    }

    fun toJson(): JSONObject = JSONObject().apply {
        put("attempts", attempts)
        put("correct", correct)
        put("streak", streak)
        put("lastAnswered", lastAnswered)
        put("dueDate", dueDate)
        put("intervalDays", intervalDays)
        put("ease", ease)
        put("roomID", roomID)
        reviewSuppressed?.let { put("reviewSuppressed", it) }
    }

    companion object {
        fun fromJson(json: JSONObject) = PracticeRecord(
            attempts = json.optInt("attempts"),
            correct = json.optInt("correct"),
            streak = json.optInt("streak"),
            lastAnswered = json.optLong("lastAnswered"),
            dueDate = json.optLong("dueDate"),
            intervalDays = json.optDouble("intervalDays", 0.0),
            ease = json.optDouble("ease", 2.5),
            roomID = json.optString("roomID"),
            reviewSuppressed = if (json.has("reviewSuppressed")) json.getBoolean("reviewSuppressed") else null,
        )
    }
}

enum class MasteryLevel(val title: String, val icon: String, val nextStep: String) {
    UNTOUCHED("Not started", "circle.dotted", "Answer a few questions here to start tracking."),
    LEARNING("Learning", "book.fill", "Get each question right twice running to lock it in."),
    SOLID("Solid", "checkmark.seal.fill", "Keep going. Sharp means nearly everything here is holding."),
    SHARP("Sharp", "star.fill", "Come back now and then so it stays sharp.");

    companion object {
        /** Thresholds are on coverage, not raw accuracy. */
        fun level(known: Int, total: Int): MasteryLevel {
            if (total <= 0 || known <= 0) return UNTOUCHED
            val fraction = known.toDouble() / total
            return when {
                fraction >= 0.85 -> SHARP
                fraction >= 0.4 -> SOLID
                else -> LEARNING
            }
        }
    }
}

data class RoomMastery(val roomID: String, val known: Int, val total: Int, val level: MasteryLevel) {
    val fraction: Double get() = if (total == 0) 0.0 else known.toDouble() / total
}

/** Per-item practice history, the spaced-repetition queue, and the room rollups. */
class PracticeRecordStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var records by mutableStateOf(load())
        private set
    var bestChallengeScore by mutableStateOf(defaults.getInt(Keys.BEST_CHALLENGE))
        private set

    /** Seeds engagement (never mastery) from the flat sets older builds kept. */
    fun migrateLegacyProgress(seen: Set<String>, missed: Set<String>) {
        if (defaults.getBoolean(Keys.LEGACY_MIGRATED)) return
        defaults.putBoolean(Keys.LEGACY_MIGRATED, true)
        if (seen.isEmpty()) return
        val now = clock.millis()
        val rooms = mutableMapOf<String, String>()
        for (room in DrillLibrary.rooms) for (id in trackableItemIDs(room, true)) rooms[id] = room.id
        val updated = records.toMutableMap()
        for (id in seen) {
            if (id in updated) continue
            val roomID = rooms[id] ?: continue
            updated[id] = if (id in missed) {
                PracticeRecord(attempts = 2, correct = 1, streak = 0, lastAnswered = now, dueDate = now, roomID = roomID)
            } else {
                PracticeRecord(attempts = 1, correct = 1, streak = 1, intervalDays = 1.0, lastAnswered = now, dueDate = now + DAY_MS, roomID = roomID)
            }
        }
        if (updated.size != records.size) {
            records = updated
            persist()
        }
    }

    data class AnswerSnapshot(val itemID: String, val record: PracticeRecord?)

    fun snapshotAnswer(itemID: String) = AnswerSnapshot(itemID, records[itemID])

    fun restoreAnswer(snapshot: AnswerSnapshot) {
        records = if (snapshot.record == null) records - snapshot.itemID else records + (snapshot.itemID to snapshot.record)
        persist()
    }

    /** Generated items collapse onto one row per skill, so the map stays bounded. */
    fun record(itemID: String, roomID: String, correct: Boolean, isReviewable: Boolean = true) {
        val now = clock.millis()
        val skill = PracticeSkill.forItemID(itemID)
        val key = skill?.name ?: itemID
        val isGenerated = skill != null
        val old = records[key] ?: PracticeRecord()
        var record = old.copy(
            attempts = old.attempts + 1,
            roomID = roomID,
            reviewSuppressed = !isReviewable || isGenerated,
            lastAnswered = now,
            correct = if (correct) old.correct + 1 else old.correct,
            streak = if (correct) old.streak + 1 else 0,
        )
        if (isReviewable && !isGenerated) record = schedule(record, correct, now)
        records = records + (key to record)
        persist()
    }

    /** SM-2, trimmed: a miss resets the interval and costs ease, a hit multiplies it. */
    private fun schedule(record: PracticeRecord, correct: Boolean, now: Long): PracticeRecord {
        val interval: Double
        val ease: Double
        if (correct) {
            interval = when (record.streak) {
                1 -> 1.0
                2 -> 3.0
                else -> minOf(record.intervalDays * record.ease, 180.0)
            }
            ease = minOf(record.ease + 0.1, 2.8)
        } else {
            interval = 0.0
            ease = maxOf(record.ease - 0.2, 1.3)
        }
        return record.copy(intervalDays = interval, ease = ease, dueDate = now + (interval * DAY_MS).toLong())
    }

    fun recordChallengeScore(score: Int) {
        if (score <= bestChallengeScore) return
        bestChallengeScore = score
        defaults.putInt(Keys.BEST_CHALLENGE, score)
    }

    /** Due ids, worst first: lowest accuracy, then longest overdue. */
    fun reviewQueue(limit: Int = 12, presentable: Set<String>? = null): List<String> =
        dueRecords(presentable).entries
            .sortedWith(compareBy<Map.Entry<String, PracticeRecord>> { it.value.accuracy }.thenBy { it.value.dueDate })
            .take(limit)
            .map { it.key }

    fun dueCount(presentable: Set<String>? = null): Int = dueRecords(presentable).size

    private fun dueRecords(presentable: Set<String>?): Map<String, PracticeRecord> {
        val now = clock.millis()
        return records.filter { (id, record) ->
            record.needsReview && record.isDue(now) && PracticeSkill.of(id) == null &&
                (presentable == null || id in presentable)
        }
    }

    data class RoomStat(val id: String, val name: String, val attempts: Int, val correct: Int) {
        val accuracy: Double get() = if (attempts == 0) 0.0 else correct.toDouble() / attempts
    }

    val totalAttempts: Int get() = records.values.sumOf { it.attempts }
    val totalCorrect: Int get() = records.values.sumOf { it.correct }
    val overallAccuracy: Double get() = if (totalAttempts == 0) 0.0 else totalCorrect.toDouble() / totalAttempts

    /** Play a Hand is stored under the Card Room but kept out of it here (iOS parity). */
    fun roomStats(): List<RoomStat> = DrillLibrary.rooms.mapNotNull { room ->
        val mine = records.filter { it.value.roomID == room.id }.values
        val attempts = mine.sumOf { it.attempts }
        if (attempts == 0) null else RoomStat(room.id, room.name, attempts, mine.sumOf { it.correct })
    }

    fun weakestRoom(): RoomStat? = roomStats().filter { it.attempts >= 5 }.minByOrNull { it.accuracy }

    fun mastery(room: Room, isMember: Boolean): RoomMastery {
        val ids = trackableItemIDs(room, isMember).toSet()
        if (ids.isEmpty()) return RoomMastery(room.id, 0, 0, MasteryLevel.UNTOUCHED)
        val now = clock.millis()
        val known = ids.count { records[it]?.isKnown(now) == true }
        return RoomMastery(room.id, known, ids.size, MasteryLevel.level(known, ids.size))
    }

    fun masteryByRoom(isMember: Boolean): List<RoomMastery> = DrillLibrary.rooms.map { mastery(it, isMember) }

    /** The least-mastered room that has been started at all. */
    fun roomToWorkOn(isMember: Boolean): RoomMastery? =
        masteryByRoom(isMember).filter { it.level != MasteryLevel.UNTOUCHED && it.level != MasteryLevel.SHARP }.minByOrNull { it.fraction }

    // Named mistakes, the habits behind Fix My Mistakes' targeted problems.
    data class MistakeTally(val pattern: MistakePattern, val outstanding: Int, val totalMisses: Int, val lastMissed: Long)

    var mistakes by mutableStateOf(loadMistakes())
        private set

    fun recordMistake(pattern: MistakePattern) {
        val old = mistakes[pattern.id]
        val tally = MistakeTally(pattern, minOf((old?.outstanding ?: 0) + 1, MAX_OUTSTANDING_PER_PATTERN), (old?.totalMisses ?: 0) + 1, clock.millis())
        mistakes = mistakes + (pattern.id to tally)
        persistMistakes()
    }

    /** A correct answer on a problem that set this trap works the habit off one at a time. */
    fun resolveMistake(patternID: String) {
        val tally = mistakes[patternID] ?: return
        mistakes = if (tally.outstanding <= 1) mistakes - patternID else mistakes + (patternID to tally.copy(outstanding = tally.outstanding - 1))
        persistMistakes()
    }

    fun outstandingMistakes(limit: Int = 4): List<MistakePattern> = mistakes.values
        .sortedWith(compareByDescending<MistakeTally> { it.outstanding }.thenByDescending { it.lastMissed })
        .take(limit).map { it.pattern }

    val outstandingMistakeCount: Int get() = mistakes.values.sumOf { it.outstanding }

    private fun persistMistakes() {
        val json = JSONObject()
        mistakes.forEach { (id, t) ->
            json.put(id, JSONObject().put("id", t.pattern.id).put("skill", t.pattern.skill).put("summary", t.pattern.summary)
                .put("outstanding", t.outstanding).put("totalMisses", t.totalMisses).put("lastMissed", t.lastMissed))
        }
        defaults.putString(Keys.MISTAKES, json.toString())
    }

    private fun loadMistakes(): Map<String, MistakeTally> {
        val json = defaults.getString(Keys.MISTAKES)?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return emptyMap()
        return json.keys().asSequence().associateWith { id ->
            val row = json.getJSONObject(id)
            // The catalogue's current copy wins over a stored summary from an older release.
            val pattern = CandidateMistake.pattern(id) ?: MistakePattern(row.getString("id"), row.getString("skill"), row.getString("summary"))
            MistakeTally(pattern, row.getInt("outstanding"), row.getInt("totalMisses"), row.getLong("lastMissed"))
        }
    }

    fun resetAll() {
        mistakes = emptyMap()
        defaults.remove(Keys.MISTAKES)
        records = emptyMap()
        bestChallengeScore = 0
        defaults.remove(Keys.RECORDS)
        defaults.remove(Keys.BEST_CHALLENGE)
    }

    private fun persist() {
        val json = JSONObject()
        records.forEach { (id, record) -> json.put(id, record.toJson()) }
        defaults.putString(Keys.RECORDS, json.toString())
    }

    private fun load(): Map<String, PracticeRecord> {
        val raw = defaults.getString(Keys.RECORDS) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { PracticeRecord.fromJson(json.getJSONObject(it)) }
    }

    companion object {
        const val MAX_OUTSTANDING_PER_PATTERN = 5

        /** Every gradeable item id in a room that this player can open. */
        fun trackableItemIDs(room: Room, isMember: Boolean): List<String> =
            room.drills.filterNot { room.isLocked(it, isMember) }.flatMap { drill ->
                when (val kind = drill.kind) {
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.Calc -> kind.scenarios.map { it.id }
                    is DrillKind.Flashcards -> kind.cards.filter { it.choice != null }.map { it.id }
                }
            }
    }

    private object Keys {
        const val RECORDS = "practice.records"
        const val BEST_CHALLENGE = "practice.bestChallengeScore"
        const val LEGACY_MIGRATED = "practice.migratedLegacyProgress"
        const val MISTAKES = "practice.mistakePatterns"
    }
}
