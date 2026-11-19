package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

/**
 * Implemented by the Activity that the platform launches for a W3C Digital
 * Credentials API request. It is the seam between the credential-provider
 * Activity (which owns the {@code Intent} the platform reads its answer from)
 * and {@link IrmaMobileBridge} (which learns the session's outcome from Dart).
 *
 * <p>The bridge dispatches {@code HandleDigitalCredentialsRequestEvent} into the
 * Flutter engine using {@link #getDigitalCredentialsRequestJson()}, and later
 * hands the outcome back through exactly one of the two callbacks below. The
 * platform holds the caller's {@code navigator.credentials.get()} open until
 * the host answers it, so every started session must end in one of them.
 */
public interface DigitalCredentialsHost {
  /**
   * The {@code {"request": {"protocol", "origin", "data"}}} payload for the
   * {@code HandleDigitalCredentialsRequestEvent}, already extracted from the
   * platform's provider request, or {@code null} if this launch carried none.
   */
  String getDigitalCredentialsRequestJson();

  /**
   * The session produced an OpenID4VP Authorization Response. Return it to the
   * platform as the {@code data} member of the response and finish.
   */
  void onDigitalCredentialsResponse(String response);

  /**
   * The session ended without an Authorization Response. {@code reason} is
   * {@code "cancelled"} (the user's own choice — no error to report) or
   * {@code "error"} (a failure the caller may surface). Answer the platform and
   * finish.
   */
  void onDigitalCredentialsFailure(String reason);
}
