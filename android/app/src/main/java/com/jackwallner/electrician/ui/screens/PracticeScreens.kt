package com.jackwallner.electrician.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.electrician.content.DrillLibrary
import com.jackwallner.electrician.content.PracticeSkill
import com.jackwallner.electrician.content.SessionBuilder
import com.jackwallner.electrician.data.MasteryLevel
import com.jackwallner.electrician.data.PracticeRecordStore
import com.jackwallner.electrician.data.RoomMastery
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.symbol
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.nav.PracticeMode
import com.jackwallner.electrician.ui.nav.Route
import com.jackwallner.electrician.ui.nav.SessionPurpose
import com.jackwallner.electrician.ui.theme.CapsuleBar
import com.jackwallner.electrician.ui.theme.DayPickerRow
import com.jackwallner.electrician.ui.theme.ElecSwitch
import com.jackwallner.electrician.ui.theme.TimePickerRow
import com.jackwallner.electrician.ui.theme.Eyebrow
import com.jackwallner.electrician.ui.theme.IconBadge
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecScreen
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.PrimaryCTA
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.navBarPadding
import com.jackwallner.electrician.ui.theme.pressable
import com.jackwallner.electrician.ui.theme.rounded
import com.jackwallner.electrician.ui.theme.themedCard
import kotlin.math.roundToInt

private fun percent(fraction: Double) = "${(fraction * 100).roundToInt()}%"

/** One tap between Home and the first dealt hand. */
@Composable
fun EndlessPickerScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    ElecScreen("Endless Practice", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    Modifier.fillMaxWidth().padding(top = 12.dp).background(colors.voltage.copy(alpha = 0.10f), rounded(16.dp)).padding(14.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Icon(symbol("infinity"), null, tint = colors.voltage, modifier = Modifier.size(20.dp))
                    Text(
                        "Every calculation here is generated the moment you see it, from the same tables the exam uses, so you can practise for as long as you like without repeating a question.",
                        style = ElecType.subheadline,
                        color = colors.inkSecondary,
                    )
                }
                PracticeSkill.endlessCases.forEach { skill ->
                    val record = graph.records.records[skill.raw]
                    Row(
                        Modifier.fillMaxWidth().testTag("skill-${skill.raw}").pressable {
                            navigator.push(Route.Practice(PracticeMode.Endless(skill)))
                        }.themedCard().padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        IconBadge(skill.icon, colors.voltage, size = 48.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text(skill.title, style = ElecType.headline, color = colors.ink)
                            Text(skill.subtitle, style = ElecType.subheadline, color = colors.inkSecondary)
                            if (record != null && record.attempts > 0) {
                                Text("${percent(record.accuracy)} across ${record.attempts} answered", style = ElecType.caption2, color = colors.inkTertiary)
                            }
                        }
                        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
    }
}

/** Practice history: accuracy, mastery, and the room worth working on next. Free for everyone. */
@Composable
fun StatsScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    val records = graph.records
    val isPro = graph.subscriptions.isPro
    val roomStats = records.roomStats()
    ElecScreen("Your Progress", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                if (records.totalAttempts == 0) {
                    Column(
                        Modifier.fillMaxWidth().padding(top = 12.dp).themedCard().padding(28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(symbol("chart.bar.fill"), null, tint = colors.voltage.copy(alpha = 0.5f), modifier = Modifier.size(40.dp))
                        Text("No practice yet", style = ElecType.headline, color = colors.ink)
                        Text(
                            "Answer a few questions and your accuracy for every room shows up here.",
                            style = ElecType.subheadline,
                            color = colors.inkSecondary,
                            textAlign = TextAlign.Center,
                        )
                    }
                } else {
                    Row(Modifier.fillMaxWidth().padding(top = 12.dp).themedCard().padding(vertical = 18.dp), verticalAlignment = Alignment.CenterVertically) {
                        StatMetric(percent(records.overallAccuracy), "accuracy", colors.voltage, Modifier.weight(1f))
                        Divider()
                        StatMetric("${records.totalAttempts}", "answered", colors.ink, Modifier.weight(1f))
                        Divider()
                        StatMetric("${records.bestChallengeScore}", "best challenge", colors.copper, Modifier.weight(1f))
                    }
                    val focus = records.roomToWorkOn(isPro)
                    val weakest = records.weakestRoom()
                    if (focus != null) {
                        val room = DrillLibrary.room(focus.roomID)
                        FocusCard("Work on ${room?.name ?: "this room"}", "${focus.known} of ${focus.total} questions are holding. ${focus.level.nextStep}")
                    } else if (weakest != null && roomStats.size > 1) {
                        FocusCard("Work on ${weakest.name}", "${percent(weakest.accuracy)} right across ${weakest.attempts} questions, your lowest so far.")
                    }
                    MasteryBreakdown(records.masteryByRoom(isPro).filter { it.total > 0 })
                    AccuracyBreakdown(roomStats)
                }
                Row(
                    Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    IconBadge("flame.fill", colors.copper)
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text("${graph.progress.streakCount}-day streak", style = ElecType.headline, color = colors.ink)
                        val sessions = graph.progress.totalSessions
                        Text("$sessions drill${if (sessions == 1) "" else "s"} finished", style = ElecType.caption, color = colors.inkSecondary)
                    }
                }
            }
        }
    }
}

@Composable
private fun Divider() {
    Box(Modifier.width(1.dp).height(34.dp).background(Elec.colors.rule))
}

@Composable
private fun StatMetric(value: String, caption: String, color: Color, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, style = ElecType.display(26.sp), color = color)
        Text(caption, style = ElecType.caption, color = Elec.colors.inkSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun FocusCard(title: String, body: String) {
    val colors = Elec.colors
    Row(
        Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("target", colors.copper)
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = ElecType.headline, color = colors.ink)
            Text(body, style = ElecType.caption, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun levelColor(level: MasteryLevel): Color {
    val colors = Elec.colors
    return when (level) {
        MasteryLevel.UNTOUCHED -> colors.inkTertiary
        MasteryLevel.LEARNING -> colors.copper
        MasteryLevel.SOLID -> colors.brass
        MasteryLevel.SHARP -> colors.rightGreen
    }
}

@Composable
private fun MasteryBreakdown(masteries: List<RoomMastery>) {
    val colors = Elec.colors
    Column(Modifier.fillMaxWidth().themedCard().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Eyebrow("WHAT IS HOLDING")
        Text(
            "A question counts here once you have answered it right twice in a row, and drops off if you leave it long enough to go rusty.",
            style = ElecType.caption,
            color = colors.inkTertiary,
        )
        masteries.forEach { mastery ->
            val room = DrillLibrary.room(mastery.roomID) ?: return@forEach
            val tint = levelColor(mastery.level)
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(room.name, style = ElecType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                    Icon(symbol(mastery.level.icon), null, tint = tint, modifier = Modifier.size(12.dp))
                    Text(" ${mastery.level.title}", style = ElecType.caption.copy(fontWeight = FontWeight.Bold), color = tint)
                }
                CapsuleBar(mastery.fraction.toFloat(), tint)
                Text("${mastery.known} of ${mastery.total} questions solid", style = ElecType.caption2, color = colors.inkTertiary)
            }
        }
    }
}

@Composable
private fun AccuracyBreakdown(stats: List<PracticeRecordStore.RoomStat>) {
    val colors = Elec.colors
    Column(Modifier.fillMaxWidth().themedCard().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Eyebrow("ACCURACY")
        stats.forEach { stat ->
            val tint = when {
                stat.accuracy >= 0.8 -> colors.rightGreen
                stat.accuracy >= 0.6 -> colors.brass
                else -> colors.copper
            }
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row {
                    Text(stat.name, style = ElecType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                    Text(percent(stat.accuracy), style = ElecType.subheadline.copy(fontWeight = FontWeight.Bold), color = tint)
                }
                CapsuleBar(stat.accuracy.toFloat(), tint)
                Text("${stat.correct} of ${stat.attempts} right", style = ElecType.caption2, color = colors.inkTertiary)
            }
        }
    }
}

/** The weekly game-night reminder and the personalised prep session. */
@Composable
fun GameNightPrepScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    val settings = graph.settings
    val records = graph.records
    val reviewable = SessionBuilder.reviewableIDs(true)
    ElecScreen("Exam Warm-Up", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(
                    Modifier.fillMaxWidth().themedCard().padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    IconBadge("person.2.fill", colors.service, size = 68.dp, iconSize = 30.dp)
                    Text("Walk in ready", style = ElecType.display(28.sp), color = colors.ink)
                    Text(
                        "Pick a day to study. The reminder opens a fresh session built from your mistakes, weakest room, and material you have not seen yet.",
                        style = ElecType.subheadline,
                        color = colors.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
                Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Eyebrow("WEEKLY REMINDER")
                            Text(
                                if (settings.gameNightReminderEnabled) "Prep is scheduled" else "Choose your study day",
                                style = ElecType.headline,
                                color = colors.ink,
                            )
                        }
                        ElecSwitch(settings.gameNightReminderEnabled, "Weekly warm-up reminder") { on ->
                            if (on) requestNotifications { settings.updateGameNightReminderEnabled(true) }
                            else settings.updateGameNightReminderEnabled(false)
                        }
                    }
                    Box(Modifier.fillMaxWidth().height(1.dp).background(colors.rule))
                    DayPickerRow(settings.gameNightDay) { settings.updateGameNightDay(it) }
                    TimePickerRow("Prep Reminder", settings.gameNightHour, settings.gameNightMinute) { hour, minute ->
                        settings.updateGameNightTime(hour, minute)
                    }
                    Text(
                        "At that time each ${settings.gameNightDay.displayName}, the notification opens directly into your personalized practice session.",
                        style = ElecType.caption,
                        color = colors.inkSecondary,
                    )
                }
                val weakest = records.weakestRoom()
                val due = records.dueCount(reviewable)
                val copy = when {
                    due > 0 && weakest != null -> "$due due mistake${if (due == 1) "" else "s"} first, then extra work in ${weakest.name}."
                    due > 0 -> "$due due mistake${if (due == 1) "" else "s"} first, followed by material you have not seen yet."
                    weakest != null -> "Extra work in ${weakest.name}, followed by a balanced mix from the other rooms."
                    else -> "A balanced member mix now. As you answer more questions, this session will zero in on your real weak spots."
                }
                Row(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    IconBadge("scope", colors.copper, size = 40.dp)
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text("What today's prep targets", style = ElecType.headline, color = colors.ink)
                        Text(copy, style = ElecType.subheadline, color = colors.inkSecondary)
                    }
                }
                PrimaryCTA("Start My Five-Minute Prep", Modifier.testTag("start-prep"), color = colors.service) {
                    navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
                }
                Spacer(Modifier.height(4.dp))
            }
        }
    }
}

fun gameNightPrepItems(graph: com.jackwallner.electrician.AppGraph) = SessionBuilder.gameNightPrep(
    seen = graph.progress.seenItems,
    missed = graph.progress.missedItems,
    dueIDs = graph.records.reviewQueue(presentable = SessionBuilder.reviewableIDs(true)),
    weakestRoomID = graph.records.weakestRoom()?.id,
)
