import "dart:convert";
import "dart:typed_data";

import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

/// Draws a base64-encoded image: an SVG with flutter_svg, anything else as a
/// bitmap. Renders nothing for text that is not base64 or not an image, so a
/// bad value from an issuer never shows as an error box.
class Base64Image extends StatefulWidget {
  final String base64;
  final String? mimeType;
  final BoxFit? fit;

  Base64Image({Key? key, required this.base64, this.mimeType, this.fit})
    : super(key: key ?? ValueKey(base64));

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  late final Uint8List? _bytes = _decode(widget.base64);
  late final bool _isSvg = _bytes != null && _detectSvg(_bytes);
  late final MemoryImage? _provider = _bytes == null || _isSvg
      ? null
      : MemoryImage(_bytes);

  static Uint8List? _decode(String base64) {
    try {
      final bytes = base64Decode(base64.trim());
      return bytes.isEmpty ? null : bytes;
    } on FormatException {
      return null;
    }
  }

  bool _detectSvg(Uint8List bytes) {
    final mimeType = widget.mimeType;
    if (mimeType != null) {
      // Strip parameters like "; charset=utf-8" from the Content-Type.
      return mimeType.split(";").first.trim() == "image/svg+xml";
    }
    // Logos cached before the MIME type was recorded, and attribute images
    // from an irmago that does not send one, come through without it; every
    // bitmap format starts with binary magic bytes, so data starting with
    // "<" (allowing a BOM/whitespace) can only be SVG/XML.
    return _looksLikeSvg(bytes);
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
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return const SizedBox.shrink();
    if (_isSvg) {
      return SvgPicture.memory(
        bytes,
        fit: widget.fit ?? BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    return Image(
      image: _provider!,
      fit: widget.fit,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
