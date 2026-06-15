package foundation.privacybydesign.irmamobile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.gemalto.jp2.JP2Decoder
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream

// Decodes JPEG 2000 chip photos to JPEG bytes for Flutter. Mirrors the vcmrtd
// example app, with null/exception guards so a bad photo fails gracefully
// instead of crashing.
object ImageUtil {

    fun decodeImage(context: Context?, jp2ImageData: ByteArray, result: MethodChannel.Result) {
        try {
            val inputStream: InputStream = ByteArrayInputStream(jp2ImageData)
            val decodedBitmap = decodeImage(context, "image/jp2", inputStream)
            if (decodedBitmap == null) {
                result.error("DECODE_FAILED", "Could not decode JP2 image", null)
                return
            }
            val byteArrayOutputStream = ByteArrayOutputStream()
            decodedBitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream)
            result.success(byteArrayOutputStream.toByteArray())
        } catch (e: Exception) {
            result.error("DECODE_FAILED", e.message, null)
        }
    }

    fun decodeImage(context: Context?, mimeType: String, inputStream: InputStream?): Bitmap? {
        return if (mimeType.equals("image/jp2", ignoreCase = true) ||
            mimeType.equals("image/jpeg2000", ignoreCase = true)
        ) {
            JP2Decoder(inputStream).decode()
        } else {
            BitmapFactory.decodeStream(inputStream)
        }
    }
}
