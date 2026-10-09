package foundation.privacybydesign.yivi_core.dcapi;

import android.os.SystemClock;

/**
 * Carries one unlock from the Activity that answered a Digital Credentials API request to the wallet
 * Activity the user is handed to afterwards.
 *
 * <p>It exists because the lock lives in Dart, per Flutter engine: {@code IrmaRepository} seeds its
 * locked flag true and nothing outside that engine can see it. A presentation runs in a second
 * engine, so without this the user unlocks to approve a disclosure and then unlocks again, two
 * seconds later, to look at the record of it — twice for one continuous action they never left.
 *
 * <p>This does not weaken the lock so much as restore what one engine used to mean. What is carried
 * is a fact about this process: somebody completed a PIN or biometric unlock in it, moments ago. It
 * is fenced accordingly:
 *
 * <ul>
 *   <li><b>Only after a real unlock.</b> It is marked when a presentation session ends, and a session
 *       cannot start before the app is unlocked — PendingPointerListener waits for exactly that. So
 *       reaching the mark implies an unlock already happened.
 *   <li><b>One shot.</b> Consuming clears it, so a second engine cannot reuse the first one's.
 *   <li><b>Seconds, not minutes.</b> It covers a handover that takes one screen transition; anything
 *       slower is a different situation and gets the lock screen.
 *   <li><b>Process-local.</b> A static field, so it cannot outlive the process, reach the disk, or
 *       be set by anything outside this app.
 * </ul>
 */
public final class UnlockHandover {
  /**
   * How long a handover stays good for. Long enough for an Activity to start and a Flutter engine to
   * boot on a slow device, short enough that it cannot cover a user who put the phone down.
   */
  private static final long VALID_FOR_MS = 15_000;

  private static volatile long unlockedAt;

  private UnlockHandover() {}

  /** Records that the user completed an unlock in this process just now. */
  public static void mark() {
    unlockedAt = SystemClock.elapsedRealtime();
  }

  /**
   * Reports whether a recent unlock is available to carry, and consumes it.
   *
   * <p>Uses elapsedRealtime rather than wall-clock time: the wall clock can move backwards or jump,
   * and a window that widens when the clock changes is not a window.
   */
  public static boolean consume() {
    long at = unlockedAt;
    unlockedAt = 0;
    return at != 0 && SystemClock.elapsedRealtime() - at <= VALID_FOR_MS;
  }
}
