package com.jackwallner.electrician

import android.content.Intent
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The Play reviewer unlock. Pass the throwaway code whose SHA-256 is in
 * local.properties with `-Pandroid.testInstrumentationRunnerArguments.reviewCode=...`.
 */
@RunWith(AndroidJUnit4::class)
class ReviewerUnlockTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    @After
    fun tearDown() {
        scenario?.close()
    }

    @Test
    fun longPressOnVersionRejectsAWrongCodeAndUnlocksWithTheRightOne() {
        val code = checkNotNull(InstrumentationRegistry.getArguments().getString("reviewCode")) {
            "Supply the throwaway reviewer code as the reviewCode instrumentation argument."
        }
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as ElectricianApplication
        val intent = Intent(app, MainActivity::class.java)
            .putExtra("uiTest", true)
            .putExtra("onboarded", true)
            .putExtra("appearance", "light")
        scenario = ActivityScenario.launch(intent)
        assertFalse(app.graph.subscriptions.isPro)

        compose.waitUntil(15_000) { compose.onAllNodes(hasContentDescription("Settings")).fetchSemanticsNodes().isNotEmpty() }
        compose.onNodeWithContentDescription("Settings").performClick()
        compose.waitUntil(15_000) { compose.onAllNodes(hasTestTag("version-row")).fetchSemanticsNodes().isNotEmpty() }
        compose.onNodeWithTag("version-row").performScrollTo().performTouchInput { longClick() }

        compose.onNodeWithTag("reviewer-code").performTextInput("wrong")
        compose.onNodeWithText("Unlock").performClick()
        compose.onNodeWithText("That code isn't valid.").assertIsDisplayed()
        assertFalse(app.graph.subscriptions.isPro)

        compose.onNodeWithTag("reviewer-code").performTextClearance()
        compose.onNodeWithTag("reviewer-code").performTextInput(code)
        compose.onNodeWithText("Unlock").performClick()
        compose.waitForIdle()
        assertTrue(app.graph.subscriptions.isPro)
        compose.onAllNodes(hasTestTag("reviewer-code")).fetchSemanticsNodes().let { assertTrue(it.isEmpty()) }
    }
}
