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
  // Whether the app has been backgrounded at least once since launch. The
  // warm-resume handshake (ResumeAckEvent) is emitted only after a real
  // background, so the initial onResume at launch can't close the carrier window
  // ahead of the cold-start AppReadyAckEvent.
  private boolean hasBackgrounded = false;

  public IrmaMobileBridge(Context context, Activity activity, MethodChannel channel, Uri initialURL) {
    this.channel = channel;
    this.activity = activity;
    this.initialURL = initialURL;
    this.context = context;
    appReady = false;
  }

  private void init() {
    try {
      IrmaConfigurationCopier copier = new IrmaConfigurationCopier(context);
      byte[] aesKey = AESKey.getKey(context);
      PackageInfo pi = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
      assert pi.applicationInfo != null;
      Irmagobridge.start(this, pi.applicationInfo.dataDir, copier.destAssetsPath.toString(),
        new ECDSA(context), aesKey);
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
        activity.runOnUiThread(this::init);
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
    activity.runOnUiThread(() -> channel.invokeMethod(name, payload));
  }

  public void onNewIntent(Intent intent) {
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

  public void onStop() {
    hasBackgrounded = true;
  }

  public void onResume() {
    // Warm-resume handshake, the twin of the AppReadyAckEvent cold-start ack.
    // Only after a real background, so the launch onResume can't pre-empt the
    // cold-start handshake. onNewIntent runs before onResume for this singleTask
    // activity and invokes HandleURLEvent on this same channel, so FIFO ordering
    // means any resume-opened link's pointer is queued before ResumeAckEvent
    // arrives and closes the carrier window.
    if (hasBackgrounded && appReady) {
      channel.invokeMethod("ResumeAckEvent", "{}");
    }
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
