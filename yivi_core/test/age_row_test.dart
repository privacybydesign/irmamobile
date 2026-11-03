import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/age/age_row_renderer.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

schemaless.Attribute _str(String id, String value) => schemaless.Attribute(
  claimPath: [id],
  displayName: id == "over18"
      ? "Over 18"
      : id == "over75"
      ? "Over 75"
      : id,
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: value,
  ),
);

schemaless.Attribute _bool(String id, bool value) => schemaless.Attribute(
  claimPath: [id],
  displayName: id == "over18" ? "Over 18" : id,
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.boolean,
    boolValue: value,
  ),
);

// Any credential type: the age row is not tied to one.
const _anyCredential = "irma-demo.example.person";

Future<void> _pump(
  WidgetTester tester,
  List<schemaless.Attribute> attrs, {
  List<schemaless.Attribute>? compareTo,
}) async {
  await tester.pumpWidget(
    _wrap(
      YiviCredentialCardAttributeList(
        attrs,
        compareTo: compareTo,
        credentialId: _anyCredential,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("the highest age that is true and the lowest that is false", (
    tester,
  ) async {
    await _pump(tester, [
      _str("over12", "yes"),
      _str("over16", "yes"),
      _str("over18", "yes"),
      _str("over21", "yes"),
      _str("over65", "no"),
      _str("over75", "no"),
    ]);
    expect(find.text("Age"), findsOneWidget);
    expect(find.text("Older than 21, not older than 65"), findsOneWidget);
    expect(find.text("Over 18"), findsNothing);
    expect(find.text("Show all ages"), findsOneWidget);
    expect(
      tester.widget<Text>(find.text("Show all ages")).style?.fontWeight,
      FontWeight.w400,
      reason: "the toggle is not bold",
    );
  });

  testWidgets("only true ages give the highest, only false the lowest", (
    tester,
  ) async {
    await _pump(tester, [_str("over12", "yes"), _str("over18", "yes")]);
    expect(find.text("Older than 18"), findsOneWidget);

    await _pump(tester, [_str("over18", "no"), _str("over21", "no")]);
    expect(find.text("Not older than 18"), findsOneWidget);
  });

  testWidgets("boolean values count the same as yes and no", (tester) async {
    await _pump(tester, [_bool("over18", true), _bool("over21", false)]);
    expect(find.text("Older than 18, not older than 21"), findsOneWidget);
  });

  testWidgets("Show all ages expands into one chip per age, in order", (
    tester,
  ) async {
    await _pump(tester, [
      _str("over65", "no"),
      _str("over21", "yes"),
      _str("over18", "yes"),
    ]);
    await tester.tap(find.text("Show all ages"));
    await tester.pumpAndSettle();

    final labels = ["Older than 18", "Older than 21", "Not older than 65"];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text("Older than 21, not older than 65"), findsNothing);
    expect(
      [for (final l in labels) tester.getTopLeft(find.text(l)).dx],
      orderedEquals(
        [for (final l in labels) tester.getTopLeft(find.text(l)).dx]..sort(),
      ),
    );

    await tester.tap(find.text("Hide ages"));
    await tester.pumpAndSettle();
    expect(find.text("Older than 21, not older than 65"), findsOneWidget);
  });

  testWidgets("a single age has nothing to expand into", (tester) async {
    await _pump(tester, [_str("over18", "yes")]);
    expect(find.text("Older than 18"), findsOneWidget);
    expect(find.text("Show all ages"), findsNothing);
  });

  testWidgets("the row sits where the first age was, among other attributes", (
    tester,
  ) async {
    await _pump(tester, [
      _str("name", "Anna"),
      _str("over18", "yes"),
      _str("over21", "no"),
      _str("city", "Meppel"),
    ]);
    final name = tester.getTopLeft(find.text("name")).dy;
    final age = tester.getTopLeft(find.text("Age")).dy;
    final city = tester.getTopLeft(find.text("city")).dy;
    expect(name, lessThan(age));
    expect(age, lessThan(city));
    expect(find.text("Older than 18, not older than 21"), findsOneWidget);
  });

  testWidgets("a comparison against another credential keeps every row", (
    tester,
  ) async {
    final attrs = [_str("over18", "yes"), _str("over75", "no")];
    await _pump(tester, attrs, compareTo: attrs);
    expect(find.text("Over 18"), findsOneWidget);
    expect(find.text("Over 75"), findsOneWidget);
    expect(find.text("Age"), findsNothing);
  });

  group("ageEntry", () {
    test("top-level overNN with a yes/no value", () {
      final e = AgeRowRenderer.ageEntry(_str("over18", "Yes"))!;
      expect((e.age, e.over), (18, true));
      expect(AgeRowRenderer.ageEntry(_str("over18", "false"))!.over, isFalse);
    });

    test("anything else is not an age", () {
      expect(AgeRowRenderer.ageEntry(_str("over18", "maybe")), isNull);
      expect(AgeRowRenderer.ageEntry(_str("overall", "yes")), isNull);
      expect(AgeRowRenderer.ageEntry(_str("age_over_18", "yes")), isNull);
      expect(
        AgeRowRenderer.ageEntry(
          schemaless.Attribute(
            claimPath: ["details", "over18"],
            displayName: "over18",
            value: schemaless.AttributeValue(
              type: schemaless.AttributeType.boolean,
              boolValue: true,
            ),
          ),
        ),
        isNull,
        reason: "nested claims are not folded",
      );
    });
  });
}
