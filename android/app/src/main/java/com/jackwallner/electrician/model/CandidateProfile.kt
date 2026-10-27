package com.jackwallner.electrician.model

import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.ceil

import org.json.JSONArray
import org.json.JSONObject

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.objects
import com.jackwallner.electrician.content.strings

private fun metadata(group: String, id: String): JSONObject =
    ElectricianContent.raw.getJSONArray(group).objects().first { it.getString("id") == id }

enum class LicenseTrack {
    apprentice, residential, journeyman, master, contractor;
    val title: String get() = metadata("licenseTracks", name).getString("name")
    val detail: String get() = metadata("licenseTracks", name).getString("detail")
    val emphasis: String get() = metadata("licenseTracks", name).getString("emphasis")
}
enum class CandidateEdition(val year: Int?) {
    unsure(null), nec2014(2014), nec2017(2017), nec2020(2020), nec2023(2023), nec2026(2026), different(null);
    val title: String get() = metadata("candidateEditions", name).getString("name")
    val note: String get() = metadata("candidateEditions", name).getString("note")
}
enum class ExperienceLevel {
    new, apprentice, working, retaking, renewing;
    val title: String get() = metadata("experienceLevels", name).getString("title")
    val detail: String get() = metadata("experienceLevels", name).getString("detail")
    val recommendedRoomID: String get() = metadata("experienceLevels", name).getString("recommendedRoom")
}
enum class StudyPace {
    cram, sprint, build, foundation, undated;
    val title: String get() = metadata("studyPaces", name).getString("title")
    val summary: String get() = metadata("studyPaces", name).getString("summary")
    val priorities: List<String> get() = metadata("studyPaces", name).getJSONArray("priorities").strings()
    val urgent: Boolean get() = metadata("studyPaces", name).getBoolean("urgent")
}

data class Jurisdiction(val id: String, val name: String, val commonEdition: Int?, val authority: String, val examProvider: String?, val path: String) {
    val editionLabel: String get() = commonEdition?.let { "$it NEC" } ?: "Adopted locally"
    val providerLabel: String get() = examProvider ?: "Varies by jurisdiction"
}
object Jurisdictions {
    val reviewed: String get() = ElectricianContent.raw.getString("jurisdictionsReviewed")
    val all: List<Jurisdiction> by lazy { ElectricianContent.raw.getJSONArray("jurisdictions").objects().map(::decode) }
    val other: Jurisdiction by lazy { decode(ElectricianContent.raw.getJSONObject("otherJurisdiction")) }
    fun named(name: String): Jurisdiction? = (all + other).firstOrNull { it.name.equals(name.trim(), ignoreCase = true) }
    private fun decode(row: JSONObject) = Jurisdiction(row.getString("id"), row.getString("name"),
        if (row.isNull("commonEdition")) null else row.getInt("commonEdition"), row.getString("authority"),
        if (row.isNull("examProvider")) null else row.getString("examProvider"), row.getString("path"))
}

data class CandidateProfile(
    val licenseTrack: LicenseTrack = LicenseTrack.journeyman,
    val jurisdiction: String = "",
    val edition: CandidateEdition = CandidateEdition.nec2023,
    val examDate: LocalDate? = null,
    val experience: ExperienceLevel? = null,
    val focusAreas: Set<String> = emptySet(),
    val dailyGoal: Int = 15,
    val hasSelectedTrack: Boolean = false,
    val setupComplete: Boolean = false,
) {
    val trimmedJurisdiction: String get() = jurisdiction.trim()
    val jurisdictionRecord: Jurisdiction? get() = Jurisdictions.named(jurisdiction)
    val canCompleteSetup: Boolean get() = trimmedJurisdiction.isNotEmpty()
    val targetSummary: String get() = if (setupComplete) "${licenseTrack.title} · $trimmedJurisdiction" else "Set your exam target"
    val suggestedEdition: Int? get() = jurisdictionRecord?.commonEdition
    val resolvedEdition: Int? get() = edition.year ?: if (edition == CandidateEdition.unsure) suggestedEdition else null
    val editionMatchesApp: Boolean get() = resolvedEdition == NECTables.edition.take(4).toInt()
    val editionShortSummary: String get() = resolvedEdition?.let { "$it NEC" } ?: if (edition == CandidateEdition.different) "Another edition" else "Edition not set"
    val editionSummary: String get() = editionShortSummary + if (resolvedEdition != null && edition == CandidateEdition.unsure) " (from $trimmedJurisdiction)" else ""
    val editionAdvice: String get() = resolvedEdition?.let { year ->
        (CandidateEdition.entries.firstOrNull { it.year == year }
            ?: CandidateEdition.nec2014.takeIf { year < NECTables.edition.take(4).toInt() })?.note
    } ?: "Set your code edition so we can tell you where this app's ${NECTables.edition} values differ from your exam."
    val orderedRooms: List<Room> get() = ElectricianContent.rooms.filter { it.id in focusAreas } + ElectricianContent.rooms.filter { it.id !in focusAreas }

    fun daysUntilExam(today: LocalDate = LocalDate.now()): Int? = examDate?.let { ChronoUnit.DAYS.between(today, it).coerceAtLeast(0).toInt() }
    fun countdown(today: LocalDate = LocalDate.now()): String? = daysUntilExam(today)?.let { when (it) { 0 -> "Exam today"; 1 -> "1 day out"; else -> "$it days out" } }
    fun pace(today: LocalDate = LocalDate.now()): StudyPace = when (daysUntilExam(today)) {
        null -> StudyPace.undated
        in 0..3 -> StudyPace.cram
        in 4..14 -> StudyPace.sprint
        in 15..60 -> StudyPace.build
        else -> StudyPace.foundation
    }
    fun suggestedDailyQuestions(today: LocalDate = LocalDate.now()): Int {
        val days = daysUntilExam(today) ?: return 15
        return when (pace(today)) {
            StudyPace.cram -> if (days == 0) 40 else 60
            StudyPace.sprint -> ceil(400.0 / days).toInt().coerceIn(25, 50)
            StudyPace.build -> ceil(600.0 / days).toInt().coerceIn(15, 35)
            StudyPace.foundation, StudyPace.undated -> 15
        }
    }
    fun selectTrack(track: LicenseTrack): CandidateProfile = copy(licenseTrack = track, hasSelectedTrack = true)
    fun selectJurisdiction(record: Jurisdiction): CandidateProfile = copy(jurisdiction = record.name)
    fun toggleFocus(roomID: String): CandidateProfile = copy(focusAreas = if (roomID in focusAreas) focusAreas - roomID else focusAreas + roomID)
    fun completeSetup(): CandidateProfile = if (canCompleteSetup) copy(setupComplete = true) else this

    fun encode(): String = JSONObject().put("candidate.licenseTrack", licenseTrack.name).put("candidate.jurisdiction", jurisdiction)
        .put("candidate.edition", edition.name).put("candidate.examDate", examDate?.toString() ?: JSONObject.NULL)
        .put("electrician.skillLevel", experience?.name ?: JSONObject.NULL).put("candidate.focusAreas", JSONArray(focusAreas.sorted()))
        .put("candidate.dailyGoal", dailyGoal).put("candidate.hasSelectedTrack", hasSelectedTrack).put("candidate.setupComplete", setupComplete).toString()

    companion object {
        fun decode(text: String): CandidateProfile {
            val row = JSONObject(text)
            return CandidateProfile(
                LicenseTrack.entries.firstOrNull { it.name == row.optString("candidate.licenseTrack") } ?: LicenseTrack.journeyman,
                row.optString("candidate.jurisdiction"),
                CandidateEdition.entries.firstOrNull { it.name == row.optString("candidate.edition") } ?: CandidateEdition.nec2023,
                if (row.isNull("candidate.examDate")) null else LocalDate.parse(row.getString("candidate.examDate")),
                ExperienceLevel.entries.firstOrNull { it.name == row.optString("electrician.skillLevel") },
                row.optJSONArray("candidate.focusAreas")?.strings()?.toSet().orEmpty(), row.optInt("candidate.dailyGoal", 15),
                row.optBoolean("candidate.hasSelectedTrack"), row.optBoolean("candidate.setupComplete"),
            )
        }
    }
}
