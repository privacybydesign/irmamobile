// Root detection, vendored from https://github.com/w3connext/jailbreak_root_detection
// (MIT, Copyright (c) 2023 w3connext). Only the root check the app actually shows a
// warning for; the upstream Frida, Magisk-module, tamper, dev-mode, debugger and
// external-storage checks are left out.

package foundation.privacybydesign.yivi_core.plugins.root_detection;

import android.content.Context;
import android.os.Build;

import com.scottyab.rootbeer.RootBeer;
import com.scottyab.rootbeer.util.QLog;

import java.io.File;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class RootDetectionPlugin implements MethodCallHandler, FlutterPlugin {
    private Context applicationContext;

    @Override
    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        applicationContext = binding.getApplicationContext();
        new MethodChannel(binding.getBinaryMessenger(), "yivi.app/root_detection")
                .setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
        applicationContext = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("isDeviceRooted")) {
            result.success(isRooted(applicationContext));
        } else {
            result.notImplemented();
        }
    }

    static boolean isRooted(Context context) {
        QLog.LOGGING_LEVEL = QLog.NONE;
        return rootBeerSaysRooted(context) || suBinaryExists();
    }

    private static boolean rootBeerSaysRooted(Context context) {
        RootBeer rootBeer = new RootBeer(context);
        // BusyBox ships with the stock ROM on these brands, so the full check reports
        // every device as rooted.
        if (busyBoxIsStock()) {
            return rootBeer.isRootedWithoutBusyBoxCheck();
        }
        return rootBeer.isRooted();
    }

    private static boolean busyBoxIsStock() {
        String brand = Build.BRAND == null ? "" : Build.BRAND.toLowerCase();
        return brand.contains("oneplus") || brand.contains("moto") || brand.contains("xiaomi");
    }

    private static boolean suBinaryExists() {
        return new File("/data/adb/magisk.img").exists()
                || new File("/su/bin/su").exists()
                || new File("/system/xbin/su").exists();
    }
}
