package com.jackwallner.electrician.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.jackwallner.electrician.content.DrillLibrary
import com.jackwallner.electrician.model.ChoiceShuffle
import com.jackwallner.electrician.model.Drill
import com.jackwallner.electrician.model.CalcScenario
import com.jackwallner.electrician.model.Given
import com.jackwallner.electrician.model.QuizQuestion
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.ChoiceList
import com.jackwallner.electrician.ui.components.DrillProgress
import com.jackwallner.electrician.ui.components.DrillStage
import com.jackwallner.electrician.ui.components.MissNote
import com.jackwallner.electrician.ui.components.QuestionPager
import com.jackwallner.electrician.ui.components.capitalizedFirst
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.theme.ElecScreen
import com.jackwallner.electrician.ui.theme.PrimaryCTA
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.screenPadding

/** One question on screen, the shape every choice drill renders. */
data class ChoiceQuestion(
    val key: String,
    val prompt: String,
    val givens: List<Given>,
    val labels: List<String>,
    val answerIndex: Int,
    val explanation: String,
    val eyebrow: String? = null,
    val missNote: (Int) -> MissNote? = { null },
    val requeuesOnMiss: Boolean = false,
    val steps: List<String> = emptyList(),
    val citation: String? = null,
)

/**
 * The shared pick, grade, hold, Next beat. [header] sits above the question
 * (a progress bar or a run's status line); [footerLabel] shows until graded.
 */
@Composable
fun ChoiceQuestionBody(
    question: ChoiceQuestion,
    selection: Int?,
    nextTitle: String,
    footerLabel: String,
    onPick: (Int) -> Unit,
    onNext: () -> Unit,
    onAnswerBounds: (Rect) -> Unit,
    header: @Composable ColumnScope.() -> Unit,
) {
    Readable(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            header()
            AnimatedContent(
                targetState = question,
                transitionSpec = {
                    (slideInHorizontally(tween(320)) { it } + fadeIn(tween(320))) togetherWith
                        (slideOutHorizontally(tween(320)) { -it } + fadeOut(tween(320)))
                },
                contentKey = { it.key },
                modifier = Modifier.fillMaxWidth().weight(1f),
                label = "question",
            ) { shown ->
                val live = shown.key == question.key
                val picked = if (live) selection else null
                Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    QuestionPager(
                        prompt = shown.prompt,
                        givens = shown.givens,
                        explanation = shown.explanation,
                        steps = shown.steps,
                        citation = shown.citation,
                        answered = picked != null,
                        eyebrow = shown.eyebrow,
                        missNote = picked?.takeIf { it != shown.answerIndex }?.let(shown.missNote),
                        requeued = picked != null && picked != shown.answerIndex && shown.requeuesOnMiss,
                        modifier = Modifier.weight(1f),
                    ) {
                        ChoiceList(shown.labels, picked, shown.answerIndex, onAnswerBounds) { if (live) onPick(it) }
                    }
                    if (picked != null) PrimaryCTA(nextTitle, Modifier.testTag("next"), onClick = onNext)
                    else FooterCounter(footerLabel)
                }
            }
        }
    }
}

@Composable
fun QuizDrillScreen(drill: Drill, questions: List<QuizQuestion>) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    var index by rememberSaveable { mutableIntStateOf(0) }
    var selection by rememberSaveable { mutableStateOf<Int?>(null) }
    var score by rememberSaveable { mutableIntStateOf(0) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }
    var answerRect by remember { mutableStateOf<Rect?>(null) }

    if (finished) {
        DrillCompleteScreen(drill, score, questions.size) { navigator.pop() }
        return
    }
    val question = questions[index]
    val (labels, answerIndex) = remember(question.id) {
        val permutation = ChoiceShuffle.permutation(question.choices.size, question.id)
        permutation.map { question.choices[it] } to permutation.indexOf(question.answerIndex)
    }
    ElecScreen(drill.title, onBack = { navigator.pop() }) {
        DrillStage(confetti, answerRect = answerRect) {
            ChoiceQuestionBody(
                ChoiceQuestion(question.id, question.prompt, question.givens, labels, answerIndex, question.explanation, citation = question.citation),
                selection,
                nextTitle = if (index + 1 < questions.size) "Next Question" else "Finish",
                footerLabel = "Question ${index + 1} of ${questions.size}",
                onPick = { pick ->
                    if (selection != null) return@ChoiceQuestionBody
                    selection = pick
                    val correct = pick == answerIndex
                    graph.recordAnswer(question.id, DrillLibrary.roomID(drill.id), correct)
                    if (correct) {
                        score += 1
                        confetti += 1
                        celebrateCorrect()
                    } else {
                        consoleMiss()
                    }
                },
                onNext = {
                    if (index + 1 < questions.size) {
                        selection = null
                        index += 1
                    } else {
                        finished = true
                    }
                },
                onAnswerBounds = { answerRect = it },
            ) { DrillProgress(index, questions.size) }
        }
    }
}

/**
 * Worked calculations: the one genuinely new screen. Pick an answer, and the
 * numbered working appears, because a miss is almost always one skipped step.
 * A wrong pick that one named mistake produces says which mistake it was.
 */
@Composable
fun CalcDrillScreen(drill: Drill, scenarios: List<CalcScenario>) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    var index by rememberSaveable { mutableIntStateOf(0) }
    var selection by rememberSaveable { mutableStateOf<Int?>(null) }
    var score by rememberSaveable { mutableIntStateOf(0) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }
    var answerRect by remember { mutableStateOf<Rect?>(null) }

    if (finished) {
        DrillCompleteScreen(drill, score, scenarios.size) { navigator.pop() }
        return
    }
    val scenario = scenarios[index]
    val (labels, answerIndex) = remember(scenario.id) {
        val permutation = ChoiceShuffle.permutation(scenario.choices.size, scenario.id)
        permutation.map { scenario.choices[it] } to permutation.indexOf(scenario.answerIndex)
    }
    ElecScreen(drill.title, onBack = { navigator.pop() }) {
        DrillStage(confetti, answerRect = answerRect) {
            ChoiceQuestionBody(
                ChoiceQuestion(
                    key = scenario.id,
                    prompt = scenario.situation,
                    givens = scenario.givens,
                    labels = labels,
                    answerIndex = answerIndex,
                    explanation = scenario.steps.firstOrNull().orEmpty(),
                    missNote = { pick -> scenario.mistakes[labels[pick]]?.let { MissNote(labels[pick], it.summary) } },
                    steps = scenario.steps,
                    citation = scenario.citation,
                ),
                selection,
                nextTitle = if (index + 1 < scenarios.size) "Next Calculation" else "Finish",
                footerLabel = "Calculation ${index + 1} of ${scenarios.size}",
                onPick = { pick ->
                    if (selection != null) return@ChoiceQuestionBody
                    selection = pick
                    val correct = pick == answerIndex
                    graph.recordAnswer(scenario.id, DrillLibrary.roomID(drill.id), correct)
                    if (correct) {
                        score += 1
                        confetti += 1
                        celebrateCorrect()
                    } else {
                        scenario.mistakes[labels[pick]]?.let(graph.records::recordMistake)
                        consoleMiss()
                    }
                },
                onNext = {
                    if (index + 1 < scenarios.size) {
                        selection = null
                        index += 1
                    } else {
                        finished = true
                    }
                },
                onAnswerBounds = { answerRect = it },
            ) { DrillProgress(index, scenarios.size) }
        }
    }
}
