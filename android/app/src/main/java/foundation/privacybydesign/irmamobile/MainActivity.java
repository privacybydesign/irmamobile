package foundation.privacybydesign.irmamobile;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import foundation.privacybydesign.irmamobile.plugins.irma_mobile_bridge.IrmaMobileBridgePlugin;
import irmagobridge.Irmagobridge;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    // Initialize the Go binding here by calling a seemingly noop function
    Irmagobridge.prestart();

    // Plugins
    GeneratedPluginRegistrant.registerWith(this);
    IrmaMobileBridgePlugin.registerWith(
      this.registrarFor("foundation.privacybydesign.irmamobile.plugins.irma_mobile_bridge.IrmaMobileBridgePlugin")
    );
  }
}
