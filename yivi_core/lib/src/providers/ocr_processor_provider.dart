import "package:camera/camera.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// What an [OcrProcessor] read in one camera frame.
class OcrResult {
  const OcrResult({this.lines, this.glare = false});

  /// The MRZ lines in the frame, or null when it had none.
  final List<String>? lines;

  /// Whether a reflection washed out part of the MRZ.
  final bool glare;
}

abstract class OcrProcessor {
  /// Processes the image and returns the MRZ lines it finds, and whether there was
  /// a reflection on them.
  Future<OcrResult> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  });
}

final ocrProcessorProvider = Provider<OcrProcessor?>((ref) => null);
