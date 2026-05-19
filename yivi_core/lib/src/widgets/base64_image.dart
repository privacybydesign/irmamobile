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
  late final Uint8List _bytes = base64Decode(widget.base64);
  late final MemoryImage _provider = MemoryImage(_bytes);

  @override
  Widget build(BuildContext context) => Image(image: _provider);
}
