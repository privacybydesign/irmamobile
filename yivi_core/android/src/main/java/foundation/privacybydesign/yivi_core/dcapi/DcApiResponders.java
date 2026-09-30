package foundation.privacybydesign.yivi_core.dcapi;

import androidx.annotation.Nullable;

/**
 * Holds the {@link DcApiResponder} waiting for the outcome of a Digital Credentials API session.
 *
 * <p>Static for the same reason as {@link DcApiRegistration}: the producer is the Go bridge, created
 * deep inside the Flutter engine's lifecycle, and the consumer is an Activity that exists only for
 * the duration of one request. One slot is enough because the presentation Activity is {@code
 * singleInstance} and the platform starts one request at a time.
 *
 * <p>Absent is the ordinary state — it is what every session that did not come from a credential
 * picker looks like.
 */
public final class DcApiResponders {
  @Nullable private static volatile DcApiResponder responder;

  private DcApiResponders() {}

  /** Installs the responder to deliver the next session's outcome to. */
  public static void install(@Nullable DcApiResponder value) {
    responder = value;
  }

  /**
   * Removes the given responder, if it is still the installed one.
   *
   * <p>Compared rather than cleared outright so an Activity being destroyed late cannot uninstall
   * the responder of the request that replaced it.
   */
  public static void uninstall(DcApiResponder value) {
    if (responder == value) {
      responder = null;
    }
  }

  /** Returns the responder waiting for a session outcome, or null when nothing is. */
  @Nullable
  public static DcApiResponder get() {
    return responder;
  }
}
