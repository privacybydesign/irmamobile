package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Arrays;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import irmagobridge.Irmagobridge;

public class IrmaMobileBridge implements MethodCallHandler, irmagobridge.IrmaMobileBridge {
  private final MethodChannel channel;
  private final Activity activity;
  private Uri initialURL;
  private boolean appReady;
  private String nativeError;
  private final Context context;

  public IrmaMobileBridge(Context context, Activity activity, MethodChannel channel, Uri initialURL) {
    this.channel = channel;
    this.activity = activity;
    this.initialURL = initialURL;
    this.context = context;
    appReady = false;
  }

  private void init(String locale) {
    try {
      IrmaConfigurationCopier copier = new IrmaConfigurationCopier(context);
      byte[] aesKey = AESKey.getKey(context);
      PackageInfo pi = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
      assert pi.applicationInfo != null;
      Irmagobridge.start(this, pi.applicationInfo.dataDir, copier.destAssetsPath.toString(),
        new ECDSA(context), aesKey, locale);
    } catch (GeneralSecurityException | IOException | PackageManager.NameNotFoundException e) {
      StringBuilder exception = new StringBuilder(e.toString());
      Throwable cause = e.getCause();
      while (cause != null) {
        exception.append("\nCaused by: ").append(cause);
        cause = cause.getCause();
      }
      String[] stackTrace = Arrays.stream(e.getStackTrace()).map(StackTraceElement::toString).toArray(String[]::new);

      JSONObject jsonObject = new JSONObject();
      try {
        jsonObject.put("Exception", exception.toString());
        jsonObject.put("Stack", String.join("\n", stackTrace));
        jsonObject.put("Fatal", true);
        this.nativeError = jsonObject.toString();
      } catch (JSONException jsonException) {
        this.nativeError = String.format("{\"Exception\":\"%s\",\"Stack\":\"\",\"Fatal\":true}",
          "Unable to parse Java exception");
      }
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (this.nativeError != null) {
      channel.invokeMethod("ErrorEvent", this.nativeError);
      return;
    }

    switch (call.method) {
      // Send a previously recorded initial URL back to the UI once the app is ready
      case "AppReadyEvent":
        appReady = true;
        // The effective app language rides in the AppReadyEvent payload so the
        // Go client is constructed with the right locale from the start.
        String locale = "";
        try {
          if (call.arguments instanceof String) {
            locale = new JSONObject((String) call.arguments).optString("locale", "");
          }
        } catch (JSONException ignored) {
          // Fall back to empty locale (Go defaults to English).
        }
        final String initLocale = locale;
        activity.runOnUiThread(() -> init(initLocale));
        if (initialURL != null) {
          channel.invokeMethod("HandleURLEvent",
            String.format("{\"url\": \"%s\", \"isInitialURL\": true}", initialURL));
          initialURL = null;
          // Drop the launching intent's data so a later maybeCreateBridge() — e.g.,
          // after a configuration change — doesn't read the same URL and replay it.
          activity.setIntent(new Intent());
        }

        // Acknowledge the launch handshake AFTER any initial URL, so the UI knows
        // the launch URL (if any) has been delivered. Channel messages are FIFO,
        // so the HandleURLEvent above is always processed first; the lock screen
        // relies on this to hold off biometric until it knows whether the app was
        // opened with a session.
        channel.invokeMethod("AppReadyAckEvent", "{}");

        break;

      case "AndroidSendToBackgroundEvent":
        activity.moveTaskToBack(true);
        break;
    }

    Irmagobridge.dispatchFromNative(call.method, (String) call.arguments);
    result.success(null);
  }

  @Override
  public void dispatchFromGo(String name, String payload) {
    dumpDcApiResponse(payload);
    activity.runOnUiThread(() -> channel.invokeMethod(name, payload));
  }

  /**
   * LOCAL DEVELOPMENT ONLY -- DO NOT COMMIT. Writes a Digital Credentials API response to a file so
   * it can be read back off the device.
   *
   * <p>logcat cannot carry one. Android caps a single log entry at 4068 bytes, and a
   * zero-knowledge response is around 480 KB of base64: a capture on 2026-09-23 recovered 7% of one
   * and no closing quote, which is enough to see that a response was large and not enough to see
   * what was in it. Telling a real proof from a plain presentation means decrypting the whole
   * thing, so the whole thing has to leave the device intact.
   *
   * <p>Read it with:
   *
   * <pre>
   *   adb shell run-as org.irmacard.cardemu.alpha cat files/dcapi_response.b64 &gt; response.b64
   *   mintreq -check response.b64
   * </pre>
   *
   * <p>Overwritten each time, and only written when a response is actually present, so an ordinary
   * session leaves nothing behind.
   */
  private void dumpDcApiResponse(String payload) {
    if (payload == null || !payload.contains("dc_api_response")) {
      return;
    }
    try {
      JSONObject event = new JSONObject(payload);
      // snake_case, matching the Go field tag. An earlier version looked for
      // "SessionState", fell through to the outer object, found nothing there
      // and returned without a word -- so the file was simply never written and
      // nothing said why.
      JSONObject state = event.optJSONObject("session_state");
      if (state == null) {
        state = event;
      }
      String response = state.optString("dc_api_response", "");
      if (response.isEmpty()) {
        // Reachable only when the payload contains the key and this code cannot
        // find it, which means the event shape moved. Silence here is what cost
        // a debugging round; a log is the difference between a wrong guess and
        // a known one.
        debugLog("[dcapi] payload carries dc_api_response but not where expected; the event shape changed");
        return;
      }
      java.io.File out = new java.io.File(context.getFilesDir(), "dcapi_response.b64");
      try (java.io.FileOutputStream stream = new java.io.FileOutputStream(out)) {
        stream.write(response.getBytes(java.nio.charset.StandardCharsets.UTF_8));
      }
      debugLog("[dcapi] response written to " + out.getAbsolutePath() + " (" + response.length() + " chars)");
    } catch (JSONException | java.io.IOException e) {
      debugLog("[dcapi] could not write the response: " + e.getMessage());
    }
  }

  public void onNewIntent(Intent intent) {
    if (handleDcApiIntent(intent)) {
      return;
    }

    Uri link = intent.getData();
    if (link == null) {
      return;
    }

    if (appReady) {
      channel.invokeMethod("HandleURLEvent", String.format("{\"url\": \"%s\"}", link));
    } else {
      initialURL = link;
    }
  }

  /**
   * Forwards a request the platform delivered through the W3C Digital Credentials API, and reports
   * whether this intent was one.
   *
   * <p>A DC API request is not a link: the protocol the platform negotiated, the origin it
   * authenticated and the request itself arrive as three separate values, none of which belong in a
   * Uri. So they travel as extras and reach Dart as their own event rather than being forced
   * through HandleURLEvent.
   *
   * <p>The origin is the part worth not losing: the session transcript binds to it, so a response
   * built for one origin is not valid at another. It is taken from the intent rather than assumed,
   * because only the platform knows which caller it actually verified.
   */
  private boolean handleDcApiIntent(Intent intent) {
    String protocol = intent.getStringExtra("dcapi_protocol");
    String origin = intent.getStringExtra("dcapi_origin");
    String data = intent.getStringExtra("dcapi_data");
    if (protocol == null || origin == null || data == null) {
      return false;
    }

    // Dropped rather than queued when the app is still starting. Unlike a link,
    // which the user can be shown once the wallet is up, a DC API request is one
    // half of a call the platform is waiting on, and answering it late is worse
    // than not answering: the caller has moved on and the origin binding is stale.
    if (!appReady) {
      debugLog("[dcapi] request arrived before the client was ready; dropping it");
      return true;
    }

    try {
      JSONObject event = new JSONObject();
      event.put("protocol", protocol);
      event.put("origin", origin);
      // Parsed rather than embedded as a string: the Go core takes `data` as raw
      // JSON whose shape depends on the protocol, so it has to arrive as an
      // object and not as a quoted blob.
      event.put("data", new JSONObject(data));
      channel.invokeMethod("HandleDcApiEvent", event.toString());
    } catch (JSONException e) {
      debugLog("[dcapi] request could not be forwarded: " + e.getMessage());
    }
    return true;
  }

  @Override
  public void debugLog(String message) {
    if (appReady) {
      activity.runOnUiThread(() -> channel.invokeMethod("GoLog", message));
    }
  }

  public void stop() {
    Irmagobridge.stop();
  }
}
