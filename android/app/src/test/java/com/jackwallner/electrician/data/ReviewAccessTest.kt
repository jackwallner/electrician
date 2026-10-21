package com.jackwallner.electrician.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReviewAccessTest {
    // A throwaway fixture, not a real reviewer code.
    private val fixture = "local-review-fixture"
    private val digest = ReviewAccess.sha256(fixture)

    @Test
    fun digestIsLowercaseSha256Hex() {
        assertTrue(Regex("[a-f0-9]{64}").matches(digest))
        assertEquals(
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            ReviewAccess.sha256(""),
        )
    }

    @Test
    fun unconfiguredAccessCannotUnlock() {
        assertFalse(ReviewAccess(InMemoryStore(), "").activate(fixture))
        assertFalse(ReviewAccess(InMemoryStore(), "invalid").activate("invalid"))
        assertFalse(ReviewAccess(InMemoryStore(), "").isGranted)
    }

    @Test
    fun wrongOrBlankCodeDoesNotGrantAccess() {
        val values = InMemoryStore()
        val access = ReviewAccess(values, digest)
        assertFalse(access.activate("wrong"))
        assertFalse(access.activate("  "))
        assertFalse(access.isGranted)
        assertTrue(values.keys().isEmpty())
    }

    @Test
    fun validCodePersistsOnlyTheDigest() {
        val values = InMemoryStore()
        assertTrue(ReviewAccess(values, digest).activate(" $fixture "))
        assertTrue(ReviewAccess(values, digest).isGranted)
        assertEquals(setOf("reviewAccessDigest"), values.keys())
        assertEquals(digest, values.getString("reviewAccessDigest"))
    }

    @Test
    fun rotatingTheDigestRevokesAnExistingGrant() {
        val values = InMemoryStore()
        assertTrue(ReviewAccess(values, digest).activate(fixture))
        assertFalse(ReviewAccess(values, ReviewAccess.sha256("another-fixture")).isGranted)
        assertFalse(ReviewAccess(values, "").isGranted)
    }
}
