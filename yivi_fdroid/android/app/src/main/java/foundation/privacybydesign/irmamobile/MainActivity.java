package foundation.privacybydesign.irmamobile;

import androidx.annotation.NonNull;
import android.util.Log;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import org.opencv.android.OpenCVLoader;

public class MainActivity extends FlutterFragmentActivity {
    private static final String TAG = "MainActivity";

    static {
        if (!OpenCVLoader.initDebug()) {
            Log.e(TAG, "OpenCV initialization failed");
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // Register the new Tesseract OCR Plugin
        flutterEngine.getPlugins().add(new TesseractOcrPlugin());
    }
}
