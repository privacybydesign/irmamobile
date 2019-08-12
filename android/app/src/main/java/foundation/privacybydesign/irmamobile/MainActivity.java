package foundation.privacybydesign.irmamobile;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    GeneratedPluginRegistrant.registerWith(this);

    IrmaMobileBridgePlugin.registerWith(
      this.registrarFor("foundation.privacybydesign.irmamobile.IrmaMobileBridgePlugin")
    );
  }
}
