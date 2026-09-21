import "dart:isolate";

import "package:camera/camera.dart";
import "package:flutter/services.dart";
import "package:image/image.dart" as img;

/// Pixel layout of a [RawFrame], one per platform: Android streams three-plane
/// YUV420 (U/V possibly interleaved), iOS a single BGRA plane.
enum RawFrameFormat { yuv420, bgra8888 }

/// One camera plane, copied out of the plugin's buffer.
class RawPlane {
  const RawPlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

/// A camera frame as plain data, so it can cross into the encoding isolate
/// without dragging the camera plugin's types along.
class RawFrame {
  const RawFrame({
    required this.format,
    required this.width,
    required this.height,
    required this.planes,
  });

  factory RawFrame.fromCameraImage(CameraImage image) => RawFrame(
    format: switch (image.format.group) {
      ImageFormatGroup.bgra8888 => RawFrameFormat.bgra8888,
      _ => RawFrameFormat.yuv420,
    },
    width: image.width,
    height: image.height,
    planes: [
      for (final plane in image.planes)
        RawPlane(
          // Copy: the plugin recycles its buffers once the callback returns.
          bytes: Uint8List.fromList(plane.bytes),
          bytesPerRow: plane.bytesPerRow,
          bytesPerPixel: plane.bytesPerPixel ?? 1,
        ),
    ],
  );

  final RawFrameFormat format;
  final int width;
  final int height;
  final List<RawPlane> planes;
}

/// The size a [width]×[height] frame is sent at: never upscaled, the long side
/// capped at [maxLongSide], aspect ratio kept.
({int width, int height}) scaledFrameSize(
  int width,
  int height,
  int maxLongSide,
) {
  final longSide = width > height ? width : height;
  if (longSide <= maxLongSide) return (width: width, height: height);
  final scale = maxLongSide / longSide;
  return (
    width: (width * scale).round().clamp(1, maxLongSide),
    height: (height * scale).round().clamp(1, maxLongSide),
  );
}

/// The verifier's orientation enum for a frame: the clockwise rotation, in
/// quarter turns (0–3), that makes it upright. Same arithmetic as the MRZ
/// scanner uses for ML Kit: iOS frames only need the sensor's rotation; on
/// Android the device rotation is added for the front camera.
int frameOrientation({
  required int sensorOrientation,
  required DeviceOrientation deviceOrientation,
  required bool frontCamera,
  required bool isIOS,
}) {
  var degrees = sensorOrientation;
  if (!isIOS) {
    final device = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
    degrees = frontCamera
        ? (sensorOrientation + device) % 360
        : (sensorOrientation - device + 360) % 360;
  }
  return (degrees ~/ 90) % 4;
}

/// Converts and downscales [frame] to a JPEG off the UI isolate. This is the
/// seam for a native encoder: the capture screen only depends on this
/// signature.
Future<Uint8List> encodeFrameJpeg(
  RawFrame frame, {
  required int maxLongSide,
  int quality = 80,
}) => Isolate.run(
  () => encodeFrameJpegSync(frame, maxLongSide: maxLongSide, quality: quality),
);

/// Same as [encodeFrameJpeg], on the calling isolate.
Uint8List encodeFrameJpegSync(
  RawFrame frame, {
  required int maxLongSide,
  int quality = 80,
}) {
  final size = scaledFrameSize(frame.width, frame.height, maxLongSide);
  // Sampling at the output size folds the downscale into the colour
  // conversion, so no pixel is converted only to be thrown away.
  final rgb = switch (frame.format) {
    RawFrameFormat.yuv420 => _yuv420ToRgb(frame, size.width, size.height),
    RawFrameFormat.bgra8888 => _bgraToRgb(frame, size.width, size.height),
  };
  final image = img.Image.fromBytes(
    width: size.width,
    height: size.height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
  return img.encodeJpg(image, quality: quality);
}

Uint8List _bgraToRgb(RawFrame frame, int outWidth, int outHeight) {
  final plane = frame.planes.first;
  final src = plane.bytes;
  final out = Uint8List(outWidth * outHeight * 3);
  var o = 0;
  for (var y = 0; y < outHeight; y++) {
    final sy = y * frame.height ~/ outHeight;
    final row = sy * plane.bytesPerRow;
    for (var x = 0; x < outWidth; x++) {
      final i = row + (x * frame.width ~/ outWidth) * plane.bytesPerPixel;
      out[o++] = src[i + 2];
      out[o++] = src[i + 1];
      out[o++] = src[i];
    }
  }
  return out;
}

Uint8List _yuv420ToRgb(RawFrame frame, int outWidth, int outHeight) {
  final yPlane = frame.planes[0];
  final uPlane = frame.planes[1];
  final vPlane = frame.planes[2];
  final out = Uint8List(outWidth * outHeight * 3);
  var o = 0;
  for (var y = 0; y < outHeight; y++) {
    final sy = y * frame.height ~/ outHeight;
    final yRow = sy * yPlane.bytesPerRow;
    final uvRow = (sy >> 1) * uPlane.bytesPerRow;
    for (var x = 0; x < outWidth; x++) {
      final sx = x * frame.width ~/ outWidth;
      final luma = yPlane.bytes[yRow + sx * yPlane.bytesPerPixel];
      final uvIndex = uvRow + (sx >> 1) * uPlane.bytesPerPixel;
      final u = uPlane.bytes[uvIndex] - 128;
      final v = vPlane.bytes[uvIndex] - 128;
      // BT.601 in fixed point (×1024), the usual YUV_420_888 conversion.
      out[o++] = _clamp8(luma + ((1436 * v) >> 10));
      out[o++] = _clamp8(luma - ((352 * u + 731 * v) >> 10));
      out[o++] = _clamp8(luma + ((1815 * u) >> 10));
    }
  }
  return out;
}

int _clamp8(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);
