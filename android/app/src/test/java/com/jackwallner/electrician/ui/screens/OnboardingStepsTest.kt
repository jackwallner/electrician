package com.jackwallner.electrician.ui.screens

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OnboardingStepsTest {
    /** iOS B8: on the plan recap, "Continue" takes a member straight in, past the trial step. */
    @Test
    fun entitledCandidateSkipsTheTrialStep() {
        assertTrue(onboardingSkipsTrial(nextIsTrial = true, isPro = true))
        assertFalse("everyone else is still offered the trial", onboardingSkipsTrial(nextIsTrial = true, isPro = false))
        assertFalse("a member still answers the setup steps", onboardingSkipsTrial(nextIsTrial = false, isPro = true))
    }
}
