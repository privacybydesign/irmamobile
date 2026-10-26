import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/wallet/card_hero.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "helpers/credential_factory.dart";
import "helpers/test_translation_loader.dart";

final _card = testCredential(type: "pbdf.sidn-pbdf.email", hash: "email");

void main() {
  tearDown(() => WalletTransition.openKey.value = null);

  // "See all" on a card's details switches to the Activity tab and then
  // closes the details: the Data tab's heroes are off (HeroMode) while it is
  // not shown, so no flight comes back to the card's place in the stack.
  testWidgets("a card closed while its tab is hidden is back in its place", (
    tester,
  ) async {
    final heroes = ValueNotifier(true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        child: IrmaTheme(
          builder: (_) => MaterialApp(
            navigatorKey: navigator,
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
              body: ValueListenableBuilder<bool>(
                valueListenable: heroes,
                builder: (context, on, _) => HeroMode(
                  enabled: on,
                  child: Center(
                    key: const Key("stack"),
                    child: CardHero(credential: _card, width: 200),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final inStack = find.descendant(
      of: find.byKey(const Key("stack")),
      matching: find.byType(CredentialCardArt),
    );
    expect(inStack, findsOneWidget);

    // Open the card: its place in the stack is empty while it is open.
    WalletTransition.openKey.value = _card.hash;
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: CardHero(credential: _card, width: 360),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(inStack, findsNothing);

    // The tab goes away, then the details close: no flight back.
    heroes.value = false;
    await tester.pump();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    WalletTransition.openKey.value = null;
    heroes.value = true;
    await tester.pumpAndSettle();
    expect(inStack, findsOneWidget);
  });
}
