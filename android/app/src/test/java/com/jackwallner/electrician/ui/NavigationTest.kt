package com.jackwallner.electrician.ui

import com.jackwallner.electrician.content.PracticeSkill
import com.jackwallner.electrician.ui.nav.AppSheets
import com.jackwallner.electrician.ui.nav.Navigator
import com.jackwallner.electrician.ui.nav.PracticeMode
import com.jackwallner.electrician.ui.nav.Route
import com.jackwallner.electrician.ui.nav.SessionPurpose
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
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

    /** iOS B10: the Exam Warm-Up notification over an open sheet still shows the session. */
    @Test
    fun warmUpNotificationOverOpenSheetsOpensTheSession() {
        val navigator = Navigator()
        navigator.push(Route.Settings)
        val sheets = AppSheets().apply {
            showWhatsNew = true
            showFeedback = true
            paywallSource = "electrician_home_sheet"
        }
        val session = Route.Session(emptyList(), SessionPurpose.GameNightPrep)
        sheets.open(session, navigator)
        assertFalse(sheets.showWhatsNew)
        assertFalse(sheets.showFeedback)
        assertNull(sheets.paywallSource)
        assertEquals(session, navigator.top)
        assertEquals("Home, then the session: Settings is gone", 2, navigator.depth)
    }
}
