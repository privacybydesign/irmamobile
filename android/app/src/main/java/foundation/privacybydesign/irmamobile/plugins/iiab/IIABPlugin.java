package foundation.privacybydesign.irmamobile.plugins.iiab;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.net.Uri;
import androidx.browser.customtabs.CustomTabsIntent;
import android.graphics.Color;

public class IIABPlugin implements MethodCallHandler {
    private Registrar registrar;

    public static void registerWith(Registrar registrar) {
        MethodChannel channel = new MethodChannel(registrar.messenger(), "irma.app/iiab");
        channel.setMethodCallHandler(new IIABPlugin(registrar));
    }

    public IIABPlugin(Registrar registrar) {
        super();
        this.registrar = registrar;
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
                    customTabsIntent.launchUrl(registrar.activity(), Uri.parse(url));
                } catch (Exception e) {
                    result.error("", e.toString(), e);
                    return;
                }
        }
        result.success(null);
    }
}
