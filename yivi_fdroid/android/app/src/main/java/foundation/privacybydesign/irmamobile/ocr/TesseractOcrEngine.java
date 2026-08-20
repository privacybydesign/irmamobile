package foundation.privacybydesign.irmamobile.ocr;

import android.content.Context;
import android.util.Log;
import com.googlecode.tesseract.android.TessBaseAPI;
import android.graphics.Bitmap;
import org.opencv.android.Utils;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.imgproc.Imgproc;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

public class TesseractOcrEngine {
    private static final String TAG = "TesseractOcrEngine";
    private final Context context;
    private TessBaseAPI tess;
    private final Object tessLock = new Object();
    private String currentLang = "";

    public TesseractOcrEngine(Context context) {
        this.context = context;
    }

    private void ensureTesseractInitialized(String lang) {
        synchronized (tessLock) {
            if (tess != null && lang.equals(currentLang)) return;
            if (tess != null) tess.recycle();

            String dataPath = context.getFilesDir().getAbsolutePath();
            copyTrainedDataIfNeeded(dataPath, lang);

            tess = new TessBaseAPI();
            if (!tess.init(dataPath, lang, TessBaseAPI.OEM_LSTM_ONLY)) {
                throw new IllegalStateException("Tesseract init failed");
            }

            tess.setVariable("load_system_dawg", "0");
            tess.setVariable("load_freq_dawg", "0");
            tess.setVariable("user_defined_dpi", "300");
            tess.setVariable(TessBaseAPI.VAR_CHAR_WHITELIST, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<");
            tess.setPageSegMode(TessBaseAPI.PageSegMode.PSM_SINGLE_BLOCK);
            currentLang = lang;
        }
    }

    private void copyTrainedDataIfNeeded(String dataPath, String lang) {
        File tessDir = new File(dataPath + "/tessdata");
        if (!tessDir.exists()) tessDir.mkdirs();
        File trainedFile = new File(tessDir, lang + ".traineddata");
        if (trainedFile.exists() && trainedFile.length() > 0) return;

        try (InputStream in = context.getAssets().open("tessdata/" + lang + ".traineddata");
             OutputStream out = new FileOutputStream(trainedFile)) {
            byte[] buffer = new byte[1024];
            int read;
            while ((read = in.read(buffer)) != -1) out.write(buffer, 0, read);
        } catch (Exception e) {
            Log.e(TAG, "Error copying trained data", e);
        }
    }

    public String ocrYPlane(
            byte[] bytes, int width, int height, int stride, int rotation,
            String lang, double roiLeft, double roiTop, double roiWidth, double roiHeight
    ) {
        ensureTesseractInitialized(lang);

        // 1. Mat object frame
        Mat mat = new Mat(height, stride, CvType.CV_8UC1);
        mat.put(0, 0, bytes);
        if (stride > width) {
            mat = mat.colRange(0, width);
        }

        // 2. ROI math + crop
        int lx, ly, lcw, lch;
        if (rotation == 90) {
            lx = (int) (roiTop * width);
            ly = (int) ((1.0 - roiLeft - roiWidth) * height);
            lcw = (int) (roiHeight * width);
            lch = (int) (roiWidth * height);
        } else if (rotation == 270) {
            lx = (int) ((1.0 - roiTop - roiHeight) * width);
            ly = (int) (roiLeft * height);
            lcw = (int) (roiHeight * width);
            lch = (int) (roiWidth * height);
        } else {
            lx = (int) (roiLeft * width);
            ly = (int) (roiTop * height);
            lcw = (int) (roiWidth * width);
            lch = (int) (roiHeight * height);
        }

        lx = Math.max(0, Math.min(lx, mat.cols() - 1));
        ly = Math.max(0, Math.min(ly, mat.rows() - 1));
        lcw = Math.max(1, Math.min(lcw, mat.cols() - lx));
        lch = Math.max(1, Math.min(lch, mat.rows() - ly));

        Mat cropped = mat.submat(ly, ly + lch, lx, lx + lcw).clone();
        mat.release();
        mat = cropped;

        // 3. Rotation landscape to portret
        if (rotation == 90) Core.rotate(mat, mat, Core.ROTATE_90_CLOCKWISE);
        else if (rotation == 180) Core.rotate(mat, mat, Core.ROTATE_180);
        else if (rotation == 270) Core.rotate(mat, mat, Core.ROTATE_90_COUNTERCLOCKWISE);

        // 4. MRZ Zone Detector
        MrzZoneDetector.RoiResult zone = MrzZoneDetector.detect(mat);

        // 5. MRZ crop
        if (zone != null) {
            int zX = (int)(zone.left * mat.cols());
            int zY = (int)(zone.top * mat.rows());
            int zW = (int)(zone.width * mat.cols());
            int zH = (int)(zone.height * mat.rows());
            Mat mrzCrop = mat.submat(
                    Math.max(0, zY), Math.min(mat.rows(), zY + zH),
                    Math.max(0, zX), Math.min(mat.cols(), zX + zW)
            ).clone();
            mat.release();
            mat = mrzCrop;
        }

        // 6. Normalize + invert check
        Core.normalize(mat, mat, 0, 255, Core.NORM_MINMAX);
        if (Core.mean(mat).val[0] < 110.0) Core.bitwise_not(mat, mat);

        // 7. Border
        Core.copyMakeBorder(mat, mat, 10, 10, 10, 10, Core.BORDER_CONSTANT, new Scalar(255));

        // 8. Tesseract OCR
        int w = mat.cols();
        int h = mat.rows();
        byte[] pixels = new byte[w * h];
        mat.get(0, 0, pixels);
        mat.release();

        String result = "";
        synchronized (tessLock) {
            tess.setImage(pixels, w, h, 1, w);
            result = tess.getUTF8Text();
            tess.clear();
        }
        return (result != null ? result : "").trim();
    }

    public void close() {
        synchronized (tessLock) {
            if (tess != null) { tess.recycle(); tess = null; }
        }
    }
}