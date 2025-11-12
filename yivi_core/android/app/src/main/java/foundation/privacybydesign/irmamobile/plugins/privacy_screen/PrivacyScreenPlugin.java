// Code originally from: https://github.com/jeroentrappers/flutter_privacy_screen

package foundation.privacybydesign.irmamobile.plugins.privacy_screen;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import android.net.Uri;
import android.util.Log;
import android.app.Activity;
import android.view.WindowManager;
public class PrivacyScreenPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
    private FlutterPlugin.FlutterPluginBinding binding;
    private Activity mainActivity;
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
            mainActivity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE);
            result.success(null);
        }
        else if (call.method.equals("disablePrivacyScreen")) {
            mainActivity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
            result.success(null);
        }
        else {
            result.notImplemented();
        }
    }
}
