package com.jackwallner.electrician.data

import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.ceil

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONObject

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.objects
import com.jackwallner.electrician.content.strings
import com.jackwallner.electrician.model.NECTables

data class LicenseTrack(val id: String, val name: String, val shortName: String, val detail: String, val emphasis: String)
data class CandidateEdition(val id: String, val name: String, val edition: Int?, val note: String)
data class ExperienceLevel(val id: String, val title: String, val detail: String, val recommendedRoom: String)
data class StudyPace(val id: String, val title: String, val summary: String, val priorities: List<String>, val isUrgent: Boolean)
data class Jurisdiction(val id: String, val name: String, val authority: String, val commonEdition: Int?, val examProvider: String?, val path: String)

/** The candidate choices, exported from the iOS enums so copy and raw values cannot drift. */
object CandidateCatalog {
    private val raw: JSONObject get() = ElectricianContent.raw
    private fun JSONObject.intOrNull(key: String): Int? = if (!has(key) || isNull(key)) null else getInt(key)
    private fun JSONObject.stringOrNull(key: String): String? = if (!has(key) || isNull(key)) null else getString(key)

    val tracks by lazy { raw.getJSONArray("licenseTracks").objects().map { LicenseTrack(it.getString("id"), it.getString("name"), it.getString("shortName"), it.getString("detail"), it.getString("emphasis")) } }
    val editions by lazy { raw.getJSONArray("candidateEditions").objects().map { CandidateEdition(it.getString("id"), it.getString("name"), it.intOrNull("edition"), it.getString("note")) } }
    val experience by lazy { raw.getJSONArray("experienceLevels").objects().map { ExperienceLevel(it.getString("id"), it.getString("title"), it.getString("detail"), it.getString("recommendedRoom")) } }
    val paces by lazy { raw.getJSONArray("studyPaces").objects().map { StudyPace(it.getString("id"), it.getString("title"), it.getString("summary"), it.getJSONArray("priorities").strings(), it.getBoolean("urgent")) } }
    private fun jurisdiction(row: JSONObject) = Jurisdiction(row.getString("id"), row.getString("name"), row.getString("authority"), row.intOrNull("commonEdition"), row.stringOrNull("examProvider"), row.getString("path"))
    val jurisdictions by lazy { raw.getJSONArray("jurisdictions").objects().map(::jurisdiction) }
    val other by lazy { jurisdiction(raw.getJSONObject("otherJurisdiction")) }
    val reviewed: String get() = raw.getString("jurisdictionsReviewed")

    fun jurisdiction(id: String): Jurisdiction? = jurisdictions.firstOrNull { it.id == id } ?: other.takeIf { it.id == id }
    fun pace(id: String): StudyPace = paces.first { it.id == id }
}

/**
 * The seven setup answers, under the iOS `candidate.*` keys. The pace is
 * derived from the exam date, never stored.
 */
class CandidateProfile(private val defaults: KeyValueStore, private val clock: AppClock) {
    var licenseTrack by mutableStateOf(defaults.getString(Keys.TRACK) ?: "journeyman")
        private set
    var jurisdiction by mutableStateOf(defaults.getString(Keys.JURISDICTION).orEmpty())
        private set
    // An absent value resolves to this app's own edition (older installs chose from a list defaulting to it).
    var edition by mutableStateOf(defaults.getString(Keys.EDITION) ?: "nec2023")
        private set
    var examDate by mutableStateOf(defaults.getString(Keys.EXAM_DATE)?.let { runCatching { LocalDate.parse(it) }.getOrNull() })
        private set
    var focusAreas by mutableStateOf(defaults.getStringSet(Keys.FOCUS))
        private set
    var setupComplete by mutableStateOf(defaults.getBoolean(Keys.SETUP_COMPLETE))
        private set

    fun updateTrack(id: String) { licenseTrack = id; defaults.putString(Keys.TRACK, id); defaults.putBoolean(Keys.HAS_SELECTED_TRACK, true) }
    fun updateJurisdiction(id: String) { jurisdiction = id; defaults.putString(Keys.JURISDICTION, id) }
    fun updateEdition(id: String) { edition = id; defaults.putString(Keys.EDITION, id) }
    fun updateExamDate(date: LocalDate?) {
        examDate = date
        if (date == null) defaults.remove(Keys.EXAM_DATE) else defaults.putString(Keys.EXAM_DATE, date.toString())
    }
    fun toggleFocus(roomID: String) {
        focusAreas = if (roomID in focusAreas) focusAreas - roomID else focusAreas + roomID
        defaults.putStringSet(Keys.FOCUS, focusAreas)
    }
    fun completeSetup() { setupComplete = true; defaults.putBoolean(Keys.SETUP_COMPLETE, true); defaults.putInt(Keys.DAILY_GOAL, suggestedDailyQuestions) }

    val track: LicenseTrack get() = CandidateCatalog.tracks.firstOrNull { it.id == licenseTrack } ?: CandidateCatalog.tracks.first()
    val jurisdictionRecord: Jurisdiction? get() = CandidateCatalog.jurisdiction(jurisdiction)

    /** "I'm not sure" falls back to the state's commonly adopted edition. */
    val resolvedEdition: Int? get() {
        val chosen = CandidateCatalog.editions.firstOrNull { it.id == edition }
        return if (chosen?.id == "unsure" || chosen == null) jurisdictionRecord?.commonEdition else chosen.edition
    }
    val editionShortSummary: String get() = resolvedEdition?.let { "$it NEC" } ?: if (edition == "different") "Another edition" else "Edition not set"
    val editionMatchesApp: Boolean get() = resolvedEdition == NECTables.edition.takeWhile { it.isDigit() }.toIntOrNull()

    val daysUntilExam: Int? get() = examDate?.let { maxOf(0, ChronoUnit.DAYS.between(clock.today(), it).toInt()) }
    val countdownText: String? get() = daysUntilExam?.let { when (it) { 0 -> "Exam today"; 1 -> "1 day out"; else -> "$it days out" } }

    val pace: StudyPace get() = CandidateCatalog.pace(paceID(daysUntilExam))

    val suggestedDailyQuestions: Int get() = suggestedDaily(daysUntilExam)

    private object Keys {
        const val TRACK = "candidate.licenseTrack"
        const val JURISDICTION = "candidate.jurisdiction"
        const val EDITION = "candidate.edition"
        const val EXAM_DATE = "candidate.examDate"
        const val HAS_SELECTED_TRACK = "candidate.hasSelectedTrack"
        const val SETUP_COMPLETE = "candidate.setupComplete"
        const val FOCUS = "candidate.focusAreas"
        const val DAILY_GOAL = "candidate.dailyGoal"
    }

    companion object {
        fun paceID(days: Int?): String = when {
            days == null -> "undated"
            days <= 3 -> "cram"
            days <= 14 -> "sprint"
            days <= 60 -> "build"
            else -> "foundation"
        }

        /** Branches on the pace rather than dividing a fixed total by the days left. */
        fun suggestedDaily(days: Int?): Int {
            val pace = paceID(days)
            if (days == null || days <= 0) return if (pace == "cram") 40 else 15
            return when (pace) {
                "cram" -> 60
                "sprint" -> minOf(50, maxOf(25, ceil(400.0 / days).toInt()))
                "build" -> minOf(35, maxOf(15, ceil(600.0 / days).toInt()))
                else -> 15
            }
        }
    }
}
