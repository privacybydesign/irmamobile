import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_content.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/credential_type_thumbnail.dart";

import "helpers/credential_factory.dart";
import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

CredentialDescriptor _type(String id, String name, List<String> attributes) =>
    CredentialDescriptor(
      credentialId: id,
      name: name,
      issuer: _party("Yivi"),
      category: "Personal",
      attributes: [for (final a in attributes) stringAttr(a, null)],
      issueURL: null,
    );

/// The FAQ of the e-mail address in the scheme, with its escaped breaks.
final _emailFaq = Faq(
  intro: "Add your email address to your Yivi app.",
  purpose:
      "With your email address in your Yivi app, you can show that "
      "this address is really yours.",
  content:
      r"You will add the following data:\n• email address\n• email "
      "domain name.",
  howTo:
      r"Complete the following steps.\n1. Enter your e-mail address.\n"
      r"2. Open your email application.\n3. Click the link.\n\nYou now "
      "receive a card.",
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    CredentialDescriptor credential, {
    Faq? faq,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await pumpTranslated(
      tester,
      IrmaTheme(
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
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AddDataDetailsContent(credential: credential, faq: faq),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final email = _type("pbdf.sidn-pbdf.email", "Email address", [
    "Email address",
    "Email domain name",
  ]);

  testWidgets("the card large above its name, who gives it as a card, what "
      "you get as a row per field", (tester) async {
    await pump(tester, email, faq: _emailFaq);
    // The hero: the card large, its name centred under it.
    final card = tester.getRect(find.byType(CredentialTypeThumbnail).first);
    expect(card.width, 200);
    final name = tester.getRect(find.byKey(const Key("add_data_details_name")));
    expect(name.top, greaterThan(card.bottom));
    expect(name.center.dx, closeTo(card.center.dx, 2));
    // Who gives it: the issuer as a card under its own label, as the share
    // screen shows who asks; no "From …" line under the name.
    expect(find.text("YOU GET THIS FROM"), findsOneWidget);
    final issuer = find.byKey(const Key("add_data_details_issuer"));
    expect(
      find.descendant(of: issuer, matching: find.text("Yivi")),
      findsOneWidget,
    );
    expect(find.text("From Yivi"), findsNothing);
    expect(tester.getRect(issuer).top, greaterThan(name.bottom));
    // What you get: only the fields. The card is not repeated as a tile.
    expect(find.byType(CredentialTypeThumbnail), findsOneWidget);
    expect(find.text("THIS GOES IN YOUR APP"), findsOneWidget);
    final list = find.byKey(const Key("add_data_checklist"));
    expect(
      tester.getRect(list).top,
      greaterThan(tester.getRect(issuer).bottom),
    );
    for (final field in ["Email address", "Email domain name"]) {
      expect(
        find.descendant(of: list, matching: find.text(field)),
        findsOneWidget,
      );
    }
    expect(find.textContaining("Example card"), findsNothing);
    // The FAQ's own list repeats the attributes: left out.
    expect(
      find.textContaining("You will add the following data"),
      findsNothing,
    );
  });

  testWidgets("the questions are folded, the question only; a tap opens one", (
    tester,
  ) async {
    await pump(tester, email, faq: _emailFaq);
    expect(find.text("GOOD TO KNOW"), findsOneWidget);
    expect(find.textContaining("Enter your e-mail address."), findsNothing);

    await tester.tap(find.byKey(const Key("add_data_howto")));
    await tester.pumpAndSettle();
    for (final step in ["Enter your e-mail address.", "Click the link."]) {
      expect(find.textContaining(step), findsOneWidget);
    }
    expect(find.text("2"), findsOneWidget);
    expect(find.textContaining("You now receive a card."), findsOneWidget);
    // The other question stays folded.
    double turns(String key) => tester
        .widget<AnimatedRotation>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(AnimatedRotation),
          ),
        )
        .turns;
    expect(turns("add_data_howto"), 0.5);
    expect(turns("add_data_purpose"), 0);
  });

  testWidgets("no FAQ: the fallback intro and the attributes only", (
    tester,
  ) async {
    await pump(
      tester,
      _type("irma-demo.gemeente.personalData", "Personal data", ["BSN"]),
    );
    expect(find.text("This card goes into your Yivi app."), findsOneWidget);
    expect(find.text("BSN"), findsOneWidget);
    expect(find.text("GOOD TO KNOW"), findsNothing);
  });

  testWidgets("a document: only its issuer under it, no word of NFC", (
    tester,
  ) async {
    await pump(tester, _type("pbdf.pbdf.passport", "Passport", ["Photo"]));
    expect(find.textContaining("NFC"), findsNothing);
  });
}
