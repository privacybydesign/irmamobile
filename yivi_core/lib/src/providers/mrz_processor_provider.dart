import "package:camera/camera.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

abstract class OcrProcessor {
  /// Processes the images and returns the lines of text it finds
  Future<List<String>?> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  });
}

final ocrProcessorProvider = Provider<OcrProcessor?>((ref) => null);
