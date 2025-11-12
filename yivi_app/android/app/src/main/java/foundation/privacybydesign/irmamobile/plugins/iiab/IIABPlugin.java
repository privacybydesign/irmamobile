package foundation.privacybydesign.irmamobile.plugins.iiab;

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
import androidx.browser.customtabs.CustomTabsIntent;
import androidx.browser.customtabs.CustomTabColorSchemeParams;
import android.graphics.Color;

public class IIABPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
    private FlutterPlugin.FlutterPluginBinding binding;
    private Activity mainActivity;

    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        this.binding = binding;
        MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "irma.app/iiab");
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
        if ("open_browser".equals(call.method)) {
            try {
                String url = call.<String>arguments();

                int toolbarColor = Color.parseColor("#FFFFFF");

                CustomTabColorSchemeParams darkParams = new CustomTabColorSchemeParams.Builder()
                        .setToolbarColor(toolbarColor)
                        .build();

                CustomTabColorSchemeParams defaultParams = new CustomTabColorSchemeParams.Builder()
                        .setNavigationBarColor(toolbarColor)
                        .build();

                CustomTabsIntent intent = new CustomTabsIntent.Builder()
                        .setColorScheme(CustomTabsIntent.COLOR_SCHEME_SYSTEM)
                        .setColorSchemeParams(CustomTabsIntent.COLOR_SCHEME_DARK, darkParams)
                        .setDefaultColorSchemeParams(defaultParams)
                        .build();

                intent.launchUrl(mainActivity, Uri.parse(url));
            } catch (Exception e) {
                result.error("failed to launchUrl", e.toString(), e);
                return;
            }
        }
        result.success(null);
    }
}
