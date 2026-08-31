package foundation.privacybydesign.irmamobile;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.credentials.CredentialOption;
import androidx.credentials.DigitalCredential;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.GetDigitalCredentialOption;
import androidx.credentials.exceptions.GetCredentialCancellationException;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.exceptions.GetCredentialUnknownException;
import androidx.credentials.provider.CallingAppInfo;
import androidx.credentials.provider.PendingIntentHandler;
import androidx.credentials.provider.ProviderGetCredentialRequest;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import foundation.privacybydesign.yivi_core.irma_mobile_bridge.DigitalCredentialsHost;
import foundation.privacybydesign.yivi_core.irma_mobile_bridge.DigitalCredentialsRequestExtractor;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * The Activity the platform launches to fulfil a W3C Digital Credentials API
 * request routed to Yivi through the Android Credential Manager. It reads the
 * OpenID4VP request out of the platform's provider request, runs the ordinary
 * Yivi session UI in its own Flutter engine, and hands the platform back either
 * the Authorization Response or the reason the session ended without one.
 *
 * <p>Separate from {@link MainActivity} because the platform holds the caller's
 * {@code navigator.credentials.get()} open until this Activity returns a result
 * and finishes — a lifecycle {@link MainActivity} (the launcher task) must not
 * take on.
 */
public class DigitalCredentialsActivity extends FlutterFragmentActivity
    implements DigitalCredentialsHost {
  private static final String TAG = "DigitalCredentials";

  // Privileged-caller (browser) allowlist consulted to read the web origin a
  // browser relayed the request on behalf of. Bundled as an asset so it can be
  // refreshed without code changes.
  private static final String ALLOWLIST_ASSET = "digital_credentials/privileged_allowlist.json";

  private String requestJson;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    // Read the request before the engine attaches: the plugin wires this host to
    // the bridge during the engine's onAttachedToActivity, inside super.onCreate.
    requestJson = extractRequestJson();
    super.onCreate(savedInstanceState);
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  @Override
  public String getDigitalCredentialsRequestJson() {
    return requestJson;
  }

  @Override
  public void onDigitalCredentialsResponse(String response) {
    Intent resultData = new Intent();
    PendingIntentHandler.setGetCredentialResponse(
        resultData, new GetCredentialResponse(new DigitalCredential(response)));
    setResult(RESULT_OK, resultData);
    finish();
  }

  @Override
  public void onDigitalCredentialsFailure(String reason) {
    Intent resultData = new Intent();
    GetCredentialException exception = "cancelled".equals(reason)
        ? new GetCredentialCancellationException("User cancelled the disclosure")
        : new GetCredentialUnknownException("The session could not be completed");
    PendingIntentHandler.setGetCredentialException(resultData, exception);
    // The platform reads both success and failure from a RESULT_OK result.
    setResult(RESULT_OK, resultData);
    finish();
  }

  /**
   * Pulls the OpenID4VP request out of the platform's provider request and
   * reshapes it into the {@code HandleDigitalCredentialsRequestEvent} payload,
   * or returns null if this launch carried no usable request (the session then
   * ends as a failure, releasing the caller's call).
   */
  @Nullable
  private String extractRequestJson() {
    try {
      ProviderGetCredentialRequest request =
          PendingIntentHandler.retrieveProviderGetCredentialRequest(getIntent());
      if (request == null) {
        Log.w(TAG, "launched without a provider get-credential request");
        return null;
      }

      String origin = readOrigin(request.getCallingAppInfo());

      for (CredentialOption option : request.getCredentialOptions()) {
        if (option instanceof GetDigitalCredentialOption) {
          String rawRequestJson = ((GetDigitalCredentialOption) option).getRequestJson();
          return DigitalCredentialsRequestExtractor.toHandleEventJson(rawRequestJson, origin);
        }
      }
      Log.w(TAG, "provider request carried no Digital Credentials option");
      return null;
    } catch (Exception e) {
      Log.e(TAG, "failed to read Digital Credentials request", e);
      return null;
    }
  }

  /**
   * The web origin the caller relayed the request on behalf of, authenticated by
   * the platform against the bundled privileged-caller allowlist. Empty when no
   * origin can be established; the core then rejects the request, which is the
   * correct outcome rather than trusting an unauthenticated origin.
   */
  private String readOrigin(CallingAppInfo callingAppInfo) {
    try {
      String origin = callingAppInfo.getOrigin(loadPrivilegedAllowlist());
      return origin != null ? origin : "";
    } catch (Exception e) {
      Log.w(TAG, "could not read caller origin: " + e.getMessage());
      return "";
    }
  }

  private String loadPrivilegedAllowlist() {
    try (InputStream in = getAssets().open(ALLOWLIST_ASSET)) {
      byte[] bytes = new byte[in.available()];
      int read = in.read(bytes);
      return read > 0 ? new String(bytes, 0, read, StandardCharsets.UTF_8) : "{\"apps\":[]}";
    } catch (Exception e) {
      Log.w(TAG, "no privileged allowlist bundled; caller origin will be unavailable");
      return "{\"apps\":[]}";
    }
  }
}
