import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";

class Base64Image extends StatefulWidget {
  final String base64;

  Base64Image({Key? key, required this.base64})
    : super(key: key ?? ValueKey(base64));

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  late Uint8List _bytes;
  late MemoryImage _provider;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  // With the default ValueKey(base64) this State is never reused across a
  // different base64, but a caller may pass a custom Key and later change
  // base64. Recompute so the decoded bytes/provider don't go stale.
  @override
  void didUpdateWidget(covariant Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.base64 != oldWidget.base64) {
      _decode();
    }
  }

  void _decode() {
    _bytes = base64Decode(widget.base64);
    _provider = MemoryImage(_bytes);
  }

  @override
  Widget build(BuildContext context) => Image(image: _provider);
}
