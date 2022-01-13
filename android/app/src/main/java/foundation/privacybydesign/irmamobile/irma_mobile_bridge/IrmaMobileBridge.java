package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import irmagobridge.Irmagobridge;

import android.net.Uri;
import android.content.Intent;

public class IrmaMobileBridge implements MethodCallHandler, irmagobridge.IrmaMobileBridge {
  private MethodChannel channel;
  private Context context;
  private Activity activity;
  private Uri initialURL;
  private boolean debug;
  private boolean appReady;

  public IrmaMobileBridge(Context context, Activity activity, MethodChannel channel, Uri initialURL) {
    this.channel = channel;
    this.context = context;
    this.activity = activity;
    this.initialURL = initialURL;
    appReady = false;

    IrmaConfigurationCopier copier = new IrmaConfigurationCopier(context);

    try {
      PackageInfo pi = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
      Irmagobridge.start(this, pi.applicationInfo.dataDir, copier.destAssetsPath.toString());
      this.debug = (pi.applicationInfo.flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    } catch (PackageManager.NameNotFoundException e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      // Send a previously recorded initial URL back to the UI once the app is ready
      case "AppReadyEvent":
        appReady = true;
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
    activity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        channel.invokeMethod(name, payload);
      }
    });
  }

  public boolean onNewIntent(Intent intent) {
    Uri link = intent.getData();
    if (link == null) {
      return true;
    }

    if (appReady) {
      channel.invokeMethod("HandleURLEvent", String.format("{\"url\": \"%s\"}", link));
    } else {
      initialURL = link;
    }
    return true;
  }

  @Override
  public void debugLog(String message) {
    if (debug)
      System.out.printf("[IrmaMobileBridgePlugin] %s\n", message);
  }
}
