package foundation.privacybydesign.yivi_core.plugins.nfc_settings;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.provider.Settings;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** Opens the system NFC settings so the user can turn NFC on. */
public class NfcSettingsPlugin implements MethodCallHandler, FlutterPlugin {
    private Context applicationContext;

    @Override
    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        applicationContext = binding.getApplicationContext();
        new MethodChannel(binding.getBinaryMessenger(), "yivi.app/nfc_settings")
                .setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
        applicationContext = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (!call.method.equals("open")) {
            result.notImplemented();
            return;
        }

        // The application context has no task of its own to start the settings in.
        Intent intent = new Intent(Settings.ACTION_NFC_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            applicationContext.startActivity(intent);
            result.success(null);
        } catch (ActivityNotFoundException e) {
            result.error("no_nfc_settings", "This device has no NFC settings screen", null);
        }
    }
}
