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

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterFragmentActivity {
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    // Advertise Yivi to the Credential Manager as an OpenID4VP Digital
    // Credentials provider so verifier requests can reach it. Idempotent and
    // self-guarding, so it is safe to call for every engine.
    DigitalCredentialsRegistrar.register(getApplicationContext());
  }
}
