import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "support/pump_translated.dart";

// WCAG 1.4.3 AA for normal text.
const _minTextContrast = 4.5;

// Added to both luminances in the WCAG contrast ratio.
const _luminanceOffset = 0.05;

double _contrast(Color a, Color b) {
  final [lighter, darker] = [a, b].map((c) => c.computeLuminance()).toList()
    ..sort((x, y) => y.compareTo(x));
  return (lighter + _luminanceOffset) / (darker + _luminanceOffset);
}

enum _Answer { yes, no }

enum _Flag { on, off }

schemaless.Attribute _text(String claim, String name, String value) =>
    schemaless.Attribute(
      claimPath: [claim],
      displayName: name,
      value: schemaless.AttributeValue(
        type: schemaless.AttributeType.string,
        string: value,
      ),
    );

schemaless.Attribute _age(int age, _Answer answer) => schemaless.Attribute(
  claimPath: ["over$age"],
  displayName: "Over $age",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: answer.name,
  ),
);

Widget _app(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );

Future<void> _pumpList(
  WidgetTester tester,
  List<schemaless.Attribute> attributes, {
  AgeDisplay ageDisplay = AgeDisplay.collapsed,
  List<schemaless.Attribute>? compareTo,
}) async {
  await pumpTranslated(
    tester,
    _app(
      YiviCredentialCardAttributeList(
        attributes,
        ageDisplay: ageDisplay,
        compareTo: compareTo,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _mixedAges = [
  _age(12, .yes),
  _age(16, .yes),
  _age(18, .yes),
  _age(21, .yes),
  _age(65, .no),
  _age(75, .no),
];

void main() {
  testWidgets("the highest age that is true and the lowest that is false", (
    tester,
  ) async {
    await _pumpList(tester, _mixedAges);

    expect(find.text("Age"), findsOneWidget);
    expect(find.text("Older than 21, not older than 65"), findsOneWidget);
    // The 18 attribute is part of the row, not a row of its own.
    expect(find.text("Over 18"), findsNothing);
    expect(find.text("Show all ages"), findsOneWidget);
  });

  testWidgets("only true ages give the highest, only false the lowest", (
    tester,
  ) async {
    await _pumpList(tester, [_age(12, .yes), _age(18, .yes)]);
    expect(find.text("Older than 18"), findsOneWidget);

    await _pumpList(tester, [_age(18, .no), _age(21, .no)]);
    expect(find.text("Not older than 18"), findsOneWidget);
  });

  testWidgets("boolean values count the same as yes and no", (tester) async {
    schemaless.Attribute boolAge(int age, _Answer answer) =>
        schemaless.Attribute(
          claimPath: ["over$age"],
          displayName: "Over $age",
          value: schemaless.AttributeValue(
            type: schemaless.AttributeType.boolean,
            boolValue: answer == .yes,
          ),
        );

    await _pumpList(tester, [boolAge(18, .yes), boolAge(21, .no)]);

    expect(find.text("Older than 18, not older than 21"), findsOneWidget);
  });

  testWidgets("Show all ages adds one chip per age under the summary, in "
      "order", (tester) async {
    await _pumpList(tester, _mixedAges);

    await tester.tap(find.text("Show all ages"));
    await tester.pumpAndSettle();

    for (final label in ["✓ 12", "✓ 16", "✓ 18", "✓ 21", "– 65", "– 75"]) {
      expect(find.text(label), findsOneWidget);
    }
    // The summary stays, and a label says what the chips are about.
    expect(find.text("Older than 21, not older than 65"), findsOneWidget);
    expect(find.text("Older than"), findsOneWidget);
    expect(
      tester.getTopLeft(find.text("✓ 12")).dx,
      lessThan(tester.getTopLeft(find.text("✓ 16")).dx),
    );

    await tester.tap(find.text("Hide ages"));
    await tester.pumpAndSettle();
    expect(find.text("✓ 12"), findsNothing);
    expect(find.text("Older than 21, not older than 65"), findsOneWidget);
  });

  testWidgets("a chip says in words whether the holder is over that age", (
    tester,
  ) async {
    await _pumpList(tester, _mixedAges);
    await tester.tap(find.text("Show all ages"));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel("Older than 21: yes"), findsOneWidget);
    expect(find.bySemanticsLabel("Older than 65: no"), findsOneWidget);
  });

  testWidgets("chip text is legible on the chip surface", (tester) async {
    await _pumpList(tester, _mixedAges);
    await tester.tap(find.text("Show all ages"));
    await tester.pumpAndSettle();

    for (final label in ["✓ 21", "– 65"]) {
      final text = tester.widget<Text>(find.text(label));
      final chip = tester
          .element(find.text(label))
          .findAncestorWidgetOfExactType<Container>()!;
      final surface = (chip.decoration! as BoxDecoration).color!;

      expect(
        _contrast(text.style!.color!, surface),
        greaterThanOrEqualTo(_minTextContrast),
        reason: label,
      );
    }
  });

  testWidgets("the toggle tells assistive technology whether it is open", (
    tester,
  ) async {
    await _pumpList(tester, _mixedAges);

    expect(
      tester.getSemantics(find.text("Show all ages")),
      matchesSemantics(
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label: "Show all ages",
      ),
    );

    await tester.tap(find.text("Show all ages"));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text("Hide ages")),
      matchesSemantics(
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label: "Hide ages",
      ),
    );
  });

  testWidgets("a single age has nothing to expand into", (tester) async {
    await _pumpList(tester, [_age(18, .yes)]);

    expect(find.text("Older than 18"), findsOneWidget);
    expect(find.text("Show all ages"), findsNothing);
  });

  testWidgets("the row sits where the first age was, among other attributes", (
    tester,
  ) async {
    await _pumpList(tester, [
      _text("name", "Name", "Anna"),
      _age(18, .yes),
      _text("city", "City", "Utrecht"),
      _age(21, .no),
    ]);

    final name = tester.getTopLeft(find.text("Name")).dy;
    final age = tester.getTopLeft(find.text("Age")).dy;
    final city = tester.getTopLeft(find.text("City")).dy;
    expect(name, lessThan(age));
    expect(age, lessThan(city));
    expect(find.text("Older than 18, not older than 21"), findsOneWidget);
  });

  testWidgets("per attribute is the default: one row per age", (tester) async {
    await _pumpList(tester, _mixedAges, ageDisplay: AgeDisplay.perAttribute);

    expect(find.text("Over 18"), findsOneWidget);
    expect(find.text("Over 75"), findsOneWidget);
    expect(find.text("Age"), findsNothing);
  });

  testWidgets("a comparison against another credential keeps every row", (
    tester,
  ) async {
    await _pumpList(tester, _mixedAges, compareTo: _mixedAges);

    expect(find.text("Over 18"), findsOneWidget);
    expect(find.text("Age"), findsNothing);
  });

  group("on a credential card", () {
    Future<void> pumpCard(WidgetTester tester, {required _Flag flag}) async {
      await pumpTranslated(
        tester,
        _app(
          YiviCredentialCard(
            credentialName: "Personal data",
            issuerName: "Issuer",
            attributes: _mixedAges,
            status: CredentialCardStatus(
              revoked: false,
              batchInstanceCountsRemaining: const {},
            ),
            compact: false,
            hideFooter: true,
          ),
          overrides: [
            featureFlagProvider(
              FeatureFlag.documentFlowV2,
            ).overrideWith((ref) => Stream.value(flag == .on)),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("flag on: one age row", (tester) async {
      await pumpCard(tester, flag: .on);

      expect(find.text("Older than 21, not older than 65"), findsOneWidget);
      expect(find.text("Over 18"), findsNothing);
    });

    testWidgets("flag off: a row per age, as before", (tester) async {
      await pumpCard(tester, flag: .off);

      expect(find.text("Over 18"), findsOneWidget);
      expect(find.text("Age"), findsNothing);
    });
  });
}
