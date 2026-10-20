package com.jackwallner.electrician

import android.content.Intent
import com.jackwallner.electrician.data.Appearance

/**
 * Debug-only launch extras for tests and screenshots, the Android side of the
 * iOS launch arguments. None of this is compiled into a release build.
 *
 *     adb shell am start -n com.jackwallner.electrician/.MainActivity \
 *         --ez resetAll true --ez onboarded true --ez forcePro true --es appearance dark
 */
object DebugLaunchOptions {
    fun apply(graph: AppGraph, intent: Intent?) {
        val extras = intent?.extras ?: return
        if (extras.getBoolean("uiTest")) graph.review.isAutomationRun = true
        if (extras.getBoolean("resetAll")) {
            graph.resetProgress()
            graph.progress.setOnboarded(false)
            graph.defaults.keys().filter { it.startsWith("electrician.") || it.startsWith("candidate.") || it.startsWith("whatsnew.") || it.startsWith("reviewPrompt.") }
                .forEach(graph.defaults::remove)
        }
        extras.getString("skillLevel")?.let { graph.defaults.putString("electrician.skillLevel", it) }
        if (extras.getBoolean("onboarded")) {
            graph.whatsNew.markCurrentAsBaseline()
            graph.progress.setOnboarded(true)
        }
        if (extras.getBoolean("seedProgress")) ScreenshotFixtures.seed(graph)
        extras.getString("jurisdiction")?.let(graph.candidate::updateJurisdiction)
        if (extras.containsKey("examInDays")) graph.candidate.updateExamDate(graph.clock.today().plusDays(extras.getInt("examInDays").toLong()))
        if (extras.getBoolean("forcePro")) graph.subscriptions.forceProForDebug()
        extras.getString("appearance")?.let { graph.settings.updateAppearance(Appearance.fromRaw(it)) }
    }
}
