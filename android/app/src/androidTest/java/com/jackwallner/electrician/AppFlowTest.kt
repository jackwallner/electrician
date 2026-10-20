package com.jackwallner.electrician

import android.content.Intent
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The first-run path, the free drills, and the paid boundary, on a real device. */
@RunWith(AndroidJUnit4::class)
class AppFlowTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    private fun launch(onboarded: Boolean, forcePro: Boolean = false, skill: String? = null) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
            .putExtra("resetAll", true)
            .putExtra("uiTest", true)
            .putExtra("onboarded", onboarded)
            .putExtra("forcePro", forcePro)
            .putExtra("appearance", "light")
        skill?.let { intent.putExtra("skillLevel", it) }
        scenario = ActivityScenario.launch(intent)
    }

    @After
    fun tearDown() {
        scenario?.close()
    }

    private fun waitFor(text: String, timeout: Long = 15_000) {
        compose.waitUntil(timeout) {
            compose.onAllNodes(hasText(text, substring = true) or hasContentDescription(text) or hasTestTag(text))
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Waits until exactly one node carries [tag] (transitions briefly show two), then taps it. */
    private fun tag(tag: String) {
        compose.waitUntil(15_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
        compose.onNodeWithTag(tag).performClick()
        compose.waitForIdle()
    }

    private fun scrollTag(tag: String) {
        compose.waitUntil(15_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
        compose.onNodeWithTag(tag).performScrollTo().performClick()
        compose.waitForIdle()
    }

    @Test
    fun twelveStepOnboardingGatesSetupAndLandsOnTheCandidatesHome() {
        launch(onboarded = false)
        waitFor("The exam is open book")
        repeat(3) { tag("onboarding-primary") }
        waitFor("Which licence?")
        tag("track-journeyman")
        tag("onboarding-primary")
        waitFor("Where are you sitting it?")
        // Continue is gated until a jurisdiction is chosen.
        tag("onboarding-primary")
        waitFor("Where are you sitting it?")
        compose.onNodeWithTag("jurisdiction-search").performTextInput("Texas")
        scrollTag("jurisdiction-TX")
        tag("onboarding-primary")
        waitFor("Which code edition?")
        tag("onboarding-primary")
        waitFor("When is the exam?")
        scrollTag("date-14")
        waitFor("study-pace")
        tag("onboarding-primary")
        tag("skill-working")
        tag("onboarding-primary")
        waitFor("What do you want to hit hardest?")
        scrollTag("focus-grounding-room")
        tag("onboarding-primary")
        tag("reminder-no")
        tag("onboarding-primary")
        waitFor("Your plan")
        waitFor("Texas")
        tag("onboarding-primary")
        tag("soft-exit")
        waitFor("Six rooms, one exam")
        tag("tour-skip")
        waitFor("Journeyman Prep")
        waitFor("exam-target")
    }

    @Test
    fun freeQuizGradesAndFinishes() {
        launch(onboarded = true)
        scrollTag("room-basics-room")
        tag("drill-navigation-quiz")
        repeat(4) {
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("drill-score")
        tag("drill-done")
        waitFor("Code Basics")
    }

    @Test
    fun paidModesAndRoomsOpenThePaywallForFreeUsers() {
        launch(onboarded = true)
        tag("tile-endless")
        waitFor("Restore")
        waitFor("Terms of Use")
        waitFor("Privacy Policy")
    }

    @Test
    fun paidRoomIsLockedForFreeUsers() {
        launch(onboarded = true)
        scrollTag("room-calc-room")
        waitFor("Every drill here opens with Electrician+")
        tag("drill-worked-examples")
        waitFor("Restore")
    }

    @Test
    fun fieldToolsAreFreeAndCompute() {
        launch(onboarded = true)
        tag("tile-field-tools")
        tag("tool-ampacity")
        waitFor("tool-result")
        waitFor("Allowable")
    }

    @Test
    fun membersGetEndlessGeneratedCalculationsWithNumberedWorking() {
        launch(onboarded = true, forcePro = true)
        tag("tile-endless")
        tag("skill-ampacity")
        waitFor("Find the allowable ampacity")
        waitFor("givens")
        tag("choice-0")
        waitFor("working")
    }

    @Test
    fun membersWorkTheAuthoredCalculations() {
        launch(onboarded = true, forcePro = true)
        scrollTag("room-calc-room")
        tag("drill-worked-examples")
        tag("choice-0")
        waitFor("working")
        waitFor("2023 NEC ·")
    }
}
