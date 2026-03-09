package foundation.privacybydesign.irmamobile.ocr;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;

public class ImagePreprocess {

    public static Bitmap toGrayBitmap(Bitmap src) {
        int w = src.getWidth();
        int h = src.getHeight();
        int[] px = new int[w * h];
        src.getPixels(px, 0, w, 0, 0, w, h);

        for (int i = 0; i < px.length; i++) {
            int c = px[i];
            int r = (c >> 16) & 0xFF;
            int g = (c >> 8) & 0xFF;
            int b = c & 0xFF;
            int y = (int) (0.299 * r + 0.587 * g + 0.114 * b);
            if (y < 0) y = 0;
            if (y > 255) y = 255;
            px[i] = (0xFF << 24) | (y << 16) | (y << 8) | y;
        }
        return Bitmap.createBitmap(px, w, h, Bitmap.Config.ARGB_8888);
    }

    public static double meanGray(Bitmap bmp) {
        int w = bmp.getWidth();
        int h = bmp.getHeight();
        int[] px = new int[w * h];
        bmp.getPixels(px, 0, w, 0, 0, w, h);
        long sum = 0;
        for (int c : px) sum += (c & 0xFF);
        return (double) sum / (w * h);
    }

    public static Bitmap invertGray(Bitmap bmp) {
        int w = bmp.getWidth();
        int h = bmp.getHeight();
        int[] px = new int[w * h];
        bmp.getPixels(px, 0, w, 0, 0, w, h);
        for (int i = 0; i < px.length; i++) {
            int g = px[i] & 0xFF;
            int inv = 255 - g;
            px[i] = (0xFF << 24) | (inv << 16) | (inv << 8) | inv;
        }
        return Bitmap.createBitmap(px, w, h, Bitmap.Config.ARGB_8888);
    }

    public static Bitmap contrastStretchGray(Bitmap src) {
        int w = src.getWidth();
        int h = src.getHeight();
        int[] px = new int[w * h];
        src.getPixels(px, 0, w, 0, 0, w, h);

        int min = 255;
        int max = 0;
        for (int c : px) {
            int g = c & 0xFF;
            if (g < min) min = g;
            if (g > max) max = g;
        }

        int range = Math.max(max - min, 1);
        for (int i = 0; i < px.length; i++) {
            int g = px[i] & 0xFF;
            int v = ((g - min) * 255) / range;
            px[i] = (0xFF << 24) | (v << 16) | (v << 8) | v;
        }

        return Bitmap.createBitmap(px, w, h, Bitmap.Config.ARGB_8888);
    }

    public static Bitmap addBorder(Bitmap src, int pad) {
        Bitmap out = Bitmap.createBitmap(src.getWidth() + 2 * pad, src.getHeight() + 2 * pad, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(out);
        canvas.drawColor(Color.WHITE);
        canvas.drawBitmap(src, pad, pad, null);
        return out;
    }

    public static Bitmap cropToNormalizedRoi(Bitmap src, double roiLeft, double roiTop, double roiWidth, double roiHeight) {
        int x = (int) (roiLeft * src.getWidth());
        x = Math.max(0, Math.min(x, src.getWidth() - 1));
        int y = (int) (roiTop * src.getHeight());
        y = Math.max(0, Math.min(y, src.getHeight() - 1));
        int w0 = (int) (roiWidth * src.getWidth());
        w0 = Math.max(1, Math.min(w0, src.getWidth() - x));
        int h0 = (int) (roiHeight * src.getHeight());
        h0 = Math.max(1, Math.min(h0, src.getHeight() - y));
        return Bitmap.createBitmap(src, x, y, w0, h0);
    }
}
