package com.jackwallner.electrician.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.electrician.data.Membership
import com.jackwallner.electrician.data.PaywallPlan
import com.jackwallner.electrician.data.PaywallPricing
import com.jackwallner.electrician.data.PurchaseException
import com.jackwallner.electrician.data.PurchaseOutcome
import com.jackwallner.electrician.data.StoreLinks
import com.jackwallner.electrician.content.DrillLibrary
import com.jackwallner.electrician.data.CandidateCatalog
import com.jackwallner.electrician.data.CandidateProfile
import com.jackwallner.electrician.model.Given
import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.CoachNote
import com.jackwallner.electrician.ui.components.GivenChips
import com.jackwallner.electrician.ui.components.symbol
import com.jackwallner.electrician.ui.findActivity
import com.jackwallner.electrician.ui.openUrl
import com.jackwallner.electrician.ui.theme.Haptics
import com.jackwallner.electrician.ui.theme.IconBadge
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecAlert
import com.jackwallner.electrician.ui.theme.ElecSheet
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.PrimaryCTA
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.pressable
import com.jackwallner.electrician.ui.theme.rounded
import kotlinx.coroutines.launch

private enum class Stage { STEPS, HOW_TO_PLAY, TOUR }

/** Twelve steps: three value pages, seven setup questions, a plan recap, then the trial. */
private enum class Step { OPEN_BOOK, WHAT_FAILS, WALK_IN_READY, TRACK, JURISDICTION, EDITION, EXAM_DATE, EXPERIENCE, FOCUS, REMINDER, PLAN, TRIAL;
    val isSetup: Boolean get() = this in TRACK..REMINDER
}

private data class DatePreset(val label: String, val detail: String, val days: Int?, val tolerance: Int)

private val datePresets = listOf(
    DatePreset("Tomorrow", "No time to cover everything. We will tell you what to skip.", 1, 0),
    DatePreset("Later this week", "Triage: calculations, then the mistakes you repeat.", 5, 2),
    DatePreset("In about 2 weeks", "Every problem shape twice, then the weak ones.", 14, 3),
    DatePreset("In about a month", "Enough to cover every room twice.", 30, 5),
    DatePreset("In about 3 months", "Comfortable. Build the navigation habit first.", 90, 20),
    DatePreset("No date yet", "Study now, book later. Nothing is locked by this.", null, 0),
)

/**
 * A step machine, not a pager: a pager cannot refuse a swipe, so the old
 * version let a candidate swipe past a disabled Continue into the paywall with
 * no jurisdiction set. One `step` with `canAdvance` gating it fixes that.
 * Afterwards brand-new candidates get the primer, then everyone gets the tour.
 */
@Composable
fun OnboardingScreen() {
    val graph = LocalGraph.current
    var stage by rememberSaveable { mutableStateOf(Stage.STEPS) }
    var skillLevel by rememberSaveable { mutableStateOf(graph.defaults.getString(SKILL_LEVEL).orEmpty()) }

    fun finish() {
        graph.whatsNew.markCurrentAsBaseline()
        graph.progress.sessionsAtOnboarding = graph.progress.totalSessions
        graph.progress.setOnboarded(true)
    }

    AnimatedContent(
        stage,
        transitionSpec = { (slideInHorizontally(tween(350)) { it } + fadeIn()) togetherWith fadeOut(tween(250)) },
        label = "onboarding",
    ) { current ->
        when (current) {
            Stage.STEPS -> OnboardingSteps(skillLevel, onSkill = {
                skillLevel = it
                graph.defaults.putString(SKILL_LEVEL, it)
            }, onDone = { stage = if (skillLevel == "new") Stage.HOW_TO_PLAY else Stage.TOUR })
            Stage.HOW_TO_PLAY -> HowToPlayScreen(onDone = { stage = Stage.TOUR }, onSkip = ::finish)
            Stage.TOUR -> FeatureTourScreen(onDone = ::finish)
        }
    }
}

@Composable
private fun OnboardingSteps(skillLevel: String, onSkill: (String) -> Unit, onDone: () -> Unit) {
    val graph = LocalGraph.current
    val profile = graph.candidate
    val service = graph.subscriptions
    val context = LocalContext.current
    val colors = Elec.colors
    val scope = rememberCoroutineScope()
    var step by rememberSaveable { mutableStateOf(Step.OPEN_BOOK) }
    var movingForward by remember { mutableStateOf(true) }
    var reminderChoice by rememberSaveable { mutableStateOf<Boolean?>(null) }
    var purchasing by remember { mutableStateOf(false) }
    var restoring by remember { mutableStateOf(false) }
    var showFallback by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val isPro = service.isPro
    val onTrial = step == Step.TRIAL
    val currentSkill by rememberUpdatedState(skillLevel)

    // A fresh install answers the edition question from "I'm not sure", not from the app's own edition.
    LaunchedEffect(Unit) { if (!graph.defaults.contains("candidate.edition")) profile.updateEdition("unsure") }
    LaunchedEffect(step) { if (onTrial) service.trackPaywallImpression("electrician_onboarding_trial", oncePerSession = true) }
    LaunchedEffect(isPro, showFallback) { if (isPro && showFallback) { showFallback = false; onDone() } }

    val canAdvance = when (step) {
        Step.JURISDICTION -> profile.jurisdiction.isNotEmpty()
        Step.EXPERIENCE -> currentSkill.isNotEmpty()
        Step.REMINDER -> reminderChoice != null
        else -> true
    }

    fun go(to: Step) {
        movingForward = to > step
        step = to
    }

    BackHandler(enabled = step > Step.OPEN_BOOK) { go(Step.entries[step.ordinal - 1]) }

    fun purchase() {
        if (isPro) { profile.completeSetup(); onDone(); return }
        val activity = context.findActivity() ?: return
        purchasing = true
        scope.launch {
            try {
                service.ensureOfferings()
                val monthly = service.packageFor(PaywallPlan.MONTHLY)
                if (monthly == null) { showFallback = true; return@launch }
                when (service.purchase(activity, monthly)) {
                    PurchaseOutcome.PURCHASED -> if (service.confirmEntitlement()) { profile.completeSetup(); onDone() }
                    else error = "Your purchase went through, but ${Membership.NAME} hasn't unlocked yet. Give it a moment, then tap Restore."
                    PurchaseOutcome.PENDING -> error = "Google Play is still processing your payment. ${Membership.NAME} unlocks as soon as it completes."
                    PurchaseOutcome.CANCELLED -> Unit
                }
            } catch (failure: PurchaseException) {
                error = failure.message
            } finally {
                purchasing = false
            }
        }
    }

    fun primaryAction() {
        if (!canAdvance) return
        if (step == Step.REMINDER && reminderChoice == true) {
            graph.settings.updateReminderEnabled(true)
        }
        if (step == Step.TRIAL) { purchase(); return }
        if (step == Step.PLAN) profile.completeSetup()
        go(Step.entries[step.ordinal + 1])
    }

    fun restore() {
        if (restoring || purchasing) return
        restoring = true
        scope.launch {
            try {
                service.restore()
                if (service.isPro) onDone() else error = "No previous purchase found on this Google account."
            } catch (failure: PurchaseException) {
                error = failure.message
            } finally {
                restoring = false
            }
        }
    }

    Column(Modifier.fillMaxSize().background(colors.background).statusBarsPadding().navigationBarsPadding()) {
        Readable {
            Row(Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.weight(1f).height(4.dp).background(colors.rule, rounded(2.dp))) {
                    Box(Modifier.fillMaxWidth((step.ordinal + 1f) / Step.entries.size).height(4.dp).background(colors.voltage, rounded(2.dp)))
                }
                val setup = Step.entries.filter { it.isSetup }
                Text(if (step.isSetup) "${setup.indexOf(step) + 1}/${setup.size}" else " ", style = ElecType.numeric(12.sp), color = colors.inkTertiary, modifier = Modifier.testTag("step-counter"))
            }
        }
        AnimatedContent(
            step,
            transitionSpec = {
                val dir = if (movingForward) 1 else -1
                (slideInHorizontally(tween(320)) { it * dir / 3 } + fadeIn(tween(320))) togetherWith (slideOutHorizontally(tween(320)) { -it * dir / 3 } + fadeOut(tween(200)))
            },
            modifier = Modifier.fillMaxWidth().weight(1f),
            label = "step",
        ) { shown ->
            Readable(Modifier.fillMaxSize()) {
                when (shown) {
                    Step.OPEN_BOOK -> InfoPage("book.closed.fill", colors.voltage, "The exam is open book",
                        "Which means it is not testing what you remember. It is testing how fast you find it. Short drills on where each kind of question actually lives.", emptyList())
                    Step.WHAT_FAILS -> InfoPage("thermometer.medium", colors.copper, "The problems that fail people",
                        "Derating, breaker sizing, conduit and box fill, grounding conductors, motor circuits, the whole dwelling service. Every one is a pure calculation, so we generate them forever instead of shipping the same fifty questions.",
                        listOf(Given.conductor("6 AWG", "THHN"), Given.ambient(45), Given.currentCarrying(6)))
                    Step.WALK_IN_READY -> InfoPage("checkmark.seal.fill", colors.ground, "Walk in ready",
                        "Know the small-conductor cap, size a motor off the table and not the nameplate, and stop reading Table 250.66 where 250.122 was wanted. Sitting it this week? Tell us the date and we will tell you what to skip.", emptyList())
                    Step.TRACK -> SetupStep("Which licence?", "It changes what we put in front of you first.") {
                        CandidateCatalog.tracks.forEach { track ->
                            OptionRow("track-${track.id}", track.name, track.detail, profile.licenseTrack == track.id) { profile.updateTrack(track.id) }
                        }
                        Text(profile.track.emphasis, style = ElecType.footnote, color = colors.inkSecondary)
                    }
                    Step.JURISDICTION -> JurisdictionStep(profile)
                    Step.EDITION -> SetupStep("Which code edition?", "Exams are written against one cycle. This app's numbers are ${NECTables.edition}, and we would rather tell you where that differs than let you find out in the exam.") {
                        CandidateCatalog.editions.forEach { edition ->
                            OptionRow("edition-${edition.id}", edition.name, null, profile.edition == edition.id) { profile.updateEdition(edition.id) }
                        }
                        val chosen = CandidateCatalog.editions.firstOrNull { it.id == profile.edition }
                        val suggestion = profile.jurisdictionRecord?.commonEdition
                        val note = if (chosen?.id == "unsure" && suggestion != null) "${profile.jurisdictionRecord?.name} commonly adopts the $suggestion NEC. Checked ${CandidateCatalog.reviewed}; confirm with ${profile.jurisdictionRecord?.authority}." else chosen?.note
                        note?.let { CoachNote(it) }
                    }
                    Step.EXAM_DATE -> SetupStep("When is the exam?", "The date changes what we put in front of you, not just what the countdown says. Sitting it this week gets a different plan from sitting it in the spring. You can skip it.") {
                        datePresets.forEach { preset ->
                            val days = profile.daysUntilExam
                            val selected = if (preset.days == null) profile.examDate == null && graph.defaults.contains("candidate.examDateAnswered")
                            else days != null && kotlin.math.abs(days - preset.days) <= preset.tolerance
                            OptionRow("date-${preset.days ?: "none"}", preset.label, preset.detail, selected) {
                                graph.defaults.putBoolean("candidate.examDateAnswered", true)
                                profile.updateExamDate(preset.days?.let { graph.clock.today().plusDays(it.toLong()) })
                            }
                        }
                        if (profile.daysUntilExam != null) StudyPaceCard(profile)
                    }
                    Step.EXPERIENCE -> SetupStep("Where are you starting from?", "This decides which room we open first and whether you get the primer.") {
                        CandidateCatalog.experience.forEach { level ->
                            OptionRow("skill-${level.id}", level.title, level.detail, skillLevel == level.id) { onSkill(level.id) }
                        }
                    }
                    Step.FOCUS -> SetupStep("What do you want to hit hardest?", "Pick as many as you like, or none. We surface these first on Home; everything stays available either way.") {
                        DrillLibrary.rooms.forEach { room ->
                            OptionRow("focus-${room.id}", room.name, room.tagline, room.id in profile.focusAreas, multi = true) { profile.toggleFocus(room.id) }
                        }
                    }
                    Step.REMINDER -> SetupStep("One nudge a day?", "Code Minute is five questions. The candidates who pass are the ones who did it on the days they did not feel like it.") {
                        OptionRow("reminder-yes", "Remind me daily", "One notification, at a time you choose", reminderChoice == true) { reminderChoice = true }
                        OptionRow("reminder-no", "No reminders", "You can switch this on later in Settings", reminderChoice == false) { reminderChoice = false }
                    }
                    Step.PLAN -> SetupStep("Your plan", "Change any of it later in Settings.") {
                        PlanRow("Licence", profile.track.name)
                        PlanRow("Jurisdiction", profile.jurisdictionRecord?.name ?: "Not set")
                        PlanRow("Code edition", profile.resolvedEdition?.let { "$it NEC" } ?: "Not sure yet")
                        PlanRow("Exam date", profile.countdownText ?: "No date yet", "${profile.pace.title}: ${profile.suggestedDailyQuestions} questions a day.")
                        PlanRow("Starting from", CandidateCatalog.experience.firstOrNull { it.id == skillLevel }?.title ?: "Not set")
                        PlanRow("Focus", DrillLibrary.rooms.filter { it.id in profile.focusAreas }.joinToString { it.name }.ifEmpty { "Everything, in order" })
                        StudyPaceCard(profile)
                    }
                    Step.TRIAL -> TrialPage(offersTrial = !isPro && service.offersFreeTrial(PaywallPlan.MONTHLY))
                }
            }
        }
        Readable {
            Column(
                Modifier.padding(horizontal = 24.dp).padding(bottom = 10.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (onTrial && !isPro) {
                    Text(
                        "Not now",
                        style = ElecType.subheadline.copy(fontWeight = FontWeight.Medium),
                        color = colors.inkSecondary,
                        modifier = Modifier.testTag("soft-exit").pressable(enabled = !purchasing && !restoring) { onDone() }.padding(horizontal = 12.dp, vertical = 4.dp),
                    )
                    Text(PaywallPricing.priceText(service, PaywallPlan.MONTHLY), style = ElecType.display(22.sp), color = colors.ink)
                    Text(PaywallPricing.terms(service, PaywallPlan.MONTHLY), style = ElecType.caption2, color = colors.inkTertiary, textAlign = TextAlign.Center)
                }
                PrimaryCTA(
                    when {
                        !onTrial || isPro -> if (step == Step.EXAM_DATE && profile.examDate == null) "Continue" else "Continue"
                        service.offersFreeTrial(PaywallPlan.MONTHLY) -> "Start 7-day free trial"
                        else -> "Subscribe"
                    },
                    Modifier.testTag("onboarding-primary"),
                    enabled = canAdvance && !purchasing && !restoring,
                    loading = purchasing || restoring,
                    dimmed = !canAdvance,
                    onClick = { primaryAction() },
                )
                if (onTrial && !isPro) {
                    Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
                        val active = !purchasing && !restoring
                        LegalLink("Terms", active) { context.openUrl(StoreLinks.TERMS_URL) }
                        LegalLink("Privacy", active) { context.openUrl(StoreLinks.PRIVACY_URL) }
                        LegalLink("Restore", active) { restore() }
                    }
                }
            }
        }
    }
    ElecSheet(showFallback, onDismiss = { showFallback = false }) {
        PaywallSheet("electrician_onboarding_fallback", onClose = { showFallback = false })
    }
    error?.let { ElecAlert("Electrician", it, onConfirm = { error = null }) }
}

@Composable
private fun LegalLink(text: String, enabled: Boolean, onClick: () -> Unit) {
    Text(text, style = ElecType.caption2, color = Elec.colors.inkTertiary, modifier = Modifier.pressable(enabled = enabled, onClick = onClick).padding(4.dp))
}

@Composable
private fun InfoPage(icon: String, tint: Color, title: String, body: String, givens: List<Given>) {
    val colors = Elec.colors
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 28.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(26.dp, Alignment.CenterVertically),
    ) {
        IconBadge(icon, tint, size = 96.dp, iconSize = 40.dp, alpha = 0.12f)
        Text(title, style = ElecType.display(32.sp), color = colors.ink, textAlign = TextAlign.Center)
        GivenChips(givens)
        Text(body, style = ElecType.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
    }
}

/** Shared chrome so all seven setup steps line up: same title position, same subtitle voice. */
@Composable
private fun SetupStep(title: String, subtitle: String, content: @Composable ColumnScope.() -> Unit) {
    val colors = Elec.colors
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 24.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, style = ElecType.display(30.sp), color = colors.ink)
        Text(subtitle, style = ElecType.subheadline, color = colors.inkSecondary, modifier = Modifier.padding(bottom = 8.dp))
        content()
        Spacer(Modifier.height(12.dp))
    }
}

@Composable
private fun OptionRow(tag: String, title: String, detail: String?, selected: Boolean, multi: Boolean = false, onSelect: () -> Unit) {
    val colors = Elec.colors
    val shape = rounded(16.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .testTag(tag)
            .semantics { this.selected = selected }
            .pressable {
                Haptics.light()
                onSelect()
            }
            .background(if (selected) colors.voltage.copy(alpha = 0.08f) else colors.card, shape)
            .border(if (selected) 2.dp else 1.dp, if (selected) colors.voltage else colors.rule, shape)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, style = ElecType.headline, color = colors.ink)
            detail?.let { Text(it, style = ElecType.subheadline, color = colors.inkSecondary) }
        }
        Icon(
            symbol(if (selected) "checkmark.circle.fill" else "circle"),
            null,
            tint = if (selected) colors.voltage else colors.inkTertiary,
            modifier = Modifier.size(24.dp),
        )
    }
}

@Composable
private fun JurisdictionStep(profile: CandidateProfile) {
    val colors = Elec.colors
    var query by rememberSaveable { mutableStateOf("") }
    val matches = CandidateCatalog.jurisdictions.filter { query.isBlank() || it.name.contains(query.trim(), ignoreCase = true) || it.id.equals(query.trim(), ignoreCase = true) }
    SetupStep("Where are you sitting it?", "We use this to work out which code edition your exam is written against, and who actually issues your licence.") {
        BasicTextField(
            query,
            { query = it },
            singleLine = true,
            textStyle = ElecType.body.copy(color = colors.ink),
            cursorBrush = SolidColor(colors.voltage),
            modifier = Modifier.fillMaxWidth().testTag("jurisdiction-search").background(colors.well, rounded(12.dp)).padding(14.dp),
            decorationBox = { inner -> Box { if (query.isEmpty()) Text("Search states", style = ElecType.body, color = colors.inkTertiary); inner() } },
        )
        profile.jurisdictionRecord?.let { record ->
            CoachNote(buildString {
                append("${record.name}: ")
                append(record.commonEdition?.let { "commonly adopted $it NEC. " } ?: "edition set locally. ")
                record.examProvider?.let { append("Exams usually through $it. ") }
                append("Checked ${CandidateCatalog.reviewed}. Adoption and vendors change, and local amendments are common. Confirm with ${record.authority} before you rely on it.")
            })
        }
        if (matches.isEmpty()) Text("No match. Choose ${CandidateCatalog.other.name} and set your edition by hand on the next step.", style = ElecType.footnote, color = colors.inkSecondary)
        (matches + CandidateCatalog.other).forEach { record ->
            OptionRow("jurisdiction-${record.id}", record.name, null, profile.jurisdiction == record.id) { profile.updateJurisdiction(record.id) }
        }
    }
}

@Composable
private fun PlanRow(label: String, value: String, detail: String? = null) {
    val colors = Elec.colors
    Column(Modifier.fillMaxWidth().background(colors.card, rounded(14.dp)).border(1.dp, colors.rule, rounded(14.dp)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(label.uppercase(), style = ElecType.eyebrow, color = colors.inkTertiary)
        Text(value, style = ElecType.headline, color = colors.ink)
        detail?.let { Text(it, style = ElecType.footnote, color = colors.inkSecondary) }
    }
}

/** The plan the exam date implies: shown in setup, in the recap and on Home while urgent. */
@Composable
fun StudyPaceCard(profile: CandidateProfile, modifier: Modifier = Modifier) {
    val colors = Elec.colors
    val pace = profile.pace
    val tint = if (pace.isUrgent) colors.copper else colors.voltage
    Column(
        modifier.fillMaxWidth().background(tint.copy(alpha = 0.08f), rounded(16.dp)).border(1.dp, tint.copy(alpha = 0.3f), rounded(16.dp)).padding(16.dp).testTag("study-pace"),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(pace.title, style = ElecType.display(20.sp), color = tint, modifier = Modifier.weight(1f))
            Text("${profile.suggestedDailyQuestions}/day", style = ElecType.numeric(14.sp, FontWeight.Bold), color = tint)
        }
        Text(pace.summary, style = ElecType.subheadline, color = colors.ink)
        pace.priorities.forEachIndexed { index, line ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("${index + 1}.", style = ElecType.numeric(13.sp, FontWeight.Bold), color = tint)
                Text(line, style = ElecType.footnote, color = colors.inkSecondary)
            }
        }
    }
}

@Composable
private fun TrialPage(offersTrial: Boolean) {
    val colors = Elec.colors
    val free = DrillLibrary.freeItemCount
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 28.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(22.dp, Alignment.CenterVertically),
    ) {
        IconBadge("sparkles", colors.brass, size = 92.dp, iconSize = 42.dp, alpha = 0.14f)
        Text(if (offersTrial) "Try ${Membership.NAME} free" else "Get ${Membership.NAME}", style = ElecType.display(30.sp), color = colors.ink, textAlign = TextAlign.Center)
        Text("The free rooms hold $free questions. The calculations that fail people never run out here.", style = ElecType.subheadline, color = colors.inkSecondary, textAlign = TextAlign.Center)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            listOf(
                "Endless calculations: derating, breakers, fill, grounding, motors, services",
                "Fix My Mistakes targets the errors you repeat",
                "Code Minute and a timed exam warm-up",
                DrillLibrary.rooms.filter { !it.isFree }.joinToString(", ") { it.name } + ", with extra sets in every room",
                DrillLibrary.rooms.filter { it.isFree }.joinToString(", ") { it.name } + " and all eight Field Tools stay free",
            ).forEach { line ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(symbol("checkmark.circle.fill"), null, tint = colors.voltage, modifier = Modifier.size(20.dp))
                    Text(line, style = ElecType.subheadline, color = colors.ink)
                }
            }
        }
    }
}
