import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
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

const _dl = "pbdf-staging.pbdf.drivinglicence";
const _municipality = "irma-demo.gemeente.personalData";
const _idcard = "pbdf-staging.pbdf.idcard";

List<String?> _titles(List<AssembledSection> sections) => [
  for (final s in sections) s.titleKey,
];

List<String> _fieldIds(AssembledSection s) => [
  for (final a in s.fields) a.claimPath.first as String,
];

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

void main() {
  final drivingLicence = [
    _str("documentNumber", "1234567890"),
    _str("firstName", "Anna"),
    _str("lastName", "de Vries"),
    _str("issuingAuthority", "Gemeente Meppel"),
    _str("issuingMemberState", "NLD"),
    _str("dateOfBirth", "1996-12-17"),
    _str("placeOfBirth", "Meppel"),
    _str("yearOfBirth", "1996"),
    _str("dateOfExpiry", "2027-07-12"),
    _bool("over18", true),
    _bool("over65", false),
    _bool("activeAuthentication", true),
    _bool("categoryB", true),
    _str("categoryBDateOfExpiry", "2030-03-01"),
  ];

  group("assembleSections", () {
    test(
      "driving licence: Persoon, Rijbevoegdheid, Document, nothing left",
      () {
        final sections = assembleSections(cardLayouts[_dl]!, drivingLicence);
        expect(_titles(sections), [
          "credential.sections.person",
          "credential.sections.driving_entitlement",
          "credential.sections.document",
        ]);
        expect(
          sections[0].groups,
          hasLength(1),
          reason: "the header, ages as its chips",
        );
        expect(
          _fieldIds(sections[0]),
          isEmpty,
          reason: "the year of birth is in the date of birth",
        );
        expect(sections.last.rest, isEmpty, reason: "taken, not left over");
        expect(sections[1].groups, hasLength(1), reason: "categories");
        expect(_fieldIds(sections[2]), [
          "documentNumber",
          "dateOfExpiry",
          "issuingAuthority",
          "issuingMemberState",
        ]);
        expect(sections[2].trailing, hasLength(1), reason: "the chip check");
      },
    );

    test("an attribute no section names lands in a trailing section", () {
      final sections = assembleSections(cardLayouts[_dl]!, [
        ...drivingLicence,
        _str("somethingNew", "x"),
      ]);
      expect(sections.last.titleKey, isNull);
      expect(
        [for (final a in sections.last.rest) a.claimPath.first],
        ["somethingNew"],
      );
    });

    test("only ages shared: the standalone age row in Persoon", () {
      final sections = assembleSections(cardLayouts[_dl]!, [
        _bool("over18", true),
        _bool("over65", false),
      ]);
      expect(sections.single.groups.single.claimed, hasLength(2));
      expect(sections.single.fields, isEmpty);
    });

    test("a year of birth shared without the date of birth stays", () {
      final sections = assembleSections(cardLayouts[_dl]!, [
        _str("yearOfBirth", "1996"),
      ]);
      expect(sections.single.titleKey, isNull);
      expect(
        [for (final a in sections.single.rest) a.claimPath.first],
        ["yearOfBirth"],
      );
    });

    test("a disclosure subset drops the empty sections", () {
      final sections = assembleSections(cardLayouts[_dl]!, [
        _bool("over18", true),
      ]);
      expect(_titles(sections), ["credential.sections.person"]);
    });

    test("ID card: not an EU citizen is a Persoon field", () {
      final sections = assembleSections(cardLayouts[_idcard]!, [
        _str("firstName", "Anna"),
        _str("lastName", "de Vries"),
        _bool("isEuCitizen", false),
        _str("documentType", "I"),
        _str("country", "NLD"),
      ]);
      expect(_fieldIds(sections[0]), ["isEuCitizen"]);
      expect(_fieldIds(sections[1]), ["documentType", "country"]);
    });

    test("municipality: Naam and Registratie", () {
      final sections = assembleSections(cardLayouts[_municipality]!, [
        _str("initials", "A."),
        _str("firstnames", "Anna"),
        _str("prefix", "de"),
        _str("familyname", "Vries"),
        _str("surname", "de Vries-Jansen"),
        _str("bsn", "999999990"),
        _str("digidlevel", "Substantieel"),
      ]);
      expect(_titles(sections), [
        "credential.sections.person",
        "credential.sections.name",
        "credential.sections.registration",
      ]);
      // The prefix is in the surname the header shows, but belongs to the
      // birth name (Geslachtsnaam) too, so it stays.
      expect(_fieldIds(sections[1]), ["initials", "familyname", "prefix"]);
      expect(_fieldIds(sections[2]), ["bsn", "digidlevel"]);
    });

    test("municipality with a full name: taken by the header, not shown", () {
      final sections = assembleSections(cardLayouts[_municipality]!, [
        _str("fullname", "A. de Vries-Jansen"),
        _str("firstnames", "Anna"),
        _str("surname", "de Vries-Jansen"),
      ]);
      expect(_titles(sections), ["credential.sections.person"]);
      expect(sections.single.fields, isEmpty);
    });
  });

  group("rendering", () {
    testWidgets("driving licence: titled sections with a field grid", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList(drivingLicence, credentialId: _dl),
        ),
      );
      await tester.pumpAndSettle();

      for (final title in ["PERSON", "DRIVING ENTITLEMENT", "DOCUMENT"]) {
        expect(find.text(title), findsOneWidget);
      }
      // Two fields per row in the Document section.
      final number = tester.getRect(
        find.byKey(const Key("field_documentNumber")),
      );
      final expiry = tester.getRect(
        find.byKey(const Key("field_dateOfExpiry")),
      );
      final authority = tester.getRect(
        find.byKey(const Key("field_issuingAuthority")),
      );
      expect(expiry.top, number.top);
      expect(expiry.left, greaterThan(number.left));
      expect(authority.top, greaterThan(number.bottom - 1));
      expect(authority.left, number.left);
    });

    testWidgets("credentials without a layout keep the plain list", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _str("email", "a@b.nl"),
          ], credentialId: "pbdf.sidn-pbdf.email"),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CardSections), findsNothing);
      expect(find.text("label-email"), findsOneWidget);
    });

    testWidgets("field values are coloured against compareTo", (tester) async {
      final theme = IrmaThemeData();
      await tester.pumpWidget(
        _wrap(
          FieldGrid(
            fields: [_str("documentNumber", "1"), _str("dateOfExpiry", "2")],
            compareTo: [_str("documentNumber", "1"), _str("dateOfExpiry", "9")],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text("1")).style?.color, theme.success);
      expect(tester.widget<Text>(find.text("2")).style?.color, theme.error);
    });
  });
}
