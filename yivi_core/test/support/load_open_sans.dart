import "dart:io";

import "package:flutter/services.dart";

const _weights = ["Regular", "SemiBold", "Bold"];

/// Loads the Open Sans of the app, so text is as wide as on a device.
///
/// Without it tests draw every glyph one em wide, which overflows layouts
/// that fit at a large text size on a device. The font stays loaded for the
/// rest of the test file.
Future<void> loadOpenSans() async {
  final loader = FontLoader("Open Sans");
  for (final weight in _weights) {
    final bytes = File(
      "fonts/open-sans/OpenSans-$weight.ttf",
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
