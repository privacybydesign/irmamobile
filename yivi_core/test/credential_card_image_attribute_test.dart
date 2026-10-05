import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

// Regression tests for an issuer (the Ver.iD vergoedingenpas demo) that fills
// an empty photo attribute with a single space. Decoding that as base64 threw
// during build, which release builds render as a grey error box.

// A valid 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(home: Scaffold(body: child)),
);

schemaless.Attribute _photo(String base64Image) => schemaless.Attribute(
  claimPath: ["photo"],
  displayName: "Pasfoto",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.base64Image,
    base64Image: base64Image,
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
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList([_photo(value)])),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
    });
  }

  testWidgets("renders nothing for valid base64 that is not an image", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        YiviCredentialCardAttributeList([
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
    await tester.pumpWidget(
      _wrap(YiviCredentialCardAttributeList([_photo(_png)])),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });
}
