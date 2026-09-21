import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:image/image.dart" as img;
import "package:yivi/iris_frame.dart";

/// A solid-colour BGRA frame with [padding] extra bytes per row, as iOS
/// delivers it.
RawFrame _bgraFrame(int width, int height, {int padding = 0}) {
  final bytesPerRow = width * 4 + padding;
  final bytes = Uint8List(bytesPerRow * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * bytesPerRow + x * 4;
      bytes[i] = 200; // B
      bytes[i + 1] = 100; // G
      bytes[i + 2] = 50; // R
      bytes[i + 3] = 255; // A
    }
  }
  return RawFrame(
    format: RawFrameFormat.bgra8888,
    width: width,
    height: height,
    planes: [
      RawPlane(bytes: bytes, bytesPerRow: bytesPerRow, bytesPerPixel: 4),
    ],
  );
}

/// A mid-grey YUV420 frame with interleaved U/V (pixel stride 2), as Android
/// commonly delivers it.
RawFrame _yuvFrame(int width, int height) {
  final y = Uint8List(width * height)..fillRange(0, width * height, 128);
  final uvRow = width; // pixel stride 2 → a full width per chroma row
  final uv = Uint8List(uvRow * (height ~/ 2))
    ..fillRange(0, uvRow * (height ~/ 2), 128);
  return RawFrame(
    format: RawFrameFormat.yuv420,
    width: width,
    height: height,
    planes: [
      RawPlane(bytes: y, bytesPerRow: width, bytesPerPixel: 1),
      RawPlane(bytes: uv, bytesPerRow: uvRow, bytesPerPixel: 2),
      RawPlane(bytes: uv, bytesPerRow: uvRow, bytesPerPixel: 2),
    ],
  );
}

void main() {
  group("scaledFrameSize", () {
    test("caps the long side and keeps the aspect ratio", () {
      expect(scaledFrameSize(720, 480, 640), (width: 640, height: 427));
      expect(scaledFrameSize(480, 720, 640), (width: 427, height: 640));
    });

    test("never upscales", () {
      expect(scaledFrameSize(640, 480, 640), (width: 640, height: 480));
      expect(scaledFrameSize(320, 240, 640), (width: 320, height: 240));
    });
  });

  group("frameOrientation", () {
    test("iOS uses the sensor orientation as is", () {
      expect(
        frameOrientation(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          frontCamera: true,
          isIOS: true,
        ),
        1,
      );
    });

    test("Android front camera adds the device rotation", () {
      expect(
        frameOrientation(
          sensorOrientation: 270,
          deviceOrientation: DeviceOrientation.portraitUp,
          frontCamera: true,
          isIOS: false,
        ),
        3,
      );
      expect(
        frameOrientation(
          sensorOrientation: 270,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          frontCamera: true,
          isIOS: false,
        ),
        0, // (270 + 90) % 360
      );
    });

    test("Android back camera subtracts the device rotation", () {
      expect(
        frameOrientation(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          frontCamera: false,
          isIOS: false,
        ),
        0,
      );
    });
  });

  group("encodeFrameJpeg", () {
    test("BGRA with row padding decodes to the scaled size and colour", () {
      final jpeg = encodeFrameJpegSync(
        _bgraFrame(96, 64, padding: 16),
        maxLongSide: 48,
      );

      final decoded = img.decodeJpg(jpeg)!;
      expect(decoded.width, 48);
      expect(decoded.height, 32);
      final pixel = decoded.getPixel(10, 10);
      expect(pixel.r, closeTo(50, 6));
      expect(pixel.g, closeTo(100, 6));
      expect(pixel.b, closeTo(200, 6));
    });

    test("YUV420 with interleaved chroma decodes to grey", () {
      final jpeg = encodeFrameJpegSync(_yuvFrame(64, 48), maxLongSide: 640);

      final decoded = img.decodeJpg(jpeg)!;
      expect(decoded.width, 64);
      expect(decoded.height, 48);
      final pixel = decoded.getPixel(5, 5);
      expect(pixel.r, closeTo(128, 4));
      expect(pixel.g, closeTo(128, 4));
      expect(pixel.b, closeTo(128, 4));
    });

    test("the isolate variant produces the same bytes", () async {
      final frame = _bgraFrame(32, 24);
      final sync = encodeFrameJpegSync(frame, maxLongSide: 640);

      final async = await encodeFrameJpeg(frame, maxLongSide: 640);

      expect(async, sync);
    });
  });
}
