package foundation.privacybydesign.yivi_core.plugins.screen_awake;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import android.app.Activity;
import android.view.WindowManager;

/**
 * Holds the screen on for the duration of a flow, via FLAG_KEEP_SCREEN_ON.
 *
 * <p>Why the app cares: a ZK age proof is ~2 s of single-threaded CPU on a
 * modern phone, and the user is watching a progress indicator without touching
 * the screen while it runs. If the display timeout fires the app loses
 * `top-app`, Android moves it into the `background` cpuset — little cores only
 * on every big.LITTLE device we have measured — and the remaining work finishes
 * roughly three times slower. Keeping the screen on for a user-attended flow
 * removes that cliff, and is what the user expects of a screen they are waiting
 * on anyway.
 *
 * <p>Holds are counted rather than a flag, because sessions nest: a disclosure
 * can start an issuance session on top of itself, and the inner one ending must
 * not release the outer one's hold.
 */
public class ScreenAwakePlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
    private MethodChannel channel;
    private Activity mainActivity;

    /** How many flows currently need the screen held on. */
    private int holdCount = 0;

    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "screen_awake");
        channel.setMethodCallHandler(this);
    }

    public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        mainActivity = binding.getActivity();
        // The flag lives on the window, so a new Activity starts without it.
        // Re-apply if a flow is still holding across the configuration change.
        applyFlag();
    }

    @Override
    public void onDetachedFromActivity() {
        mainActivity = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("keepScreenOn")) {
            holdCount++;
            applyFlag();
            result.success(null);
        } else if (call.method.equals("allowScreenOff")) {
            holdCount = Math.max(0, holdCount - 1);
            applyFlag();
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    private void applyFlag() {
        // Window flags must be touched on the UI thread; method calls arrive on it.
        if (mainActivity == null) {
            return;
        }
        if (holdCount > 0) {
            mainActivity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        } else {
            mainActivity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
    }
}
