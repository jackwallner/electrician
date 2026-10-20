package com.jackwallner.electrician.ui.theme

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.electrician.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private fun rgb(r: Double, g: Double, b: Double) = Color(r.toFloat(), g.toFloat(), b.toFloat())

/**
 * The electrician palette from iOS `Theme.swift`, value for value. Names are
 * semantic: a room accent means something (voltage blue for basics, copper for
 * conductors, galvanized conduit for calculations, grounding green for Article
 * 250 and nothing else). Every accent lightens in dark mode; anything painting a
 * solid accent behind white text uses `voltageFill` / `copperFill`.
 */
@Immutable
data class ElecColors(
    val isDark: Boolean,
    val voltage: Color,
    val copper: Color,
    val brass: Color,
    val conduit: Color,
    val ground: Color,
    val highLeg: Color,
    val service: Color,
    val voltageFill: Color,
    val copperFill: Color,
    val background: Color,
    val card: Color,
    val well: Color,
    val rule: Color,
    val ink: Color,
    val inkSecondary: Color,
    val inkTertiary: Color,
    val worksheet: Color,
    val worksheetEdge: Color,
    val grid: Color,
) {
    val worksheetInk = rgb(0.09, 0.12, 0.16)
    val worksheetInkSecondary = rgb(0.29, 0.33, 0.39)
    val worksheetAccent = rgb(0.05, 0.34, 0.64)
    val rightGreen = rgb(0.12, 0.47, 0.29)
    val wrongRed = rgb(0.72, 0.17, 0.16)

    companion object {
        val light = ElecColors(
            isDark = false,
            voltage = rgb(0.05, 0.34, 0.64),
            copper = rgb(0.70, 0.36, 0.15),
            brass = rgb(0.63, 0.47, 0.10),
            conduit = rgb(0.30, 0.36, 0.47),
            ground = rgb(0.13, 0.45, 0.24),
            highLeg = rgb(0.71, 0.34, 0.03),
            service = rgb(0.29, 0.24, 0.60),
            voltageFill = rgb(0.05, 0.34, 0.64),
            copperFill = rgb(0.65, 0.31, 0.11),
            background = rgb(0.937, 0.949, 0.961),
            card = rgb(0.996, 1.0, 1.0),
            well = rgb(0.902, 0.922, 0.941),
            rule = rgb(0.796, 0.827, 0.859),
            ink = rgb(0.09, 0.12, 0.16),
            inkSecondary = rgb(0.31, 0.35, 0.41),
            inkTertiary = rgb(0.39, 0.43, 0.49),
            worksheet = rgb(0.980, 0.988, 1.0),
            worksheetEdge = rgb(0.769, 0.812, 0.859),
            grid = rgb(0.05, 0.30, 0.55),
        )
        val dark = ElecColors(
            isDark = true,
            voltage = rgb(0.42, 0.70, 1.0),
            copper = rgb(0.91, 0.58, 0.33),
            brass = rgb(0.87, 0.72, 0.34),
            conduit = rgb(0.60, 0.69, 0.82),
            ground = rgb(0.42, 0.76, 0.50),
            highLeg = rgb(0.95, 0.60, 0.25),
            service = rgb(0.66, 0.62, 0.95),
            voltageFill = rgb(0.11, 0.44, 0.80),
            copperFill = rgb(0.72, 0.36, 0.14),
            background = rgb(0.070, 0.078, 0.094),
            card = rgb(0.125, 0.141, 0.169),
            well = rgb(0.094, 0.106, 0.129),
            rule = rgb(0.235, 0.259, 0.302),
            ink = rgb(0.93, 0.95, 0.97),
            inkSecondary = rgb(0.70, 0.74, 0.79),
            inkTertiary = rgb(0.60, 0.64, 0.70),
            worksheet = rgb(0.918, 0.937, 0.957),
            worksheetEdge = rgb(0.635, 0.678, 0.729),
            grid = rgb(0.10, 0.25, 0.45),
        )
    }
}

val LocalElecColors = staticCompositionLocalOf { ElecColors.light }

object Elec {
    val colors: ElecColors
        @Composable @ReadOnlyComposable get() = LocalElecColors.current
}

@Composable
fun ElecTheme(dark: Boolean, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalElecColors provides if (dark) ElecColors.dark else ElecColors.light, content = content)
}

/** The iOS text styles at their default Dynamic Type sizes. */
object ElecType {
    private val system = FontFamily.Default

    private val condensed = FontFamily(android.graphics.Typeface.create("sans-serif-condensed", android.graphics.Typeface.BOLD))

    /** Heavy condensed sans for every title: panel-schedule lettering. */
    fun display(size: TextUnit, weight: FontWeight = FontWeight.Bold) =
        TextStyle(fontFamily = condensed, fontWeight = weight, fontSize = size, lineHeight = size * 1.15f)

    /** Monospaced instrument values: amps, AWG, volts. */
    fun numeric(size: TextUnit, weight: FontWeight = FontWeight.SemiBold) =
        TextStyle(fontFamily = FontFamily.Monospace, fontWeight = weight, fontSize = size, lineHeight = size * 1.25f)

    val title3 = TextStyle(fontFamily = system, fontSize = 20.sp, lineHeight = 25.sp)
    val headline = TextStyle(fontFamily = system, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, lineHeight = 22.sp)
    val body = TextStyle(fontFamily = system, fontSize = 17.sp, lineHeight = 23.sp)
    val subheadline = TextStyle(fontFamily = system, fontSize = 15.sp, lineHeight = 20.sp)
    val footnote = TextStyle(fontFamily = system, fontSize = 13.sp, lineHeight = 18.sp)
    val caption = TextStyle(fontFamily = system, fontSize = 12.sp, lineHeight = 16.sp)
    val caption2 = TextStyle(fontFamily = system, fontSize = 11.sp, lineHeight = 13.sp)

    /** The small uppercase eyebrow used for section headings. */
    val eyebrow = caption.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 1.4.sp)
}

object ElecGeo {
    val cardCorner = 20.dp
    val deckCorner = 26.dp
    val ctaHeight = 56.dp
    val ctaCorner = 18.dp
    val readableWidth = 760.dp
}

/**
 * Grading haptics have to feel like opposites in the hand: right is a crisp
 * tick into a confirm, wrong is a dull double thud.
 */
object Haptics {
    @Volatile var enabled: Boolean = true
    @Volatile private var view: View? = null
    private val scope = CoroutineScope(Dispatchers.Main)

    fun attach(view: View?) {
        this.view = view
    }

    fun light() = perform(HapticFeedbackConstants.CLOCK_TICK)
    fun soft() = perform(HapticFeedbackConstants.CLOCK_TICK)
    fun rigid() = perform(HapticFeedbackConstants.VIRTUAL_KEY)
    fun success() = perform(if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY)
    fun error() = perform(if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS)

    fun correctAnswer() {
        light()
        scope.launch {
            delay(70)
            success()
        }
    }

    fun wrongAnswer() {
        perform(HapticFeedbackConstants.LONG_PRESS)
        scope.launch {
            delay(110)
            perform(HapticFeedbackConstants.CLOCK_TICK)
        }
    }

    private fun perform(constant: Int) {
        if (!enabled) return
        view?.performHapticFeedback(constant)
    }
}

/** The app's three short UI sounds, respecting the Settings toggle. */
object SoundPlayer {
    enum class Effect(val resource: Int) {
        SUCCESS(R.raw.sound_success),
        MISS(R.raw.sound_miss),
        COMPLETE(R.raw.sound_complete),
    }

    @Volatile var enabled: Boolean = true
    private var pool: SoundPool? = null
    private val ids = mutableMapOf<Effect, Int>()

    fun load(context: Context) {
        if (pool != null) return
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val created = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(attributes).build()
        Effect.entries.forEach { ids[it] = created.load(context, it.resource, 1) }
        pool = created
    }

    fun play(effect: Effect) {
        if (!enabled) return
        val id = ids[effect] ?: return
        pool?.play(id, 0.8f, 0.8f, 1, 0, 1f)
    }
}
