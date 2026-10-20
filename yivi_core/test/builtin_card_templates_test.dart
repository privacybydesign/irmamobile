import "dart:io";

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

String _value(Attribute a) =>
    attributeText(a.value, yes: "Yes", no: "No") ?? "";

/// The `{{…}}` placeholders of [svg] that are attribute values.
Set<String> _valueIds(String svg) => RegExp(
  r"\{\{\s*([A-Za-z0-9_.\-]+)\s*\}\}",
).allMatches(svg).map((m) => m[1]!).where((id) => !id.contains(".")).toSet();

void main() {
  group("which credentials have one", () {
    test("every listed type has a template", () {
      for (final id in builtinCardCredentialIds) {
        expect(builtinCardTemplate(id), isNotNull, reason: id);
      }
    });

    test("production and staging share a template", () {
      for (final id in builtinCardCredentialIds.where(
        (id) => id.startsWith("pbdf."),
      )) {
        final staging = "pbdf-staging.${id.substring("pbdf.".length)}";
        expect(builtinCardTemplate(staging)?.svg, builtinCardTemplate(id)!.svg);
      }
    });

    test("demo copies share the PbDF design", () {
      expect(
        builtinCardTemplate("irma-demo.sidn-pbdf.email")!.svg,
        builtinCardTemplate("pbdf.sidn-pbdf.email")!.svg,
      );
      expect(
        builtinCardTemplate("irma-demo.IRMATube.member")!.svg,
        builtinCardTemplate("pbdf.pbdf.yivitube")!.svg,
      );
    });

    test("the test issuers' SD-JWT credentials, by vct", () {
      const host = "https://veramo-issuer.openid4vc.staging.yivi.app";
      for (final path in ["", "/test-issuer", "/authcode-issuer"]) {
        expect(
          builtinCardTemplate("$host$path/vct/email")!.svg,
          builtinCardTemplate("pbdf.sidn-pbdf.email")!.svg,
          reason: path,
        );
      }
      expect(
        builtinCardTemplate("$host/vct/phone")!.svg,
        builtinCardTemplate("pbdf.sidn-pbdf.mobilenumber")!.svg,
      );
      expect(builtinCardTemplate("$host/vct/organization"), isNotNull);
      expect(builtinCardTemplate("$host/vct/statuslist"), isNotNull);
      expect(builtinCardTemplate("$host/vct/unknown"), isNull);
      expect(builtinCardTemplate("https://example.com/vct/email"), isNull);
    });

    test("mdoc credentials, by doctype", () {
      expect(builtinCardTemplate("eu.europa.ec.eudi.pid.1"), isNotNull);
      expect(builtinCardTemplate("org.iso.18013.5.1.mDL"), isNotNull);
      expect(builtinCardTemplate("eu.europa.ec.av.1"), isNotNull);
    });

    test("the deprecated diploma keeps the Yivi card", () {
      const id = "pbdf.pbdf.diploma";
      expect(
        builtinCardTemplate(id, attributeIds: ["institute", "degree"]),
        isNull,
      );
      expect(
        builtinCardTemplate(id, attributeIds: ["qualification", "fullName"]),
        isNotNull,
      );
    });

    test("others keep the Yivi card", () {
      expect(builtinCardTemplate("irma-demo.RU.studentCard"), isNull);
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

    test("a phone number fills the mobile number card", () {
      final values = builtinTemplateValues(
        _credential("phone", [_text("phone_number", "Phone", "+31 6 1")]),
        _value,
      );
      expect(values["mobilenumber"], "+31 6 1");
      expect(values["label.mobilenumber"], "Phone");
    });

    test("every placeholder of every template is filled", () {
      for (final type in builtinCardCredentialIds) {
        final svg = builtinCardTemplate(type)!.svg;
        final ids = _valueIds(svg);
        final credential = _credential(type, [
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

    test("every typeface a template uses is bundled", () {
      final pubspec = File("pubspec.yaml").readAsStringSync();
      final bundled = RegExp(
        r"- family: (.+)",
      ).allMatches(pubspec).map((m) => m[1]!.trim()).toSet();
      for (final type in builtinCardCredentialIds) {
        final svg = builtinCardTemplate(type)!.svg;
        final families = RegExp(
          r'font-family="packages/yivi_core/([^"]+)"',
        ).allMatches(svg).map((m) => m[1]!);
        for (final family in families) {
          expect(bundled, contains(family), reason: "$type: $family");
        }
        expect(svg, isNot(contains("§")), reason: type);
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
        _credential("irma-demo.RU.studentCard", [
          _text("email", "Email address", "demo@example.com"),
        ]),
      );
      expect(find.byType(SvgPicture), findsNothing);
      expect(find.text("Card irma-demo.RU.studentCard"), findsOneWidget);
    });
  });
}
