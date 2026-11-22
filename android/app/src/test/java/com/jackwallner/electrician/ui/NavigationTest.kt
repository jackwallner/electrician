package com.jackwallner.electrician.ui

import com.jackwallner.electrician.content.PracticeSkill
import com.jackwallner.electrician.ui.nav.PracticeMode
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NavigationTest {
    /** iOS B4: Close in Fix My Mistakes leaves; only the last item's Finish completes the run. */
    @Test
    fun closingFixMyMistakesPartWayIsNotAFinishedRun() {
        assertFalse(PracticeMode.Review.closeEndsRun)
        assertTrue("an endless run has no last item, so its bar button ends it", PracticeMode.Endless(PracticeSkill.ampacity).closeEndsRun)
        assertTrue(PracticeMode.Timed.closeEndsRun)
    }
}
