package foundation.privacybydesign.yivi_core;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;

import foundation.privacybydesign.yivi_core.irma_mobile_bridge.IrmaMobileBridge;
import foundation.privacybydesign.yivi_core.plugins.iiab.IIABPlugin;
import foundation.privacybydesign.yivi_core.plugins.privacy_screen.PrivacyScreenPlugin;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import irmagobridge.Irmagobridge;

public class YiviCorePlugin implements FlutterPlugin, ActivityAware, PluginRegistry.NewIntentListener {
    private IrmaMobileBridge bridge;
    private MethodChannel channel;
    private static final String CHANNEL_NAME = "irma.app/irma_mobile_bridge";
    private Activity activity;
    private Context applicationContext;
    private IIABPlugin webBrowser;
    private PrivacyScreenPlugin privacyScreenPlugin;

    public YiviCorePlugin() {
        Irmagobridge.prestart();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        cleanupActivity();
        webBrowser.onDetachedFromActivityForConfigChanges();
        privacyScreenPlugin.onDetachedFromActivityForConfigChanges();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addOnNewIntentListener(this);
        maybeCreateBridge();

        webBrowser.onReattachedToActivityForConfigChanges(binding);
        privacyScreenPlugin.onReattachedToActivityForConfigChanges(binding);
    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        if (bridge != null) {
            bridge.onNewIntent(intent);
        }
        return true;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        binding.addOnNewIntentListener(this);
        activity = binding.getActivity();
        maybeCreateBridge();

        webBrowser.onAttachedToActivity(binding);
        privacyScreenPlugin.onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        cleanupActivity();
        webBrowser.onDetachedFromActivity();
        privacyScreenPlugin.onDetachedFromActivity();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
        applicationContext = binding.getApplicationContext();
        // Don't create the bridge yet; we don't have an Activity.
        // We'll create it in onAttachedToActivity().

        webBrowser = new IIABPlugin();
        webBrowser.onAttachedToEngine(binding);

        privacyScreenPlugin = new PrivacyScreenPlugin();
        privacyScreenPlugin.onAttachedToEngine(binding);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        applicationContext = null;

        webBrowser.onDetachedFromEngine(binding);
        privacyScreenPlugin.onDetachedFromEngine(binding);
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
            bridge = new IrmaMobileBridge(applicationContext, activity, channel, activity.getIntent().getData());
            channel.setMethodCallHandler(bridge);
        }
    }
}
