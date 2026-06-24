package foundation.privacybydesign.yivi_core

import android.content.Intent
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.Mockito

/**
 * Regression test for the Android deep-link session-replay bug (#568).
 *
 * Before the fix, the launching intent's deep link was replayed on every bridge
 * (re)creation. When Android relaunches the app from recents — or restores the task
 * after a process kill — it replays the original intent with
 * [Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY] set, which made a stale (already
 * consumed) session URL fire again as a brand new session.
 *
 * [YiviCorePlugin.shouldDropDeepLink] is the guard that prevents this. These tests
 * pin both branches.
 */
internal class YiviCorePluginTest {
    private fun intentWithFlags(flags: Int): Intent {
        val intent = Mockito.mock(Intent::class.java)
        Mockito.`when`(intent.flags).thenReturn(flags)
        return intent
    }

    @Test
    fun shouldDropDeepLink_dropsLinkWhenLaunchedFromHistory() {
        val intent = intentWithFlags(Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY)

        assertTrue(
            YiviCorePlugin.shouldDropDeepLink(intent),
            "A deep link replayed from recents/history must be dropped to avoid a stale session replay",
        )
    }

    @Test
    fun shouldDropDeepLink_dropsLinkWhenHistoryFlagCombinedWithOtherFlags() {
        val intent = intentWithFlags(
            Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY or
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )

        assertTrue(
            YiviCorePlugin.shouldDropDeepLink(intent),
            "The history flag must be detected even when other intent flags are set",
        )
    }

    @Test
    fun shouldDropDeepLink_keepsLinkForFreshLaunch() {
        val intent = intentWithFlags(0)

        assertFalse(
            YiviCorePlugin.shouldDropDeepLink(intent),
            "A genuine deep-link launch (no history flag) must be kept",
        )
    }

    @Test
    fun shouldDropDeepLink_keepsLinkForOtherFlagsWithoutHistory() {
        val intent = intentWithFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )

        assertFalse(
            YiviCorePlugin.shouldDropDeepLink(intent),
            "Unrelated intent flags must not be mistaken for a replay from history",
        )
    }
}
