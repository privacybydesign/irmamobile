package foundation.privacybydesign.yivi_core.plugins.device_security;

import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.provider.Settings;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Tells the app whether the device has a secure screen lock (a PIN, pattern or
 * password, which fingerprint and face unlock also require), and opens the
 * screen lock settings. Uses only the Android framework, so the F-Droid app has
 * it too.
 */
public class DeviceSecurityPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "yivi.app/device_security");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        context = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "isDeviceSecure": {
                KeyguardManager keyguardManager = context.getSystemService(KeyguardManager.class);
                result.success(keyguardManager != null && keyguardManager.isDeviceSecure());
                break;
            }
            case "openSecuritySettings": {
                Intent intent = new Intent(Settings.ACTION_SECURITY_SETTINGS);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                try {
                    context.startActivity(intent);
                } catch (android.content.ActivityNotFoundException e) {
                    // Some devices have no separate security screen: open the settings app.
                    context.startActivity(new Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                }
                result.success(null);
                break;
            }
            default:
                result.notImplemented();
        }
    }
}
