import "dart:io";
import "dart:typed_data";
import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:yivi_core/yivi_core.dart";

class TesseractOcrProcessor implements OcrProcessor {
  static const _channel =
  MethodChannel("foundation.privacybydesign.irmamobile/tesseract");

  bool _isProcessing = false;

  @override
  Future<List<String>?> processImage({
    required CameraImage inputImage,
    required int imageRotation,
  }) async {
    if (!Platform.isAndroid) return null;
    if (_isProcessing) return null;

    _isProcessing = true;
    try {
      final plane = inputImage.planes[0];

      final String? rawText = await _channel.invokeMethod("processImage", {
        "bytes": plane.bytes,
        "width": inputImage.width,
        "height": inputImage.height,
        "stride": plane.bytesPerRow,
        "rotation": imageRotation,
        "lang": "ocrb",
        "roiLeft": 0.05,
        "roiTop": 0.30,
        "roiWidth": 0.90,
        "roiHeight": 0.40,
      });

      if (rawText == null || rawText.trim().isEmpty) return null;

      final lines = rawText
          .split(RegExp(r"[\r\n]+"))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => MRZHelper.normalizeLine(s))
          .where((s) => s.isNotEmpty)
          .toList();

      return MRZHelper.getFinalListToParse(lines);
    } catch (e) {
      debugPrint("Error in TesseractOcrProcessor: $e"); // Remove
      return null;
    } finally {
      _isProcessing = false;
    }
  }
}

class MRZHelper {
  static const _allowedLineLen = <int>{30, 36, 44};

  // normalize OCR line to valid MRZ chars. Empty if len wrong
  // could improve to try to find mrz if len wrong <- only if len longer
  // shorter only if its missing '<' or un needed mrz chars
  static String normalizeLine(String text) {
    final s = text.toUpperCase().replaceAll(RegExp(r"\s+"), "");
    if (!_allowedLineLen.contains(s.length)) return "";

    final buf = StringBuffer();
    final mrzChars = RegExp(r"[A-Z0-9<]");

    for (final code in s.codeUnits) {
      final ch = String.fromCharCode(code);
      buf.write(mrzChars.hasMatch(ch) ? ch : "<");
    }
    return buf.toString();
  }

  /// Validates and returns the MRZ lines following ICAO 9303 structure.
  ///
  /// Supported formats:
  /// - TD1 (ID-kaart):     3 lines × 30 chars, type I/A/C
  /// - TD2 (reisdocument): 2 lines × 36 chars, type I/A/C/V
  /// - TD3 (paspoort):     2 lines × 44 chars, type P/V
  /// - MRVA (visum A):     2 lines × 44 chars, type V
  /// - MRVB (visum B):     2 lines × 36 chars, type V
  /// - Rijbewijs:          not ICAO, still has MRZ
  static List<String>? getFinalListToParse(List<String> lines) {
    if (lines.isEmpty) return null;

    final first = lines.first;
    final len = first.length;

    // Rijbewijs: not ICAO, own format
    if (len >= 2) {
      final pfx = first.substring(0, 2);
      if (["D1", "D2", "DL"].contains(pfx)) {
        debugPrint("Rijbewijs detected"); // Remove
        return [...lines];
      }
    }

    // ICAO documents: all lines must have same length
    if (lines.length < 2) return null;
    if (!lines.every((e) => e.length == len)) return null;

    final typeChar = first[0];

    switch (len) {
      case 30:
      // TD1: 3 lines, type I/A/C
        if (lines.length < 3) return null;
        if (!["I", "A", "C"].contains(typeChar)) return null;
        debugPrint("TD1 document detected (3×30)"); // Remove
        return lines.sublist(0, 3);

      case 36:
      // TD2 or MRVB: 2 lines, type I/A/C/V
        if (!["I", "A", "C", "V"].contains(typeChar)) return null;
        debugPrint("${typeChar == "V" ? "MRVB" : "TD2"} document detected (2×36)"); // Remove
        return lines.sublist(0, 2);

      case 44:
      // TD3 of MRVA: 2 lines, type P/V
        if (!["P", "V"].contains(typeChar)) return null;
        debugPrint("${typeChar == "V" ? "MRVA" : "TD3"} document detected (2×44)"); // Remove
        return lines.sublist(0, 2);

      default:
        return null;
    }
  }
}