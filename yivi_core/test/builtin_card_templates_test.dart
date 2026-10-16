import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/builtin_card_templates.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/card_art_support.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "support/pump_translated.dart";

// The card templates Yivi ships for its own (PbDF) credentials.

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

Attribute _text(String id, String name, String value) => Attribute(
  claimPath: [id],
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: value),
);

Credential _credential(String id, List<Attribute> attributes) => Credential(
  credentialId: id,
  hash: id,
  name: "Card $id",
  issuer: _party("Issuer"),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

const _types = [
  "gemeente.personalData",
  "gemeente.address",
  "pbdf.passport",
  "pbdf.drivinglicence",
  "pbdf.ageLimits",
  "sidn-pbdf.email",
  "sidn-pbdf.mobilenumber",
  "pbdf.iban",
];

String _value(Attribute a) =>
    attributeText(a.value, yes: "Yes", no: "No") ?? "";

void main() {
  group("which credentials have one", () {
    for (final type in _types) {
      test("$type: production and staging share it", () {
        final production = builtinCardTemplate("pbdf.$type");
        final staging = builtinCardTemplate("pbdf-staging.$type");
        expect(production, isNotNull);
        expect(staging?.svg, production!.svg);
        expect(production.orientation, "landscape");
      });
    }

    test("others keep the Yivi card", () {
      expect(builtinCardTemplate("irma-demo.sidn-pbdf.email"), isNull);
      expect(builtinCardTemplate("pbdf.pbdf.unknown"), isNull);
      expect(builtinCardTemplate("pbdf-stagingx.pbdf.passport"), isNull);
    });
  });

  group("filling a template", () {
    final email = _credential("pbdf.sidn-pbdf.email", [
      _text("email", "Email address", "sanne@devries.example"),
      _text("domain", "Email domain", "devries.example"),
    ]);

    test("values and names by attribute id, plus name and issuer", () {
      final values = builtinTemplateValues(email, _value);
      expect(values["email"], "sanne@devries.example");
      expect(values["label.domain"], "Email domain");
      expect(values["yivi.name"], "Card pbdf.sidn-pbdf.email");
      expect(values["yivi.issuer"], "Issuer");
    });

    test("an empty photo slot gets a transparent picture", () {
      final values = builtinTemplateValues(
        _credential("pbdf.pbdf.passport", const []),
        _value,
      );
      expect(values["photo"], transparentPixel);
    });

    test("every placeholder of every template is filled", () {
      for (final type in _types) {
        final svg = builtinCardTemplate("pbdf.$type")!.svg;
        final ids = RegExp(r"\{\{\s*([A-Za-z0-9_.\-]+)\s*\}\}")
            .allMatches(svg)
            .map((m) => m[1]!)
            .where((id) => !id.contains("."))
            .toSet();
        final credential = _credential("pbdf.$type", [
          for (final id in ids) _text(id, "Name of $id", "value of $id"),
        ]);
        final filled = fillSvgTemplate(
          svg,
          builtinTemplateValues(credential, _value),
        );
        expect(filled, isNot(contains("{{")), reason: type);
        for (final id in ids.where((id) => !builtinImageSlots.contains(id))) {
          expect(filled, contains("value of $id"), reason: "$type: $id");
        }
      }
    });
  });

  group("CredentialCardArt", () {
    Future<void> pump(WidgetTester tester, Credential credential) =>
        pumpTranslated(
          tester,
          IrmaTheme(
            builder: (context) => MaterialApp(
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: FileTranslationLoader(
                    basePath: "assets/locales",
                    forcedLocale: const Locale("en", "US"),
                  ),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
              home: Scaffold(
                body: CredentialCardArt(credential: credential, width: 358),
              ),
            ),
          ),
        );

    testWidgets("draws the template of a staging credential", (tester) async {
      await pump(
        tester,
        _credential("pbdf-staging.sidn-pbdf.mobilenumber", [
          _text("mobilenumber", "Mobile phone number", "+31 6 1234 5678"),
        ]),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets("keeps the Yivi card for other credentials", (tester) async {
      await pump(
        tester,
        _credential("irma-demo.sidn-pbdf.email", [
          _text("email", "Email address", "demo@example.com"),
        ]),
      );
      expect(find.byType(SvgPicture), findsNothing);
      expect(find.text("Card irma-demo.sidn-pbdf.email"), findsOneWidget);
    });
  });
}
