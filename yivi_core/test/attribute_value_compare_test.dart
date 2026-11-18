import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

// Booleans and integers keep their data outside `string`, so comparing only
// strings made every pair of them match: a differing value was drawn green.

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(home: Scaffold(body: child)),
);

schemaless.AttributeValue _bool(bool v) =>
    schemaless.AttributeValue(type: .boolean, boolValue: v);

schemaless.AttributeValue _int(int v) =>
    schemaless.AttributeValue(type: .integer, intValue: v);

schemaless.Attribute _age(int v) => schemaless.Attribute(
  claimPath: ["age"],
  displayName: "Age",
  value: _int(v),
);

void main() {
  group("attributeValuesEqual", () {
    test("compares booleans and integers by their value", () {
      expect(attributeValuesEqual(_bool(true), _bool(true)), isTrue);
      expect(attributeValuesEqual(_bool(true), _bool(false)), isFalse);
      expect(attributeValuesEqual(_int(3), _int(3)), isTrue);
      expect(attributeValuesEqual(_int(3), _int(4)), isFalse);
    });

    test("compares strings", () {
      final a = schemaless.AttributeValue(type: .string, string: "x");
      final b = schemaless.AttributeValue(type: .string, string: "y");
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
      List<schemaless.Attribute> compareTo,
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
      final theme = IrmaTheme.of(tester.element(find.text("3")));
      expect(color, theme.success);
    });
  });
}
