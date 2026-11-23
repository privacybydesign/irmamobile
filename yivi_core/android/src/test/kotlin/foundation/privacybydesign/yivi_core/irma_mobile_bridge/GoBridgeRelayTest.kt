package foundation.privacybydesign.yivi_core.irma_mobile_bridge

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The Go core is one per process, Flutter engines are not: the Activity that
 * fulfils a Digital Credentials API request runs a second engine next to the
 * launcher's. [GoBridgeRelay] is what lets them share the core.
 *
 * The bugs these tests pin:
 * - Each engine used to stop the core when its Activity detached, so the
 *   Digital Credentials Activity finishing closed the client under the
 *   launcher's engine, whose next event then blocked the platform thread for
 *   good.
 * - Each engine numbers its sessions itself and the core keeps them in one map,
 *   so two engines both counting from 1 evicted each other's sessions, and the
 *   state of a session went to whichever engine was in front, not to the one
 *   showing it.
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

    // What the Go bridge sends: the indented JSON of its sessionStateEvent. The
    // requestor has an id of its own, which must not be taken for the session's.
    private fun sessionState(id: Int) =
        """
        {
            "session_state": {
                "id": $id,
                "status": "request_permission",
                "requestor": {
                    "id": "42"
                }
            }
        }
        """.trimIndent()

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
        val launcherBase = relay.attach(launcher)
        relay.attach(digitalCredentials)

        assertEquals(launcherBase, relay.attach(launcher), "An engine keeps its session ids")

        relay.dispatchFromGo("Event", "{}")
        assertEquals(listOf("Event:{}"), launcher.events)

        relay.detach(launcher)
        assertTrue(relay.detach(digitalCredentials))
    }

    @Test
    fun eventsAreDroppedQuietlyWhenNoEngineIsAttached() {
        GoBridgeRelay().dispatchFromGo("Event", "{}")
        GoBridgeRelay().dispatchFromGo("SessionStateEvent", sessionState(1))
        GoBridgeRelay().debugLog("line")
    }

    @Test
    fun theFirstEngineNumbersItsSessionsAsASingleEngineAlwaysHas() {
        assertEquals(0, GoBridgeRelay().attach(RecordingBridge()))
    }

    @Test
    fun everyEngineGetsSessionIdsOfItsOwn() {
        val relay = GoBridgeRelay()
        val launcherBase = relay.attach(RecordingBridge())
        val digitalCredentialsBase = relay.attach(RecordingBridge())

        assertNotEquals(launcherBase, digitalCredentialsBase)
        assertTrue(
            Math.abs(launcherBase - digitalCredentialsBase) >= GoBridgeRelay.SESSION_ID_RANGE,
            "The ranges must not overlap",
        )
    }

    @Test
    fun aRangeIsNotHandedOutAgainWhenItsEngineIsGone() {
        val relay = GoBridgeRelay()
        relay.attach(RecordingBridge())
        val first = RecordingBridge()
        val firstBase = relay.attach(first)
        relay.detach(first)

        // The core may still hold sessions the first engine started.
        assertNotEquals(firstBase, relay.attach(RecordingBridge()))
    }

    @Test
    fun theStateOfASessionGoesToTheEngineThatStartedIt() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        val launcherBase = relay.attach(launcher)
        val digitalCredentialsBase = relay.attach(digitalCredentials)

        // The first id an engine hands out, and the last one of its range.
        relay.dispatchFromGo("SessionStateEvent", sessionState(launcherBase + 1))
        relay.dispatchFromGo(
            "SessionStateEvent",
            sessionState(launcherBase + GoBridgeRelay.SESSION_ID_RANGE),
        )
        relay.dispatchFromGo("SessionStateEvent", sessionState(digitalCredentialsBase + 1))

        assertEquals(2, launcher.events.size, "The launcher's session must keep being updated")
        assertEquals(1, digitalCredentials.events.size)
        assertTrue(digitalCredentials.events.single().contains("\"id\": ${digitalCredentialsBase + 1}"))
    }

    @Test
    fun theStateOfASessionWhoseEngineIsGoneGoesToTheEngineInFront() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        val digitalCredentialsBase = relay.attach(digitalCredentials)
        relay.detach(digitalCredentials)

        relay.dispatchFromGo("SessionStateEvent", sessionState(digitalCredentialsBase + 1))

        assertEquals(1, launcher.events.size)
    }

    @Test
    fun aSessionStateThatCannotBeReadGoesToTheEngineInFront() {
        val relay = GoBridgeRelay()
        val launcher = RecordingBridge()
        val digitalCredentials = RecordingBridge()
        relay.attach(launcher)
        relay.attach(digitalCredentials)

        relay.dispatchFromGo("SessionStateEvent", "not json")
        relay.dispatchFromGo("SessionStateEvent", "{}")

        assertEquals(2, digitalCredentials.events.size)
        assertTrue(launcher.events.isEmpty())
    }
}
