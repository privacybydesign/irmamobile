package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

import java.util.ArrayList;
import java.util.List;

/**
 * The one bridge the Go core is ever started with.
 *
 * <p>The Go core is a process-wide singleton: one client, and one bridge it
 * sends its events to. Flutter engines are not. The launcher Activity has one,
 * and the Activity that fulfils a Digital Credentials API request starts a
 * second one next to it. If each engine handed the core its own bridge and
 * stopped the core when its Activity went away, the engine that finished first
 * would close the client under the other: every event the survivor then sends
 * blocks on the platform thread waiting for a client that never loads again.
 *
 * <p>So the engines share the core through this relay. It forwards what the
 * core sends to the engine that attached most recently, which is the one in
 * front of the user, and falls back to the one before it when that engine
 * detaches. {@link #detach} tells the caller whether it was the last, which is
 * the only moment the core may be stopped.
 */
final class GoBridgeRelay implements irmagobridge.IrmaMobileBridge {
  static final GoBridgeRelay INSTANCE = new GoBridgeRelay();

  // In order of attaching; the last one receives what the core sends.
  private final List<irmagobridge.IrmaMobileBridge> attached = new ArrayList<>();

  GoBridgeRelay() {}

  /** Makes {@code bridge} the receiver of what the core sends from now on. */
  synchronized void attach(irmagobridge.IrmaMobileBridge bridge) {
    attached.remove(bridge);
    attached.add(bridge);
  }

  /**
   * Stops forwarding to {@code bridge}.
   *
   * @return whether no bridge is attached any more, so the core has no engine
   *     left to serve and may be stopped
   */
  synchronized boolean detach(irmagobridge.IrmaMobileBridge bridge) {
    attached.remove(bridge);
    return attached.isEmpty();
  }

  private synchronized irmagobridge.IrmaMobileBridge receiver() {
    return attached.isEmpty() ? null : attached.get(attached.size() - 1);
  }

  @Override
  public void dispatchFromGo(String name, String payload) {
    irmagobridge.IrmaMobileBridge receiver = receiver();
    if (receiver != null) {
      receiver.dispatchFromGo(name, payload);
    }
  }

  @Override
  public void debugLog(String message) {
    irmagobridge.IrmaMobileBridge receiver = receiver();
    if (receiver != null) {
      receiver.debugLog(message);
    }
  }
}
