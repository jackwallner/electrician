package com.jackwallner.electrician.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

import com.jackwallner.electrician.model.ConductorMaterial
import com.jackwallner.electrician.model.ElectrodeType
import com.jackwallner.electrician.model.FieldCalculators
import com.jackwallner.electrician.model.MotorProtection
import com.jackwallner.electrician.model.MotorSupply
import com.jackwallner.electrician.model.NECTables
import com.jackwallner.electrician.model.Phase
import com.jackwallner.electrician.model.TemperatureRating
import com.jackwallner.electrician.model.areaText
import com.jackwallner.electrician.model.factorText
import com.jackwallner.electrician.model.groupedText
import com.jackwallner.electrician.model.roundedAmpsText
import com.jackwallner.electrician.model.roundedAway
import com.jackwallner.electrician.model.trimmedAmps
import com.jackwallner.electrician.model.voltsText
import com.jackwallner.electrician.model.volumeText
import com.jackwallner.electrician.ui.components.CitationLine
import com.jackwallner.electrician.ui.components.symbol
import com.jackwallner.electrician.ui.nav.LocalNavigator
import com.jackwallner.electrician.ui.theme.Elec
import com.jackwallner.electrician.ui.theme.ElecScreen
import com.jackwallner.electrician.ui.theme.ElecType
import com.jackwallner.electrician.ui.theme.IconBadge
import com.jackwallner.electrician.ui.theme.Readable
import com.jackwallner.electrician.ui.theme.navBarPadding
import com.jackwallner.electrician.ui.theme.pressable
import com.jackwallner.electrician.ui.theme.rounded
import com.jackwallner.electrician.ui.theme.themedCard

private enum class FieldTool(val title: String, val subtitle: String, val icon: String) {
    AMPACITY("Ampacity", "Derate for heat and bundling, capped at the terminals", "thermometer.medium"),
    CONDUIT("Conduit Fill", "Does the bundle fit this EMT?", "cylinder.fill"),
    VOLTAGE_DROP("Voltage Drop", "The 3% figure, for a real run", "chart.line.downtrend.xyaxis"),
    OHMS("Ohm's Law", "Any two of volts, amps, ohms, watts", "function"),
    GROUNDING("Grounding", "EGC from the breaker, GEC from the service", "leaf.fill"),
    MOTOR("Motor Circuit", "Table current, 125%, 430.52 and overloads", "fan.fill"),
    BOX("Box Fill", "Count allowances, then pick the box", "shippingbox.fill"),
    DWELLING("Dwelling Service", "The standard calculation, step by step", "house.fill"),
}

/**
 * The eight Field Tools, free for everyone. Each one is the same calculation
 * the drills teach, run on your own numbers, with the article to look it up in.
 */
@Composable
fun FieldToolsScreen() {
    val navigator = LocalNavigator.current
    val colors = Elec.colors
    var open by rememberSaveable { mutableStateOf<FieldTool?>(null) }
    ElecScreen("Field Tools", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Values follow the ${NECTables.edition}. ${NECTables.coverageLabel} tables match.", style = ElecType.footnote, color = colors.inkSecondary)
                FieldTool.entries.forEach { tool ->
                    val expanded = open == tool
                    Column(Modifier.fillMaxWidth().themedCard()) {
                        Row(
                            Modifier.fillMaxWidth().testTag("tool-${tool.name.lowercase()}").pressable { open = if (expanded) null else tool }.padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                        ) {
                            IconBadge(tool.icon, colors.voltage, size = 44.dp, iconSize = 22.dp, corner = 12.dp, alpha = 0.12f)
                            Column(Modifier.weight(1f)) {
                                Text(tool.title, style = ElecType.display(18.sp), color = colors.ink)
                                Text(tool.subtitle, style = ElecType.subheadline, color = colors.inkSecondary)
                            }
                            Icon(symbol(if (expanded) "chevron.down" else "chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
                        }
                        AnimatedVisibility(expanded) {
                            Column(Modifier.padding(start = 14.dp, end = 14.dp, bottom = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                when (tool) {
                                    FieldTool.AMPACITY -> AmpacityTool()
                                    FieldTool.CONDUIT -> ConduitTool()
                                    FieldTool.VOLTAGE_DROP -> VoltageDropTool()
                                    FieldTool.OHMS -> OhmsTool()
                                    FieldTool.GROUNDING -> GroundingTool()
                                    FieldTool.MOTOR -> MotorTool()
                                    FieldTool.BOX -> BoxTool()
                                    FieldTool.DWELLING -> DwellingTool()
                                }
                            }
                        }
                    }
                }
                Text("A study and estimating aid. The code book your jurisdiction adopted, and the authority having jurisdiction, have the final word.", style = ElecType.caption, color = colors.inkTertiary)
            }
        }
    }
}

@Composable
private fun <T> Picker(label: String, options: List<T>, selected: T, name: (T) -> String, onSelect: (T) -> Unit) {
    val colors = Elec.colors
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label.uppercase(), style = ElecType.eyebrow, color = colors.inkTertiary)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            options.forEach { option ->
                val on = option == selected
                Text(
                    name(option),
                    style = ElecType.numeric(13.sp, if (on) FontWeight.Bold else FontWeight.Medium),
                    color = if (on) Color.White else colors.ink,
                    modifier = Modifier
                        .semantics { this.selected = on }
                        .background(if (on) colors.voltageFill else colors.well, rounded(10.dp))
                        .pressable { onSelect(option) }
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                )
            }
        }
    }
}

@Composable
private fun NumberField(label: String, value: String, tag: String, onChange: (String) -> Unit) {
    val colors = Elec.colors
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label.uppercase(), style = ElecType.eyebrow, color = colors.inkTertiary)
        BasicTextField(
            value,
            { next -> onChange(next.filter { it.isDigit() || it == '.' }.take(9)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            textStyle = ElecType.numeric(17.sp).copy(color = colors.ink),
            cursorBrush = SolidColor(colors.voltage),
            modifier = Modifier.fillMaxWidth().testTag(tag).background(colors.well, rounded(10.dp)).padding(12.dp),
        )
    }
}

@Composable
private fun ResultCard(lines: List<Pair<String, String>>, citation: String?, note: String? = null) {
    val colors = Elec.colors
    Column(
        Modifier.fillMaxWidth().background(colors.worksheet, rounded(14.dp)).border(1.dp, colors.worksheetEdge, rounded(14.dp)).padding(14.dp).testTag("tool-result"),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        lines.forEach { (label, value) ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(label, style = ElecType.subheadline, color = colors.worksheetInkSecondary, modifier = Modifier.weight(1f))
                Text(value, style = ElecType.numeric(16.sp, FontWeight.Bold), color = colors.worksheetInk)
            }
        }
        note?.let { Text(it, style = ElecType.footnote, color = colors.worksheetInkSecondary) }
        citation?.let { Box(Modifier.padding(top = 4.dp)) { CitationLine(it) } }
    }
}

private val toolSizes = listOf("14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG", "4 AWG", "3 AWG", "2 AWG", "1 AWG", "1/0 AWG", "2/0 AWG", "3/0 AWG", "4/0 AWG", "250 kcmil", "350 kcmil", "500 kcmil")
private fun String.number(): Double? = toDoubleOrNull()?.takeIf { it > 0 && it.isFinite() }

@Composable
private fun ColumnScope.AmpacityTool() {
    var size by rememberSaveable { mutableStateOf("10 AWG") }
    var material by rememberSaveable { mutableStateOf(ConductorMaterial.copper) }
    var insulation by rememberSaveable { mutableStateOf(TemperatureRating.c90) }
    var termination by rememberSaveable { mutableStateOf(TemperatureRating.c75) }
    var ambient by rememberSaveable { mutableStateOf(30) }
    var count by rememberSaveable { mutableStateOf(3) }
    Picker("Conductor", toolSizes.filter { NECTables.ampacity(it, ConductorMaterial.copper, TemperatureRating.c90) != null }, size, { it }) { size = it }
    Picker("Material", ConductorMaterial.entries, material, { it.displayName }) { material = it }
    Picker("Insulation", TemperatureRating.entries, insulation, { it.displayName }) { insulation = it }
    Picker("Terminations", TemperatureRating.entries, termination, { it.displayName }) { termination = it }
    Picker("Ambient °C", listOf(25, 30, 35, 40, 45, 50, 55, 60), ambient, { "$it" }) { ambient = it }
    Picker("Current-carrying", listOf(3, 4, 6, 7, 9, 10, 20, 21), count, { "$it" }) { count = it }
    val result = FieldCalculators.ampacity(size, material, insulation, termination, ambient, count)
    if (result == null) ResultCard(listOf("Not in Table 310.16" to "-"), null)
    else ResultCard(listOfNotNull(
        "Table value" to "${result.tableAmps} A",
        "Ambient × bundling" to "${result.ambientFactor.factorText} × ${result.adjustment.factorText}",
        "After derating" to "${result.afterDerate.roundedAmpsText} A",
        "${termination.displayName} termination" to "${result.terminationCap} A",
        "Allowable" to "${result.allowable.trimmedAmps} A",
        "OCPD ceiling" to "${result.ocpdCeiling.trimmedAmps} A",
    ), result.citation)
}

@Composable
private fun ColumnScope.ConduitTool() {
    var size by rememberSaveable { mutableStateOf("12 AWG") }
    var count by rememberSaveable { mutableStateOf("9") }
    var trade by rememberSaveable { mutableStateOf("3/4\"") }
    Picker("Conductor (THHN)", toolSizes.filter { NECTables.thhnArea[it] != null }, size, { it }) { size = it }
    NumberField("How many", count, "fill-count") { count = it }
    Picker("EMT trade size", NECTables.emtTradeSizes, trade, { it }) { trade = it }
    val result = count.number()?.toInt()?.let { FieldCalculators.conduitFill(size, it, trade) }
    if (result == null) ResultCard(listOf("Enter a conductor count" to "-"), null)
    else ResultCard(listOf(
        "Bundle area" to "${result.bundleArea.areaText} in²",
        "Allowed (${(result.allowedPercent * 100).toInt()}%)" to "${result.allowedArea.areaText} in²",
        "Fill" to "${result.actualPercent.voltsText}%",
        "Fits $trade" to if (result.fits) "Yes" else "No",
        "Smallest that fits" to (result.smallestFitting ?: "Over 4\""),
    ), result.citation)
}

@Composable
private fun ColumnScope.VoltageDropTool() {
    var size by rememberSaveable { mutableStateOf("10 AWG") }
    var material by rememberSaveable { mutableStateOf(ConductorMaterial.copper) }
    var phase by rememberSaveable { mutableStateOf(Phase.single) }
    var volts by rememberSaveable { mutableStateOf("240") }
    var amps by rememberSaveable { mutableStateOf("16") }
    var feet by rememberSaveable { mutableStateOf("100") }
    Picker("Conductor", toolSizes.filter { NECTables.circularMils[it] != null }, size, { it }) { size = it }
    Picker("Material", ConductorMaterial.entries, material, { it.displayName }) { material = it }
    Picker("System", Phase.entries, phase, { it.displayName }) { phase = it }
    NumberField("System volts", volts, "vd-volts") { volts = it }
    NumberField("Load amps", amps, "vd-amps") { amps = it }
    NumberField("One-way feet", feet, "vd-feet") { feet = it }
    val v = volts.number(); val a = amps.number(); val f = feet.number()
    val result = if (v != null && a != null && f != null) FieldCalculators.voltageDrop(size, material, phase, v, a, f) else null
    if (result == null) ResultCard(listOf("Enter volts, amps and length" to "-"), null)
    else ResultCard(listOf("Voltage drop" to "${result.volts.voltsText} V", "Percent" to "${result.percent.voltsText}%"), result.citation,
        if (result.withinThreePercent) "Within the 3% the informational note suggests for a branch circuit." else "Past the 3% the informational note suggests. Consider the next size up.")
}

@Composable
private fun ColumnScope.OhmsTool() {
    var volts by rememberSaveable { mutableStateOf("120") }
    var amps by rememberSaveable { mutableStateOf("") }
    var ohms by rememberSaveable { mutableStateOf("") }
    var watts by rememberSaveable { mutableStateOf("1500") }
    NumberField("Volts", volts, "ohm-volts") { volts = it }
    NumberField("Amps", amps, "ohm-amps") { amps = it }
    NumberField("Ohms", ohms, "ohm-ohms") { ohms = it }
    NumberField("Watts", watts, "ohm-watts") { watts = it }
    val result = FieldCalculators.ohmsLaw(volts.number(), amps.number(), ohms.number(), watts.number())
    if (result == null) ResultCard(listOf("Enter any two values" to "-"), null)
    else ResultCard(listOf(
        "Volts" to "${result.volts.voltsText} V", "Amps" to "${result.amps.roundedAmpsText} A",
        "Ohms" to "${result.ohms.factorText} Ω", "Watts" to "${result.watts.wholeText()} W",
    ), null, (listOf("Solved from ${result.basis}.") + result.conflicts).joinToString(" "))
}

private fun Double.wholeText(): String = roundedAway.toLong().toInt().groupedText

@Composable
private fun ColumnScope.GroundingTool() {
    var size by rememberSaveable { mutableStateOf("3/0 AWG") }
    var material by rememberSaveable { mutableStateOf(ConductorMaterial.copper) }
    var ocpd by rememberSaveable { mutableStateOf(200) }
    var electrode by rememberSaveable { mutableStateOf(ElectrodeType.rodPipePlate) }
    var sets by rememberSaveable { mutableStateOf(1) }
    Picker("Service conductor", toolSizes.filter { NECTables.circularMilsExtended[it] != null }, size, { it }) { size = it }
    Picker("Service material", ConductorMaterial.entries, material, { it.displayName }) { material = it }
    Picker("Parallel sets", listOf(1, 2, 3), sets, { "$it" }) { sets = it }
    Picker("Overcurrent device", NECTables.standardOCPD.filter { it in 15..1200 }, ocpd, { "$it A" }) { ocpd = it }
    Picker("Electrode", ElectrodeType.entries, electrode, { it.displayName }) { electrode = it }
    val result = FieldCalculators.grounding(size, material, ocpd, electrode, sets)
    if (result == null) ResultCard(listOf("Outside the tables" to "-"), null)
    else ResultCard(listOf(
        "Equipment ground (250.122)" to result.equipmentGround,
        "Electrode conductor (250.66)" to result.electrodeConductor,
    ), result.citation, if (result.cappedByElectrode) "The table calls for ${result.electrodeConductorFromTable}; the electrode caps it." else null)
}

@Composable
private fun ColumnScope.MotorTool() {
    var supply by rememberSaveable { mutableStateOf(MotorSupply.three460) }
    val ratings = NECTables.motorRatings(supply)
    var hp by rememberSaveable { mutableStateOf("10 hp") }
    var protection by rememberSaveable { mutableStateOf(MotorProtection.inverseTimeBreaker) }
    var nameplate by rememberSaveable { mutableStateOf("13") }
    Picker("Supply", MotorSupply.entries, supply, { it.displayName }) { supply = it }
    val rating = ratings.firstOrNull { it.label == hp } ?: ratings.first()
    Picker("Motor", ratings, rating, { it.label }) { hp = it.label }
    Picker("Protective device", MotorProtection.entries, protection, { it.displayName }) { protection = it }
    NumberField("Nameplate amps", nameplate, "motor-nameplate") { nameplate = it }
    val result = nameplate.number()?.let { FieldCalculators.motorCircuit(rating.label, supply, protection, it) }
    if (result == null) ResultCard(listOf("Enter the nameplate current" to "-"), null)
    else ResultCard(listOfNotNull(
        "Table current" to "${result.tableFLC.factorText} A",
        "Conductors at 125%" to "${result.conductorAmpacity.roundedAmpsText} A",
        result.conductorSize?.let { "Conductor (75°C Cu)" to it },
        "Branch device (${result.branchOCPDPercent})" to "${result.branchOCPD} A",
        "Overload 115% / 125%" to "${result.overloadAt115.roundedAmpsText} / ${result.overloadAt125.roundedAmpsText} A",
        result.equipmentGround?.let { "Equipment ground" to it },
    ), result.citation)
}

@Composable
private fun ColumnScope.BoxTool() {
    var size by rememberSaveable { mutableStateOf("12 AWG") }
    var conductors by rememberSaveable { mutableStateOf("4") }
    var devices by rememberSaveable { mutableStateOf(1) }
    var clamps by rememberSaveable { mutableStateOf(true) }
    var grounds by rememberSaveable { mutableStateOf(2) }
    Picker("Conductor", listOf("18 AWG", "16 AWG", "14 AWG", "12 AWG", "10 AWG", "8 AWG", "6 AWG").filter { NECTables.conductorVolume[it] != null }, size, { it }) { size = it }
    NumberField("Insulated conductors", conductors, "box-conductors") { conductors = it }
    Picker("Device yokes", listOf(0, 1, 2, 3), devices, { "$it" }) { devices = it }
    Picker("Internal clamps", listOf(true, false), clamps, { if (it) "Yes" else "No" }) { clamps = it }
    Picker("Equipment grounds", listOf(0, 1, 2, 3, 4), grounds, { "$it" }) { grounds = it }
    val result = conductors.number()?.toInt()?.let { FieldCalculators.boxFill(it, size, devices, clamps, grounds, size) }
    if (result == null) ResultCard(listOf("Enter the conductor count" to "-"), null)
    else ResultCard(listOf(
        "Conductors" to "${result.conductorVolume.volumeText} in³",
        "Clamps" to "${result.clampVolume.volumeText} in³",
        "Yokes" to "${result.deviceVolume.volumeText} in³",
        "Grounds (all together)" to "${result.groundVolume.volumeText} in³",
        "Required" to "${result.required.volumeText} in³",
        "Smallest listed box" to (result.smallestBox ?: "Larger than the table"),
    ), result.citation)
}

@Composable
private fun ColumnScope.DwellingTool() {
    var area by rememberSaveable { mutableStateOf("2000") }
    var range by rememberSaveable { mutableStateOf("12") }
    var dryer by rememberSaveable { mutableStateOf("5500") }
    var appliances by rememberSaveable { mutableStateOf("4500, 1200, 900, 1000") }
    var cooling by rememberSaveable { mutableStateOf("5000") }
    var heating by rememberSaveable { mutableStateOf("10000") }
    NumberField("Floor area ft²", area, "load-area") { area = it }
    NumberField("Range kW", range, "load-range") { range = it }
    NumberField("Dryer VA", dryer, "load-dryer") { dryer = it }
    val colors = Elec.colors
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("FASTENED APPLIANCES VA", style = ElecType.eyebrow, color = colors.inkTertiary)
        BasicTextField(appliances, { appliances = it.filter { c -> c.isDigit() || c == ',' || c == ' ' || c == '.' } }, singleLine = true,
            textStyle = ElecType.numeric(17.sp).copy(color = colors.ink), cursorBrush = SolidColor(colors.voltage),
            modifier = Modifier.fillMaxWidth().testTag("load-appliances").background(colors.well, rounded(10.dp)).padding(12.dp))
    }
    NumberField("Air conditioning VA", cooling, "load-cooling") { cooling = it }
    NumberField("Electric heat VA", heating, "load-heating") { heating = it }
    val list = appliances.split(",").mapNotNull { it.trim().toDoubleOrNull() }
    val result = area.number()?.let { a ->
        FieldCalculators.dwellingLoad(a, 2, 1, range.toDoubleOrNull() ?: 0.0, if ((range.toDoubleOrNull() ?: 0.0) > 0) 1 else 0,
            dryer.toDoubleOrNull() ?: 0.0, list, cooling.toDoubleOrNull() ?: 0.0, heating.toDoubleOrNull() ?: 0.0)
    }
    fun va(x: Double) = "${x.wholeText()} VA"
    if (result == null) ResultCard(listOf("Enter the floor area" to "-"), null)
    else ResultCard(listOf(
        "General lighting after demand" to va(result.generalAfterDemand),
        "Range" to va(result.rangeDemand),
        "Dryer" to va(result.dryerDemand),
        "Appliances after demand" to va(result.applianceAfterDemand),
        "Heat or cooling, larger" to va(result.climate),
        "Total" to va(result.totalVA),
        "Service" to "${result.amps.roundedAmpsText} A → ${result.serviceRating} A",
    ), result.citation, if (result.floorApplied) "Raised to the 100 A minimum for a one-family dwelling." else null)
}
