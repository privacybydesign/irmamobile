package foundation.privacybydesign.irmamobile;

import androidx.annotation.NonNull;
import android.util.Log;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import foundation.privacybydesign.irmamobile.ocr.TesseractOcrEngine;
import org.opencv.android.OpenCVLoader;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "foundation.privacybydesign.irmamobile/tesseract";
    private TesseractOcrEngine ocrEngine;

    static {
        if (!OpenCVLoader.initDebug()) {
            Log.e(TAG, "OpenCV initialization failed");
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        ocrEngine = new TesseractOcrEngine(this);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("processImage")) {
                        new Thread(() -> {
                            try {
                                byte[] bytes = call.argument("bytes");
                                Integer width = call.argument("width");
                                Integer height = call.argument("height");
                                Integer stride = call.argument("stride");
                                Integer rotation = call.argument("rotation");
                                String lang = call.argument("lang");
                                Double roiLeft = call.argument("roiLeft");
                                Double roiTop = call.argument("roiTop");
                                Double roiWidth = call.argument("roiWidth");
                                Double roiHeight = call.argument("roiHeight");

                                if (bytes == null || width == null || height == null || stride == null) {
                                    runOnUiThread(() -> result.error("ARG", "Missing arguments", null));
                                    return;
                                }

                                // We roepen nu de geoptimaliseerde ocrYPlane aan
                                String text = ocrEngine.ocrYPlane(
                                    bytes, width, height, stride, rotation != null ? rotation : 0,
                                    lang != null ? lang : "ocrb",
                                    roiLeft != null ? roiLeft : 0.0,
                                    roiTop != null ? roiTop : 0.0,
                                    roiWidth != null ? roiWidth : 1.0,
                                    roiHeight != null ? roiHeight : 1.0
                                );

                                runOnUiThread(() -> result.success(text));
                            } catch (Exception e) {
                                Log.e(TAG, "OCR error", e);
                                runOnUiThread(() -> result.error("OCR", e.getMessage(), null));
                            }
                        }).start();
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (ocrEngine != null) {
            ocrEngine.close();
        }
    }
}
