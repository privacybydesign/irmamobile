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

import foundation.privacybydesign.yivi_core.dcapi.DcApiRegistration;

public class MainActivity extends FlutterFragmentActivity {
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    // Installed before the plugins are registered, because registering them creates
    // the Go bridge, and the first credential database is built as soon as the app
    // reports itself ready. Installed any later, that first one is dropped and the
    // wallet stays invisible to the picker until its contents next change.
    //
    // Only this application does this. yivi_fdroid shares yivi_core but can carry
    // neither Play Services nor a prebuilt matcher binary, so it installs nothing
    // and the registration events are discarded — see
    // foundation.privacybydesign.yivi_core.dcapi.DcApiRegistrar.
    DcApiRegistration.install(new CredentialManagerRegistrar(getApplicationContext()));

    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
