package foundation.privacybydesign.irmamobile;

import androidx.annotation.NonNull;

import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.net.Uri;
import android.content.Intent;

import java.nio.channels.Channel;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import foundation.privacybydesign.irmamobile.irma_mobile_bridge.IrmaMobileBridge;
import foundation.privacybydesign.irmamobile.plugins.iiab.IIABPlugin;
import irmagobridge.Irmagobridge;

public class MainActivity extends FlutterActivity {
  private View RenderView;
  private Uri initialURL;
  private IrmaMobileBridge bridge;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    // We do both these steps before calling parent, to ensure that this always happens before starting the flutter
    // engine and attaching its plugins

    // Initialize the Go binding here by calling a seemingly noop function
    Irmagobridge.prestart();
    // Capture initial url only during onCreate, for use during first engine instantiation
    Uri initialURL = getIntent().getData();

    // Hand of to parent
    super.onCreate(savedInstanceState);
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins().add(new IIABPlugin());

    // Start up the irmamobile bridge
    MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "irma.app/irma_mobile_bridge");
    bridge = new IrmaMobileBridge(this, this, channel, initialURL);
    channel.setMethodCallHandler(bridge);
    initialURL = null; // Ensure we only use the initialURL once
  }

  // Capture the render view to hide/unhide it on pause/resume
  @Override
  public void onFlutterSurfaceViewCreated(@NonNull FlutterSurfaceView flutterSurfaceView) {
    super.onFlutterSurfaceViewCreated(flutterSurfaceView);
    RenderView = flutterSurfaceView;
  }
  // It can be one of two types, just catching both is most robust.
  @Override
  public void onFlutterTextureViewCreated(@NonNull FlutterTextureView flutterTextureView) {
    super.onFlutterTextureViewCreated(flutterTextureView);
    RenderView = flutterTextureView;
  }

  @Override
  protected void onPause() {
    super.onPause();
    if (RenderView != null) RenderView.setVisibility(View.INVISIBLE);
  }

  @Override
  protected void onResume() {
    if (RenderView != null) RenderView.setVisibility(View.VISIBLE);
    super.onResume();
  }

  // Forward new intents to the bridge
  @Override
  protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    if (bridge != null) bridge.onNewIntent(intent);
  }

  @Override
  protected void onDestroy() {
    Irmagobridge.stop();
    super.onDestroy();
  }
}
