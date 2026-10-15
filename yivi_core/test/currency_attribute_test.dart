import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

// Attributes with the "currency:<code>" display hint arrive as a string value
// plus that hint. The app may run against an irmago that doesn't send display
// hints, and a scheme may use codes or amounts this app can't format; in all
// those cases the raw string must still be shown.

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(home: Scaffold(body: child)),
);

schemaless.Attribute _amount(String value, {String? hint}) =>
    schemaless.Attribute(
      claimPath: ["balance"],
      displayName: "Saldo",
      value: schemaless.AttributeValue(
        type: schemaless.AttributeType.string,
        string: value,
        displayHint: hint,
      ),
    );

void main() {
  group("formatCurrencyAmount", () {
    test("formats an amount for the locale", () {
      // intl separates the symbol with a non-breaking space in Dutch.
      expect(formatCurrencyAmount("12.50", "EUR", "nl"), "€\u00A012,50");
      expect(formatCurrencyAmount("12.50", "USD", "en"), r"$12.50");
      expect(formatCurrencyAmount("-3", "EUR", "en"), "-€3.00");
    });

    test("returns null for values it can't format", () {
      expect(formatCurrencyAmount("€ 12,50", "EUR", "nl"), isNull);
      expect(formatCurrencyAmount("1e3", "EUR", "nl"), isNull);
      expect(formatCurrencyAmount("NaN", "EUR", "nl"), isNull);
      expect(formatCurrencyAmount("12.50", "eur", "nl"), isNull);
      expect(formatCurrencyAmount("12.50", "", "nl"), isNull);
    });
  });

  group("AttributeValue JSON", () {
    test("reads the display hint", () {
      final v = schemaless.AttributeValue.fromJson({
        "type": "string",
        "string": "12.50",
        "display_hint": "currency:EUR",
      });
      expect(v.displayHint, "currency:EUR");
      expect(v.string, "12.50");
    });

    test("an irmago without display hints leaves it null", () {
      final v = schemaless.AttributeValue.fromJson({
        "type": "string",
        "string": "12.50",
      });
      expect(v.displayHint, isNull);
    });
  });

  group("attribute list", () {
    testWidgets("shows an amount with a currency hint as currency", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _amount("12.50", hint: "currency:EUR"),
          ]),
        ),
      );
      expect(find.text("€12.50"), findsOneWidget);
    });

    testWidgets("shows the raw string without a currency hint", (tester) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList([_amount("12.50")])),
      );
      expect(find.text("12.50"), findsOneWidget);
    });

    testWidgets("shows the raw string for other display hints", (tester) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([_amount("12.50", hint: "unit:kg")]),
        ),
      );
      expect(find.text("12.50"), findsOneWidget);
    });

    testWidgets("shows the raw string when the amount can't be formatted", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _amount("€ 12,50", hint: "currency:EUR"),
          ]),
        ),
      );
      expect(find.text("€ 12,50"), findsOneWidget);
    });
  });
}
