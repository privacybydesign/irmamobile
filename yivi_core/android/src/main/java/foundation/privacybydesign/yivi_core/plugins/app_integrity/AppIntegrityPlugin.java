package foundation.privacybydesign.yivi_core.plugins.app_integrity;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.os.Debug;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Reports signals about the environment the app runs in: an attached debugger, a
 * dynamic instrumentation tool, a hooking framework, an emulator, or an app
 * virtualisation container. The plugin only reports; the Dart side decides how to
 * react, and only does so in release builds.
 *
 * <p>These are local, best-effort checks. Someone who controls the device can
 * bypass them, so they raise the bar without replacing attestation by a backend.
 */
public class AppIntegrityPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    // Loaded into the process by Frida and tools built on it (objection), and by
    // inline-hooking libraries that have no use in an unmodified app.
    private static final String[] INSTRUMENTATION_LIBRARIES = {
            "frida", "gum-js", "linjector", "libsandhook", "libwhale", "libsubstrate-dvm",
    };
    // Threads that a Frida agent starts inside the process.
    private static final String[] INSTRUMENTATION_THREADS = {
            "gum-js-loop", "pool-frida", "linjector",
    };
    // Frameworks that let modules change any app on a modified system. Unlike the
    // tools above they are a property of the device, not an attack in progress.
    private static final String[] HOOKING_FRAMEWORK_LIBRARIES = {
            "xposed", "lsposed", "edxposed", "libriru", "zygisk", "libsubstrate.so",
    };
    private static final String[] HOOKING_FRAMEWORK_CLASSES = {
            "de.robv.android.xposed.XposedBridge", "org.lsposed.lspd.core.Main",
    };
    // Libraries of the common app-cloning containers.
    private static final String[] VIRTUALISATION_LIBRARIES = {
            "libva++", "libva-native", "libvirtualapp", "com.lbe.parallel", "com.excelliance.dualaid",
            "io.va.exposed", "com.ludashi.dualspace",
    };

    private MethodChannel channel;
    private Context context;
    private ExecutorService executor;
    private final Handler mainThread = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        executor = Executors.newSingleThreadExecutor();
        channel = new MethodChannel(binding.getBinaryMessenger(), "yivi.app/app_integrity");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        executor.shutdown();
        executor = null;
        context = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!call.method.equals("check")) {
            result.notImplemented();
            return;
        }
        final Context ctx = context;
        // Reads a few files under /proc, so not on the main thread.
        executor.execute(() -> {
            Map<String, Boolean> report;
            try {
                report = check(ctx);
            } catch (RuntimeException e) {
                mainThread.post(() -> result.error("app_integrity_failed", e.toString(), null));
                return;
            }
            mainThread.post(() -> result.success(report));
        });
    }

    static Map<String, Boolean> check(Context context) {
        String maps = readFile("/proc/self/maps").toLowerCase(Locale.ROOT);

        Map<String, Boolean> report = new HashMap<>();
        report.put("debuggable", (context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0);
        report.put("debugger", debuggerAttached());
        report.put("instrumentation",
                containsAny(maps, INSTRUMENTATION_LIBRARIES) || instrumentationThreadRunning());
        report.put("hookingFramework",
                containsAny(maps, HOOKING_FRAMEWORK_LIBRARIES) || hookingFrameworkClassLoaded());
        report.put("emulator", isEmulator());
        report.put("virtualized",
                containsAny(maps, VIRTUALISATION_LIBRARIES) || !runsFromOwnDataDirectory(context));
        return report;
    }

    private static boolean debuggerAttached() {
        return Debug.isDebuggerConnected() || Debug.waitingForDebugger() || tracerPid(readFile("/proc/self/status")) != 0;
    }

    /** The pid of the process tracing this one with ptrace (a native debugger), or 0. */
    static int tracerPid(String procStatus) {
        for (String line : procStatus.split("\n")) {
            if (line.startsWith("TracerPid:")) {
                try {
                    return Integer.parseInt(line.substring("TracerPid:".length()).trim());
                } catch (NumberFormatException e) {
                    return 0;
                }
            }
        }
        return 0;
    }

    private static boolean instrumentationThreadRunning() {
        File[] tasks = new File("/proc/self/task").listFiles();
        if (tasks == null) return false;
        for (File task : tasks) {
            String name = readFile(new File(task, "comm").getPath()).trim();
            for (String suspect : INSTRUMENTATION_THREADS) {
                if (name.equals(suspect)) return true;
            }
        }
        return false;
    }

    private static boolean hookingFrameworkClassLoaded() {
        for (String name : HOOKING_FRAMEWORK_CLASSES) {
            try {
                Class.forName(name, false, ClassLoader.getSystemClassLoader());
                return true;
            } catch (ClassNotFoundException | LinkageError ignored) {
                // Not there, which is what we expect.
            }
        }
        return false;
    }

    private static boolean isEmulator() {
        return isEmulator(Build.FINGERPRINT, Build.HARDWARE, Build.MODEL, Build.PRODUCT, Build.MANUFACTURER)
                || new File("/dev/socket/qemud").exists()
                || new File("/dev/qemu_pipe").exists();
    }

    static boolean isEmulator(String fingerprint, String hardware, String model, String product, String manufacturer) {
        fingerprint = lower(fingerprint);
        hardware = lower(hardware);
        model = lower(model);
        product = lower(product);
        manufacturer = lower(manufacturer);
        return fingerprint.startsWith("generic")
                || fingerprint.contains("/sdk_gphone")
                || fingerprint.contains("vbox")
                || hardware.contains("goldfish")
                || hardware.contains("ranchu")
                || hardware.contains("vbox86")
                || model.contains("emulator")
                || model.contains("android sdk built for")
                || model.startsWith("sdk_gphone")
                || product.equals("google_sdk")
                || product.startsWith("sdk_gphone")
                || product.contains("vbox86p")
                || manufacturer.contains("genymotion");
    }

    /**
     * An app cloned into a virtualisation container gets its data directory inside
     * the container app's directory, instead of where Android puts it.
     */
    private static boolean runsFromOwnDataDirectory(Context context) {
        try {
            return isOwnDataDirectory(context.getFilesDir().getCanonicalPath(), context.getPackageName());
        } catch (IOException e) {
            // Cannot tell: do not flag the user.
            return true;
        }
    }

    static boolean isOwnDataDirectory(String filesDir, String packageName) {
        String pkg = Pattern.quote(packageName);
        // Internal storage for any Android user (which covers work profiles), and
        // adoptable storage the app has been moved to.
        return filesDir.matches("^/data/data/" + pkg + "/files$")
                || filesDir.matches("^/data/user/\\d+/" + pkg + "/files$")
                || filesDir.matches("^/mnt/expand/[^/]+/user/\\d+/" + pkg + "/files$");
    }

    private static boolean containsAny(String haystack, String[] needles) {
        for (String needle : needles) {
            if (haystack.contains(needle)) return true;
        }
        return false;
    }

    private static String lower(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT);
    }

    private static String readFile(String path) {
        StringBuilder content = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            while ((line = reader.readLine()) != null) {
                content.append(line).append('\n');
            }
        } catch (IOException | SecurityException e) {
            // Unreadable: treated as empty, so nothing is flagged.
        }
        return content.toString();
    }
}
