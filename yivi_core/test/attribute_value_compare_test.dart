import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

// Booleans and integers keep their data outside `string`, so comparing only
// strings made every pair of them match: a differing value was drawn green.

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(home: Scaffold(body: child)),
);

AttributeValue _bool(bool v) => AttributeValue(type: .boolean, boolValue: v);

AttributeValue _int(int v) => AttributeValue(type: .integer, intValue: v);

Attribute _age(int v) =>
    Attribute(claimPath: ["age"], displayName: "Age", value: _int(v));

void main() {
  group("attributeValuesEqual", () {
    test("compares booleans and integers by their value", () {
      expect(attributeValuesEqual(_bool(true), _bool(true)), isTrue);
      expect(attributeValuesEqual(_bool(true), _bool(false)), isFalse);
      expect(attributeValuesEqual(_int(3), _int(3)), isTrue);
      expect(attributeValuesEqual(_int(3), _int(4)), isFalse);
    });

    test("compares strings", () {
      final a = AttributeValue(type: .string, string: "x");
      final b = AttributeValue(type: .string, string: "y");
      expect(attributeValuesEqual(a, a), isTrue);
      expect(attributeValuesEqual(a, b), isFalse);
    });

    test("a missing value only equals another missing value", () {
      expect(attributeValuesEqual(_int(3), null), isFalse);
      expect(attributeValuesEqual(null, null), isTrue);
    });
  });

  group("attribute list", () {
    Future<Color?> valueColor(
      WidgetTester tester,
      List<Attribute> compareTo,
    ) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList([_age(3)], compareTo: compareTo)),
      );
      return tester.widget<Text>(find.text("3")).style?.color;
    }

    testWidgets("draws a differing integer as a mismatch", (tester) async {
      final color = await valueColor(tester, [_age(4)]);
      final theme = IrmaTheme.of(tester.element(find.text("3")));
      expect(color, theme.error);
    });

    testWidgets("draws an equal integer as a match", (tester) async {
      final color = await valueColor(tester, [_age(3)]);
      final palette = YiviPalette.of(tester.element(find.text("3")));
      expect(color, palette.successText);
    });
  });
}
