import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";

import "data_search_test.dart" show pumpFilledAppOnDataPage;
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// A card opened and closed eight times in a row, from every place a card
/// opens from on the Data tab: one details view while open, none after,
/// and the bar and the tab bar take taps again.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("card-open-repeat", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    for (final origin in ["stack", "list", "grid", "search"]) {
      testWidgets(origin, (tester) async {
        await pumpFilledAppOnDataPage(tester, irmaBinding);
        switch (origin) {
          case "list":
            await showWalletView(tester, WalletView.list);
          case "grid":
            await showWalletView(tester, WalletView.grid);
          case "search":
            await searchWallet(tester, "adres");
        }

        final count = findAllWalletCards().evaluate().length;
        expect(count, greaterThanOrEqualTo(2));
        // Top, middle, bottom, and the same again.
        final picks = [
          0,
          count ~/ 2,
          count - 1,
          0,
          count ~/ 2,
          count - 1,
          0,
          1,
        ];
        for (final (i, pick) in picks.indexed) {
          final card = findAllWalletCards().at(pick);
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
          // In the stack only a card's top shows.
          await tester.tapAt(tester.getTopLeft(card) + const Offset(60, 20));
          await tester.pumpAndSettle();
          await tester.waitFor(findCredentialDetail());
          expect(findCredentialDetail(), findsOneWidget, reason: "open $i");

          switch (i % 3) {
            case 0:
              await tester.tapAndSettle(
                find.byKey(const Key("credential_detail_done")),
              );
            case 1:
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
            case 2:
              final list = credentialDetailScrollable();
              await tester.flingFrom(
                tester.getTopLeft(list) + const Offset(150, 200),
                const Offset(0, 420),
                1600,
              );
              await tester.pumpAndSettle();
          }
          await tester.waitUntilDisappeared(findCredentialDetail());
          expect(findCredentialDetail(), findsNothing, reason: "closed $i");

          // The bar (the + or, searching, Cancel) and the tab bar.
          final action = find.byKey(
            Key(
              origin == "search" ? "data_search_cancel" : "data_tab_add_data",
            ),
          );
          expect(action.hitTestable(), findsOneWidget, reason: "bar $i");
          expect(
            find.byKey(const Key("nav_button_activity")).hitTestable(),
            findsOneWidget,
            reason: "tab bar $i",
          );
        }
      });
    }
  });
}
