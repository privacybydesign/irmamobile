import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class Base64Image extends StatefulWidget {
  final String base64;
  final String? mimeType;

  Base64Image({Key? key, required this.base64, this.mimeType})
    : super(key: key ?? ValueKey(base64));

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  late final Uint8List _bytes = base64Decode(widget.base64);
  late final bool _isSvg = _detectSvg();
  late final MemoryImage? _provider = _isSvg ? null : MemoryImage(_bytes);

  bool _detectSvg() {
    final mimeType = widget.mimeType;
    if (mimeType != null) {
      // Strip parameters like "; charset=utf-8" from the Content-Type.
      return mimeType.split(";").first.trim() == "image/svg+xml";
    }
    // Logos cached before the MIME type was recorded come through without
    // one; every bitmap format starts with binary magic bytes, so data
    // starting with "<" (allowing a BOM/whitespace) can only be SVG/XML.
    return _looksLikeSvg(_bytes);
  }

  static bool _looksLikeSvg(Uint8List bytes) {
    var start = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      start = 3;
    }
    for (var i = start; i < bytes.length; i++) {
      final byte = bytes[i];
      if (byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D) {
        continue;
      }
      return byte == 0x3C; // "<"
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      _isSvg ? SvgPicture.memory(_bytes) : Image(image: _provider!);
}
