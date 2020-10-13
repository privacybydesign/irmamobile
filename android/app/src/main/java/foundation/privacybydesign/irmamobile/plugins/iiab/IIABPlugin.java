package foundation.privacybydesign.irmamobile.plugins.iiab;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

import android.net.Uri;
import androidx.browser.customtabs.CustomTabsIntent;
import android.graphics.Color;

public class IIABPlugin implements MethodCallHandler, FlutterPlugin {
    private FlutterPlugin.FlutterPluginBinding binding;

    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        this.binding = binding;
        MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "irma.app/iiab");
        channel.setMethodCallHandler(this);
    }

    public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
        this.binding = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "open_browser":
                try {
                    String url = call.<String>arguments();
                    CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
                    builder.setToolbarColor(Color.parseColor("#DFE6EE"));
                    CustomTabsIntent customTabsIntent = builder.build();
                    customTabsIntent.launchUrl(binding.getApplicationContext(), Uri.parse(url));
                } catch (Exception e) {
                    result.error("", e.toString(), e);
                    return;
                }
        }
        result.success(null);
    }
}
