import "dart:convert";
import "dart:typed_data";

import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

/// The bytes of [base64], decoded once and then shared.
///
/// Image caches key on the bytes object ([MemoryImage] and the SVG loaders
/// compare it by identity), so decoding the same logo again for every new
/// widget misses the cache and the picture is blank for a few frames. A card
/// that is rebuilt elsewhere, such as the Hero flying to the card detail,
/// would flicker.
Uint8List decodeBase64Cached(String base64) {
  final cached = _decoded.remove(base64);
  final bytes = cached ?? base64Decode(base64);
  // Most recently used last; drop the oldest beyond the limit.
  _decoded[base64] = bytes;
  if (_decoded.length > _decodedLimit) _decoded.remove(_decoded.keys.first);
  return bytes;
}

// More than the types in the Add data list (about 200), so scrolling it does
// not decode its logos again.
const _decodedLimit = 512;
final _decoded = <String, Uint8List>{};

class Base64Image extends StatefulWidget {
  final String base64;
  final String? mimeType;

  /// The size it is shown at, when known (a logo in an avatar): a bitmap is
  /// then decoded at that size on this screen, not at its own size, which
  /// for a logo is often many times larger.
  final double? size;

  Base64Image({Key? key, required this.base64, this.mimeType, this.size})
    : super(key: key ?? ValueKey(base64));

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  late final Uint8List _bytes = decodeBase64Cached(widget.base64);
  late final bool _isSvg = _detectSvg();
  late final MemoryImage? _memory = _isSvg ? null : MemoryImage(_bytes);

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
  Widget build(BuildContext context) {
    if (_isSvg) return SvgPicture.memory(_bytes);
    final size = widget.size;
    final ImageProvider image = size == null
        ? _memory!
        : ResizeImage(
            _memory!,
            width: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
            // Never upscaled: a small logo keeps its own size.
            allowUpscaling: false,
          );
    return Image(image: image, gaplessPlayback: true);
  }
}
