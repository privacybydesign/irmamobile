import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/chip_check/chip_check_pill.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/chip_check/chip_check_renderer.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/sections/card_layout.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/sections/card_sections.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

schemaless.Attribute _str(String id, String value) => schemaless.Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: value,
  ),
);

schemaless.Attribute _bool(String id, bool value) => schemaless.Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.boolean,
    boolValue: value,
  ),
);

Widget _wrap(Widget child, {Locale locale = const Locale("en", "US")}) =>
    IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: TestTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: locale,
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

const _renderer = ChipCheckRenderer();
const _passport = "pbdf-staging.pbdf.passport";

void main() {
  group("renderer", () {
    test("claims yes and no, as boolean or string", () {
      for (final attribute in [
        _bool("activeAuthentication", true),
        _bool("activeAuthentication", false),
        _str("activeAuthentication", "yes"),
        _str("activeAuthentication", "No"),
      ]) {
        final group = _renderer.claim([_str("x", "1"), attribute]);
        expect(group?.claimed, [attribute]);
      }
    });

    test("an unknown value or a comparison stays a field", () {
      expect(_renderer.claim([_str("activeAuthentication", "")]), isNull);
      final attrs = [_bool("activeAuthentication", true)];
      expect(_renderer.claim(attrs, compareTo: attrs), isNull);
      expect(_renderer.claim([_str("documentNumber", "1")]), isNull);
    });

    test("the Document section draws it below the fields", () {
      final sections = assembleSections(cardLayouts[_passport]!, [
        _str("documentNumber", "1"),
        _bool("activeAuthentication", true),
      ]);
      final document = sections.single;
      expect(document.fields.map((a) => a.claimPath.first), ["documentNumber"]);
      expect(document.trailing, hasLength(1));
    });

    test("comparing: an ordinary Document field", () {
      final attrs = [_bool("activeAuthentication", true)];
      final sections = assembleSections(
        cardLayouts[_passport]!,
        attrs,
        compareTo: attrs,
      );
      expect(sections.single.trailing, isEmpty);
      expect(sections.single.fields, attrs);
    });
  });

  group("pill", () {
    BoxDecoration pillDecoration(WidgetTester tester) =>
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(ChipCheckPill),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    testWidgets("genuine: green", (tester) async {
      await tester.pumpWidget(_wrap(const ChipCheckPill(genuine: true)));
      await tester.pumpAndSettle();
      expect(find.text("Chip is genuine"), findsOneWidget);
      expect(pillDecoration(tester).color, IrmaThemeData().successSurface);
    });

    testWidgets("signature only: grey, Dutch", (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ChipCheckPill(genuine: false),
          locale: const Locale("nl", "NL"),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Alleen handtekening gecontroleerd"), findsOneWidget);
      expect(pillDecoration(tester).color, IrmaThemeData().neutralExtraLight);
    });

    testWidgets("the info button is a full tap target and explains", (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ChipCheckPill(genuine: false)));
      await tester.pumpAndSettle();
      final button = find.byKey(const Key("chip_check_info_button"));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(find.byTooltip("What does this mean?"), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text("Chip check"), findsOneWidget);
      expect(find.textContaining("no active authentication"), findsOneWidget);
    });

    testWidgets("in the card: below the Document fields", (tester) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _str("documentNumber", "X1"),
            _str("dateOfExpiry", "2030-01-01"),
            _bool("activeAuthentication", true),
          ], credentialId: _passport),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("label-activeAuthentication"), findsNothing);
      expect(
        tester.getTopLeft(find.byType(ChipCheckPill)).dy,
        greaterThan(
          tester
              .getBottomLeft(find.byKey(const Key("field_documentNumber")))
              .dy,
        ),
      );
    });
  });
}
