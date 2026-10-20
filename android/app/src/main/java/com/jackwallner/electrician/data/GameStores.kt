package com.jackwallner.electrician.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.electrician.content.WhatsNewContent
import com.jackwallner.electrician.content.CodeMinuteCategory
import com.jackwallner.electrician.content.CodeMinuteChallenge
import com.jackwallner.electrician.content.CodeMinuteContent
import com.jackwallner.electrician.content.WhatsNewRelease
import java.time.Instant
import java.time.LocalDate
import java.time.temporal.WeekFields
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

data class CodeMinuteResult(
    val dayKey: String,
    val shortDate: String,
    val completedAt: Long,
    val answers: List<Boolean>,
    val correctByCategory: Map<String, Int>,
    val totalByCategory: Map<String, Int>,
) {
    val score: Int get() = answers.count { it }
    val total: Int get() = answers.size

    fun correct(category: CodeMinuteCategory) = correctByCategory[category.name] ?: 0
    fun total(category: CodeMinuteCategory) = totalByCategory[category.name] ?: 0

    val shareText: String
        get() {
            val grid = answers.joinToString("") { if (it) "🟩" else "⬜️" }
            return "Code Minute $shortDate: $score/$total\n$grid\nCan you beat me? ${StoreLinks.PLAY_LISTING_URL}"
        }

    fun toJson(): JSONObject = JSONObject().apply {
        put("dayKey", dayKey)
        put("shortDate", shortDate)
        put("completedAt", completedAt)
        put("answers", JSONArray(answers))
        put("correctByCategory", JSONObject(correctByCategory as Map<*, *>))
        put("totalByCategory", JSONObject(totalByCategory as Map<*, *>))
    }

    companion object {
        fun fromJson(json: JSONObject): CodeMinuteResult {
            val answers = json.getJSONArray("answers")
            fun counts(key: String): Map<String, Int> {
                val obj = json.getJSONObject(key)
                return obj.keys().asSequence().associateWith { obj.getInt(it) }
            }
            return CodeMinuteResult(
                dayKey = json.getString("dayKey"),
                shortDate = json.getString("shortDate"),
                completedAt = json.getLong("completedAt"),
                answers = (0 until answers.length()).map { answers.getBoolean(it) },
                correctByCategory = counts("correctByCategory"),
                totalByCategory = counts("totalByCategory"),
            )
        }
    }
}

class CodeMinuteStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var results by mutableStateOf(load())
        private set

    fun result(day: LocalDate): CodeMinuteResult? = results[CodeMinuteContent.key(day)]

    /** Only the first attempt on a day counts. */
    fun record(challenge: CodeMinuteChallenge, answers: List<Boolean>): CodeMinuteResult {
        results[challenge.dayKey]?.let { return it }
        val correct = mutableMapOf<String, Int>()
        val total = mutableMapOf<String, Int>()
        challenge.questions.zip(answers).forEach { (question, right) ->
            total[question.category.name] = (total[question.category.name] ?: 0) + 1
            if (right) correct[question.category.name] = (correct[question.category.name] ?: 0) + 1
        }
        val result = CodeMinuteResult(challenge.dayKey, challenge.shortDate, clock.millis(), answers, correct, total)
        results = results + (challenge.dayKey to result)
        persist()
        return result
    }

    fun completedThisWeek(): Int {
        val fields = WeekFields.of(Locale.getDefault())
        val today = clock.today()
        val start = today.with(fields.dayOfWeek(), 1)
        val end = start.plusDays(7)
        return results.values.count {
            val day = Instant.ofEpochMilli(it.completedAt).atZone(clock.zone).toLocalDate()
            !day.isBefore(start) && day.isBefore(end)
        }
    }

    fun archiveDates(count: Int = 30): List<LocalDate> = (1..count).map { clock.today().minusDays(it.toLong()) }

    fun resetAll() {
        results = emptyMap()
        defaults.remove(KEY)
    }

    private fun persist() {
        val json = JSONObject()
        results.forEach { (key, value) -> json.put(key, value.toJson()) }
        defaults.putString(KEY, json.toString())
    }

    private fun load(): Map<String, CodeMinuteResult> {
        val raw = defaults.getString(KEY) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { CodeMinuteResult.fromJson(json.getJSONObject(it)) }
    }

    private companion object {
        const val KEY = "codeMinute.results"
    }
}

/**
 * The post-update notes, once. A fresh install never sees them: onboarding
 * marks the running version as the baseline.
 */
class WhatsNewTracker(private val defaults: KeyValueStore, val currentVersion: String) {
    /**
     * The newest notes at or below the running version, so a patch release with no entry of its
     * own (1.4.2) still carries 1.4.1's notes to a player updating straight from an older build.
     */
    val currentRelease: WhatsNewRelease?
        get() = WhatsNewContent.releases
            .filter { !isOlder(currentVersion, it.version) }
            .maxWithOrNull { a, b -> compareVersions(a.version, b.version) }

    fun shouldPresent(hasOnboarded: Boolean): Boolean {
        val release = currentRelease
        if (!hasOnboarded || release == null) return false
        val lastSeen = defaults.getString(KEY) ?: ""
        // Empty on an onboarded player means an update from a build before this feature. Anyone
        // who last saw these notes' version or later has read them.
        return lastSeen.isEmpty() || isOlder(lastSeen, release.version)
    }

    fun markSeen() = defaults.putString(KEY, currentVersion)

    fun markCurrentAsBaseline() = defaults.putString(KEY, currentVersion)

    companion object {
        private const val KEY = "whatsnew.lastSeenVersion"

        fun isOlder(version: String, other: String): Boolean = compareVersions(version, other) < 0

        /** Numeric, part by part, like Swift's `.numeric` compare: "1.4.10" is newer than "1.4.9". */
        fun compareVersions(a: String, b: String): Int {
            val left = a.split(".").map { it.toIntOrNull() ?: 0 }
            val right = b.split(".").map { it.toIntOrNull() ?: 0 }
            for (index in 0 until maxOf(left.size, right.size)) {
                val diff = left.getOrElse(index) { 0 }.compareTo(right.getOrElse(index) { 0 })
                if (diff != 0) return diff
            }
            return 0
        }
    }
}
