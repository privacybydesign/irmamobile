import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_content.dart";
import "package:yivi_core/src/theme/theme.dart";

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
    bool inDisclosure = false,
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
              child: AddDataDetailsContent(
                credential: credential,
                faq: faq,
                inDisclosure: inDisclosure,
              ),
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

  testWidgets("the card beside the name, what you get as a checklist", (
    tester,
  ) async {
    await pump(tester, email, faq: _emailFaq);
    final name = tester.getRect(find.text("Email address").first);
    final card = tester.getRect(find.text("Example"));
    // The name is beside the card, not under it.
    expect(name.left, greaterThan(card.left));
    expect(name.top, lessThan(card.bottom));
    expect(find.text("by Yivi"), findsOneWidget);
    expect(find.text("YOU GET"), findsOneWidget);
    final list = find.byKey(const Key("add_data_checklist"));
    expect(
      find.descendant(of: list, matching: find.text("Email domain name")),
      findsOneWidget,
    );
    // The FAQ's own list repeats the attributes: left out.
    expect(
      find.textContaining("You will add the following data"),
      findsNothing,
    );
    expect(find.byKey(const Key("add_data_show_all")), findsNothing);
    expect(find.byKey(const Key("add_data_details_nfc")), findsNothing);
  });

  testWidgets("past eight attributes: Show all opens the rest", (tester) async {
    final names = [for (var i = 1; i <= 11; i++) "Attribute $i"];
    await pump(tester, _type("irma-demo.x.many", "Many", names));
    expect(find.text("Attribute 8"), findsOneWidget);
    expect(find.text("Attribute 9"), findsNothing);
    expect(find.text("Show all 11"), findsOneWidget);
    await tester.tap(find.byKey(const Key("add_data_show_all")));
    await tester.pumpAndSettle();
    expect(find.text("Attribute 11"), findsOneWidget);
    expect(find.byKey(const Key("add_data_show_all")), findsNothing);
  });

  testWidgets("the questions are folded, with a peek; a tap opens one", (
    tester,
  ) async {
    await pump(tester, email, faq: _emailFaq);
    expect(find.text("GOOD TO KNOW"), findsOneWidget);
    // The steps say how many there are and where they start.
    expect(find.text("3 steps · Enter your e-mail address."), findsOneWidget);
    expect(find.text("Open your email application."), findsNothing);

    await tester.tap(find.byKey(const Key("add_data_howto")));
    await tester.pumpAndSettle();
    expect(find.text("3 steps · Enter your e-mail address."), findsNothing);
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
    expect(find.text("Add Personal data to my Yivi-app"), findsOneWidget);
    expect(find.text("BSN"), findsOneWidget);
    expect(find.text("GOOD TO KNOW"), findsNothing);
  });

  testWidgets("during a request, the note sits at the foot of what you get", (
    tester,
  ) async {
    await pump(tester, email, faq: _emailFaq, inDisclosure: true);
    final note = find.byKey(const Key("add_data_disclosure_note"));
    expect(
      find.descendant(
        of: find.byKey(const Key("add_data_you_get")),
        matching: note,
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(note).top,
      greaterThan(
        tester.getRect(find.byKey(const Key("add_data_checklist"))).bottom -
            0.5,
      ),
    );
  });

  testWidgets("a document needs NFC: the chip beside the name", (tester) async {
    await pump(tester, _type("pbdf.pbdf.passport", "Passport", ["Photo"]));
    expect(find.byKey(const Key("add_data_details_nfc")), findsOneWidget);
  });
}
