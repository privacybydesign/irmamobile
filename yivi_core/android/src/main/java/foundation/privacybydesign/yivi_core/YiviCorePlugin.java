package foundation.privacybydesign.yivi_core;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import foundation.privacybydesign.yivi_core.irma_mobile_bridge.IrmaMobileBridge;
import foundation.privacybydesign.yivi_core.plugins.iiab.IIABPlugin;
import foundation.privacybydesign.yivi_core.plugins.privacy_screen.PrivacyScreenPlugin;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
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

    // Observes the activity lifecycle so the bridge can emit its warm-resume
    // handshake (ResumeAckEvent) on onResume and mark backgrounding on onStop.
    private Lifecycle lifecycle;
    private final DefaultLifecycleObserver lifecycleObserver = new DefaultLifecycleObserver() {
        @Override
        public void onResume(@NonNull LifecycleOwner owner) {
            if (bridge != null) {
                bridge.onResume();
            }
        }

        @Override
        public void onStop(@NonNull LifecycleOwner owner) {
            if (bridge != null) {
                bridge.onStop();
            }
        }
    };

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
        observeLifecycle(binding);
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
        observeLifecycle(binding);
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

    private void observeLifecycle(@NonNull ActivityPluginBinding binding) {
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(lifecycleObserver);
    }

    private void cleanupActivity() {
        if (lifecycle != null) {
            lifecycle.removeObserver(lifecycleObserver);
            lifecycle = null;
        }
        if (bridge != null) {
            bridge.stop();
            bridge = null;
        }
        activity = null;
    }

    private void maybeCreateBridge() {
        if (bridge == null && channel != null && activity != null && applicationContext != null) {
            Intent launchIntent = activity.getIntent();
            Uri data = shouldDropDeepLink(launchIntent) ? null : launchIntent.getData();
            bridge = new IrmaMobileBridge(applicationContext, activity, channel, data);
            channel.setMethodCallHandler(bridge);
        }
    }

    /**
     * Decides whether the deep link carried by the launching intent must be ignored.
     *
     * <p>When the user relaunches the app from the recents list — or Android restores
     * the task after a process kill — the original launching intent is replayed with
     * {@link Intent#FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY} set. In that case the deep
     * link has already been consumed, so re-firing it would replay a stale session URL
     * as a brand new session (the bug fixed in #568). A genuine new deep link arrives
     * without this flag (via {@code onNewIntent}), so it is left untouched.
     *
     * <p>Pure function of the intent's flags; extracted so the regression can be unit
     * tested without an Activity lifecycle.
     */
    static boolean shouldDropDeepLink(Intent launchIntent) {
        return (launchIntent.getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0;
    }
}
