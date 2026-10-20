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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.electrician.content.CodeMinuteCategory
import com.jackwallner.electrician.content.CodeMinuteContent
import com.jackwallner.electrician.data.CodeMinuteResult
import com.jackwallner.electrician.ui.LocalAppActions
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.ConfettiBurst
import com.jackwallner.electrician.ui.components.symbol
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.nav.Route
import com.jackwallner.electrician.ui.nav.SessionPurpose
import com.jackwallner.electrician.ui.shareText
import com.jackwallner.electrician.ui.theme.Eyebrow
import com.jackwallner.electrician.ui.theme.Haptics
import com.jackwallner.electrician.ui.theme.IconBadge
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecScreen
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.PrimaryCTA
import com.jackwallner.electrician.ui.theme.QuietButton
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.SoundPlayer
import com.jackwallner.electrician.ui.theme.navBarPadding
import com.jackwallner.electrician.ui.theme.pressable
import com.jackwallner.electrician.ui.theme.themedCard
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun CodeMinuteScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    val today = LocalDate.now()
    val todayResult = graph.minutes.result(today)
    ElecScreen("Code Minute", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(
                    Modifier.fillMaxWidth().themedCard().padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    val tint = if (todayResult == null) colors.copper else colors.voltage
                    IconBadge(if (todayResult == null) "calendar.badge.clock" else "checkmark.seal.fill", tint, size = 68.dp, iconSize = 30.dp)
                    Text("Today's Code Minute", style = ElecType.display(27.sp), color = colors.ink, textAlign = TextAlign.Center)
                    Text(
                        "The same five questions for every member: two generated calculations and three drawn from across the rooms.",
                        style = ElecType.subheadline,
                        color = colors.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                    if (todayResult != null) {
                        PrimaryCTA("View Today's ${todayResult.score}/${todayResult.total}") { navigator.push(Route.MinuteResult(todayResult)) }
                    } else {
                        PrimaryCTA("Start Today's Challenge", Modifier.testTag("start-minute"), color = colors.copper) {
                            val challenge = CodeMinuteContent.challenge(today)
                            navigator.push(Route.Session(challenge.items, SessionPurpose.Minute(challenge)))
                        }
                    }
                }
                WeeklyRhythm(minOf(graph.minutes.completedThisWeek(), 5))
                Eyebrow("ARCHIVE", modifier = Modifier.padding(horizontal = 4.dp))
                val dates = graph.minutes.archiveDates()
                Column(Modifier.fillMaxWidth().themedCard(16.dp)) {
                    dates.forEachIndexed { index, date ->
                        ArchiveRow(date, graph.minutes.result(date))
                        if (index < dates.lastIndex) Box(Modifier.fillMaxWidth().height(1.dp).background(colors.rule))
                    }
                }
            }
        }
    }
}

@Composable
private fun WeeklyRhythm(completed: Int) {
    val colors = Elec.colors
    Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Eyebrow("YOUR WEEK")
                Text(if (completed >= 5) "Weekly goal complete" else "$completed of 5 practiced", style = ElecType.headline, color = colors.ink)
            }
            Icon(
                symbol(if (completed >= 5) "checkmark.seal.fill" else "calendar"),
                null,
                tint = if (completed >= 5) colors.voltage else colors.copper,
                modifier = Modifier.size(22.dp),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            repeat(5) { index ->
                val done = index < completed
                Box(Modifier.size(34.dp).background(if (done) colors.copperFill else colors.well, CircleShape), contentAlignment = Alignment.Center) {
                    if (done) Icon(symbol("checkmark.circle.fill"), null, tint = Color.White, modifier = Modifier.size(16.dp))
                }
            }
        }
        Text("Any five days count. Miss one, catch up from the archive, and keep the week alive.", style = ElecType.caption, color = colors.inkSecondary)
    }
}

private val archiveFormat = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.getDefault())

@Composable
private fun ArchiveRow(date: LocalDate, result: CodeMinuteResult?) {
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    val tint = if (result == null) colors.copper else colors.voltage
    Row(
        Modifier.fillMaxWidth().pressable {
            if (result != null) {
                navigator.push(Route.MinuteResult(result))
            } else {
                val challenge = CodeMinuteContent.challenge(date)
                navigator.push(Route.Session(challenge.items, SessionPurpose.Minute(challenge)))
            }
        }.padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(symbol(if (result == null) "play.circle" else "checkmark.circle.fill"), null, tint = tint, modifier = Modifier.width(28.dp).size(22.dp))
        Text(date.format(archiveFormat), style = ElecType.subheadline.copy(fontWeight = FontWeight.Medium), color = colors.ink, modifier = Modifier.weight(1f))
        Text(result?.let { "${it.score}/${it.total}" } ?: "Play", style = ElecType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = tint)
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(16.dp))
    }
}

@Composable
fun CodeMinuteResultScreen(result: CodeMinuteResult, recordsCompletion: Boolean = false, onDone: (() -> Unit)? = null) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val context = LocalContext.current
    val colors = Elec.colors
    val done = onDone ?: { navigator.pop(); Unit }
    var recorded by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        if (!recordsCompletion || recorded) return@LaunchedEffect
        recorded = true
        confetti += 1
        Haptics.success()
        SoundPlayer.play(SoundPlayer.Effect.COMPLETE)
        graph.progress.recordSession(CodeMinuteContent.drill.id)
        actions.positiveMoment()
    }
    ElecScreen("Code Minute", onBack = if (recordsCompletion) null else done) {
        Box(Modifier.fillMaxSize()) {
            Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), maxWidth = 620.dp) {
                Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    Column(
                        Modifier.fillMaxWidth().themedCard().padding(20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Box(Modifier.size(122.dp).background(colors.voltage.copy(alpha = 0.12f), CircleShape), contentAlignment = Alignment.Center) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("${result.score}/${result.total}", style = ElecType.display(34.sp), color = colors.voltage, modifier = Modifier.testTag("minute-score"))
                                Text("right", style = ElecType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary)
                            }
                        }
                        Text(if (result.score == result.total) "Perfect minute!" else "Minute complete", style = ElecType.display(28.sp), color = colors.ink)
                        Text("Code Minute ${result.shortDate}", style = ElecType.subheadline, color = colors.inkSecondary)
                    }
                    Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        Eyebrow("BY SKILL")
                        CodeMinuteCategory.entries.forEach { category ->
                            val correct = result.correct(category)
                            val total = result.total(category)
                            val tint = when {
                                correct == total -> colors.voltage
                                correct > 0 -> colors.brass
                                else -> colors.copper
                            }
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Icon(symbol(category.icon), null, tint = tint, modifier = Modifier.width(30.dp).size(22.dp))
                                Text(category.title, style = ElecType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                                Text("$correct/$total", style = ElecType.subheadline.copy(fontWeight = FontWeight.Bold), color = tint)
                            }
                        }
                    }
                    val completed = minOf(graph.minutes.completedThisWeek(), 5)
                    Row(
                        Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        val tint = if (completed >= 5) colors.voltage else colors.copper
                        IconBadge(if (completed >= 5) "checkmark.seal.fill" else "calendar.badge.checkmark", tint, alpha = 0.12f)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(if (completed >= 5) "Weekly goal complete" else "$completed of 5 this week", style = ElecType.headline, color = colors.ink)
                            Text("Any five days keep the rhythm going.", style = ElecType.caption, color = colors.inkSecondary)
                        }
                    }
                    PrimaryCTA("Share Result", color = colors.copper, icon = symbol("square.and.arrow.up")) { context.shareText(result.shareText) }
                    QuietButton("Done", Modifier.fillMaxWidth().testTag("minute-done"), onClick = done)
                    Spacer(Modifier.height(4.dp))
                }
            }
            ConfettiBurst(confetti, origin = Offset(0.5f, 0.22f), particleCount = 44)
        }
    }
}
