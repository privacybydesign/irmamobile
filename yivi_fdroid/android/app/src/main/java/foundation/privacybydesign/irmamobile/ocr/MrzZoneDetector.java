package foundation.privacybydesign.irmamobile.ocr;

import android.util.Log;

import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfDouble;
import org.opencv.core.MatOfPoint;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.CLAHE;
import org.opencv.imgproc.Imgproc;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class MrzZoneDetector {

    private static final String TAG = "MRZ_ZONE";
    private static final double MIN_ASPECT = 3.0;
    private static final double MIN_COVERAGE = 0.40;
    private static final int TARGET_HEIGHT = 600;

    public static class RoiResult {
        public final double left;
        public final double top;
        public final double width;
        public final double height;

        public RoiResult(double left, double top, double width, double height) {
            this.left = left;
            this.top = top;
            this.width = width;
            this.height = height;
        }
    }

    public static RoiResult detect(Mat src) {
        // Stap 1: Zet naar grayscale als het nog niet zo is
        Mat gray = new Mat();
        if (src.channels() > 1) {
            Imgproc.cvtColor(src, gray, Imgproc.COLOR_RGBA2GRAY);
        } else {
            src.copyTo(gray);
        }

        // Stap 2: Resize naar 600px hoogte voor consistente verwerking
        double scale = (double) TARGET_HEIGHT / gray.rows();
        Mat resized = new Mat();
        Imgproc.resize(gray, resized, new Size(gray.cols() * scale, TARGET_HEIGHT));
        gray.release();

        int w = resized.cols();
        int h = resized.rows();

        // test: voor lichtinval problemen
        MatOfDouble mean = new MatOfDouble();
        MatOfDouble stddev = new MatOfDouble();
        Core.meanStdDev(resized, mean, stddev);
        double brightness = mean.get(0, 0)[0];
        double contrast   = stddev.get(0, 0)[0];

        // Test of dit werkt, som s net te vel en ziet moeilijk de mrz dit zou helpen in theorie
        double clipLimit = Math.max(1.0, 4.0 - (brightness / 80.0) - (contrast / 50.0));
        int tileSize = 8;

        CLAHE clahe = Imgproc.createCLAHE(clipLimit, new Size(tileSize, tileSize));
        clahe.apply(resized, resized);

        // Stap 3: Gaussian blur (5x5)
        Mat blurred = new Mat();
        Imgproc.GaussianBlur(resized, blurred, new Size(5.0, 5.0), 0.0);
        resized.release();

        // Stap 4: Blackhat
        Mat rectKernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(13.0, 5.0));
        Mat blackhat = new Mat();
        Imgproc.morphologyEx(blurred, blackhat, Imgproc.MORPH_BLACKHAT, rectKernel);
        blurred.release();

        // Stap 5: Sobel gradiënt
        Mat gradX = new Mat();
        Imgproc.Sobel(blackhat, gradX, CvType.CV_32F, 1, 0, -1);
        blackhat.release();
        Core.convertScaleAbs(gradX, gradX);
        Core.normalize(gradX, gradX, 0.0, 255.0, Core.NORM_MINMAX, CvType.CV_8U);

        // Stap 6: Closing
        Imgproc.morphologyEx(gradX, gradX, Imgproc.MORPH_CLOSE, rectKernel);
        rectKernel.release();

        // Stap 7: Threshold (Otsu)
        Mat thresh = new Mat();
        Imgproc.threshold(gradX, thresh, 0.0, 255.0, Imgproc.THRESH_BINARY | Imgproc.THRESH_OTSU);
        gradX.release();

        // Stap 8: Closing met een grote kernel
        Mat sqKernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(21.0, 21.0));
        Imgproc.morphologyEx(thresh, thresh, Imgproc.MORPH_CLOSE, sqKernel);
        sqKernel.release();

        // Stap 9: Erosie (2 iteraties)
        Mat erodeKernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(3.0, 3.0));
        Imgproc.erode(thresh, thresh, erodeKernel, new Point(-1.0, -1.0), 2);
        erodeKernel.release();

        // Stap 10: Randen negeren (5% links/rechts)
        int borderP = (int) (w * 0.05);
        thresh.submat(0, h, 0, borderP).setTo(new Scalar(0.0));
        thresh.submat(0, h, w - borderP, w).setTo(new Scalar(0.0));

        // Stap 11: Contours zoeken
        List<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();
        Imgproc.findContours(thresh, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
        thresh.release();
        hierarchy.release();

        Collections.sort(contours, new Comparator<MatOfPoint>() {
            @Override
            public int compare(MatOfPoint o1, MatOfPoint o2) {
                return Double.compare(Imgproc.contourArea(o2), Imgproc.contourArea(o1));
            }
        });

        RoiResult result = null;

        for (MatOfPoint contour : contours) {
            Rect rect = Imgproc.boundingRect(contour);
            double ar = (double) rect.width / rect.height;
            double crWidth = (double) rect.width / w;

            if (ar > MIN_ASPECT && crWidth > MIN_COVERAGE) {
                // Verhoogde padding om te voorkomen dat de witte rand tekst afdekt
                int pX = (int) (rect.width * 0.05);
                int pY = (int) (rect.height * 0.15);

                double left   = (double) Math.max(rect.x - pX, 0) / w;
                double top    = (double) Math.max(rect.y - pY, 0) / h;
                double right  = (double) Math.min(rect.x + rect.width + pX, w) / w;
                double bottom = (double) Math.min(rect.y + rect.height + pY, h) / h;

                result = new RoiResult(left, top, right - left, bottom - top);
                break;
            }
        }

        for (MatOfPoint contour : contours) {
            contour.release();
        }

        return result;
    }
}
