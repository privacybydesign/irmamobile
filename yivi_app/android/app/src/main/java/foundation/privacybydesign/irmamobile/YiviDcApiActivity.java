package foundation.privacybydesign.irmamobile;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.credentials.DigitalCredential;
import androidx.credentials.ExperimentalDigitalCredentialApi;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.GetDigitalCredentialOption;
import androidx.credentials.exceptions.GetCredentialCustomException;
import androidx.credentials.provider.CallingAppInfo;
import androidx.credentials.provider.PendingIntentHandler;
import androidx.credentials.provider.ProviderGetCredentialRequest;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.concurrent.atomic.AtomicBoolean;

import foundation.privacybydesign.yivi_core.dcapi.DcApiResponder;
import foundation.privacybydesign.yivi_core.dcapi.DcApiResponders;
import foundation.privacybydesign.yivi_core.irma_mobile_bridge.IrmaMobileBridge;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Answers a credential request that the platform routed to this wallet from Android's Credential
 * Manager — the Activity behind a browser's {@code navigator.credentials.get()}.
 *
 * <p>It exists separately from {@link MainActivity} because it has a different contract with the
 * system. It is started into its own task by a pending intent that a caller is blocked on, it must
 * set a result before it finishes, and it must not leave the user in the wallet afterwards. Wearing
 * both hats on one Activity would mean a credential request that surfaces the running wallet and a
 * wallet launch that owes somebody a result.
 *
 * <p>What it does not do is run the session. That is the wallet's, unchanged: the request is handed
 * to the same Go core over the same bridge as every other Digital Credentials API request, the same
 * consent screen is shown, and the response comes back through {@link DcApiResponder}. This class is
 * the platform's half — retrieve, authenticate the origin, return.
 */
public class YiviDcApiActivity extends FlutterFragmentActivity {
  private static final String TAG = "YiviDcApi";

  /** Allow-list of callers trusted to report a web origin, as Credential Manager expects it. */
  private static final String PRIVILEGED_ALLOWLIST_ASSET = "privilegedUserAgents.json";

  /**
   * Guards the one result this Activity owes the caller. A session can produce an outcome more than
   * once — a response followed by a terminal state — and a pending intent can only be answered once.
   */
  private final AtomicBoolean answered = new AtomicBoolean(false);

  /**
   * Guards the one delivery of the request. onResume runs again whenever the user comes back to
   * this Activity — after a biometric prompt, for instance — and re-delivering would start a second
   * session for a request that already has one.
   */
  private final AtomicBoolean delivered = new AtomicBoolean(false);

  @Nullable private DcApiResponder responder;

  /**
   * The protocol this wallet is answering, kept because the result has to name it.
   *
   * <p>The wallet's session produces only the protocol's own payload — for org-iso-mdoc the sealed
   * {@code {"response": ...}} — because that is all it knows about. What the browser expects back is
   * the W3C DigitalCredential shape, {@code {"protocol": ..., "data": ...}}, and the protocol half
   * of that is this Activity's to supply: it is the one that read the user's choice out of the
   * picker.
   */
  private String protocol = "org-iso-mdoc";

  /**
   * When the platform handed this request over, so the wait the user actually experiences can be
   * attributed.
   *
   * <p>That wait is the gap between tapping Yivi in the picker and seeing a wallet screen, and it is
   * spent in two places that look identical from outside: starting a second Flutter engine, and
   * opening the wallet's encrypted database if no other engine has. Only one of those is worth
   * optimising, and which one it is depends on whether the wallet was already running.
   */
  private long startedAt;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    startedAt = android.os.SystemClock.elapsedRealtime();
    Log.i(TAG, "[timing] presentation started");

    responder =
        new DcApiResponder() {
          @Override
          public void onResponse(String response) {
            answer(response, null);
          }

          @Override
          public void onFailure(String reason) {
            answer(null, reason);
          }

          @Override
          public void onClosed() {
            // The result was prepared when the outcome arrived; nothing is left
            // but to deliver it, which is what finishing does. The answer here
            // only covers a screen dismissed before any outcome existed, and is
            // a no-op otherwise.
            answer(null, "the credential request was closed before it produced a response");
            closeToWallet();
          }
        };
    DcApiResponders.install(responder);
  }

  /**
   * Runs the app from its credential-request entry point rather than its usual one.
   *
   * <p>Same app, same providers, same lock screen — it just starts on a screen that waits for the
   * request instead of loading the user's wallet. The user did not open Yivi; a web page asked Yivi
   * a question, and their card collection is not on the way to the answer.
   */
  @Override
  @NonNull
  public String getDartEntrypointFunctionName() {
    return "dcApiMain";
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  @Override
  protected void onResume() {
    super.onResume();
    if (!delivered.compareAndSet(false, true)) {
      return;
    }

    // Delivered here and not from configureFlutterEngine, which runs too early:
    // registering the plugins attaches them to the engine, but a plugin only
    // becomes a new-intent listener when the engine is attached to this Activity,
    // and Flutter does that after configureFlutterEngine returns. Delivering
    // there would hand the request to nobody.
    //
    // Still early relative to Dart, which is not listening yet. The bridge holds
    // the request until it is — that is what DCAPI_AWAITS_RESULT marks it for.
    Log.i(TAG, "[timing] engine ready after "
        + (android.os.SystemClock.elapsedRealtime() - startedAt) + " ms");

    FlutterEngine engine = getFlutterEngine();
    if (engine == null || !deliverRequest(engine)) {
      // No session will run and no outcome will ever arrive, so answer now
      // rather than leaving the caller blocked on an Activity with nothing to do.
      // Closed immediately as well: there is no screen here for the user to read,
      // and the error belongs to the caller, not to them.
      answer(null, "the credential request could not be read");
      close();
    }
  }

  @androidx.annotation.OptIn(markerClass = ExperimentalDigitalCredentialApi.class)
  private boolean deliverRequest(@NonNull FlutterEngine flutterEngine) {
    try {
      ProviderGetCredentialRequest request =
          PendingIntentHandler.retrieveProviderGetCredentialRequest(getIntent());
      if (request == null) {
        Log.w(TAG, "started without a credential request");
        return false;
      }

      String origin = resolveOrigin(request.getCallingAppInfo());
      if (origin == null) {
        Log.w(TAG, "could not establish the caller's origin");
        return false;
      }

      GetDigitalCredentialOption option =
          (GetDigitalCredentialOption) request.getCredentialOptions().get(0);
      JSONObject json = new JSONObject(option.getRequestJson());

      // The platform delivers every protocol the caller offered; the user's choice
      // in the picker decided which of them this wallet is answering. That choice
      // is encoded in the entry id the matcher emitted, as
      // "<combination> <protocol> <documentId>".
      protocol = selectedProtocol(request);
      JSONObject data = requestDataFor(json, protocol);
      if (data == null) {
        Log.w(TAG, "no request for the selected protocol " + protocol);
        return false;
      }

      Intent delivery = getIntent();
      delivery.putExtra("dcapi_protocol", protocol);
      delivery.putExtra("dcapi_origin", origin);
      delivery.putExtra("dcapi_data", data.toString());
      delivery.putExtra(IrmaMobileBridge.DCAPI_AWAITS_RESULT, true);
      setIntent(delivery);

      flutterEngine.getActivityControlSurface().onNewIntent(delivery);
      return true;
    } catch (JSONException | ClassCastException | IndexOutOfBoundsException e) {
      Log.w(TAG, "could not read the credential request", e);
      return false;
    }
  }

  /**
   * Returns the origin to bind the response to.
   *
   * <p>The web origin is available only for callers on the allow-list, because only a browser the
   * wallet trusts can be believed about which site it is acting for. Anything else is named by its
   * signing certificate instead.
   *
   * <p>This is not bookkeeping: the session transcript hashes the origin, so a response built for
   * the wrong one is rejected by the reader as a bad signature, with nothing naming the cause.
   */
  @Nullable
  private String resolveOrigin(CallingAppInfo callingAppInfo) {
    try {
      String origin = callingAppInfo.getOrigin(readAsset(PRIVILEGED_ALLOWLIST_ASSET));
      if (origin != null) {
        return origin;
      }
    } catch (IOException | IllegalArgumentException | IllegalStateException e) {
      // A caller that is not on the list is the ordinary case, not a failure.
      Log.i(TAG, "caller is not a privileged user agent: " + e.getMessage());
    }
    return appOrigin(callingAppInfo);
  }

  /**
   * Names a native caller by the SHA-256 of its signing certificate, in the form Credential Manager
   * documents.
   */
  @Nullable
  private static String appOrigin(CallingAppInfo callingAppInfo) {
    try {
      byte[] signature =
          callingAppInfo
              .getSigningInfo()
              .getApkContentsSigners()[0]
              .toByteArray();
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(signature);
      return "android:apk-key-hash:" + android.util.Base64.encodeToString(
          digest, android.util.Base64.NO_WRAP | android.util.Base64.NO_PADDING | android.util.Base64.URL_SAFE);
    } catch (NoSuchAlgorithmException | NullPointerException | ArrayIndexOutOfBoundsException e) {
      Log.w(TAG, "could not derive an origin for the calling app", e);
      return null;
    }
  }

  /**
   * Reads the protocol out of the picker entry the user chose.
   *
   * <p>The id is space-delimited and built by the matcher, which is why the credential database
   * refuses a document id containing a space.
   */
  private String selectedProtocol(ProviderGetCredentialRequest request) {
    Bundle source = request.getSourceBundle();
    if (source != null) {
      String setId =
          source.getString("androidx.credentials.registry.provider.extra.CREDENTIAL_SET_ID");
      if (setId != null) {
        String[] parts = setId.split(" ");
        if (parts.length == 2) {
          return parts[1];
        }
      }
    }
    // Falls through to the org-iso-mdoc default rather than failing: it is the
    // only protocol this wallet registers for, so a selection this code cannot
    // parse still names the right one.
    return "org-iso-mdoc";
  }

  @Nullable
  private static JSONObject requestDataFor(JSONObject json, String protocol) throws JSONException {
    JSONArray requests = json.optJSONArray("requests");
    if (requests == null) {
      return null;
    }
    for (int i = 0; i < requests.length(); i++) {
      JSONObject request = requests.getJSONObject(i);
      if (protocol.equals(request.optString("protocol"))) {
        return request.optJSONObject("data");
      }
    }
    return null;
  }

  /**
   * Prepares the one result this Activity owes the caller. Does not finish.
   *
   * <p>Preparing and delivering are deliberately separate. A result exists the moment the wallet
   * stops working, but the user has not read what was shared yet — and for a zero-knowledge
   * presentation that screen is the only record they will ever have of what was proved, since an
   * unlinkable proof leaves nothing else behind. Finishing here returned them to the browser
   * mid-animation. The result waits on {@link #close} instead, which the app calls when the user
   * dismisses the screen.
   *
   * <p>Setting the result early is not merely tidy: if this Activity is destroyed before the user
   * gets there, whatever was prepared is what the caller receives, rather than nothing.
   *
   * <p>Idempotent: a session reports an outcome more than once — a response, then a terminal state —
   * and the first is the one that answers.
   */
  private void answer(@Nullable String response, @Nullable String failure) {
    if (!answered.compareAndSet(false, true)) {
      return;
    }
    Intent result = new Intent();
    if (response != null) {
      PendingIntentHandler.setGetCredentialResponse(
          result, new GetCredentialResponse(new DigitalCredential(credentialJson(response))));
    } else {
      PendingIntentHandler.setGetCredentialException(
          result, new GetCredentialCustomException("foundation.privacybydesign.Error", failure));
    }
    setResult(RESULT_OK, result);
  }

  /** Hands the prepared result back to the caller and closes. */
  private void close() {
    runOnUiThread(this::finish);
  }

  /**
   * Hands the prepared result back to the caller and leaves the user in the wallet.
   *
   * <p>Two different things, and both are wanted. The caller is a page blocked on a result, so the
   * result has to be delivered — finishing is the only way to do that. But finishing alone drops the
   * user back into the browser, and the person who just proved something about themselves has every
   * reason to be in the wallet instead: the activity log is where this disclosure is recorded, and
   * for a zero-knowledge presentation it is the only record that will ever exist of it.
   *
   * <p>The wallet is raised first and the result delivered second, so the user never sees the
   * browser flash past on the way. It goes to its own task: this Activity lives in one the platform
   * created for a single request, and leaving the wallet inside it would put the user's home screen
   * behind a credential request that no longer exists.
   */
  private void closeToWallet() {
    runOnUiThread(
        () -> {
          try {
            Intent wallet = new Intent(this, MainActivity.class);
            wallet.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(wallet);
          } catch (RuntimeException e) {
            // Never at the expense of the result. If the wallet cannot be raised
            // the user ends up in the browser, which is where they would have
            // been anyway before this existed.
            Log.w(TAG, "could not open the wallet after the request", e);
          }
          finish();
        });
  }

  @Override
  protected void onDestroy() {
    if (responder != null) {
      DcApiResponders.uninstall(responder);
    }
    // A destroyed Activity that never answered still owes the caller a result;
    // without this the browser waits for a timeout instead of learning that the
    // request was abandoned.
    answer(null, "the credential request was dismissed");
    super.onDestroy();
  }

  /**
   * Wraps the wallet's response in the shape the browser reads it out of.
   *
   * <p>A W3C DigitalCredential is {@code {"protocol": ..., "data": ...}}; the wallet produces only
   * the {@code data} half, because the protocol is a fact about the exchange rather than about the
   * credential. Handing the bare half over is not a parse error anywhere in the wallet — it travels
   * intact all the way to the page, where the browser finds no protocol it recognises and reports
   * a token it could not retrieve. Which is the same sentence it produces when nothing was shared
   * at all, so the disclosure that did happen is invisible in it.
   *
   * <p>data is spliced in as an object, not a string: a quoted blob is a different document to
   * anything reading it.
   */
  private String credentialJson(String response) {
    try {
      JSONObject credential = new JSONObject();
      credential.put("protocol", protocol);
      credential.put("data", new JSONObject(response));
      return credential.toString();
    } catch (JSONException e) {
      // The wallet's own output did not parse, which means the session produced
      // something no caller can use. Returned as-is so the failure surfaces in
      // the browser rather than being replaced by a silence here.
      Log.w(TAG, "the wallet's response is not JSON; returning it unwrapped", e);
      return response;
    }
  }

  private String readAsset(String name) throws IOException {
    try (InputStream stream = getAssets().open(name)) {
      byte[] bytes = new byte[stream.available()];
      int read = stream.read(bytes);
      return new String(bytes, 0, Math.max(read, 0), java.nio.charset.StandardCharsets.UTF_8);
    }
  }
}
