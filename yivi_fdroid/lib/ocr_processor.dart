import "dart:io";
import "package:camera/camera.dart";
import "package:flutter/services.dart";
import "package:yivi_core/yivi_core.dart";

class TesseractOcrProcessor implements OcrProcessor {
  static const _channel = MethodChannel(
    "foundation.privacybydesign.irmamobile/tesseract",
  );

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
        "roiTop": 0.25,
        "roiWidth": 0.90,
        "roiHeight": 0.50,
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
        final td1 = lines.sublist(0, 3);
        return _fixTd1(td1) ?? td1;

      case 36:
      // TD2 or MRVB: 2 lines, type I/A/C/V
        if (!["I", "A", "C", "V"].contains(typeChar)) return null;
        return lines.sublist(0, 2);

      case 44:
      // TD3 of MRVA: 2 lines, type P/V
        if (!["P", "V"].contains(typeChar)) return null;
        final td3 = lines.sublist(0, 2);
        return _fixTd3(td3) ?? td3;

      default:
        return null;
    }
  }

  // ICAO fixer
  static const Map<String, String> _toDigit = {
    "O": "0",
    "Q": "0",
    "D": "0",
    "U": "0",
    "I": "1",
    "L": "1",
    "Z": "2",
    "S": "5",
    "G": "6",
    "B": "8",
    "T": "7",
  };

  static const Map<String, String> _toAlpha = {
    "0": "O",
    "1": "I",
    "2": "Z",
    "5": "S",
    "6": "G",
    "8": "B",
  };

  static String _lettersToDigits(String s) {
    var out = s;
    _toDigit.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  static String _digitsToLetters(String s) {
    var out = s;
    _toAlpha.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  static bool _isDigits(String s) => RegExp(r"^\d+$").hasMatch(s);
  static bool _isLetters(String s) => RegExp(r"^[A-Z]+$").hasMatch(s);
  static bool _isLettersOrFiller(String s) => RegExp(r"^[A-Z<]+$").hasMatch(s);

  static String _fixSexChar(String c) {
    if (c == "M" || c == "F" || c == "X" || c == "<") return c;
    if (c == "P") return "F";
    return c;
  }

  /// Attempt to fix OCR errors in MRZ lines based on known field types.
  /// Returns fixed lines, or null if unfixable.
  static List<String>? fixLines(List<String> lines) {
    if (lines.length == 3 && lines.every((s) => s.length == 30)) {
      return _fixTd1(lines);
    }
    if (lines.length == 2 && lines[0].length == 44) {
      return _fixTd3(lines);
    }
    return null;
  }

  static List<String>? _fixTd3(List<String> lines) {
    if (lines.length != 2 || lines[0].length != 44 || lines[1].length != 44) {
      return null;
    }

    final l1 = lines[0];
    final l2 = lines[1];

    final docType = _digitsToLetters(l1.substring(0, 2));
    final issuer = _digitsToLetters(l1.substring(2, 5));
    final names = _digitsToLetters(l1.substring(5, 44));
    final nat = _digitsToLetters(l2.substring(10, 13));

    final docCd = _lettersToDigits(l2.substring(9, 10));
    final birth = _lettersToDigits(l2.substring(13, 19));
    final birthCd = _lettersToDigits(l2.substring(19, 20));
    final exp = _lettersToDigits(l2.substring(21, 27));
    final expCd = _lettersToDigits(l2.substring(27, 28));
    final sex = _fixSexChar(l2.substring(20, 21));

    if (!_isLettersOrFiller(docType)) return null;
    if (!_isLetters(issuer)) return null;
    if (!_isLettersOrFiller(names)) return null;
    if (!_isLetters(nat)) return null;
    if (!_isDigits(docCd)) return null;
    if (!_isDigits(birth) || birth.length != 6) return null;
    if (!_isDigits(birthCd)) return null;
    if (!_isDigits(exp) || exp.length != 6) return null;
    if (!_isDigits(expCd)) return null;

    final fixedL1 = docType + issuer + names;
    final fixedL2 =
        l2.substring(0, 9) +
            docCd +
            nat +
            birth +
            birthCd +
            sex +
            exp +
            expCd +
            l2.substring(28);

    return [fixedL1, fixedL2];
  }

  static List<String>? _fixTd1(List<String> lines) {
    if (lines.length != 3 || !lines.every((s) => s.length == 30)) return null;

    final l1 = lines[0];
    final l2 = lines[1];
    final l3 = lines[2];

    final docType = _digitsToLetters(l1.substring(0, 2));
    final issuer = _digitsToLetters(l1.substring(2, 5));

    final birth = _lettersToDigits(l2.substring(0, 6));
    final birthCd = _lettersToDigits(l2.substring(6, 7));
    final exp = _lettersToDigits(l2.substring(8, 14));
    final expCd = _lettersToDigits(l2.substring(14, 15));
    final nat = _digitsToLetters(l2.substring(15, 18));
    final finalCd = _lettersToDigits(l2.substring(29, 30));
    final sex = _fixSexChar(l2.substring(7, 8));
    final names = _digitsToLetters(l3);

    if (!_isLettersOrFiller(docType)) return null;
    if (!_isLetters(issuer)) return null;
    if (!_isDigits(birth) || birth.length != 6) return null;
    if (!_isDigits(birthCd)) return null;
    if (!_isDigits(exp) || exp.length != 6) return null;
    if (!_isDigits(expCd)) return null;
    if (!_isLetters(nat)) return null;
    if (!_isDigits(finalCd)) return null;
    if (!_isLettersOrFiller(names)) return null;

    final fixedL1 = docType + issuer + l1.substring(5);
    final fixedL2 =
        birth +
            birthCd +
            sex +
            exp +
            expCd +
            nat +
            l2.substring(18, 29) +
            finalCd;

    return [fixedL1, fixedL2, names];
  }
}