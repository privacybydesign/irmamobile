package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Turns the platform's Digital Credentials get-request into the
 * {@code HandleDigitalCredentialsRequestEvent} payload the Dart layer expects.
 *
 * <p>The platform hands over the {@code requestJson} of a
 * {@code GetDigitalCredentialOption} (the W3C {@code digital} member of
 * {@code navigator.credentials.get()}) plus the authenticated caller origin.
 * The core reads a single OpenID4VP request — {@code protocol}, {@code origin}
 * and the raw {@code data} member — so this pulls the OpenID4VP entry out of the
 * request and reshapes it into {@code {"request": {"protocol", "origin",
 * "data"}}}, matching {@code DigitalCredentialsRequest} on the Dart side.
 *
 * <p>Pure and free of Android types so the reshaping can be unit tested without
 * a device. Everything inside {@code data} — the response mode, the
 * {@code dcql_query}, a signature over a signed request — is validated by the
 * core, so nothing is checked here beyond finding an OpenID4VP request.
 */
public final class DigitalCredentialsRequestExtractor {
  private DigitalCredentialsRequestExtractor() {}

  /** OpenID4VP DC API protocol identifiers (OpenID4VP 1.0 Appendix A.1). */
  private static final String PROTOCOL_PREFIX = "openid4vp-v1-";

  /**
   * @param requestJson the {@code requestJson} of the platform's
   *     {@code GetDigitalCredentialOption}.
   * @param origin the caller origin as authenticated by the platform.
   * @return the {@code {"request": {...}}} JSON for the
   *     {@code HandleDigitalCredentialsRequestEvent}.
   * @throws JSONException if no OpenID4VP request can be found in the payload.
   */
  public static String toHandleEventJson(String requestJson, String origin) throws JSONException {
    JSONObject parsed = new JSONObject(requestJson);
    JSONObject openid4vp = findOpenID4VPRequest(parsed);
    if (openid4vp == null) {
      throw new JSONException("no OpenID4VP request found in Digital Credentials request");
    }

    JSONObject request = new JSONObject();
    request.put("protocol", openid4vp.getString("protocol"));
    request.put("origin", origin);
    // `data` stays whatever the verifier sent: the authorization request object
    // for an unsigned request, or {"request": <JWS>} for a signed one. The core
    // reads it as-is, so it is passed through untouched.
    request.put("data", openid4vp.get("data"));

    JSONObject event = new JSONObject();
    event.put("request", request);
    return event.toString();
  }

  /**
   * Finds the OpenID4VP request among the platform's request shapes: a
   * {@code requests} array (current), a {@code providers} array (older drafts),
   * or a single request object at the top level. The first entry whose
   * {@code protocol} is an {@code openid4vp-v1-*} identifier wins; with no
   * protocol field at all, a lone request object is taken as-is.
   */
  private static JSONObject findOpenID4VPRequest(JSONObject parsed) throws JSONException {
    JSONArray requests = parsed.optJSONArray("requests");
    if (requests == null) {
      requests = parsed.optJSONArray("providers");
    }

    if (requests != null) {
      for (int i = 0; i < requests.length(); i++) {
        JSONObject entry = requests.optJSONObject(i);
        if (entry != null && isOpenID4VP(entry.optString("protocol", ""))) {
          return entry;
        }
      }
      return null;
    }

    // No array: a single request object carrying protocol + data directly.
    if (parsed.has("protocol") && parsed.has("data")) {
      return isOpenID4VP(parsed.optString("protocol", "")) ? parsed : null;
    }
    return null;
  }

  private static boolean isOpenID4VP(String protocol) {
    return protocol.startsWith(PROTOCOL_PREFIX);
  }
}
