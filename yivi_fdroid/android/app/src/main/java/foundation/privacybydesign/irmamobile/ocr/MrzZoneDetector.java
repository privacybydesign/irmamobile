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
        /** How dense the found band is; higher means more likely the MRZ. */
        public final double score;

        public RoiResult(double left, double top, double width, double height) {
            this(left, top, width, height, 0.0);
        }

        public RoiResult(double left, double top, double width, double height, double score) {
            this.left = left;
            this.top = top;
            this.width = width;
            this.height = height;
            this.score = score;
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

        // 2b. A nearly flat frame (lens covered, phone face down) has no document in it.
        // Stretching it would turn sensor noise into a fake text band.
        MatOfDouble mean = new MatOfDouble();
        MatOfDouble stddev = new MatOfDouble();
        Core.meanStdDev(resized, mean, stddev);
        double contrast = stddev.get(0, 0)[0];
        mean.release();
        stddev.release();
        if (contrast < 4.0) {
            resized.release();
            return null;
        }

        // 3. Stretch the contrast to the full range. No local equalisation (CLAHE) here:
        // on a textured surface (fabric, wood grain) it boosts the texture until the
        // projection below scores it as a denser band than the MRZ itself.
        Core.normalize(resized, resized, 0.0, 255.0, Core.NORM_MINMAX, CvType.CV_8U);

        // 4. Gaussian Blur to remove noise and fine surface texture. The MRZ characters
        // (~19px tall at this scale) survive a 7x7 kernel.
        Mat blurred = new Mat();
        Imgproc.GaussianBlur(resized, blurred, new Size(7.0, 7.0), 0.0);
        resized.release();

        // 5. Blackhat morph to isolate dark text on bright background
        Mat rectKernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(15.0, 7.0));
        Mat blackhat = new Mat();
        Imgproc.morphologyEx(blurred, blackhat, Imgproc.MORPH_BLACKHAT, rectKernel);
        blurred.release();

        // 6. Sobel gradiënt to detect vertical text lines
        Mat gradX = new Mat();
        Imgproc.Sobel(blackhat, gradX, CvType.CV_32F, 1, 0, -1);
        blackhat.release();
        Core.convertScaleAbs(gradX, gradX);
        Core.normalize(gradX, gradX, 0.0, 255.0, Core.NORM_MINMAX, CvType.CV_8U);


        // 7. Closing operation to merge nearby letters into lines
        Imgproc.morphologyEx(gradX, gradX, Imgproc.MORPH_CLOSE, rectKernel);
        rectKernel.release();

        // 8. Otsu's Threshold to binarize the image, true black wit
        Mat thresh = new Mat();
        Imgproc.threshold(gradX, thresh, 0.0, 255.0,
                Imgproc.THRESH_BINARY | Imgproc.THRESH_OTSU);
        gradX.release();

        // 9. pass 1: Horizontal projection. Searches for a dense horizontal band of pixels
        // works great if document is straight and not tilted.
        RoiResult result = tryHorizontalProjection(thresh, w, h);

        // 10. Pass 2: Contour detection. Fallback if projection fails.
        // looks at the vorm and location of adjacent text blocks.
        if (result == null) {
            result = tryContourDetection(thresh, w, h);
        } else {
            // Projection worked, release thresh
            thresh.release();
        }

        // Null when neither pass found an MRZ; the caller skips OCR for this frame.
        return result;
    }

    /**
     * Estimates how far the document's text lines are rotated, in degrees, in the
     * convention of {@link Imgproc#getRotationMatrix2D}: rotating by the returned angle
     * levels them. At the right angle every text line falls on its own rows, so the row
     * sums of a text mask alternate between full and empty and their variance peaks.
     */
    public static double estimateSkew(Mat gray) {
        double scale = 300.0 / gray.rows();
        Mat small = new Mat();
        Imgproc.resize(gray, small, new Size(gray.cols() * scale, 300), 0, 0, Imgproc.INTER_AREA);
        Core.normalize(small, small, 0.0, 255.0, Core.NORM_MINMAX, CvType.CV_8U);
        Imgproc.GaussianBlur(small, small, new Size(3.0, 3.0), 0.0);

        Mat kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(9.0, 5.0));
        Mat mask = new Mat();
        Imgproc.morphologyEx(small, mask, Imgproc.MORPH_BLACKHAT, kernel);
        Imgproc.threshold(mask, mask, 0.0, 255.0, Imgproc.THRESH_BINARY | Imgproc.THRESH_OTSU);
        small.release();
        kernel.release();

        double best = 0;
        double bestScore = -1;
        // Text lines look the same at a and a+180, so half a turn covers every rotation;
        // the caller resolves upright versus upside down. MRZ characters also line up in
        // columns, 90 degrees off, but the text lines score higher than those columns.
        for (double angle = -90; angle < 90; angle += 3) {
            double score = rowVariance(mask, angle);
            if (score > bestScore) {
                bestScore = score;
                best = angle;
            }
        }
        double coarse = best;
        for (double angle = coarse - 1.5; angle <= coarse + 1.5; angle += 0.5) {
            double score = rowVariance(mask, angle);
            if (score > bestScore) {
                bestScore = score;
                best = angle;
            }
        }
        mask.release();
        if (best >= 90) best -= 180;
        if (best < -90) best += 180;
        return best;
    }

    private static double rowVariance(Mat mask, double angle) {
        Mat rot = Imgproc.getRotationMatrix2D(new Point(mask.cols() / 2.0, mask.rows() / 2.0), angle, 1.0);
        Mat rotated = new Mat();
        Imgproc.warpAffine(mask, rotated, rot, mask.size(), Imgproc.INTER_NEAREST, Core.BORDER_CONSTANT, new Scalar(0.0));
        rot.release();

        Mat rowSums = new Mat();
        Core.reduce(rotated, rowSums, 1, Core.REDUCE_SUM, CvType.CV_64F);
        rotated.release();

        MatOfDouble mean = new MatOfDouble();
        MatOfDouble stddev = new MatOfDouble();
        Core.meanStdDev(rowSums, mean, stddev);
        double sd = stddev.get(0, 0)[0];
        rowSums.release();
        mean.release();
        stddev.release();
        return sd * sd;
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

        // Narrow the band to the columns that hold text. Otherwise the document's edge
        // next to the MRZ reaches Tesseract as an extra character at the start or end
        // of every line, and a 31-character line no longer parses as TD1.
        Mat band = thresh.submat(absTop, absBottom + 1, 0, w);
        Mat colSums = new Mat();
        Core.reduce(band, colSums, 0, Core.REDUCE_AVG, CvType.CV_64F);
        band.release();

        double[] colDensity = new double[w];
        for (int x = 0; x < w; x++) {
            colDensity[x] = colSums.get(0, x)[0] / 255.0;
        }
        colSums.release();

        double[] smoothedCols = new double[w];
        double maxCol = 0;
        for (int x = 0; x < w; x++) {
            double total = 0;
            int count = 0;
            for (int dx = -4; dx <= 4; dx++) {
                int xx = x + dx;
                if (xx >= 0 && xx < w) {
                    total += colDensity[xx];
                    count++;
                }
            }
            smoothedCols[x] = total / count;
            maxCol = Math.max(maxCol, smoothedCols[x]);
        }

        int textLeft = -1;
        int textRight = -1;
        for (int x = 0; x < w; x++) {
            if (smoothedCols[x] > maxCol * 0.3) {
                if (textLeft < 0) textLeft = x;
                textRight = x;
            }
        }
        if (textLeft < 0) {
            return new RoiResult(0.02, roiTop, 0.96, roiHeight, bestScore);
        }

        double padX = 0.015;
        double roiLeft = Math.max(0.0, (double) textLeft / w - padX);
        double roiRight = Math.min(1.0, (double) (textRight + 1) / w + padX);

        return new RoiResult(roiLeft, roiTop, roiRight - roiLeft, roiHeight, bestScore);
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
