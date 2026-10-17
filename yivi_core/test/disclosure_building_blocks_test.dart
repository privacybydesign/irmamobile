import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/screens/session/widgets/session_scaffold.dart";
import "package:yivi_core/src/screens/session/widgets/shared_card_tile.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/card_pile.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/large_title_scroll_view.dart";

import "helpers/credential_factory.dart";
import "support/pump_translated.dart";

class _NoWallet extends SchemalessCredentialOrderController {
  @override
  Future<List<Credential>> build() async => const [];
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        schemalessCredentialOrderControllerProvider.overrideWith(_NoWallet.new),
      ],
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
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _inPage(Widget child) => Scaffold(
  body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
);

TrustedParty _party(String name, {bool verified = true}) => TrustedParty(
  id: name,
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

SelectableCredentialInstance _instance(
  String name, {
  String hash = "h",
  bool revoked = false,
  int? batch,
  List<Attribute> attributes = const [],
}) => SelectableCredentialInstance(
  credentialId: "test.$name",
  hash: hash,
  name: name,
  issuer: _party("Gemeente Nijmegen"),
  format: batch == null ? CredentialFormat.idemix : CredentialFormat.sdjwtvc,
  attributes: attributes,
  revoked: revoked,
  revocationSupported: revoked,
  batchInstanceCountRemaining: batch,
  expiryDate: 4102444800,
);

double _titleOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.byKey(const Key("irma_app_bar_title")))
    .opacity;

void main() {
  group("large title", () {
    late ValueNotifier<bool> visible;

    setUp(() => visible = ValueNotifier(false));
    tearDown(() => visible.dispose());

    Widget page() => SessionScaffold(
      appBarTitle: "issuance.title",
      scrollsUnderBars: true,
      barTitleVisibility: visible,
      onDismiss: () {},
      body: Builder(
        builder: (context) => LargeTitleScrollView(
          title: "Do you want to share this data?",
          barTitleVisible: visible,
          padding:
              MediaQuery.paddingOf(context) +
              const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            for (var i = 0; i < 20; i++)
              SizedBox(height: 80, child: Text("Row $i")),
          ],
        ),
      ),
    );

    testWidgets("the bar title waits until the large one has scrolled away", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, page());

      expect(find.text("Do you want to share this data?"), findsOneWidget);
      expect(_titleOpacity(tester), 0);
      expect(find.bySemanticsLabel("Add data"), findsNothing);

      // Not quite past the large title yet.
      await tester.drag(find.byType(ListView), const Offset(0, -20));
      await tester.pumpAndSettle();
      expect(_titleOpacity(tester), 0);

      // Past it: the test font wraps the title to a few lines, so go well
      // beyond its height.
      final titleHeight = tester
          .getSize(find.byKey(const Key("large_title")))
          .height;
      await tester.drag(find.byType(ListView), Offset(0, -titleHeight - 40));
      await tester.pumpAndSettle();
      expect(_titleOpacity(tester), 1);
      expect(find.bySemanticsLabel("Add data"), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(_titleOpacity(tester), 0);
      semantics.dispose();
    });

    testWidgets("screens without a large title keep their bar title", (
      tester,
    ) async {
      await _pump(
        tester,
        SessionScaffold(
          appBarTitle: "issuance.title",
          body: const SizedBox.expand(),
        ),
      );
      expect(find.byKey(const Key("irma_app_bar_title")), findsNothing);
      expect(find.text("Add data"), findsOneWidget);
    });
  });

  group("requestor header", () {
    testWidgets("a registered party", (tester) async {
      await _pump(
        tester,
        _inPage(SessionRequestorHeader(requestor: _party("Webshop Noord"))),
      );
      expect(find.text("Webshop Noord"), findsOneWidget);
      expect(find.text("Registered with Yivi"), findsOneWidget);
      expect(find.byKey(const Key("session_requestor_warning")), findsNothing);
    });

    testWidgets("an unknown party gets the warning", (tester) async {
      await _pump(
        tester,
        _inPage(
          SessionRequestorHeader(
            requestor: _party("shop-deals-online.example", verified: false),
          ),
        ),
      );
      expect(find.text("Not registered with Yivi"), findsOneWidget);
      expect(
        find.byKey(const Key("session_requestor_warning")),
        findsOneWidget,
      );
    });
  });

  group("shared card tile", () {
    testWidgets("only the shared values, under the card's name", (
      tester,
    ) async {
      await _pump(
        tester,
        _inPage(
          SharedCardTile(
            bundle: DisclosureBundle(
              credentials: [
                _instance(
                  "Email address",
                  attributes: [stringAttr("email", "s.devries@werk.example")],
                ),
              ],
            ),
            trailing: const Text("Change"),
          ),
        ),
      );
      // The small card art carries the name too.
      expect(find.text("Email address"), findsWidgets);
      expect(find.text("Gemeente Nijmegen"), findsWidgets);
      expect(find.text("s.devries@werk.example"), findsOneWidget);
      expect(find.text("Change"), findsOneWidget);
      expect(find.byKey(const Key("shared_card_chip")), findsNothing);
    });

    testWidgets("a value that is exactly what is asked for is green", (
      tester,
    ) async {
      await _pump(
        tester,
        _inPage(
          SharedCardTile(
            bundle: DisclosureBundle(
              credentials: [
                _instance(
                  "Address",
                  attributes: [
                    Attribute(
                      claimPath: ["city"],
                      displayName: "City",
                      value: AttributeValue(
                        type: AttributeType.string,
                        string: "Arnhem",
                      ),
                      requestedValue: AttributeValue(
                        type: AttributeType.string,
                        string: "Arnhem",
                      ),
                    ),
                    stringAttr("street", "Grote Markt 1"),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      final theme = IrmaTheme.of(tester.element(find.text("Arnhem")));
      expect(
        tester.widget<Text>(find.text("Arnhem")).style?.color,
        theme.success,
      );
      expect(
        tester.widget<Text>(find.text("Grote Markt 1")).style?.color,
        isNot(theme.success),
      );
    });

    testWidgets("a revoked card: chip, reason and the fix", (tester) async {
      var fixed = 0;
      await _pump(
        tester,
        _inPage(
          SharedCardTile(
            bundle: DisclosureBundle(
              credentials: [_instance("Address", revoked: true)],
            ),
            fixLabel: "Add a new address",
            onFix: () => fixed++,
          ),
        ),
      );
      expect(find.text("Revoked"), findsOneWidget);
      expect(
        find.text("Gemeente Nijmegen withdrew this card."),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("shared_card_fix")));
      expect(fixed, 1);
    });

    testWidgets("the last copy gets a warning chip", (tester) async {
      await _pump(
        tester,
        _inPage(
          SharedCardTile(
            bundle: DisclosureBundle(
              credentials: [_instance("Age limits", batch: 1)],
            ),
          ),
        ),
      );
      expect(find.text("Last use"), findsOneWidget);
      expect(find.byKey(const Key("shared_card_fix")), findsNothing);
    });

    testWidgets("a set of cards shows each card and both names", (
      tester,
    ) async {
      await _pump(
        tester,
        _inPage(
          SharedCardTile(
            bundle: DisclosureBundle(
              credentials: [
                _instance("BSN", hash: "a"),
                _instance("Full name", hash: "b"),
              ],
            ),
          ),
        ),
      );
      expect(find.text("BSN + Full name"), findsOneWidget);
      expect(find.byType(CredentialCardArt), findsNWidgets(2));
    });
  });

  group("card pile", () {
    testWidgets("small tilted cards, each nudged, tucked under each other", (
      tester,
    ) async {
      final cards = [
        for (var i = 0; i < 4; i++)
          testCredential(type: "test.card$i", hash: "h$i", name: "Card $i"),
      ];
      await _pump(tester, _inPage(CardPile(cards: cards)));

      expect(find.byType(CredentialCardArt), findsNWidgets(4));
      const pile = CardPile(cards: []);
      expect(
        tester.getSize(find.byKey(const Key("card_pile"))).height,
        pile.cardHeight + 3 * CardPile.step + 2 * CardPile.margin,
      );
      // Subtle, and alternating left and right.
      for (var i = 0; i < 4; i++) {
        final p = CardPile.placementOf(i);
        expect(p.degrees.abs(), lessThanOrEqualTo(3));
        expect(p.dx.abs(), lessThanOrEqualTo(32));
        if (i > 0) {
          expect(p.dx.sign, isNot(CardPile.placementOf(i - 1).dx.sign));
        }
      }
    });
  });
}
