package foundation.privacybydesign.irmamobile;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import irmagobridge.Irmagobridge;

/** IrmaMobileBridgePlugin */
public class IrmaMobileBridgePlugin implements MethodCallHandler, irmagobridge.IrmaBridge {
  private static MethodChannel channel;

  public static void registerWith(Registrar registrar) {
    MethodChannel channel = new MethodChannel(registrar.messenger(), "irma_mobile_bridge");
    channel.setMethodCallHandler(new IrmaMobileBridgePlugin(registrar, channel));
  }

  public IrmaMobileBridgePlugin(Registrar registrar, MethodChannel channel) {
    this.channel = channel;

    Context context = registrar.context();
    IrmaConfigurationCopier copier = new IrmaConfigurationCopier(context);

    try {
      PackageInfo pi = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
      Irmagobridge.start(this, pi.applicationInfo.dataDir, copier.destAssetsPath.toString());
    } catch (PackageManager.NameNotFoundException e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    /*if (call.method.equals("")) {
      result.success("");
    } else*/ {
      result.notImplemented();
    }
  }

  @Override
  public void sendEvent(String channel, String message) {
      debugLog(channel + ": " + message);
  }

  @Override
  public void debugLog(String message) {
      System.out.printf("irmagobridge: %s\n", message);
  }
}