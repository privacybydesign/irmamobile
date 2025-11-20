import "package:camera/camera.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:mrz_parser/mrz_parser.dart";

abstract class MrzProcessor {
  Future<MRZResult?> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  });
}

final mrzProcessorProvider = Provider<MrzProcessor?>((ref) => null);
