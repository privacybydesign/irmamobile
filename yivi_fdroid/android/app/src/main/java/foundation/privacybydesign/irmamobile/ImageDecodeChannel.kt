package foundation.privacybydesign.irmamobile

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Bridges the "image_channel" MethodChannel that the face_verification package
// calls to decode JPEG 2000 chip photos (passport/eID DG2), which the Dart
// `image` package cannot decode. Mirrors the vcmrtd example app.
object ImageDecodeChannel {

    @JvmStatic
    fun register(flutterEngine: FlutterEngine, appContext: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "image_channel")
            .setMethodCallHandler { call, result ->
                if (call.method == "decodeImage") {
                    val jp2ImageData = call.argument<ByteArray?>("jp2ImageData")
                    if (jp2ImageData != null) {
                        ImageUtil.decodeImage(appContext, jp2ImageData, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "jp2ImageData is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
