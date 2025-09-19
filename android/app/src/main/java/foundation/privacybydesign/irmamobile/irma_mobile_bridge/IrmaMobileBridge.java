package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;

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
        exception.append("\nCaused by: ").append(cause.toString());
        cause = cause.getCause();
      }
      String[] stackTrace = null;
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        stackTrace = Arrays.stream(e.getStackTrace()).map(StackTraceElement::toString).toArray(String[]::new);
      }

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
        }

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
