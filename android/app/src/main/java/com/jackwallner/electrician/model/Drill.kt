package com.jackwallner.electrician.model

import java.math.BigDecimal
import java.math.MathContext
import java.math.RoundingMode
import java.util.Locale

enum class ConductorMaterial(val displayName: String, val voltageDropK: Double) {
    copper("Copper", 12.9), aluminum("Aluminum", 21.2)
}
enum class TemperatureRating(val value: Int) {
    c60(60), c75(75), c90(90);
    val displayName: String get() = "$value°C"
}
enum class Phase(val displayName: String, val voltageDropFactor: Double) {
    single("1Ø", 2.0), three("3Ø", 1.732)
}

data class Given(val label: String, val value: String, val unit: String? = null) {
    val id: String get() = "$label|$value|${unit.orEmpty()}"
    val spokenLabel: String get() = "$label: $value${unit?.let { " $it" }.orEmpty()}"
    companion object {
        fun conductor(size: String, insulation: String) = Given("Conductor", "$size $insulation")
        fun material(metal: ConductorMaterial) = Given("Material", metal.displayName)
        fun ambient(celsius: Int) = Given("Ambient", "$celsius", "°C")
        fun currentCarrying(count: Int) = Given("Current-carrying", "$count", if (count == 1) "conductor" else "conductors")
        fun terminals(rating: TemperatureRating) = Given("Terminals", rating.displayName)
        fun load(amps: Double) = Given("Load", amps.trimmedAmps, "A")
        fun length(feet: Int) = Given("One-way length", "$feet", "ft")
        fun voltage(volts: Int, phase: Phase) = Given("System", "${volts}V ${phase.displayName}")
        fun raceway(type: String, trade: String) = Given("Raceway", "$trade $type")
    }
}

data class CardChoice(val options: List<String>, val answerIndex: Int)
data class Flashcard(val id: String, val frontTitle: String, val givens: List<Given> = emptyList(), val frontSubtitle: String? = null, val backTitle: String, val backBody: String, val citation: String? = null, val choice: CardChoice? = null)
data class QuizQuestion(val id: String, val prompt: String, val givens: List<Given> = emptyList(), val choices: List<String>, val answerIndex: Int, val explanation: String, val citation: String? = null)
data class MistakePattern(val id: String, val skill: String, val summary: String)
data class CalcScenario(val id: String, val situation: String, val givens: List<Given>, val choices: List<String>, val answerIndex: Int, val steps: List<String>, val citation: String, val mistakes: Map<String, MistakePattern> = emptyMap())

sealed interface DrillKind {
    data class Flashcards(val cards: List<Flashcard>) : DrillKind
    data class Quiz(val questions: List<QuizQuestion>) : DrillKind
    data class Calc(val scenarios: List<CalcScenario>) : DrillKind
    val itemCount: Int get() = when (this) {
        is Flashcards -> cards.size
        is Quiz -> questions.size
        is Calc -> scenarios.size
    }
    val unitName: String get() = if (this is Flashcards) "cards" else "questions"
}
data class Drill(val id: String, val title: String, val subtitle: String, val kind: DrillKind, val isPlus: Boolean = false)
data class Room(val id: String, val name: String, val tagline: String, val icon: String, val isFree: Boolean, val drills: List<Drill>) {
    val plusDrillCount: Int get() = if (isFree) drills.count { it.isPlus } else drills.size
    fun isLocked(drill: Drill, isMember: Boolean): Boolean = !isMember && (!isFree || drill.isPlus)
}

val Double.roundedAway: Double get() {
    val magnitude = kotlin.math.abs(this)
    val whole = kotlin.math.floor(magnitude)
    val rounded = if (magnitude - whole >= 0.5) whole + 1 else whole
    return if (java.lang.Double.doubleToRawLongBits(this) < 0) -rounded else rounded
}
val Double.trimmedAmps: String get() = if (this == roundedAway) roundedAway.toLong().toString() else swiftFixed(1)
val Double.roundedAmps: Int get() = roundedAway.toInt()
val Double.roundedAmpsText: String get() = swiftFixed(1)
val Double.factorText: String get() {
    if (this == roundedAway) return roundedAway.toLong().toString()
    val value = BigDecimal(this, MathContext(6, RoundingMode.HALF_EVEN)).stripTrailingZeros()
    val exponent = value.precision() - value.scale() - 1
    return if (exponent in -4..<6) value.toPlainString() else value.movePointLeft(exponent).toPlainString() + "e" + String.format(Locale.US, "%+03d", exponent)
}
val Double.areaText: String get() = swiftFixed(2)
val Double.volumeText: String get() = if (this == roundedAway) roundedAway.toLong().toString() else swiftFixed(2).removeSuffix("0")
val Double.voltsText: String get() = swiftFixed(1)
val Int.groupedText: String get() = String.format(Locale.US, "%,d", this)

fun Double.swiftFixed(digits: Int): String {
    if (isNaN()) return "nan"
    if (this == Double.POSITIVE_INFINITY) return "inf"
    if (this == Double.NEGATIVE_INFINITY) return "-inf"
    val rounded = BigDecimal(this).setScale(digits, RoundingMode.HALF_EVEN)
    val sign = if (rounded.signum() == 0 && java.lang.Double.doubleToRawLongBits(this) < 0) "-" else ""
    return sign + rounded.toPlainString()
}
