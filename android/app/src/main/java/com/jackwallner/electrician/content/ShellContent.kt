package com.jackwallner.electrician.content

import com.jackwallner.electrician.model.Room

object DrillLibrary {
    val rooms: List<Room> get() = ElectricianContent.rooms

    fun room(id: String): Room? = ElectricianContent.room(id)

    /** The room a drill belongs to, so drill screens can report per-room accuracy. */
    fun roomID(forDrillID: String): String = ElectricianContent.roomID(forDrillID)

    val freeItemCount: Int get() = ElectricianContent.freeItemCount
    val membershipItemCount: Int get() = ElectricianContent.membershipItemCount
    val membershipDrillCount: Int get() = ElectricianContent.membershipDrillCount
}

object HowToPlayContent {
    val pages: List<PrimerPage> get() = ElectricianContent.primer

    /** The room the primer points at for an onboarding experience level; a focus area wins. */
    fun recommendedRoom(skillLevel: String, focusAreas: Set<String> = emptySet()): Room {
        DrillLibrary.rooms.firstOrNull { it.id in focusAreas }?.let { return it }
        val roomID = when (skillLevel) {
            "apprentice" -> "conductors-room"
            "working" -> "grounding-room"
            "retaking" -> "calc-room"
            "renewing" -> "grounding-room"
            else -> "basics-room"
        }
        return DrillLibrary.room(roomID) ?: DrillLibrary.rooms.first()
    }
}

data class WhatsNewItem(val id: String, val icon: String, val title: String, val body: String, val isPlus: Boolean = false)
data class WhatsNewRelease(val version: String, val headline: String, val items: List<WhatsNewItem>)

/** Mirrors iOS `WhatsNew.releases`, which ships empty until a release earns notes. */
object WhatsNewContent {
    val releases: List<WhatsNewRelease> = emptyList()
}
