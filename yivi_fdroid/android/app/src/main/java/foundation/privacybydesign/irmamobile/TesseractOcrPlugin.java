package foundation.privacybydesign.irmamobile;

import androidx.annotation.NonNull;
import android.os.Handler;
import android.os.Looper;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import foundation.privacybydesign.irmamobile.ocr.TesseractOcrEngine;

public class TesseractOcrPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    private static final String CHANNEL = "foundation.privacybydesign.irmamobile/tesseract";
    private MethodChannel channel;
    private TesseractOcrEngine ocrEngine;
    private final Handler mainThreadHandler = new Handler(Looper.getMainLooper());
    private ExecutorService ocrExecutor;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        ocrEngine = new TesseractOcrEngine(binding.getApplicationContext());
        ocrExecutor = Executors.newSingleThreadExecutor();
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        if (ocrExecutor != null) {
            ocrExecutor.shutdownNow();
            ocrExecutor = null;
        }
        if (ocrEngine != null) {
            ocrEngine.close();
            ocrEngine = null;
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!call.method.equals("processImage")) {
            result.notImplemented();
            return;
        }

        final byte[] bytes = call.argument("bytes");
        final Integer width = call.argument("width");
        final Integer height = call.argument("height");
        final Integer stride = call.argument("stride");
        final int rotation = call.argument("rotation") != null
                ? (int) call.argument("rotation") : 0;
        final String lang = call.argument("lang") != null
                ? (String) call.argument("lang") : "ocrb";
        final double roiLeft = call.argument("roiLeft") != null
                ? (double) call.argument("roiLeft") : 0.0;
        final double roiTop = call.argument("roiTop") != null
                ? (double) call.argument("roiTop") : 0.0;
        final double roiWidth = call.argument("roiWidth") != null
                ? (double) call.argument("roiWidth") : 1.0;
        final double roiHeight = call.argument("roiHeight") != null
                ? (double) call.argument("roiHeight") : 1.0;

        if (bytes == null || width == null || height == null || stride == null) {
            result.error("ARG", "Missing required arguments", null);
            return;
        }

        // Should not happen, but if for some reason it doen't get detached right
        if (ocrExecutor == null || ocrExecutor.isShutdown()) {
            result.error("OCR", "OCR engine not available", null);
            return;
        }

        ocrExecutor.execute(() -> {
            try {
                String text = ocrEngine.ocrYPlane(
                        bytes, width, height, stride, rotation,
                        lang, roiLeft, roiTop, roiWidth, roiHeight
                );
                mainThreadHandler.post(() -> result.success(text));
            } catch (Exception e) {
                mainThreadHandler.post(() -> result.error("OCR", e.getMessage(), null));
            }
        });
    }
}