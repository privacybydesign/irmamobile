package foundation.privacybydesign.yivi_core.irma_mobile_bridge

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The Go core is one per process, Flutter engines are not: the Activity that
 * fulfils a Digital Credentials API request runs a second engine next to the
 * launcher's. [GoBridgeRelay] is what lets them share the core.
 *
 * The bug these tests pin: each engine used to stop the core when its Activity
 * detached, so the Digital Credentials Activity finishing closed the client
 * under the launcher's engine, whose next event then blocked the platform
 * thread for good.
 */
internal class GoBridgeRelayTest {
    private class RecordingBridge : irmagobridge.IrmaMobileBridge {
        val events = mutableListOf<String>()
        val logs = mutableListOf<String>()

        override fun dispatchFromGo(name: String, payload: String) {
            events.add("$name:$payload")
        }

        override fun debugLog(message: String) {
            logs.add(message)
        }
    }

    @Test
    fun detach_keepsTheCoreRunningWhileAnotherEngineIsAttached() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        relay.attach(digitalCredentials)

        assertFalse(
            relay.detach(digitalCredentials),
            "The core must not be stopped while the launcher's engine still uses it",
        )
    }

    @Test
    fun detach_saysTheCoreMayStopOnceTheLastEngineIsGone() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        relay.attach(digitalCredentials)
        relay.detach(digitalCredentials)

        assertTrue(relay.detach(launcher))
    }

    @Test
    fun detach_ofAnEngineThatNeverAttachedLeavesTheOthersAlone() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        relay.attach(launcher)

        // An engine whose Activity went away before its app was ready.
        assertFalse(relay.detach(RecordingBridge()))

        relay.dispatchFromGo("Event", "{}")
        assertEquals(listOf("Event:{}"), launcher.events)
    }

    @Test
    fun eventsGoToTheEngineThatAttachedLast() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        relay.attach(digitalCredentials)

        relay.dispatchFromGo("Event", "{}")
        relay.debugLog("line")

        assertEquals(listOf("Event:{}"), digitalCredentials.events)
        assertEquals(listOf("line"), digitalCredentials.logs)
        assertTrue(launcher.events.isEmpty())
        assertTrue(launcher.logs.isEmpty())
    }

    @Test
    fun eventsFallBackToTheEarlierEngineWhenTheLastOneDetaches() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        relay.attach(digitalCredentials)
        relay.detach(digitalCredentials)

        relay.dispatchFromGo("Event", "{}")

        assertEquals(listOf("Event:{}"), launcher.events)
        assertTrue(digitalCredentials.events.isEmpty())
    }

    @Test
    fun attachingAgainMovesAnEngineToTheFrontWithoutCountingItTwice() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        relay.attach(digitalCredentials)
        relay.attach(launcher)

        relay.dispatchFromGo("Event", "{}")
        assertEquals(listOf("Event:{}"), launcher.events)

        relay.detach(launcher)
        assertTrue(relay.detach(digitalCredentials))
    }

    @Test
    fun eventsAreDroppedQuietlyWhenNoEngineIsAttached() {
        GoBridgeRelay().dispatchFromGo("Event", "{}")
        GoBridgeRelay().debugLog("line")
    }
}
