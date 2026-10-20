package com.jackwallner.electrician.ui.screens

import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.data.CandidateCatalog
import com.jackwallner.electrician.data.CandidateProfile
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.electrician.content.DrillLibrary
import com.jackwallner.electrician.content.SessionBuilder
import com.jackwallner.electrician.data.MasteryLevel
import com.jackwallner.electrician.data.Membership
import com.jackwallner.electrician.data.RoomMastery
import com.jackwallner.electrician.model.Room
import com.jackwallner.electrician.ui.LocalAppActions
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.symbol
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.nav.PracticeMode
import com.jackwallner.electrician.ui.nav.Route
import com.jackwallner.electrician.ui.nav.SessionPurpose
import com.jackwallner.electrician.ui.theme.BarIconButton
import com.jackwallner.electrician.ui.theme.Eyebrow
import com.jackwallner.electrician.ui.theme.IconBadge
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecColors
import com.jackwallner.electrician.ui.theme.ElecGeo
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.PlusBadge
import com.jackwallner.electrician.ui.theme.voltageGradient
import com.jackwallner.electrician.ui.theme.navBarPadding
import com.jackwallner.electrician.ui.theme.pressable
import com.jackwallner.electrician.ui.theme.rounded
import com.jackwallner.electrician.ui.theme.themedCard
import java.time.LocalDate
import kotlinx.coroutines.delay

/** Every room id that claims an accent. A room missing here fails `ShellContentTest`, never inherits a colour. */
val ROOM_ACCENT_IDS = setOf("basics-room", "conductors-room", "install-room", "calc-room", "loads-room", "grounding-room")

/** Room identity: each room keeps its own accent so the doors feel like places. */
fun Room.accent(colors: ElecColors): Color = when (id) {
    "basics-room" -> colors.voltage
    "conductors-room" -> colors.copper
    "install-room" -> colors.highLeg
    "calc-room" -> colors.conduit
    "loads-room" -> colors.service
    "grounding-room" -> colors.ground
    else -> colors.brass
}

/**
 * Home is the lobby: Get Started, the training modes, then the rooms as
 * doors. Everything that is not a room earns its space or leaves.
 */
@Composable
fun HomeScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val colors = Elec.colors
    val progress = graph.progress
    val isPro = graph.subscriptions.isPro
    val scroll = rememberScrollState()
    var highlightedRoom by remember { mutableStateOf<String?>(null) }
    val roomOffsets = remember { mutableMapOf<String, Int>() }

    // The one-shot hint the primer leaves: scroll to and briefly ring the recommended room.
    LaunchedEffect(Unit) {
        val hint = graph.defaults.getString(RECOMMENDED_ROOM_HINT).orEmpty()
        if (hint.isEmpty()) return@LaunchedEffect
        graph.defaults.remove(RECOMMENDED_ROOM_HINT)
        if (DrillLibrary.room(hint) == null) return@LaunchedEffect
        delay(400)
        roomOffsets[hint]?.let { scroll.animateScrollTo((it - 200).coerceAtLeast(0)) }
        highlightedRoom = hint
        delay(2_200)
        highlightedRoom = null
    }

    Column(Modifier.fillMaxSize().background(colors.background)) {
        Row(
            Modifier.fillMaxWidth().statusBarsPadding().height(52.dp).padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BarIconButton("wrench.and.screwdriver.fill", "Field tools") { navigator.push(Route.FieldTools) }
            Spacer(Modifier.weight(1f))
            BarIconButton("gearshape", "Settings") { navigator.push(Route.Settings) }
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(scroll).padding(horizontal = 16.dp).padding(navBarPadding()),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Header(graph.candidate, progress.streakCount, progress.totalSessions) { navigator.push(Route.Stats) }
            ExamTargetCard(graph.candidate)
            if (graph.candidate.daysUntilExam != null && graph.candidate.pace.isUrgent) StudyPaceCard(graph.candidate)
            if (progress.quickSessionCompletedToday()) GetStartedDoneCard() else GetStartedCard {
                val items = SessionBuilder.quickSession(seen = progress.seenItems, missed = progress.missedItems, includePro = isPro)
                navigator.push(Route.Session(items, SessionPurpose.Quick(isDaily = true)))
            }
            val skillLevel = graph.defaults.getString(SKILL_LEVEL).orEmpty()
            if (skillLevel == "new" && !graph.defaults.getBoolean(HAS_READ_PRIMER)) {
                HowToPlayCard { navigator.push(Route.HowToPlay) }
            }
            TrainingSection(isPro, onLocked = { actions.openPaywall("electrician_home_sheet") })
            Row(Modifier.padding(top = 6.dp, start = 4.dp)) { Eyebrow("THE ROOMS") }
            // Focus areas order the rooms (an ordering, never a filter).
            DrillLibrary.rooms.sortedBy { if (it.id in graph.candidate.focusAreas) 0 else 1 }.forEach { room ->
                Box(Modifier.onGloballyPositioned { roomOffsets[room.id] = it.positionInParent().y.toInt() }) {
                    RoomCard(
                        room = room,
                        locked = !room.isFree && !isPro,
                        mastery = graph.records.mastery(room, isPro),
                        highlighted = highlightedRoom == room.id,
                    ) { navigator.push(Route.Room(room.id)) }
                }
            }
            if (!isPro) UpgradeCard { actions.openPaywall("electrician_home_sheet") }
            Text(
                "Built on the ${NECTables.edition}, and every table here is unchanged across the ${NECTables.coverageLabel}. A study aid, not a code book. Not affiliated with or endorsed by the NFPA. Concepts and calculations in original wording, with article numbers so you can verify each one in the code in force where you work.",
                style = ElecType.caption2,
                color = colors.inkTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
            )
        }
    }
}

const val SKILL_LEVEL = "electrician.skillLevel"
const val HAS_READ_PRIMER = "electrician.hasReadPrimer"
const val RECOMMENDED_ROOM_HINT = "electrician.recommendedRoomHint"

@Composable
private fun Header(profile: CandidateProfile, streak: Int, sessions: Int, onStats: () -> Unit) {
    val colors = Elec.colors
    // The licence track titles the header once setup says what the candidate is here to do.
    val title = if (profile.setupComplete) "${profile.track.name} Prep" else "Exam Prep"
    val place = profile.jurisdictionRecord?.takeIf { it.id != CandidateCatalog.other.id }?.name
    val subtitle = if (profile.setupComplete && place != null) "${profile.editionShortSummary} · $place" else "Code navigation and calculations"
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, style = ElecType.display(32.sp), color = colors.ink, modifier = Modifier.testTag("home-title"))
            Text(subtitle, style = ElecType.subheadline, color = colors.inkSecondary)
        }
        Row(
            Modifier.pressable(label = "Opens your progress breakdown", onClick = onStats),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            StatChip(streak, "flame.fill", colors.copper, "$streak day streak")
            StatChip(sessions, "checkmark.seal.fill", colors.voltage, "$sessions drills done")
        }
    }
}

@Composable
private fun StatChip(value: Int, icon: String, color: Color, label: String) {
    Row(
        Modifier.background(color.copy(alpha = 0.12f), CircleShape).padding(horizontal = 9.dp, vertical = 6.dp).semantics(mergeDescendants = true) {
            contentDescription = label
        },
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(symbol(icon), null, tint = color, modifier = Modifier.size(14.dp))
        Text("$value", style = ElecType.subheadline.copy(fontWeight = FontWeight.Bold), color = Elec.colors.ink)
    }
}

/** The exam date keeps paying off after onboarding: countdown, pace and the daily number. */
@Composable
private fun ExamTargetCard(profile: CandidateProfile) {
    val days = profile.daysUntilExam ?: return
    val colors = Elec.colors
    Row(
        Modifier.fillMaxWidth().themedCard(16.dp).padding(12.dp).testTag("exam-target"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.size(46.dp).background(colors.voltage.copy(alpha = 0.12f), rounded(12.dp)), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text("$days", style = ElecType.numeric(20.sp, FontWeight.Bold), color = colors.voltage)
            Text(if (days == 1) "day" else "days", style = ElecType.caption2.copy(fontWeight = FontWeight.SemiBold), color = colors.inkTertiary)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(if (profile.setupComplete) "${profile.track.name} · ${profile.jurisdictionRecord?.name.orEmpty()}" else "Set your exam target", style = ElecType.display(17.sp), color = colors.ink)
            Text("${profile.editionShortSummary} · ${profile.pace.title}. Target ${profile.suggestedDailyQuestions} questions a day.", style = ElecType.caption, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun GetStartedCard(onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("get-started")
            .pressable(onClick = onClick)
            .background(voltageGradient(), rounded(ElecGeo.cardCorner))
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Get Started", style = ElecType.display(24.sp), color = Color.White)
            Text("A five-minute mix of what you need next", style = ElecType.subheadline, color = Color.White.copy(alpha = 0.85f))
        }
        Icon(symbol("play.circle.fill"), null, tint = Color.White, modifier = Modifier.size(44.dp))
    }
}

/** Today's Get Started is spent; the card rests until tomorrow. */
@Composable
private fun GetStartedDoneCard() {
    val colors = Elec.colors
    Row(
        Modifier.fillMaxWidth().themedCard().padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge("checkmark.circle.fill", colors.voltage, size = 44.dp, iconSize = 28.dp, alpha = 0.12f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text("Today's session is done", style = ElecType.headline, color = colors.ink)
            Text("A fresh mix lands tomorrow. Keep going in any room below.", style = ElecType.subheadline, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun HowToPlayCard(onClick: () -> Unit) {
    val colors = Elec.colors
    Row(
        Modifier.fillMaxWidth().pressable(onClick = onClick).themedCard(16.dp).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("book.fill", colors.brass, corner = 12.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("How the Exam Works", style = ElecType.headline, color = colors.ink)
            Text("New here? Start with the five-minute primer", style = ElecType.caption, color = colors.inkSecondary)
        }
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
    }
}

/** The cross-cutting practice modes in one scrolling row of compact tiles. */
@Composable
private fun TrainingSection(isPro: Boolean, onLocked: () -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    val records = graph.records
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Eyebrow("TRAINING")
            Spacer(Modifier.weight(1f))
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                Text("SWIPE FOR MORE", style = ElecType.caption2.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 1.1.sp), color = colors.inkTertiary)
                Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(12.dp))
            }
        }
        Row(
            Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 4.dp, vertical = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            // Field Tools are free for everyone: the calculators a working electrician looks up.
            TrainingTile("Field\nTools", "wrench.and.screwdriver.fill", colors.voltage, "Free", locked = false, tag = "tile-field-tools") {
                navigator.push(Route.FieldTools)
            }
            TrainingTile("Endless\nPractice", "infinity", colors.voltage, null, locked = !isPro, tag = "tile-endless") {
                if (isPro) navigator.push(Route.EndlessPicker) else onLocked()
            }
            val minute = graph.minutes.result(LocalDate.now())
            TrainingTile(
                "Code\nMinute", "calendar.badge.clock", colors.copper,
                minute?.let { "${it.score}/${it.total} today" } ?: "Daily", locked = !isPro, tag = "tile-minute",
            ) { if (isPro) navigator.push(Route.CodeMinute) else onLocked() }
            TrainingTile(
                "Exam\nWarm-Up", "person.2.fill", colors.service,
                if (graph.settings.gameNightReminderEnabled) graph.settings.gameNightDay.displayName else "Weekly",
                locked = !isPro, tag = "tile-game-night",
            ) { if (isPro) navigator.push(Route.GameNightPrep) else onLocked() }
            TrainingTile(
                "Timed\nChallenge", "timer", colors.copper,
                if (records.bestChallengeScore > 0) "Best ${records.bestChallengeScore}" else null, locked = !isPro, tag = "tile-timed",
            ) { if (isPro) navigator.push(Route.Practice(PracticeMode.Timed)) else onLocked() }
            // Only offered when there is something the runner can actually ask.
            val reviewable = SessionBuilder.reviewableIDs(isPro)
            val due = records.dueCount(reviewable) + records.outstandingMistakeCount
            if (due > 0) {
                TrainingTile("Fix My\nMistakes", "arrow.trianglehead.counterclockwise", colors.service, "$due due", locked = !isPro, tag = "tile-review") {
                    if (!isPro) {
                        onLocked()
                    } else {
                        navigator.push(Route.Practice(PracticeMode.Review, graph.fixMyMistakesItems(isPro)))
                    }
                }
            }
        }
    }
}

@Composable
private fun TrainingTile(title: String, icon: String, color: Color, badge: String?, locked: Boolean, tag: String, onClick: () -> Unit) {
    val colors = Elec.colors
    Column(
        Modifier
            .width(128.dp)
            .height(118.dp)
            .testTag(tag)
            .pressable(label = if (locked) "Included with ${Membership.NAME}" else null, onClick = onClick)
            .themedCard(16.dp)
            .padding(12.dp),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(symbol(icon), null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(Modifier.weight(1f))
            if (locked) Icon(symbol("lock.fill"), null, tint = colors.brass, modifier = Modifier.size(12.dp))
        }
        Spacer(Modifier.weight(1f))
        Text(title, style = ElecType.subheadline.copy(fontWeight = FontWeight.Bold), color = colors.ink)
        Text(
            badge ?: if (locked) Membership.NAME else " ",
            style = ElecType.caption2.copy(fontWeight = FontWeight.SemiBold),
            color = if (badge != null) color else colors.brass,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun RoomCard(room: Room, locked: Boolean, mastery: RoomMastery, highlighted: Boolean, onClick: () -> Unit) {
    val colors = Elec.colors
    val accent = room.accent(colors)
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("room-${room.id}")
            .pressable(
                label = if (locked) "Locked. ${room.drills.size} drills, included with ${Membership.NAME}"
                else "${mastery.level.title}. ${mastery.known} of ${mastery.total} questions solid",
                onClick = onClick,
            )
            .themedCard()
            .border(2.5.dp, if (highlighted) accent else Color.Transparent, rounded(ElecGeo.cardCorner))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge(room.icon, accent, size = 48.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(room.name, style = ElecType.headline, color = colors.ink)
                if (locked) PlusBadge()
            }
            Text(room.tagline, style = ElecType.subheadline, color = colors.inkSecondary, maxLines = 2)
        }
        if (locked) Icon(symbol("lock.fill"), null, tint = colors.brass, modifier = Modifier.size(16.dp))
        else MasteryRing(mastery, accent)
    }
}

/** Room mastery at a glance: a ring that fills as questions start holding. */
@Composable
fun MasteryRing(mastery: RoomMastery, color: Color) {
    val colors = Elec.colors
    val fraction by animateFloatAsState(mastery.fraction.toFloat(), spring(dampingRatio = 0.8f, stiffness = 200f), label = "ring")
    Column(Modifier.width(46.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Box(Modifier.size(32.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                val stroke = 3.dp.toPx()
                val inset = stroke / 2
                val arcSize = Size(size.width - stroke, size.height - stroke)
                drawArc(color.copy(alpha = 0.18f), 0f, 360f, false, Offset(inset, inset), arcSize, style = Stroke(stroke))
                if (fraction > 0f) {
                    drawArc(color, -90f, 360f * fraction, false, Offset(inset, inset), arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
                }
            }
            when (mastery.level) {
                MasteryLevel.SHARP -> Icon(symbol("star.fill"), null, tint = color, modifier = Modifier.size(12.dp))
                MasteryLevel.UNTOUCHED -> Unit
                else -> Text(
                    "${(mastery.fraction * 100).toInt()}",
                    style = ElecType.caption2.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
                    color = colors.inkSecondary,
                )
            }
        }
        Text(
            if (mastery.level == MasteryLevel.UNTOUCHED) "New" else mastery.level.title,
            style = ElecType.caption2.copy(fontSize = 9.sp, fontWeight = FontWeight.SemiBold),
            color = colors.inkTertiary,
        )
    }
}

@Composable
private fun UpgradeCard(onClick: () -> Unit) {
    val colors = Elec.colors
    val locked = DrillLibrary.rooms.sumOf { it.plusDrillCount }
    Row(
        Modifier
            .fillMaxWidth()
            .padding(top = 2.dp)
            .pressable(onClick = onClick)
            .themedCard(16.dp)
            .border(1.dp, colors.brass.copy(alpha = 0.35f), rounded(16.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("sparkles", colors.brass, alpha = 0.14f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("Get ${Membership.NAME}", style = ElecType.headline, color = colors.ink)
            Text(
                "Code Minute, Exam Warm-Up, endless modes, and $locked more drills across every room",
                style = ElecType.caption,
                color = colors.inkSecondary,
            )
        }
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
    }
}
