import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_comparison.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/requested_value.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

AttributeValue _s(String v) =>
    AttributeValue(type: AttributeType.string, string: v);
AttributeValue _b(bool v) =>
    AttributeValue(type: AttributeType.boolean, boolValue: v);

Attribute _attr(
  String id,
  AttributeValue? value, {
  AttributeValue? requested,
}) => Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: value,
  requestedValue: requested,
);

Widget _wrap(Widget child, {Locale locale = const Locale("en", "US")}) =>
    ProviderScope(
      child: IrmaTheme(
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
      ),
    );

const _dl = "pbdf-staging.pbdf.drivinglicence";

TrustedParty _issuer() => TrustedParty(
  id: "issuer",
  name: "Issuer",
  url: null,
  parent: null,
  verified: true,
);

void main() {
  group("sameAttributeValue", () {
    test("IRMA's yes / no strings equal booleans", () {
      expect(sameAttributeValue(_b(true), _s("yes")), isTrue);
      expect(sameAttributeValue(_s("no"), _b(false)), isTrue);
      expect(sameAttributeValue(_s(" Yes "), _b(true)), isTrue);
      expect(sameAttributeValue(_b(true), _s("no")), isFalse);
    });

    test("numbers equal their digits; strings compare as given", () {
      expect(
        sameAttributeValue(
          AttributeValue(type: AttributeType.integer, intValue: 18),
          _s("18"),
        ),
        isTrue,
      );
      expect(sameAttributeValue(_s("2030-03-01"), _s("2030-03-01")), isTrue);
      expect(sameAttributeValue(_s("Anna"), _s("anna")), isFalse);
      expect(sameAttributeValue(_s("x"), null), isFalse);
    });
  });

  group("requestedValueKind", () {
    final match = _attr("over18", _b(true), requested: _s("yes"));
    final miss = _attr("categoryB", _s("no"), requested: _s("yes"));
    final free = _attr("firstName", _s("Anna"));

    test("satisfied, mismatch, none", () {
      expect(
        requestedValueKind([match], template: false),
        RequestedValueKind.satisfied,
      );
      expect(
        requestedValueKind([match, miss], template: false),
        RequestedValueKind.mismatch,
      );
      expect(requestedValueKind([free], template: false), isNull);
    });

    test("a card to obtain: required", () {
      expect(
        requestedValueKind([match], template: true),
        RequestedValueKind.required,
      );
    });

    test("withRequestedValues fills in by claim path", () {
      final merged = withRequestedValues(
        [_attr("over18", _b(false)), free],
        [_attr("over18", null, requested: _s("yes"))],
      );
      expect(merged[0].requestedValue?.string, "yes");
      expect(merged[0].value?.boolValue, false);
      expect(merged[1], same(free));
    });
  });

  group("chips", () {
    testWidgets("owned option: Satisfies on the requested row only", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _attr("email", _s("a@b.nl"), requested: _s("a@b.nl")),
            _attr("domain", _s("b.nl")),
          ], credentialId: "pbdf.sidn-pbdf.email"),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Satisfies"), findsOneWidget);
      // On the right of its value.
      expect(
        tester.getTopLeft(find.text("Satisfies")).dx,
        greaterThan(tester.getTopRight(find.text("a@b.nl")).dx),
      );
    });

    testWidgets("mismatch: red, with the value asked for", (tester) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _attr("over18", _b(false), requested: _s("yes")),
          ], credentialId: "pbdf.sidn-pbdf.email"),
          locale: const Locale("nl", "NL"),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Vereist: Ja"), findsOneWidget);
      final chip = tester.widget<Container>(
        find.byKey(const Key("requested_value_mismatch")),
      );
      expect(
        (chip.decoration as BoxDecoration).color,
        IrmaThemeData().errorSurface,
      );
    });

    testWidgets("driving licence disclosure: age row and category row", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList(
            [
              _attr("firstName", _s("Anna")),
              _attr("lastName", _s("de Vries")),
              _attr("over18", _b(true), requested: _s("yes")),
              _attr("categoryB", _b(true), requested: _s("yes")),
            ],
            credentialId: _dl,
            disclosure: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The requested age leaves the header for the age row and its chip.
      expect(find.byKey(const Key("profile_header_chips")), findsNothing);
      final ageRow = find.byKey(const Key("attribute_group_age_row"));
      expect(ageRow, findsOneWidget);
      expect(find.text("Satisfies"), findsNWidgets(2));
      // The category chip sits on B's table row.
      final b = tester.getCenter(find.text("B"));
      final chips = find.text("Satisfies");
      expect(
        [
          for (final e in chips.evaluate())
            tester.getCenter(find.byWidget(e.widget)).dy,
        ].any((y) => (y - b.dy).abs() < 4),
        isTrue,
      );
    });

    testWidgets("compared with a request: the table, not tiles", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _attr("categoryAM", _b(true)),
            _attr("categoryAMDateOfExpiry", _s("2030-01-01")),
            _attr("categoryB", _b(false), requested: _s("yes")),
          ], credentialId: _dl),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key("driving_licence_categories_tiles")),
        findsNothing,
      );
      expect(find.text("Required: Yes"), findsOneWidget);
    });

    testWidgets("field grid: a requested document field", (tester) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _attr("documentNumber", _s("X1"), requested: _s("X1")),
          ], credentialId: "pbdf-staging.pbdf.passport"),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key("field_documentNumber")),
          matching: find.text("Satisfies"),
        ),
        findsOneWidget,
      );
    });

    testWidgets("card to obtain: Required, values not coloured", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCard.fromDescriptor(
            descriptor: CredentialDescriptor(
              credentialId: "pbdf.sidn-pbdf.email",
              name: "Email",
              issuer: _issuer(),
              category: null,
              attributes: [
                _attr("email", null, requested: _s("a@b.nl")),
                _attr("domain", null),
              ],
              issueURL: "https://example.com",
            ),
            compact: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Required"), findsOneWidget);
      expect(find.text("label-domain"), findsNothing);
      expect(
        tester.widget<Text>(find.text("a@b.nl")).style?.color,
        IrmaThemeData().dark,
      );
    });

    testWidgets("wrong credential: red on the mismatch, green on the match", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCard.fromCredential(
            credential: Credential(
              credentialId: "pbdf.sidn-pbdf.email",
              hash: "h",
              name: "Email",
              issuer: _issuer(),
              credentialInstanceIds: const {},
              batchInstanceCountsRemaining: const {},
              attributes: [
                _attr("email", _s("c@d.nl")),
                _attr("domain", _s("b.nl")),
              ],
              revoked: false,
              revocationSupported: false,
              issueUrl: null,
            ),
            compact: true,
            hideFooter: true,
            requested: [
              _attr("email", null, requested: _s("a@b.nl")),
              _attr("domain", null, requested: _s("b.nl")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Required: a@b.nl"), findsOneWidget);
      expect(find.text("Satisfies"), findsOneWidget);
    });
  });
}
