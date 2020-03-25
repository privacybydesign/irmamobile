package foundation.privacybydesign.irmamobile;

import android.os.Build;
import android.os.Bundle;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.net.Uri;

import java.nio.channels.Channel;

import foundation.privacybydesign.irmamobile.plugins.irma_mobile_bridge.IrmaMobileBridgePlugin;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import irmagobridge.Irmagobridge;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    boolean flutter_native_splash = true;
    int originalStatusBarColor = 0;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      originalStatusBarColor = getWindow().getStatusBarColor();
      getWindow().setStatusBarColor(0xffdee1e4);
    }
    int originalStatusBarColorFinal = originalStatusBarColor;

    // Initialize the Go binding here by calling a seemingly noop function
    Irmagobridge.prestart();
    // Plugins
    GeneratedPluginRegistrant.registerWith(this);
    ViewTreeObserver vto = getFlutterView().getViewTreeObserver();
    vto.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
      @Override
      public void onGlobalLayout() {
        getFlutterView().getViewTreeObserver().removeOnGlobalLayoutListener(this);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          getWindow().setStatusBarColor(originalStatusBarColorFinal);
        }
      }
    });

    Uri initialURL = getIntent().getData();
    IrmaMobileBridgePlugin.registerWith(
        this.registrarFor("foundation.privacybydesign.irmamobile.plugins.irma_mobile_bridge.IrmaMobileBridgePlugin"),
        initialURL);

  }
}
