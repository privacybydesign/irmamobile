import "dart:convert";

import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/widgets/credential_card/card_attribute_list.dart";

import "support/pump_translated.dart";
import "support/test_app.dart";

// Regression tests for an issuer (the Ver.iD vergoedingenpas demo) that fills
// an empty photo attribute with a single space. Decoding that as base64 threw
// during build, which release builds render as a grey error box.

// A valid 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";

Widget _wrap(Widget child) => testApp(Scaffold(body: child));

Attribute _photo(String base64Image, {String? mimeType}) => Attribute(
  claimPath: ["photo"],
  displayName: "Pasfoto",
  value: AttributeValue(
    type: AttributeType.base64Image,
    base64Image: base64Image,
    mimeType: mimeType,
  ),
);

void main() {
  for (final (name, value) in [
    ("a single space", " "),
    ("an empty string", ""),
    ("invalid base64", "not base64!"),
  ]) {
    testWidgets("renders nothing for an image attribute holding $name", (
      tester,
    ) async {
      await pumpTranslated(tester, _wrap(CardAttributeList([_photo(value)])));

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
    });
  }

  testWidgets("renders nothing for valid base64 that is not an image", (
    tester,
  ) async {
    await pumpTranslated(
      tester,
      _wrap(
        CardAttributeList([
          _photo(base64Encode(utf8.encode("definitely not a PNG"))),
        ]),
      ),
    );
    // Let the image codec fail so the errorBuilder runs.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets("still renders a valid image", (tester) async {
    await pumpTranslated(tester, _wrap(CardAttributeList([_photo(_png)])));

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets("renders an SVG image when irmago says it is one", (
    tester,
  ) async {
    const svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="red"/></svg>';
    await pumpTranslated(
      tester,
      _wrap(
        CardAttributeList([
          _photo(base64Encode(utf8.encode(svg)), mimeType: "image/svg+xml"),
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets("renders a bitmap with its MIME type as a bitmap", (
    tester,
  ) async {
    await pumpTranslated(
      tester,
      _wrap(CardAttributeList([_photo(_png, mimeType: "image/png")])),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  test("reads the MIME type irmago sends", () {
    final value = AttributeValue.fromJson({
      "type": "base64_image",
      "base64_image": _png,
      "mime_type": "image/png",
    });
    expect(value.mimeType, "image/png");
    expect(
      AttributeValue.fromJson({
        "type": "base64_image",
        "base64_image": _png,
      }).mimeType,
      isNull,
    );
  });
}
