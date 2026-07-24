import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/widgets/base64_image.dart";

// Regression tests for privacybydesign/irmamobile#674: SD-JWT VC credential
// logos in SVG format were forced through MemoryImage and rendered blank.

const _svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="red"/></svg>';

// A valid 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";

String _svgBase64([String prefix = ""]) =>
    base64Encode(utf8.encode(prefix + _svg));

void main() {
  Future<void> pump(WidgetTester tester, Base64Image widget) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: widget)),
        ),
      );

  testWidgets("renders SVG via flutter_svg when the MIME type says so", (
    tester,
  ) async {
    await pump(
      tester,
      Base64Image(base64: _svgBase64(), mimeType: "image/svg+xml"),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets("ignores MIME type parameters like charset", (tester) async {
    await pump(
      tester,
      Base64Image(
        base64: _svgBase64(),
        mimeType: "image/svg+xml; charset=utf-8",
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets("detects SVG from the bytes when no MIME type is available", (
    tester,
  ) async {
    // Logos cached before the MIME type was recorded, including ones with
    // an XML declaration and leading whitespace.
    await pump(
      tester,
      Base64Image(base64: _svgBase64('\n <?xml version="1.0"?>\n')),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets("still renders bitmaps through MemoryImage", (tester) async {
    await pump(tester, Base64Image(base64: _png, mimeType: "image/png"));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets("still renders bitmaps without a MIME type", (tester) async {
    await pump(tester, Base64Image(base64: _png));

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });
}
