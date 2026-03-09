import "dart:io";
import "dart:typed_data";
import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:yivi_core/yivi_core.dart";

class TesseractOcrProcessor implements OcrProcessor {
  static const _channel = MethodChannel("foundation.privacybydesign.irmamobile/tesseract");

  @override
  Future<List<String>?> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  }) async {
    if (!Platform.isAndroid) return null;

    try {
      final plane = inputImage.planes[0];
      
      // We gebruiken strakkere, handmatige waarden voor het document-kader (ROI).
      // Dit voorkomt dat we de gedeelde yivi_core code hoeven aan te passen.
      // Deze waarden komen overeen met het witte vakje op het scherm.
      final String? rawText = await _channel.invokeMethod("processImage", {
        "bytes": plane.bytes,
        "width": inputImage.width,
        "height": inputImage.height,
        "stride": plane.bytesPerRow,
        "rotation": imageRotation,
        "lang": "ocrb",
        "roiLeft": 0.10,   // 10% marge links
        "roiTop": 0.35,    // 35% marge boven
        "roiWidth": 0.80,  // 80% breedte
        "roiHeight": 0.30, // 30% hoogte (de MRZ strip)
      });

      if (rawText == null || rawText.trim().isEmpty) return null;

      debugPrint("Tesseract RAW: ${rawText.replaceAll("\n", " | ")}");

      final lines = rawText.split(RegExp(r"[\r\n]+"))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => MRZHelper.normalizeLine(s))
          .where((s) => s.isNotEmpty)
          .toList();

      final finalLines = MRZHelper.getFinalListToParse(lines);
      if (finalLines != null) {
        debugPrint("MRZ SUCCESS!");
        return finalLines;
      }

      return null;
    } catch (e) {
      debugPrint("Error in TesseractOcrProcessor: $e");
      return null;
    }
  }

  Uint8List? _getNv21Bytes(CameraImage img) {
    if (img.planes.length == 1) return img.planes[0].bytes;
    if (img.planes.length == 3) {
      final int width = img.width;
      final int height = img.height;
      final int ySize = width * height;
      final Uint8List nv21 = Uint8List(ySize + width * height ~/ 2);
      nv21.setRange(0, ySize, img.planes[0].bytes);
      final u = img.planes[1];
      final v = img.planes[2];
      int uvIndex = ySize;
      for (int row = 0; row < height ~/ 2; row++) {
        final int uRowStart = row * u.bytesPerRow;
        final int vRowStart = row * v.bytesPerRow;
        for (int col = 0; col < width ~/ 2; col++) {
          nv21[uvIndex++] = v.bytes[vRowStart + col * (v.bytesPerPixel ?? 1)];
          nv21[uvIndex++] = u.bytes[uRowStart + col * (u.bytesPerPixel ?? 1)];
        }
      }
      return nv21;
    }
    return null;
  }
}

class MRZHelper {
  static const _allowedLineLen = <int>{30, 36, 44};

  static String normalizeLine(String text) {
    final s = text.toUpperCase().replaceAll(RegExp(r"\s+"), "");
    final buf = StringBuffer();
    final mrzChars = RegExp(r"[A-Z0-9<]");
    for (final code in s.codeUnits) {
      final ch = String.fromCharCode(code);
      buf.write(mrzChars.hasMatch(ch) ? ch : "<");
    }
    final out = buf.toString();
    return _allowedLineLen.contains(out.length) ? out : "";
  }

  static List<String>? getFinalListToParse(List<String> lines) {
    if (lines.isEmpty) return null;
    final first = lines.first;
    if (first.length >= 2) {
      final pfx = first.substring(0, 2);
      if (["D1", "D2", "DL"].contains(pfx)) return [...lines];
    }
    if (lines.length < 2) return null;
    final len = lines.first.length;
    if (!lines.every((e) => e.length == len)) return null;
    if (["P", "V", "I"].contains(lines.first[0])) return [...lines];
    return null;
  }
}
