package foundation.privacybydesign.irmamobile.plugins.irma_mobile_bridge;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import irmagobridge.Irmagobridge;

public class IrmaMobileBridgePlugin implements MethodCallHandler, irmagobridge.IrmaMobileBridge {
  private Context context;
  private MethodChannel channel;

  public static void registerWith(Registrar registrar) {
    MethodChannel channel = new MethodChannel(registrar.messenger(), "irma.app/irma_mobile_bridge");
    channel.setMethodCallHandler(new IrmaMobileBridgePlugin(registrar, channel));
  }

  public IrmaMobileBridgePlugin(Registrar registrar, MethodChannel channel) {
    this.channel = channel;
    this.context = registrar.context();

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
    Irmagobridge.dispatchFromNative(call.method, (String)call.arguments);
    result.success(null);
  }

  @Override
  public void dispatchFromGo(String name, String payload) {
      this.channel.invokeMethod(name, payload);
  }

  @Override
  public void debugLog(String message) {
      // TODO: Only make this print in development
      System.out.printf("[IrmaMobileBridgePlugin] %s\n", message);
  }
}
