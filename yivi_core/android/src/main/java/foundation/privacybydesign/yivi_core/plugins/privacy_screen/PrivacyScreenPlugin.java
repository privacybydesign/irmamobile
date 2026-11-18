// Code originally from: https://github.com/jeroentrappers/flutter_privacy_screen

package foundation.privacybydesign.yivi_core.plugins.privacy_screen;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.app.Activity;
import android.view.View;
import android.view.WindowManager;
public class PrivacyScreenPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
    private FlutterPlugin.FlutterPluginBinding binding;
    private Activity mainActivity;
    // Whether the window is kept out of screenshots, screen recordings and the recents
    // view. On until the app says otherwise, so the window is protected before the first
    // Flutter frame instead of only once Dart has read the user's preference.
    private boolean secure = true;
    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        this.binding = binding;
        MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "privacy_screen");
        channel.setMethodCallHandler(this);
    }
    public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
        this.binding = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        mainActivity = binding.getActivity();
        applySecureFlag();
        protectAgainstOverlays(mainActivity);
        hideFromUntrustedAccessibilityServices(mainActivity);
    }

    private void applySecureFlag() {
        if (mainActivity == null) return;
        if (secure) {
            mainActivity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE);
        } else {
            mainActivity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
        }
    }

    // From Android 14 on, the content of the app is only given to accessibility services
    // that declare themselves an accessibility tool, such as TalkBack, Voice Access and
    // Switch Access, which Google Play only allows for real assistive apps. Other
    // services, which malware uses to read the screen and press buttons, get nothing.
    // The touch filter set in protectAgainstOverlays already implies this (the automatic
    // value follows it); it is set explicitly so it does not depend on that.
    private static void hideFromUntrustedAccessibilityServices(Activity activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            activity.getWindow().getDecorView()
                    .setAccessibilityDataSensitive(View.ACCESSIBILITY_DATA_SENSITIVE_YES);
        }
    }

    // Protects the whole app, and so the PIN keypad and the consent screens, against
    // tapjacking: another app drawing over Yivi to read or redirect the user's taps.
    //  - From Android 12 on, windows of other apps that draw over Yivi
    //    (TYPE_APPLICATION_OVERLAY) are hidden while Yivi is in the foreground. This
    //    needs the HIDE_OVERLAY_WINDOWS permission, declared in this plugin's manifest.
    //  - On every version, a touch that arrives while another window covers Yivi is
    //    dropped. Set on the decor view, it applies to every view below it, the Flutter
    //    view included, because ViewGroup.dispatchTouchEvent filters at every level.
    //    From Android 12 on the system already blocks touches through untrusted
    //    overlays, so this mostly matters for Android 8 to 11.
    private static void protectAgainstOverlays(Activity activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            activity.getWindow().setHideOverlayWindows(true);
        }
        activity.getWindow().getDecorView().setFilterTouchesWhenObscured(true);
    }
    @Override
    public void onDetachedFromActivity(){
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
        if (call.method.equals("enablePrivacyScreen")) {
            secure = true;
            applySecureFlag();
            result.success(null);
        }
        else if (call.method.equals("disablePrivacyScreen")) {
            secure = false;
            applySecureFlag();
            result.success(null);
        }
        // Nothing to suspend here: the Android privacy screen is FLAG_SECURE, which
        // keeps the window out of screenshots and the recents view but draws nothing
        // on top of the app, so system UI shown during a flow is unaffected by it.
        // Accepted rather than left unimplemented so the channel behaves the same on
        // both platforms and callers need no platform check.
        else if (call.method.equals("suspendPrivacyScreen") || call.method.equals("resumePrivacyScreen")) {
            result.success(null);
        }
        else {
            result.notImplemented();
        }
    }
}
