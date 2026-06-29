import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/widgets/base64_image.dart";

// Two distinct valid 1x1 PNGs (red / blue) so the decoded bytes differ.
const _redPng =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";
const _bluePng =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYPgPAAEDAQAIicLsAAAAAElFTkSuQmCC";

MemoryImage _shownProvider(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image));
  return image.image as MemoryImage;
}

void main() {
  testWidgets("renders the decoded base64 bytes", (tester) async {
    await tester.pumpWidget(MaterialApp(home: Base64Image(base64: _redPng)));

    expect(_shownProvider(tester).bytes, base64Decode(_redPng));
  });

  testWidgets("default ValueKey(base64) swaps the State when base64 changes", (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: Base64Image(base64: _redPng)));
    expect(_shownProvider(tester).bytes, base64Decode(_redPng));

    await tester.pumpWidget(MaterialApp(home: Base64Image(base64: _bluePng)));
    expect(_shownProvider(tester).bytes, base64Decode(_bluePng));
  });

  testWidgets(
    "recomputes the image when base64 changes under a stable custom Key",
    (tester) async {
      const key = ValueKey("stable");

      await tester.pumpWidget(
        MaterialApp(
          home: Base64Image(key: key, base64: _redPng),
        ),
      );
      expect(_shownProvider(tester).bytes, base64Decode(_redPng));

      // Same Key forces Flutter to reuse the existing State via
      // didUpdateWidget; without the recompute the red bytes would persist.
      await tester.pumpWidget(
        MaterialApp(
          home: Base64Image(key: key, base64: _bluePng),
        ),
      );
      expect(_shownProvider(tester).bytes, base64Decode(_bluePng));
    },
  );
}
