package foundation.privacybydesign.yivi_core.plugins.app_integrity

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

internal class AppIntegrityPluginTest {
    @Test
    fun tracerPid_isZeroWithoutATracer() {
        val status = "Name:\tcardemu\nState:\tR (running)\nTracerPid:\t0\nUid:\t10123\n"
        assertEquals(0, AppIntegrityPlugin.tracerPid(status))
    }

    @Test
    fun tracerPid_isThePidOfAnAttachedTracer() {
        val status = "Name:\tcardemu\nTracerPid:\t4242\nUid:\t10123\n"
        assertEquals(4242, AppIntegrityPlugin.tracerPid(status))
    }

    @Test
    fun tracerPid_isZeroWhenTheStatusCannotBeRead() {
        assertEquals(0, AppIntegrityPlugin.tracerPid(""))
        assertEquals(0, AppIntegrityPlugin.tracerPid("TracerPid:\tgarbage\n"))
    }

    @Test
    fun isEmulator_recognisesTheAndroidEmulator() {
        assertTrue(
            AppIntegrityPlugin.isEmulator(
                "google/sdk_gphone64_arm64/emu64a:14/UE1A.230829.036/11228894:userdebug/dev-keys",
                "ranchu", "sdk_gphone64_arm64", "sdk_gphone64_arm64", "Google",
            )
        )
        assertTrue(AppIntegrityPlugin.isEmulator("generic/vbox86p/vbox86p", "vbox86", "Custom Phone", "vbox86p", "Genymotion"))
    }

    @Test
    fun isEmulator_doesNotFlagRealPhones() {
        assertFalse(
            AppIntegrityPlugin.isEmulator(
                "google/shiba/shiba:15/AP4A.250205.002/12821496:user/release-keys",
                "shiba", "Pixel 8", "shiba", "Google",
            )
        )
        assertFalse(
            AppIntegrityPlugin.isEmulator(
                "samsung/a54xnaeea/a54x:14/UP1A.231005.007/A546BXXS9CXF2:user/release-keys",
                "s5e8835", "SM-A546B", "a54xnaeea", "samsung",
            )
        )
        assertFalse(AppIntegrityPlugin.isEmulator(null, null, null, null, null))
    }

    @Test
    fun isOwnDataDirectory_acceptsWhereAndroidPutsAppData() {
        val pkg = "org.irmacard.cardemu"
        assertTrue(AppIntegrityPlugin.isOwnDataDirectory("/data/user/0/$pkg/files", pkg))
        assertTrue(AppIntegrityPlugin.isOwnDataDirectory("/data/data/$pkg/files", pkg))
        // A work profile or a second user.
        assertTrue(AppIntegrityPlugin.isOwnDataDirectory("/data/user/10/$pkg/files", pkg))
        // Adoptable storage.
        assertTrue(
            AppIntegrityPlugin.isOwnDataDirectory("/mnt/expand/6c3f0bba-5d1c-4a7e-8f0f-1f2f3a4b5c6d/user/0/$pkg/files", pkg)
        )
    }

    @Test
    fun isOwnDataDirectory_rejectsADirectoryInsideAnotherApp() {
        val pkg = "org.irmacard.cardemu"
        assertFalse(
            AppIntegrityPlugin.isOwnDataDirectory("/data/user/0/com.lbe.parallel.intl/parallel_intl/0/$pkg/files", pkg)
        )
        assertFalse(AppIntegrityPlugin.isOwnDataDirectory("/data/user/0/io.va.exposed/virtual/data/user/0/$pkg/files", pkg))
        // The dots of the package name are not wildcards.
        assertFalse(AppIntegrityPlugin.isOwnDataDirectory("/data/user/0/orgXirmacardXcardemu/files", pkg))
    }
}
