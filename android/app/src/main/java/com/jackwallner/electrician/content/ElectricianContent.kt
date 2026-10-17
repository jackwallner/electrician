package com.jackwallner.electrician.content

import org.json.JSONArray
import org.json.JSONObject

import com.jackwallner.electrician.model.CardChoice
import com.jackwallner.electrician.model.CalcScenario
import com.jackwallner.electrician.model.Drill
import com.jackwallner.electrician.model.DrillKind
import com.jackwallner.electrician.model.Flashcard
import com.jackwallner.electrician.model.Given
import com.jackwallner.electrician.model.MistakePattern
import com.jackwallner.electrician.model.QuizQuestion
import com.jackwallner.electrician.model.Room

data class PrimerPage(val id: String, val icon: String, val title: String, val body: String, val givens: List<Given>, val tip: String?)
data class ArticleInfo(val id: String, val citation: String, val displayName: String, val shortName: String, val howToSpot: String)

object ElectricianContent {
    val raw: JSONObject by lazy {
        val stream = checkNotNull(ElectricianContent::class.java.getResourceAsStream("/electrician-content.json")) { "Run scripts/sync-android-content.py" }
        JSONObject(stream.bufferedReader().use { it.readText() })
    }
    val rooms: List<Room> by lazy {
        raw.getJSONArray("rooms").objects().map { row ->
            Room(row.getString("id"), row.getString("name"), row.getString("tagline"), row.getString("icon"), row.getBoolean("isFree"), row.getJSONArray("drills").objects().map(::drill))
        }
    }
    val primer: List<PrimerPage> by lazy {
        raw.getJSONArray("primer").objects().map { PrimerPage(it.getString("id"), it.getString("icon"), it.getString("title"), it.getString("body"), givens(it), it.stringOrNull("tip")) }
    }
    val articles: List<ArticleInfo> by lazy {
        raw.getJSONArray("articles").objects().map { ArticleInfo(it.getString("id"), it.getString("citation"), it.getString("displayName"), it.getString("shortName"), it.getString("howToSpot")) }
    }
    val freeItemCount: Int get() = rooms.filter { it.isFree }.flatMap { it.drills }.filter { !it.isPlus }.sumOf { it.kind.itemCount }
    val membershipItemCount: Int get() = rooms.sumOf { room -> room.drills.filter { room.isLocked(it, false) }.sumOf { it.kind.itemCount } }
    val membershipDrillCount: Int get() = rooms.sumOf { it.plusDrillCount }
    fun room(id: String): Room? = rooms.firstOrNull { it.id == id }
    fun roomID(drillID: String): String = rooms.firstOrNull { room -> room.drills.any { it.id == drillID } }?.id ?: "basics-room"

    private fun drill(row: JSONObject): Drill {
        val items = row.getJSONArray("items").objects()
        val kind = when (row.getString("kind")) {
            "flashcards" -> DrillKind.Flashcards(items.map { item ->
                val choice = item.optJSONObject("choice")?.let { CardChoice(it.getJSONArray("options").strings(), it.getInt("answerIndex")) }
                Flashcard(item.getString("id"), item.getString("frontTitle"), givens(item), item.stringOrNull("frontSubtitle"), item.getString("backTitle"), item.getString("backBody"), item.stringOrNull("citation"), choice)
            })
            "quiz" -> DrillKind.Quiz(items.map { QuizQuestion(it.getString("id"), it.getString("prompt"), givens(it), it.getJSONArray("choices").strings(), it.getInt("answerIndex"), it.getString("explanation"), it.stringOrNull("citation")) })
            "calc" -> DrillKind.Calc(items.map(::scenario))
            else -> error("Unknown exported drill kind")
        }
        return Drill(row.getString("id"), row.getString("title"), row.getString("subtitle"), kind, row.getBoolean("isPlus"))
    }

    fun scenario(row: JSONObject): CalcScenario {
        val mistakes = row.getJSONObject("mistakes")
        return CalcScenario(row.getString("id"), row.getString("situation"), givens(row), row.getJSONArray("choices").strings(), row.getInt("answerIndex"), row.getJSONArray("steps").strings(), row.getString("citation"),
            mistakes.keys().asSequence().associateWith { key -> mistakes.getJSONObject(key).let { MistakePattern(it.getString("id"), it.getString("skill"), it.getString("summary")) } })
    }

    fun givens(row: JSONObject): List<Given> = row.getJSONArray("givens").objects().map { Given(it.getString("label"), it.getString("value"), it.stringOrNull("unit")) }
}

fun JSONArray.objects(): List<JSONObject> = (0 until length()).map(::getJSONObject)
fun JSONArray.strings(): List<String> = (0 until length()).map(::getString)
fun JSONObject.stringOrNull(key: String): String? = if (!has(key) || isNull(key)) null else getString(key)
