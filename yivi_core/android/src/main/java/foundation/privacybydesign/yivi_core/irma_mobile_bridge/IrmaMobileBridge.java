package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.util.Base64;

import androidx.annotation.NonNull;

import foundation.privacybydesign.yivi_core.dcapi.DcApiRegistrar;
import foundation.privacybydesign.yivi_core.dcapi.DcApiRegistration;
import foundation.privacybydesign.yivi_core.dcapi.DcApiResponder;
import foundation.privacybydesign.yivi_core.dcapi.DcApiResponders;
import foundation.privacybydesign.yivi_core.dcapi.UnlockHandover;

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

  /**
   * A Digital Credentials API request that arrived before Dart was listening, held until it is.
   *
   * <p>The counterpart of {@link #initialURL}, and held for the same reason: a presentation Activity
   * is started by the platform with the request already in hand, so the request is always earlier
   * than the engine it has to be drawn in.
   *
   * <p>Only requests whose caller is still waiting are held — see {@link #handleDcApiIntent}.
   */
  private String pendingDcApiEvent;

  private boolean appReady;
  private String nativeError;
  private final Context context;

  /**
   * Identifies this bridge's attachment to the Go side, so detaching it detaches this one and not
   * whichever was attached most recently.
   *
   * <p>More than one can exist at a time: a Digital Credentials API presentation runs in its own
   * Activity while the wallet's own Activity is still alive, and both drive the same wallet client.
   * Detaching by identity would close the client out from under the Activity the user returns to.
   *
   * <p>Zero until {@link #init} has run, which is the state a bridge is in if the wallet failed to
   * start; detaching then has nothing to detach.
   */
  private long attachmentId;

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
      // Timed because this is the one step whose cost depends on whether another
      // engine already paid it. Irmagobridge.start opens the encrypted database
      // and loads the schemes on the first attachment and returns immediately on
      // every later one, so the same line reads in milliseconds or in seconds and
      // the difference is the whole answer to "why was that slow".
      long startedAt = android.os.SystemClock.elapsedRealtime();
      attachmentId = Irmagobridge.start(this, pi.applicationInfo.dataDir, copier.destAssetsPath.toString(),
        new ECDSA(context), aesKey, locale);
      debugLog("[timing] Irmagobridge.start took "
        + (android.os.SystemClock.elapsedRealtime() - startedAt) + " ms");
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

        // A DC API request the platform delivered before Dart was listening. Sent
        // after the initial URL for the same FIFO reason, and before the ack, so
        // the UI knows the app was opened with a session before it decides what to
        // show.
        if (pendingDcApiEvent != null) {
          channel.invokeMethod("HandleDcApiEvent", pendingDcApiEvent);
          pendingDcApiEvent = null;
        }

        // An unlock this process already did, carried over from the Activity that
        // answered a credential request. Sent before the ack so the lock screen is
        // never drawn: the UI settles on the acknowledged launch state, and a lock
        // that flashed up and vanished would be worse than either outcome.
        if (UnlockHandover.consume()) {
          channel.invokeMethod("UnlockHandoverEvent", "{}");
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

      // The user is done reading what a Digital Credentials API session shared.
      // Not moveTaskToBack: that Activity owes its caller a result, and
      // backgrounding it leaves a browser waiting for one that never arrives.
      case "AndroidFinishDcApiPresentationEvent": {
        // Reaching the end of a presentation means the user unlocked this process
        // to get here — a session does not start before the app is unlocked. Carry
        // that to the wallet Activity they are about to land in, so one continuous
        // action does not ask them twice. See UnlockHandover.
        UnlockHandover.mark();
        DcApiResponder closing = DcApiResponders.get();
        if (closing != null) {
          closing.onClosed();
        }
        break;
      }
    }

    Irmagobridge.dispatchFromNative(call.method, (String) call.arguments);
    result.success(null);
  }

  /** Event name of the credential database, from the Go event type of the same name. */
  private static final String DC_API_REGISTRATION_EVENT = "DcApiRegistrationEvent";

  @Override
  public void dispatchFromGo(String name, String payload) {
    dumpDcApiResponse(payload);

    if (DC_API_REGISTRATION_EVENT.equals(name)) {
      handleDcApiRegistration(payload);
      return;
    }

    if (SESSION_STATE_EVENT.equals(name)) {
      reportDcApiOutcome(payload);
    }

    activity.runOnUiThread(() -> channel.invokeMethod(name, payload));
  }

  /** Event name of a session state change, from the Go event type of the same name. */
  private static final String SESSION_STATE_EVENT = "SessionStateEvent";

  /**
   * Hands a finished Digital Credentials API session to whoever is waiting to answer the platform.
   *
   * <p>Forwarded rather than intercepted: the UI still needs this event to draw the outcome. This
   * only tees off the part the Activity needs.
   *
   * <p>A session that ends without a response is reported as a failure and not merely ignored. The
   * caller is blocked on a result either way, and the Activity must return something; leaving it to
   * time out would show the user a browser that hangs after they already refused.
   */
  private void reportDcApiOutcome(String payload) {
    DcApiResponder responder = DcApiResponders.get();
    if (responder == null) {
      return;
    }
    try {
      JSONObject state = new JSONObject(payload).optJSONObject("session_state");
      if (state == null) {
        return;
      }
      String status = state.optString("status", "");
      String response = state.optString("dc_api_response", "");

      if (!response.isEmpty()) {
        responder.onResponse(response);
      } else if ("error".equals(status) || "dismissed".equals(status)) {
        responder.onFailure("the session ended as " + status);
      } else if ("success".equals(status)) {
        // Reachable when a session succeeded over a transport that answers
        // somewhere else. Not this Activity's session, and nothing to return.
        responder.onFailure("the session produced no digital credentials response");
      }
    } catch (JSONException e) {
      debugLog("[dcapi] could not read the session outcome: " + e.getMessage());
    }
  }

  /**
   * Publishes a credential database to the platform's provider registry, and does not forward it to
   * Dart.
   *
   * <p>Nothing in the UI consumes this event, and it carries the whole wallet base64-encoded —
   * hundreds of kilobytes on every finished session. Forwarding it would cost a platform-channel
   * hop and a Dart-side decode per credential change to reach code that would throw it away.
   *
   * <p>Handled on the calling thread rather than the UI thread: registration is IPC to Play
   * Services, the user is not waiting on it, and the alternative is competing with whatever the
   * session just finished drawing.
   *
   * @see foundation.privacybydesign.yivi_core.dcapi.DcApiRegistrar for why the implementation is not
   *     in this module.
   */
  private void handleDcApiRegistration(String payload) {
    DcApiRegistrar registrar = DcApiRegistration.get();
    if (registrar == null) {
      // The ordinary state for a build without Credential Manager support, so no
      // log: this would otherwise fire on every session in the F-Droid build.
      return;
    }
    try {
      String encoded = new JSONObject(payload).optString("database", "");
      if (encoded.isEmpty()) {
        debugLog("[dcapi] registration event carried no database; the event shape changed");
        return;
      }
      registrar.register(Base64.decode(encoded, Base64.DEFAULT));
    } catch (JSONException | IllegalArgumentException e) {
      debugLog("[dcapi] could not read the credential database: " + e.getMessage());
    }
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
  /**
   * Intent extra marking a request whose caller is blocked on a result, so it is held until Dart
   * can answer instead of being dropped. Set by the presentation Activity; absent on a request fired
   * as a bare intent by the development harness.
   */
  public static final String DCAPI_AWAITS_RESULT = "dcapi_awaits_result";

  /**
   * Logs the origin and a digest of the request exactly as this wallet received it.
   *
   * <p>Both are inputs to the readerAuth signature and neither survives into its failure message, so
   * a mismatch in either reads as "the reader is broken". Printed here rather than deeper in because
   * this is the one point both delivery paths — the credential picker and a bare intent — pass
   * through, so the line means the same thing either way.
   */
  private void describeDcApiRequest(String origin, String data) {
    try {
      String deviceRequest = new JSONObject(data).optString("deviceRequest", "");
      java.security.MessageDigest sha256 = java.security.MessageDigest.getInstance("SHA-256");
      byte[] digest = sha256.digest(deviceRequest.getBytes(java.nio.charset.StandardCharsets.UTF_8));
      StringBuilder hex = new StringBuilder(16);
      for (int i = 0; i < 8 && i < digest.length; i++) {
        hex.append(Character.forDigit((digest[i] >> 4) & 0xf, 16));
        hex.append(Character.forDigit(digest[i] & 0xf, 16));
      }
      debugLog("[dcapi] origin " + origin);
      debugLog("[dcapi] deviceRequest " + deviceRequest.length() + " chars, sha256 " + hex);
    } catch (JSONException | java.security.NoSuchAlgorithmException e) {
      debugLog("[dcapi] could not describe the request: " + e.getMessage());
    }
  }

  private boolean handleDcApiIntent(Intent intent) {
    String protocol = intent.getStringExtra("dcapi_protocol");
    String origin = intent.getStringExtra("dcapi_origin");
    String data = intent.getStringExtra("dcapi_data");
    if (protocol == null || origin == null || data == null) {
      return false;
    }

    try {
      JSONObject event = new JSONObject();
      event.put("protocol", protocol);
      event.put("origin", origin);

      // Fingerprint what arrived, on the one seam both delivery paths cross.
      //
      // readerAuth signs the session transcript and the itemsRequest bytes, so
      // when it fails the question is always "did the origin differ, or did the
      // bytes?" — and neither is visible from the failure. The reader prints the
      // same two lines when it mints, so comparing them answers it outright
      // instead of by elimination.
      describeDcApiRequest(origin, data);
      // Parsed rather than embedded as a string: the Go core takes `data` as raw
      // JSON whose shape depends on the protocol, so it has to arrive as an
      // object and not as a quoted blob.
      event.put("data", new JSONObject(data));

      if (appReady) {
        channel.invokeMethod("HandleDcApiEvent", event.toString());
        return true;
      }

      // The app is still starting, and what happens next depends on whether
      // anyone is still listening for an answer.
      //
      // A request that arrived as a bare intent is dropped. It is one half of a
      // call the platform was waiting on, and answering it late is worse than
      // not answering: the caller has moved on and the origin binding is stale.
      //
      // A request delivered by the presentation Activity is held. That caller is
      // blocked on a pending intent this process has to resolve either way, and
      // the request is always earlier than the engine — the platform starts the
      // Activity with the request already in hand. Dropping it would make every
      // credential request to a cold wallet fail.
      if (!intent.getBooleanExtra(DCAPI_AWAITS_RESULT, false)) {
        debugLog("[dcapi] request arrived before the client was ready; dropping it");
        return true;
      }
      pendingDcApiEvent = event.toString();
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
    if (attachmentId == 0) {
      // init() never ran, so nothing was ever attached. Calling stop() here would
      // detach the most recent attachment, which belongs to somebody else.
      return;
    }
    Irmagobridge.stopAttachment(attachmentId);
    attachmentId = 0;
  }
}
