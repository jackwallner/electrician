package com.jackwallner.electrician.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

import com.jackwallner.electrician.data.CandidateCatalog
import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.ui.LocalGraph
import com.jackwallner.electrician.ui.components.CoachNote
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecScreen
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.navBarPadding
import com.jackwallner.electrician.ui.theme.themedCard

/** Answers "which NEC is this?": the citation basis, what matches, and what to check in your own book. */
@Composable
fun EditionScreen() {
    val navigator = LocalNavigator.current
    val profile = LocalGraph.current.candidate
    val colors = Elec.colors
    ElecScreen("Code Edition", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Column(Modifier.fillMaxWidth().themedCard().padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("TABLE BASIS", style = ElecType.eyebrow, color = colors.inkTertiary)
                    Text(NECTables.edition, style = ElecType.display(30.sp), color = colors.ink)
                    Text(NECTables.editionNote, style = ElecType.subheadline, color = colors.inkSecondary)
                }
                Column(Modifier.fillMaxWidth().themedCard().padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("VERIFIED AGAINST", style = ElecType.eyebrow, color = colors.inkTertiary)
                    Text(NECTables.coverageLabel, style = ElecType.display(22.sp), color = colors.ink)
                    Text(NECTables.coverageNote, style = ElecType.subheadline, color = colors.inkSecondary)
                }
                val record = profile.jurisdictionRecord
                val resolved = profile.resolvedEdition
                if (record != null) {
                    CoachNote(buildString {
                        append("${record.name}: ")
                        append(resolved?.let { "you are studying for the $it NEC. " } ?: "edition set locally. ")
                        append(if (profile.editionMatchesApp) "That matches this app's tables. " else "Practise the calculations here and check coverage changes in your own book. ")
                        append("Adoption checked ${CandidateCatalog.reviewed}; confirm with ${record.authority}.")
                    })
                }
                Text("This app reproduces no NFPA text. It cites article numbers and carries the underlying numbers, with explanations written from scratch.", style = ElecType.caption, color = colors.inkTertiary)
            }
        }
    }
}
