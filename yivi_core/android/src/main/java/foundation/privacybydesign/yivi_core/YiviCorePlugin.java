package foundation.privacybydesign.yivi_core;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;

import foundation.privacybydesign.yivi_core.irma_mobile_bridge.IrmaMobileBridge;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import irmagobridge.Irmagobridge;

public class YiviCorePlugin implements FlutterPlugin, ActivityAware, PluginRegistry.NewIntentListener {
    private Uri initialURL;
    private IrmaMobileBridge bridge;
    private MethodChannel channel;
    private static final String CHANNEL_NAME = "irma.app/irma_mobile_bridge";
    private Activity activity;
    private Context applicationContext;

    public YiviCorePlugin() {
        Irmagobridge.prestart();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        cleanupActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addOnNewIntentListener(this);
        maybeCreateBridge();
    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        if (bridge != null) {
            bridge.onNewIntent(intent);
        } else {
            initialURL = intent.getData();
        }
        return true;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        binding.addOnNewIntentListener(this);
        activity = binding.getActivity();
        maybeCreateBridge();
    }

    @Override
    public void onDetachedFromActivity() {
        cleanupActivity();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
        applicationContext = binding.getApplicationContext();
        // Don't create the bridge yet; we don't have an Activity.
        // We'll create it in onAttachedToActivity().
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        applicationContext = null;
    }

    private void cleanupActivity() {
        if (bridge != null) {
            bridge.stop();
            bridge = null;
        }
        activity = null;
    }

    private void maybeCreateBridge() {
        if (bridge == null && channel != null && activity != null && applicationContext != null) {
            bridge = new IrmaMobileBridge(applicationContext, activity, channel, initialURL);
            channel.setMethodCallHandler(bridge);
            // Only use initialURL once
            initialURL = null;
        }
    }
}

