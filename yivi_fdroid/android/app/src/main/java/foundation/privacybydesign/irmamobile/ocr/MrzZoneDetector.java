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

    /**
     * Head method to detect the MRZ zone in an image.
     */
    public static RoiResult detect(Mat src) {
        // 1. Convert to grayscale
        Mat gray = new Mat();
        if (src.channels() > 1) {
            Imgproc.cvtColor(src, gray, Imgproc.COLOR_RGBA2GRAY);
        } else {
            src.copyTo(gray);
        }

        // 2. Scale the image to a fixed height (600px) for consistent parameters
        double scale = (double) TARGET_HEIGHT / gray.rows();
        Mat resized = new Mat();
        Imgproc.resize(gray, resized, new Size(gray.cols() * scale, TARGET_HEIGHT));
        gray.release();

        int w = resized.cols();
        int h = resized.rows();

        // 3. calculate contrast
        MatOfDouble mean = new MatOfDouble();
        MatOfDouble stddev = new MatOfDouble();
        Core.meanStdDev(resized, mean, stddev);
        double contrast = stddev.get(0, 0)[0];
        mean.release();
        stddev.release();


        // 4 contrast correction with CLAHE
        Core.normalize(resized, resized, 0.0, 255.0, Core.NORM_MINMAX, CvType.CV_8U);
        double clipLimit = (contrast < 20) ? 10.0 : (contrast < 35) ? 6.0 : 3.0;
        CLAHE clahe = Imgproc.createCLAHE(clipLimit, new Size(4, 4));
        clahe.apply(resized, resized);

        // 5. Gaussian Blur to remove noise
        Mat blurred = new Mat();
        Imgproc.GaussianBlur(resized, blurred, new Size(3.0, 3.0), 0.0);
        resized.release();

        // 6. Blackhat morph to isolate dark text on bright background
        Mat rectKernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(15.0, 7.0));
        Mat blackhat = new Mat();
        Imgproc.morphologyEx(blurred, blackhat, Imgproc.MORPH_BLACKHAT, rectKernel);
        blurred.release();

        // 7. Sobel gradiënt to detect vertical text lines
        Mat gradX = new Mat();
        Imgproc.Sobel(blackhat, gradX, CvType.CV_32F, 1, 0, -1);
        blackhat.release();
        Core.convertScaleAbs(gradX, gradX);
        Core.normalize(gradX, gradX, 0.0, 255.0, Core.NORM_MINMAX, CvType.CV_8U);


        // 8. Closing operation to merge nearby letters into lines
        Imgproc.morphologyEx(gradX, gradX, Imgproc.MORPH_CLOSE, rectKernel);
        rectKernel.release();

        // 9. Otsu's Threshold to binarize the image, true black wit
        Mat thresh = new Mat();
        Imgproc.threshold(gradX, thresh, 0.0, 255.0,
                Imgproc.THRESH_BINARY | Imgproc.THRESH_OTSU);
        gradX.release();

        // 10. pass 1: Horizontal projection. Searches for a dense horizontal band of pixels
        // works great if document is straight and not tilted.
        RoiResult result = tryHorizontalProjection(thresh, w, h);

        // 11. Pass 2: Contour detection. Fallback if projection fails.
        // looks at the vorm and location of adjacent text blocks.
        if (result == null) {
            result = tryContourDetection(thresh, w, h);
        } else {
            // Projection worked, release thresh
            thresh.release();
        }

        // 12. Extra fallback: Use a fixed ROI in the bottom half of the image
        if (result == null) {
            result = new RoiResult(0.02, 0.70, 0.96, 0.28);
        }

        return result;
    }

    /**
     * Horizontal projection - tries to detect the MRZ as a dense horizontal band
     * in the bottom half of the image.
     */
    private static RoiResult tryHorizontalProjection(Mat thresh, int w, int h) {
        int searchStartY = (int) (h * 0.45);
        Mat bottomHalf = thresh.submat(searchStartY, h, 0, w);
        int bh = bottomHalf.rows();

        // Calculate density of pixels in each row
        Mat rowSums = new Mat();
        Core.reduce(bottomHalf, rowSums, 1, Core.REDUCE_AVG, CvType.CV_64F);

        double[] density = new double[bh];
        for (int y = 0; y < bh; y++) {
            density[y] = rowSums.get(y, 0)[0] / 255.0;
        }
        rowSums.release();

        // smooth the density profile to remove noise
        int smoothW = 5;
        double[] smoothed = new double[bh];
        for (int y = 0; y < bh; y++) {
            double total = 0;
            int count = 0;
            for (int dy = -smoothW; dy <= smoothW; dy++) {
                int yy = y + dy;
                if (yy >= 0 && yy < bh) {
                    total += density[yy];
                    count++;
                }
            }
            smoothed[y] = total / count;
        }

        // search rhe most dense band of 70px (typical MRZ height)
        double bestScore = 0;
        int bestStart = 0;
        int bestWindow = 70;

        for (int y = 0; y <= bh - 70; y++) {
            double score = 0;
            for (int dy = 0; dy < 70; dy++) {
                score += smoothed[y + dy];
            }
            score /= 70;
            if (score > bestScore) {
                bestScore = score;
                bestStart = y;
            }
        }


        if (bestScore < 0.10) {
            return null;
        }

        // make the band wider at the top and bottom until the density drops
        double cutoff = bestScore * 0.25;
        int mrzTop = bestStart;
        int mrzBottom = Math.min(bestStart + bestWindow, bh - 1);

        for (int y = bestStart - 1; y >= 0; y--) {
            if (smoothed[y] < cutoff) {
                mrzTop = y + 1;
                break;
            }
            mrzTop = y;
        }

        for (int y = bestStart + bestWindow; y < bh; y++) {
            if (smoothed[y] < cutoff) {
                mrzBottom = y - 1;
                break;
            }
            mrzBottom = y;
        }

        // translate lokal coordinates back to full image and add margin
        int absTop = mrzTop + searchStartY;
        int absBottom = mrzBottom + searchStartY;

        int padY = (int) ((absBottom - absTop) * 0.15);
        absTop = Math.max(0, absTop - padY);
        absBottom = Math.min(h - 1, absBottom + padY);

        double roiTop = (double) absTop / h;
        double roiHeight = (double) (absBottom - absTop) / h;


        // validate of the found height is reasonable for a MRZ
        if (roiHeight < 0.08 || roiHeight > 0.45) {
            return null;
        }

        return new RoiResult(0.02, roiTop, 0.96, roiHeight);
    }

    /**
     * Search for MRZ by grouping contours and filtering on aspect ratio.
     */
    private static RoiResult tryContourDetection(Mat thresh, int w, int h) {
        // Use morph to merge lines and words into blocks
        Mat smallClose = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(9.0, 9.0));
        Imgproc.morphologyEx(thresh, thresh, Imgproc.MORPH_CLOSE, smallClose);
        smallClose.release();

        Mat vErode = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(1.0, 15.0));
        Imgproc.erode(thresh, thresh, vErode, new Point(-1.0, -1.0), 2);
        vErode.release();

        Mat hErode = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(5.0, 1.0));
        Imgproc.erode(thresh, thresh, hErode, new Point(-1.0, -1.0), 1);
        hErode.release();

        Mat hClose = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(31.0, 1.0));
        Imgproc.morphologyEx(thresh, thresh, Imgproc.MORPH_CLOSE, hClose);
        hClose.release();

        Mat vClose = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(1.0, 21.0));
        Imgproc.morphologyEx(thresh, thresh, Imgproc.MORPH_CLOSE, vClose);
        vClose.release();

        Mat hDilate = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(31.0, 5.0));
        Imgproc.dilate(thresh, thresh, hDilate, new Point(-1.0, -1.0), 4);
        hDilate.release();

        // ignore the borders of the image
        int borderP = (int) (w * 0.05);
        thresh.submat(0, h, 0, borderP).setTo(new Scalar(0.0));
        thresh.submat(0, h, w - borderP, w).setTo(new Scalar(0.0));

        // Find contours
        List<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();
        Imgproc.findContours(thresh, contours, hierarchy,
                Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
        thresh.release();
        hierarchy.release();

        // sort contours by area (Biggest first)
        Collections.sort(contours, new Comparator<MatOfPoint>() {
            @Override
            public int compare(MatOfPoint o1, MatOfPoint o2) {
                return Double.compare(Imgproc.contourArea(o2), Imgproc.contourArea(o1));
            }
        });

        RoiResult best = null;
        double bestCenterY = 0;

        // Filter contours based on typical MRZ properties (width, height, location)
        for (MatOfPoint contour : contours) {
            Rect rect = Imgproc.boundingRect(contour);
            double ar = (double) rect.width / rect.height;
            double crWidth = (double) rect.width / w;
            double areaRatio = (double) (rect.width * rect.height) / (w * h);
            double heightRatio = (double) rect.height / h;
            double centerY = ((double) rect.y + rect.height / 2.0) / h;

            if (areaRatio > 0.40) continue;
            if (heightRatio > 0.35) continue;
            if (centerY < 0.4) continue;

            // MRZ is typical wide (ar > 2.5) and occupies a large part of the width
            if (ar > 2.5 && crWidth > 0.25 && rect.height > 15 && areaRatio > 0.05) {
                if (centerY > bestCenterY) {
                    int pX = (int) (rect.width * 0.08);
                    int pY = (int) (rect.height * 0.20);

                    double left   = (double) Math.max(rect.x - pX, 0) / w;
                    double top    = (double) Math.max(rect.y - pY, 0) / h;
                    double right  = (double) Math.min(rect.x + rect.width + pX, w) / w;
                    double bottom = (double) Math.min(rect.y + rect.height + pY, h) / h;

                    best = new RoiResult(left, top, right - left, bottom - top);
                    bestCenterY = centerY;
                }
            }
        }

        for (MatOfPoint contour : contours) {
            contour.release();
        }

        return best;
    }
}
