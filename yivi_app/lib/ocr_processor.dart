import "dart:io";
import "dart:math";
import "dart:ui";

import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:yivi_core/yivi_core.dart";

class GoogleMLKitOcrProcessor implements OcrProcessor {
  final _textRecognizer = TextRecognizer();

  @override
  Future<OcrResult> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  }) async {
    final image = _inputImageFromCameraImage(
      image: inputImage,
      imageRotation: imageRotation,
    );
    final recognizedText = await _textRecognizer.processImage(image!);
    // Glare is measured on Android only: there the frame's first plane is its
    // brightness (NV21) and ML Kit reports boxes in the upright frame. iOS frames are
    // BGRA.
    final glare =
        Platform.isAndroid &&
        mrzHasGlare(
          luminance: inputImage.planes.first.bytes,
          width: inputImage.width,
          height: inputImage.height,
          bytesPerRow: inputImage.planes.first.bytesPerRow,
          rotation: imageRotation,
          lineBoxes: mrzLineBoxes([
            for (final block in recognizedText.blocks)
              for (final line in block.lines) (line.text, line.boundingBox),
          ]),
        );
    return OcrResult(
      lines: mrzLinesFromText(recognizedText.text),
      glare: glare,
    );
  }

  /// The boxes of the MRZ lines among all the lines ML Kit read, top to bottom: the
  /// lines [mrzLinesFromText] picks, so glare is measured where the MRZ is.
  @visibleForTesting
  static List<Rect> mrzLineBoxes(Iterable<(String, Rect)> lines) {
    final candidates = [
      for (final (text, box) in lines)
        if (_looksLikeMrz(text.replaceAll(" ", "")))
          (line: _normalizeMrzLine(text.replaceAll(" ", "")), box: box),
    ]..sort((a, b) => a.box.top.compareTo(b.box.top));

    // Only lines that have, or can be repaired to, the MRZ line length, and as
    // many as the format has: a passport's two, not an upper case line above.
    final repaired = fixMrzLineLengths([for (final c in candidates) c.line]);
    if (repaired.isEmpty) return [];

    final length = repaired.first.length;
    final boxes = [
      for (final c in candidates)
        if (fixMrzLineLength(c.line, length).length == length) c.box,
    ];
    return boxes.sublist(max(0, boxes.length - mrzLineCount(length)));
  }

  /// Picks the MRZ lines out of all the text ML Kit read in a frame.
  ///
  /// ML Kit reads the whole document, not just the MRZ. Picking MRZ lines by length
  /// mixed in any other line that happened to be 30, 36 or 44 characters long, and
  /// the frame was then thrown away. MRZ text is upper case and the rest of a
  /// document's text mostly is not, so pick by that, repair lines with a miscounted
  /// run of fillers, and keep the bottom lines: the MRZ ends the document.
  @visibleForTesting
  static List<String>? mrzLinesFromText(String text) {
    final candidates = text
        .split("\n")
        .map((line) => line.replaceAll(" ", ""))
        .where(_looksLikeMrz)
        .map(_normalizeMrzLine)
        .toList();

    final lines = fixMrzLineLengths(candidates);
    if (lines.isEmpty) return null;

    final count = mrzLineCount(lines.first.length);
    return _getFinalListToParse(lines.sublist(max(0, lines.length - count)));
  }

  /// Whether [line] could be MRZ: long enough, and at most a few lower case letters
  /// that ML Kit may have misread.
  static bool _looksLikeMrz(String line) =>
      line.length >= minMrzLineLength &&
      RegExp(r"[a-z]").allMatches(line).length <= line.length ~/ 10;

  /// Upper-cases [line] and turns every character that cannot occur in an MRZ into a
  /// filler; ML Kit reads fillers as '«', '(' and the like.
  static String _normalizeMrzLine(String line) =>
      line.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9<]"), "<");

  InputImage? _inputImageFromCameraImage({
    required CameraImage image,
    required int imageRotation,
  }) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(
      imageRotation,
    );
    if (rotation == null) {
      return null;
    }

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  static List<String>? _getFinalListToParse(List<String> ableToScanTextList) {
    if (ableToScanTextList.isEmpty) {
      return null;
    }

    // Check for driver's license (starts with D1, D2, or DL)
    String firstLine = ableToScanTextList.first;
    if (firstLine.length >= 2) {
      String firstTwoChars = firstLine.substring(0, 2);
      List<String> driverLicenseTypes = ["D1", "D2", "DL"];
      if (driverLicenseTypes.contains(firstTwoChars)) {
        debugPrint("Driver's License MRZ detected");
        return [...ableToScanTextList];
      }
    }

    // Check for passport/visa (requires at least 2 lines)
    if (ableToScanTextList.length < 2) {
      // minimum length of passport MRZ format is 2 lines
      return null;
    }
    int lineLength = ableToScanTextList.first.length;
    for (var e in ableToScanTextList) {
      if (e.length != lineLength) {
        return null;
      }
      // to make sure that all lines are the same in length
    }
    List<String> firstLineChars = ableToScanTextList.first.split("");
    List<String> supportedDocTypes = [
      "P",
      "V",
      "I",
    ]; // you can add more doc types like A,C,I are also supported
    String fChar = firstLineChars[0];
    if (supportedDocTypes.contains(fChar)) {
      debugPrint("Passport or Visa MRZ detected");
      return [...ableToScanTextList];
    }
    return null;
  }
}
