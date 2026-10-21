package com.jackwallner.electrician.ui.screens

import com.jackwallner.electrician.model.NECTables
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.electrician.BuildConfig
import com.jackwallner.electrician.data.Appearance
import com.jackwallner.electrician.data.Membership
import com.jackwallner.electrician.data.PurchaseException
import com.jackwallner.electrician.data.StoreLinks
import com.jackwallner.electrician.ui.LocalAppActions
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.symbol
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.nav.Route
import com.jackwallner.electrician.ui.openFeedbackMail
import com.jackwallner.electrician.ui.openPlayListing
import com.jackwallner.electrician.ui.openUrl
import com.jackwallner.electrician.ui.theme.BarTextButton
import com.jackwallner.electrician.ui.theme.FormDivider
import com.jackwallner.electrician.ui.theme.FormRow
import com.jackwallner.electrician.ui.theme.FormSection
import com.jackwallner.electrician.ui.theme.Haptics
import com.jackwallner.electrician.ui.theme.IconBadge
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecAlert
import com.jackwallner.electrician.ui.theme.ElecBar
import com.jackwallner.electrician.ui.theme.ElecScreen
import com.jackwallner.electrician.ui.theme.ElecSwitch
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.PrimaryCTA
import com.jackwallner.electrician.ui.theme.PlusBadge
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.Segmented
import com.jackwallner.electrician.ui.theme.TimePickerRow
import com.jackwallner.electrician.ui.theme.navBarPadding
import com.jackwallner.electrician.ui.theme.pressable
import com.jackwallner.electrician.ui.theme.QuietButton
import com.jackwallner.electrician.ui.theme.themedCard
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val context = LocalContext.current
    val colors = Elec.colors
    val scope = rememberCoroutineScope()
    val settings = graph.settings
    val service = graph.subscriptions
    var restoreMessage by remember { mutableStateOf<String?>(null) }
    var confirmReset by remember { mutableStateOf(false) }
    var reviewerCodeOpen by remember { mutableStateOf(false) }

    ElecScreen("Settings", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                FormSection("Appearance") {
                    Box(Modifier.padding(12.dp)) {
                        Segmented(Appearance.entries, settings.appearance, { it.displayName }) { settings.updateAppearance(it) }
                    }
                }
                FormSection("Practice") {
                    FormRow("Haptics") { ElecSwitch(settings.hapticsEnabled, "Haptics") { settings.updateHaptics(it) } }
                    FormDivider()
                    FormRow("Sound Effects") { ElecSwitch(settings.soundEnabled, "Sound Effects") { settings.updateSound(it) } }
                    FormDivider()
                    FormRow("Daily Reminder") {
                        ElecSwitch(settings.reminderEnabled, "Daily Reminder") { on ->
                            if (on) requestNotifications { settings.updateReminderEnabled(true) } else settings.updateReminderEnabled(false)
                        }
                    }
                    if (settings.reminderEnabled) {
                        FormDivider()
                        Box(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                            TimePickerRow("Reminder Time", settings.reminderHour, settings.reminderMinute) { h, m -> settings.updateReminderTime(h, m) }
                        }
                    }
                    if (service.isPro) {
                        FormDivider()
                        FormRow("Exam Warm-Up", icon = "person.2.fill", onClick = { navigator.push(Route.GameNightPrep) }) { Chevron() }
                    }
                }
                FormSection("Membership") {
                    if (service.isPro) {
                        FormRow("${Membership.NAME} unlocked", icon = "checkmark.seal.fill", tint = colors.voltage)
                        FormDivider()
                        FormRow("Manage Subscription", onClick = { context.openUrl(StoreLinks.manageSubscriptionURL(service.activeProductId)) }) { Chevron() }
                    } else {
                        FormRow("Get ${Membership.NAME}", icon = "sparkles", onClick = { actions.openPaywall("electrician_settings_sheet") }) { PlusBadge() }
                    }
                    FormDivider()
                    FormRow("Restore Purchases", tint = colors.voltage, onClick = {
                        scope.launch {
                            restoreMessage = try {
                                service.restore()
                                if (service.isPro) "${Membership.NAME} restored!" else "No previous purchase found on this Google account."
                            } catch (error: PurchaseException) {
                                error.message
                            }
                        }
                    })
                }
                FormSection("Your Practice History") {
                    FormRow("Your Progress", icon = "chart.bar.fill", onClick = { navigator.push(Route.Stats) }) { Chevron() }
                    FormDivider()
                    FormRow("Reset Progress", tint = colors.wrongRed, onClick = { confirmReset = true })
                }
                FormSection("Support") {
                    FormRow("Code Edition", icon = "book.closed.fill", onClick = { navigator.push(Route.Edition) }) { Chevron() }
                    FormDivider()
                    FormRow("How to Play", icon = "book.fill", onClick = { navigator.push(Route.HowToPlay) }) { Chevron() }
                    if (graph.whatsNew.currentRelease != null) {
                        FormDivider()
                        FormRow("What's New", icon = "sparkle", onClick = { actions.openWhatsNew() })
                    }
                    FormDivider()
                    FormRow("Rate Electrician", icon = "star.fill", onClick = {
                        graph.review.markOpenedWriteReview()
                        context.openPlayListing()
                    })
                    FormDivider()
                    FormRow("Send Feedback", icon = "envelope.fill", onClick = { actions.openFeedback() })
                }
                FormSection("About") {
                    // A long press opens the Play reviewer unlock; the row has no other action.
                    FormRow(
                        "Version",
                        Modifier.testTag("version-row").combinedClickable(onClick = {}, onLongClick = { reviewerCodeOpen = true }),
                    ) { Text(BuildConfig.VERSION_NAME, style = ElecType.body, color = colors.inkSecondary) }
                    FormDivider()
                    Text(
                        "Every number in this app comes from the ${NECTables.edition}, and every table it computes from is unchanged across the ${NECTables.coverageLabel}. Electrician is a study aid, not a code book. It is not affiliated with, endorsed by, or connected to the NFPA. It teaches concepts and calculations in original wording and cites article numbers so you can verify each one yourself. Your jurisdiction may examine against a different edition or amend it locally, so always check the code in force where you work.",
                        style = ElecType.footnote,
                        color = colors.inkSecondary,
                        modifier = Modifier.padding(16.dp),
                    )
                }
                if (BuildConfig.DEBUG) {
                    FormSection("Developer") {
                        FormRow("Local ${Membership.NAME} override") {
                            ElecSwitch(service.isPro, "Local override") { service.setLocalOverride(it) }
                        }
                    }
                }
            }
        }
    }

    if (reviewerCodeOpen) ReviewerCodeDialog(onUnlock = service::activateReviewAccess, onClose = { reviewerCodeOpen = false })
    restoreMessage?.let { ElecAlert("Restore", it, onConfirm = { restoreMessage = null }) }
    if (confirmReset) {
        ElecAlert(
            "Reset all progress?",
            "Your streak, completed drills, and practice history will be cleared. Purchases are not affected.",
            confirmTitle = "Reset",
            destructive = true,
            dismissTitle = "Cancel",
            onConfirm = {
                confirmReset = false
                graph.resetProgress()
            },
            onDismiss = { confirmReset = false },
        )
    }
    // The "Notifications are off" alert lives in RootScreen, next to the
    // permission request, so Exam Warm-Up gets it too.
}

@Composable
private fun ReviewerCodeDialog(onUnlock: (String) -> Boolean, onClose: () -> Unit) {
    val colors = Elec.colors
    var code by remember { mutableStateOf("") }
    var failed by remember { mutableStateOf(false) }
    AlertDialog(
        onDismissRequest = onClose,
        containerColor = colors.card,
        titleContentColor = colors.ink,
        textContentColor = colors.inkSecondary,
        title = { Text("Reviewer access", style = ElecType.headline) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Enter the code from the Play review instructions.", style = ElecType.subheadline)
                OutlinedTextField(
                    value = code,
                    onValueChange = { code = it; failed = false },
                    label = { Text("Reviewer code") },
                    singleLine = true,
                    isError = failed,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false),
                    visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.testTag("reviewer-code"),
                )
                if (failed) Text("That code isn't valid.", style = ElecType.footnote, color = colors.wrongRed)
            }
        },
        confirmButton = {
            TextButton(onClick = { if (onUnlock(code)) onClose() else failed = true }) {
                Text("Unlock", style = ElecType.headline, color = colors.voltage)
            }
        },
        dismissButton = {
            TextButton(onClick = onClose) { Text("Cancel", style = ElecType.body, color = colors.inkSecondary) }
        },
    )
}

@Composable
private fun Chevron() {
    Icon(symbol("chevron.right"), null, tint = Elec.colors.inkTertiary, modifier = Modifier.size(18.dp))
}

/**
 * Shown once on the first launch after an update: what a member already owns,
 * or what the membership would add. One dismiss, at most one soft upgrade.
 */
@Composable
fun WhatsNewSheet(onClose: () -> Unit, onUpgrade: () -> Unit) {
    val graph = LocalGraph.current
    val colors = Elec.colors
    val release = graph.whatsNew.currentRelease ?: return
    val isPro = graph.subscriptions.isPro
    val hasLocked = !isPro && release.items.any { it.isPlus }
    fun close() {
        graph.whatsNew.markSeen()
        onClose()
    }
    Column(Modifier.fillMaxSize()) {
        ElecBar("", onBack = null, trailing = { BarTextButton("Done", colors.inkSecondary) { close() } }, inSheet = true)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("WHAT'S NEW", style = ElecType.eyebrow, color = colors.inkSecondary)
                Text(release.headline, style = ElecType.display(30.sp), color = colors.ink)
                Text("Version ${release.version}", style = ElecType.footnote, color = colors.inkTertiary)
            }
            release.items.forEach { item ->
                val locked = item.isPlus && !isPro
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    IconBadge(item.icon, if (locked) colors.brass else colors.voltage, size = 42.dp, iconSize = 22.dp, corner = 13.dp)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(item.title, style = ElecType.headline, color = colors.ink)
                            if (locked) PlusBadge()
                        }
                        Text(item.body, style = ElecType.subheadline, color = colors.inkSecondary)
                    }
                }
            }
        }
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 10.dp).padding(navBarPadding(0.dp)), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (hasLocked) {
                PrimaryCTA("Unlock with ${Membership.NAME}", color = colors.brass) {
                    graph.whatsNew.markSeen()
                    onUpgrade()
                }
                QuietButton("Keep practicing free", Modifier.fillMaxWidth()) { close() }
            } else {
                PrimaryCTA("Start practicing") { close() }
            }
        }
    }
}

/** Feedback goes to a real person through the mail app, and only claims success if one opened. */
@Composable
fun FeedbackSheet(onClose: () -> Unit) {
    val graph = LocalGraph.current
    val context = LocalContext.current
    val clipboard: ClipboardManager = LocalClipboardManager.current
    val colors = Elec.colors
    var text by remember { mutableStateOf("") }
    var mailFailed by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    val trimmed = text.trim()
    Column(Modifier.fillMaxSize()) {
        ElecBar("Help us improve", onBack = null, leading = { BarTextButton("Not now", colors.inkSecondary, onClick = onClose) }, inSheet = true)
        Column(Modifier.weight(1f).padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("What would make Electrician better for you?", style = ElecType.headline, color = colors.ink)
            BasicTextField(
                text,
                { text = it },
                textStyle = ElecType.body.copy(color = colors.ink),
                cursorBrush = SolidColor(colors.voltage),
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f, fill = false)
                    .testTag("feedback-text")
                    .focusRequester(focus)
                    .themedCard(14.dp)
                    .padding(12.dp),
                minLines = 6,
            )
            if (mailFailed) {
                // Plenty of people have no mail app set up; say so rather than claim it sent.
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Your mail app didn't open. You can email us directly:", style = ElecType.caption, color = colors.ink)
                    Row(
                        Modifier.testTag("copy-email").pressable {
                            clipboard.setText(AnnotatedString(StoreLinks.FEEDBACK_EMAIL))
                            Haptics.success()
                        }.padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(symbol("doc.on.doc"), null, tint = colors.voltage, modifier = Modifier.size(14.dp))
                        Text("Copy ${StoreLinks.FEEDBACK_EMAIL}", style = ElecType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.voltage)
                    }
                }
            } else {
                Text("Opens your mail app with a draft to the developer. It goes to a real person.", style = ElecType.caption, color = colors.inkSecondary)
            }
            PrimaryCTA("Send feedback", Modifier.testTag("send-feedback"), enabled = trimmed.isNotEmpty()) {
                if (context.openFeedbackMail(trimmed)) {
                    onClose()
                } else {
                    mailFailed = true
                }
            }
        }
    }
}
