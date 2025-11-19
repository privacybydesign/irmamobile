import "dart:io";
import "dart:ui";

import "package:camera/camera.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:yivi_core/yivi_core.dart";

class GoogleMLKitMrzProcessor implements MrzProcessor {
  final _textRecognizer = TextRecognizer();
  @override
  Future<MRZResult?> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  }) async {
    final image = _inputImageFromCameraImage(
      image: inputImage,
      imageRotation: imageRotation,
    );
    final recognizedText = await _textRecognizer.processImage(image!);
    String fullText = recognizedText.text;
    // Terminate as quickly as possible.
    if (fullText.isEmpty) {
      return null;
    }
    String trimmedText = fullText.replaceAll(" ", "");
    List allText = trimmedText.split("\n");

    List<String> ableToScanText = [];
    for (var e in allText) {
      final l = _testTextLine(e);
      if (l.isNotEmpty) {
        ableToScanText.add(l);
      }
    }
    List<String>? result = _getFinalListToParse([...ableToScanText]);
    if (result == null) {
      return null;
    }
    try {
      return MRZParser.parse(result);
    } catch (e) {
      return null;
    }
  }

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

  List<String>? _getFinalListToParse(List<String> ableToScanTextList) {
    if (ableToScanTextList.length < 2) {
      // minimum length of any MRZ format is 2 lines
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
    ]; // you can add more doc types like A,C,I are also supported
    String fChar = firstLineChars[0];
    if (supportedDocTypes.contains(fChar)) {
      return [...ableToScanTextList];
    }
    return null;
  }

  String _testTextLine(String text) {
    String res = text.replaceAll(" ", "");
    List<String> list = res.split("");

    // to check if the text belongs to any MRZ format or not
    if (list.length != 44 && list.length != 30 && list.length != 36) {
      return "";
    }

    for (int i = 0; i < list.length; i++) {
      if (RegExp(r"^[A-Za-z0-9_.]+$").hasMatch(list[i])) {
        list[i] = list[i].toUpperCase();
        // to ensure that every letter is uppercase
      }
      if (double.tryParse(list[i]) == null &&
          !(RegExp(r"^[A-Za-z0-9_.]+$").hasMatch(list[i]))) {
        list[i] = "<";
        // sometimes < sign not recognized well
      }
    }
    String result = list.join("");
    return result;
  }
}
