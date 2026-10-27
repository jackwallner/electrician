package com.jackwallner.electrician.model

import java.time.LocalDate

import org.junit.Assert.*
import org.junit.Test

import com.jackwallner.electrician.content.ElectricianContent

class CandidateProfileTest {
    private val today = LocalDate.of(2026, 10, 17)

    @Test fun jurisdictionIsRequiredAndDefaultTrackDoesNotRequireAnotherTap() {
        val empty = CandidateProfile()
        assertFalse(empty.canCompleteSetup)
        assertFalse(empty.completeSetup().setupComplete)
        assertFalse(empty.selectTrack(LicenseTrack.master).canCompleteSetup)
        assertFalse(empty.copy(jurisdiction = " \n ").canCompleteSetup)
        assertTrue(empty.copy(jurisdiction = "Colorado").canCompleteSetup)
    }

    @Test fun savedProfileRoundTripsOriginalRawKeysAndAllTargetAnswers() {
        val original = CandidateProfile().selectTrack(LicenseTrack.master).copy(jurisdiction = "Colorado", edition = CandidateEdition.different,
            examDate = today.plusDays(10), experience = ExperienceLevel.working, focusAreas = setOf("calc-room"), dailyGoal = 25).completeSetup()
        val encoded = original.encode()
        assertTrue(encoded.contains("candidate.licenseTrack"))
        assertTrue(encoded.contains("electrician.skillLevel"))
        assertEquals(original, CandidateProfile.decode(encoded))
        assertTrue(original.hasSelectedTrack)
        assertEquals(CandidateEdition.nec2023, CandidateProfile.decode("{}").edition)
    }

    @Test fun unsureEditionUsesStateSuggestionAndUnknownAdoptionStaysUnresolved() {
        val texas = CandidateProfile(jurisdiction = "Texas", edition = CandidateEdition.unsure)
        assertEquals(2023, texas.suggestedEdition)
        assertEquals(2023, texas.resolvedEdition)
        assertTrue(texas.editionMatchesApp)
        assertEquals("2023 NEC (from Texas)", texas.editionSummary)
        assertEquals("2023 NEC", texas.editionShortSummary)
        val missouri = texas.copy(jurisdiction = "Missouri")
        assertNull(missouri.suggestedEdition)
        assertNull(missouri.resolvedEdition)
        assertFalse(missouri.editionMatchesApp)
    }

    @Test fun stateChangeDoesNotRewriteExplicitEditionAndLegacyFreeTextRemainsUsable() {
        val profile = CandidateProfile(edition = CandidateEdition.nec2017).selectJurisdiction(Jurisdictions.named("Texas")!!)
        assertEquals(CandidateEdition.nec2017, profile.edition)
        assertEquals(2017, profile.resolvedEdition)
        assertFalse(profile.editionMatchesApp)
        assertNull(profile.copy(jurisdiction = "somewhere else").jurisdictionRecord)
        assertTrue(profile.copy(jurisdiction = "somewhere else").canCompleteSetup)
        assertNull(profile.copy(edition = CandidateEdition.different).resolvedEdition)
    }

    @Test fun dailySuggestionFollowsPaceWithoutUnboundedCramTargets() {
        val profile = CandidateProfile()
        listOf(2 to (StudyPace.cram to 60), 10 to (StudyPace.sprint to 40), 30 to (StudyPace.build to 20), 400 to (StudyPace.foundation to 15)).forEach { (days, expected) ->
            val dated = profile.copy(examDate = today.plusDays(days.toLong()))
            assertEquals(expected.first, dated.pace(today))
            assertEquals(expected.second, dated.suggestedDailyQuestions(today))
        }
        assertEquals(StudyPace.undated, profile.pace(today))
        assertEquals(15, profile.suggestedDailyQuestions(today))
        assertNull(profile.countdown(today))
    }

    @Test fun examDayAndPastDateStillHaveAPlanAndAllPaceBoundariesMatch() {
        val profile = CandidateProfile(examDate = today)
        assertEquals(0, profile.daysUntilExam(today))
        assertEquals("Exam today", profile.countdown(today))
        assertEquals(StudyPace.cram, profile.pace(today))
        assertEquals(40, profile.suggestedDailyQuestions(today))
        assertEquals(0, profile.copy(examDate = today.minusDays(2)).daysUntilExam(today))
        listOf(3 to StudyPace.cram, 4 to StudyPace.sprint, 14 to StudyPace.sprint, 15 to StudyPace.build, 60 to StudyPace.build, 61 to StudyPace.foundation).forEach { (days, pace) ->
            assertEquals(pace, profile.copy(examDate = today.plusDays(days.toLong())).pace(today))
        }
        assertEquals("1 day out", profile.copy(examDate = today.plusDays(1)).countdown(today))
        assertEquals("10 days out", profile.copy(examDate = today.plusDays(10)).countdown(today))
    }

    @Test fun focusReordersRoomsWithoutFilteringAndTogglesBothWays() {
        val original = CandidateProfile()
        val focused = original.toggleFocus("calc-room")
        assertEquals(setOf("calc-room"), focused.focusAreas)
        assertEquals("calc-room", focused.orderedRooms.first().id)
        assertEquals(ElectricianContent.rooms.map { it.id }.toSet(), focused.orderedRooms.map { it.id }.toSet())
        assertEquals(original.orderedRooms, focused.toggleFocus("calc-room").orderedRooms)
        assertEquals("Journeyman · Colorado", original.copy(jurisdiction = "Colorado").completeSetup().targetSummary)
    }

    @Test fun allJurisdictionsPreserveAdoptionAuthorityAndEditionAdvice() {
        assertEquals(52, Jurisdictions.all.size)
        assertEquals(52, Jurisdictions.all.map { it.id }.toSet().size)
        assertTrue(Jurisdictions.reviewed.isNotBlank())
        Jurisdictions.all.forEach { record ->
            assertEquals(record, Jurisdictions.named(" ${record.name.lowercase()} "))
            assertTrue(record.authority.isNotBlank())
            val profile = CandidateProfile(jurisdiction = record.name, edition = CandidateEdition.unsure)
            assertEquals(record.commonEdition, profile.resolvedEdition)
            assertTrue(profile.editionAdvice.isNotBlank())
            if (record.commonEdition != null) assertFalse(profile.editionAdvice.startsWith("Set your code edition"))
        }
        assertNull(Jurisdictions.other.commonEdition)
        assertNull(Jurisdictions.other.examProvider)
    }
}
