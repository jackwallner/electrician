package com.jackwallner.electrician.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

import com.jackwallner.electrician.model.Given
import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.rounded

/**
 * The conditions of a problem as labelled chips, the electrician's counterpart
 * of a dealt rack: worksheet paper, an uppercase label and a monospaced value,
 * so amps and AWG read as instrument values.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun GivenChips(givens: List<Given>, modifier: Modifier = Modifier) {
    if (givens.isEmpty()) return
    val colors = Elec.colors
    FlowRow(
        modifier.fillMaxWidth().testTag("givens"),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        givens.forEach { given ->
            Column(
                Modifier
                    .background(colors.worksheet, rounded(10.dp))
                    .border(1.dp, colors.worksheetEdge, rounded(10.dp))
                    .padding(horizontal = 12.dp, vertical = 8.dp)
                    .clearAndSetSemantics { contentDescription = given.spokenLabel },
            ) {
                Text(given.label.uppercase(), style = ElecType.caption2.copy(fontWeight = FontWeight.Bold, letterSpacing = 0.8.sp), color = colors.worksheetInkSecondary)
                Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(given.value, style = ElecType.numeric(17.sp, FontWeight.Bold), color = colors.worksheetInk)
                    given.unit?.let { Text(it, style = ElecType.caption, color = colors.worksheetInkSecondary, modifier = Modifier.padding(bottom = 2.dp)) }
                }
            }
        }
    }
}

/**
 * The numbered working shown once a calculation is graded. A miss is almost
 * always one skipped step rather than bad arithmetic, so the steps stay a list.
 */
@Composable
fun WorkingSteps(steps: List<String>, citation: String?, accent: Color = Elec.colors.voltage, modifier: Modifier = Modifier) {
    val colors = Elec.colors
    Column(
        modifier.fillMaxWidth().background(colors.card, rounded(16.dp)).border(1.dp, colors.rule, rounded(16.dp)).padding(16.dp).testTag("working"),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("THE WORKING", style = ElecType.eyebrow, color = colors.inkTertiary)
        steps.forEachIndexed { index, step ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.size(24.dp).background(accent.copy(alpha = 0.14f), CircleShape), contentAlignment = Alignment.Center) {
                    Text("${index + 1}", style = ElecType.numeric(12.sp, FontWeight.Bold), color = accent)
                }
                Text(step, style = ElecType.subheadline, color = colors.ink, modifier = Modifier.weight(1f))
            }
        }
        citation?.let { CitationLine(it) }
    }
}

/** "NEC 2023 · 310.16": the article to look it up in, never the code's text. */
@Composable
fun CitationLine(citation: String, modifier: Modifier = Modifier) {
    val colors = Elec.colors
    Row(modifier.semantics { contentDescription = "Look it up: ${NECTables.edition}, $citation" }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(symbol("book.closed.fill"), null, tint = colors.inkTertiary, modifier = Modifier.size(14.dp))
        Text("${NECTables.edition} · $citation", style = ElecType.numeric(12.sp, FontWeight.Medium), color = colors.inkSecondary)
    }
}
