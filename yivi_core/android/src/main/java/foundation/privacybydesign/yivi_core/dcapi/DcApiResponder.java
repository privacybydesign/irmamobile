package foundation.privacybydesign.yivi_core.dcapi;

/**
 * Receives the outcome of a Digital Credentials API session, so the Activity the platform is waiting
 * on can answer it.
 *
 * <p>The wallet's own session machinery has nowhere to put this. A session ends by telling the app
 * what happened, and for every other transport that is the end of it — the response has already gone
 * to a response_uri, or there was nothing to send. A DC API response goes back through the Activity
 * that was started to obtain it, in a result the caller is blocked on, so something has to carry it
 * from the session's last event to that Activity.
 *
 * <p>Exactly one session can be outstanding: the presentation Activity is {@code singleInstance} and
 * the platform starts one at a time.
 */
public interface DcApiResponder {
  /**
   * The wallet produced a response.
   *
   * @param response the sealed response as the Go core emitted it, to hand back unchanged. For
   *     org-iso-mdoc it is an HPKE-encrypted DeviceResponse that only the reader can open, so
   *     nothing here can or should inspect it.
   */
  void onResponse(String response);

  /**
   * The session ended without a response — the user refused, dismissed it, or it failed.
   *
   * @param reason short description for the caller's error, not for the user; the user has already
   *     seen whatever the wallet showed them.
   */
  void onFailure(String reason);

  /**
   * The user is finished with the screen, so the prepared result can be handed back.
   *
   * <p>Separate from {@link #onResponse} because the two happen at different times and for different
   * reasons. A response exists the moment the wallet stops working; the user has read what was
   * shared some seconds later. Closing on the first of those returned them to the browser mid-
   * animation, and for a zero-knowledge presentation that screen is the only record they will ever
   * have of what was proved — an unlinkable proof leaves nothing else to look at.
   */
  void onClosed();
}
