package com.jackwallner.electrician.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

import com.jackwallner.electrician.data.CandidateCatalog
import com.jackwallner.electrician.data.CandidateProfile
import com.jackwallner.electrician.ui.screens.ROOM_ACCENT_IDS

class ShellContentTest {
    @Test fun everyRoomClaimsAnAccentAndEverySkillPointsAtARealRoom() {
        val rooms = DrillLibrary.rooms.map { it.id }.toSet()
        assertEquals(rooms, ROOM_ACCENT_IDS)
        PracticeSkill.entries.forEach { assertTrue(it.name, it.roomID in rooms) }
    }

    @Test fun threeRoomsAreFreeAndInstallationRulesIsOneOfThem() {
        assertEquals(setOf("basics-room", "conductors-room", "install-room"), DrillLibrary.rooms.filter { it.isFree }.map { it.id }.toSet())
        assertTrue(DrillLibrary.freeItemCount > 0 && DrillLibrary.membershipItemCount > 0)
    }

    @Test fun paceFollowsTheExamDateNotAFixedDivision() {
        assertEquals("undated", CandidateProfile.paceID(null))
        assertEquals("cram", CandidateProfile.paceID(1))
        assertEquals("sprint", CandidateProfile.paceID(14))
        assertEquals("build", CandidateProfile.paceID(30))
        assertEquals("foundation", CandidateProfile.paceID(90))
        assertEquals(40, CandidateProfile.suggestedDaily(0))
        assertEquals(60, CandidateProfile.suggestedDaily(1))
        assertEquals(29, CandidateProfile.suggestedDaily(14))
        assertEquals(20, CandidateProfile.suggestedDaily(30))
        assertEquals(15, CandidateProfile.suggestedDaily(365))
        assertTrue(CandidateCatalog.pace("cram").isUrgent)
        assertFalse(CandidateCatalog.pace("foundation").isUrgent)
    }

    @Test fun candidateRawValuesStayPersistable() {
        assertTrue(CandidateCatalog.tracks.any { it.id == "journeyman" } && CandidateCatalog.tracks.any { it.id == "master" })
        assertTrue(CandidateCatalog.editions.any { it.id == "nec2023" } && CandidateCatalog.editions.any { it.id == "unsure" })
        assertTrue(listOf("new", "apprentice", "working").all { id -> CandidateCatalog.experience.any { it.id == id } })
        assertEquals(53, CandidateCatalog.jurisdictions.size)
        assertEquals("XX", CandidateCatalog.other.id)
    }

    @Test fun noEmDashesInGeneratedOrAuthoredCopy() {
        SessionBuilder.choicePool(true).forEach { item ->
            assertFalse(item.id, (item.prompt + item.explanation + item.choices.joinToString()).contains("—"))
        }
        HowToPlayContent.pages.forEach { assertFalse(it.id, (it.title + it.body).contains("—")) }
    }
}
