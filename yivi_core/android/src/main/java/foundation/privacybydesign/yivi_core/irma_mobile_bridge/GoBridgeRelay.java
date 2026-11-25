package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * The one bridge the Go core is ever started with.
 *
 * <p>The Go core is a process-wide singleton: one client, one map of sessions,
 * and one bridge it sends its events to. Flutter engines are not. The launcher
 * Activity has one, and the Activity that fulfils a Digital Credentials API
 * request starts a second one next to it. If each engine handed the core its
 * own bridge and stopped the core when its Activity went away, the engine that
 * finished first would close the client under the other: every event the
 * survivor then sends blocks on the platform thread waiting for a client that
 * never loads again.
 *
 * <p>So the engines share the core through this relay, which does three things.
 *
 * <ul>
 *   <li>It tells the caller of {@link #detach} whether it was the last engine,
 *       which is the only moment the core may be stopped.
 *   <li>It gives every engine a range of session ids of its own, returned by
 *       {@link #attach}. Each engine numbers its own sessions, and the core
 *       evicts a session when another one starts under the same id, so two
 *       engines both counting from 1 would end each other's sessions.
 *   <li>It forwards the state of a session to the engine that started it, found
 *       by the range its id falls in, so a session in the launcher keeps being
 *       updated while the other Activity is in front. Everything else goes to
 *       the engine that attached most recently, which is the one in front of
 *       the user, and to the one before it once that engine detaches.
 * </ul>
 */
final class GoBridgeRelay implements irmagobridge.IrmaMobileBridge {
  static final GoBridgeRelay INSTANCE = new GoBridgeRelay();

  /**
   * How many session ids each engine gets. Far more than an engine starts in
   * its lifetime, and small enough that the ids of {@link #RANGES} engines fit
   * in the 32 bits a session id has in the core on 32-bit devices.
   */
  static final int SESSION_ID_RANGE = 1_000_000;

  private static final int RANGES = 2_000;

  private static final String SESSION_STATE_EVENT = "SessionStateEvent";

  private static final class Attachment {
    final irmagobridge.IrmaMobileBridge bridge;
    final int sessionIdBase;

    Attachment(irmagobridge.IrmaMobileBridge bridge, int sessionIdBase) {
      this.bridge = bridge;
      this.sessionIdBase = sessionIdBase;
    }
  }

  // In order of attaching; the last one is the engine in front.
  private final List<Attachment> attached = new ArrayList<>();

  // Counts the engines that ever attached, so a range is not handed out again
  // while the core may still hold sessions of the engine that had it before.
  private int rangesHandedOut = 0;

  GoBridgeRelay() {}

  /**
   * Makes {@code bridge} the engine in front from now on.
   *
   * @return the number its session ids count up from: the first engine of the
   *     process gets 0, so a process with one engine numbers its sessions as it
   *     always has
   */
  synchronized int attach(irmagobridge.IrmaMobileBridge bridge) {
    int sessionIdBase = -1;
    for (int i = 0; i < attached.size(); i++) {
      if (attached.get(i).bridge == bridge) {
        sessionIdBase = attached.remove(i).sessionIdBase;
        break;
      }
    }
    if (sessionIdBase < 0) {
      sessionIdBase = (rangesHandedOut % RANGES) * SESSION_ID_RANGE;
      rangesHandedOut++;
    }
    attached.add(new Attachment(bridge, sessionIdBase));
    return sessionIdBase;
  }

  /**
   * Stops forwarding to {@code bridge}.
   *
   * @return whether no bridge is attached any more, so the core has no engine
   *     left to serve and may be stopped
   */
  synchronized boolean detach(irmagobridge.IrmaMobileBridge bridge) {
    for (int i = 0; i < attached.size(); i++) {
      if (attached.get(i).bridge == bridge) {
        attached.remove(i);
        break;
      }
    }
    return attached.isEmpty();
  }

  private synchronized irmagobridge.IrmaMobileBridge front() {
    return attached.isEmpty() ? null : attached.get(attached.size() - 1).bridge;
  }

  /**
   * The engine that started the session with this id, or the one in front when
   * that engine is gone or the id is in no range that was handed out: an engine
   * ignores the state of a session it does not know.
   */
  private synchronized irmagobridge.IrmaMobileBridge ownerOfSession(int sessionId) {
    // Ids count up from base + 1, so the last id of a range is the next base.
    int base = sessionId <= 0 ? -1 : ((sessionId - 1) / SESSION_ID_RANGE) * SESSION_ID_RANGE;
    for (Attachment attachment : attached) {
      if (attachment.sessionIdBase == base) {
        return attachment.bridge;
      }
    }
    return front();
  }

  @Override
  public void dispatchFromGo(String name, String payload) {
    irmagobridge.IrmaMobileBridge receiver = front();
    if (SESSION_STATE_EVENT.equals(name)) {
      try {
        int sessionId = new JSONObject(payload).getJSONObject("session_state").getInt("id");
        receiver = ownerOfSession(sessionId);
      } catch (JSONException | RuntimeException e) {
        // Not a payload this relay understands; the engine in front gets it.
      }
    }
    if (receiver != null) {
      receiver.dispatchFromGo(name, payload);
    }
  }

  @Override
  public void debugLog(String message) {
    irmagobridge.IrmaMobileBridge receiver = front();
    if (receiver != null) {
      receiver.debugLog(message);
    }
  }
}
