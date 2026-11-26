import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/providers/last_shared_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_keys.dart";
import "package:yivi_core/src/screens/session/models/disclosure_plan_view.dart";

import "disclosure_fixtures.dart";
import "support/test_app.dart";

const _id = 9;

SessionState _session(DisclosurePlan plan) => SessionState(
  id: _id,
  protocol: "irma",
  type: SessionType.disclosure,
  status: SessionStatus.requestPermission,
  requestor: TrustedParty(
    id: "Webshop",
    name: "Webshop",
    url: null,
    parent: null,
    verified: true,
  ),
  disclosurePlan: plan,
);

/// The change page of [plan], and the sheet behind [link] opened.
Future<void> _open(
  WidgetTester tester,
  DisclosurePlan plan,
  String link,
) async {
  final state = _session(plan);
  await pumpTestApp(
    tester,
    DisclosureFlow(
      session: state,
      onDismiss: () {},
      onClose: () {},
      onShare: (_, _) {},
    ),
    size: const Size(390, 844),
    locale: const Locale("nl", "NL"),
    overrides: [
      sessionStateProvider(_id).overrideWith((ref) => Stream.value(state)),
      walletCardsProvider.overrideWithValue(const []),
      sharesOfProvider(_id).overrideWith(
        (ref) =>
            (_) => LastShared.never,
      ),
    ],
  );
  await tester.pumpAndSettle();
  // Nothing shared yet (only optional data): the hint opens the page.
  await tester.tap(
    find.byKey(DisclosureKeys.pile).evaluate().isEmpty
        ? find.byKey(DisclosureKeys.optionalHint)
        : find.byKey(DisclosureKeys.pile),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(Key(link)));
  await tester.tap(find.byKey(Key(link)));
  await tester.pumpAndSettle();
}

Finder _row(String hash) => find.byKey(Key("which_card_row_$hash"));
Finder get _sheet => find.byKey(const Key("which_card_sheet"));
Finder get _choose => find.byKey(const Key("which_card_choose"));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group("Welk kaartje deel je?", () {
    testWidgets("several kinds: whole cards; a tap selects, Kies applies", (
      tester,
    ) async {
      await _open(tester, drie(), "change_pick_0");
      expect(_sheet, findsOneWidget);
      expect(find.text("Welk kaartje deel je?"), findsWidgets);
      expect(find.text("Webshop heeft er maar één nodig."), findsOneWidget);
      expect(_row("pp-1"), findsOneWidget);
      expect(_row("pp-2"), findsOneWidget);
      expect(_row("dr-1"), findsOneWidget);
      await _tap(tester, _row("dr-1"));
      // Still open: a tap only selects.
      expect(_sheet, findsOneWidget);
      await _tap(tester, _choose);
      expect(_sheet, findsNothing);
      expect(find.text("5012345678"), findsOneWidget);
      expect(find.text("NX4R7K2P9"), findsNothing);
    });

    testWidgets("closing discards what was picked", (tester) async {
      await _open(tester, drie(), "change_pick_0");
      await _tap(tester, _row("dr-1"));
      await tester.tap(find.bySemanticsLabel("Sluiten").last);
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(find.text("NX4R7K2P9"), findsOneWidget);
    });

    testWidgets("identical cards are one row", (tester) async {
      await _open(tester, keuze(), "change_pick_0");
      expect(_row("pp-2"), findsNothing);
      expect(find.text("twee kaartjes met dezelfde gegevens"), findsOneWidget);
    });

    testWidgets("a revoked card is last, without a radio", (tester) async {
      await _open(tester, eeningetrokken(), "change_pick_0");
      expect(
        find.text("Ingetrokken. Dit kaartje kun je niet meer delen."),
        findsOneWidget,
      );
      final ys = [
        for (final h in ["e-1", "e-2", "e-3"]) tester.getTopLeft(_row(h)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(
        find.descendant(
          of: _row("e-3"),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets("one card: no radio, no Kies, the add link", (tester) async {
      await _open(tester, eenvoudig(), "change_pick_0");
      expect(_choose, findsNothing);
      expect(find.text("Ander e-mailadres toevoegen"), findsOneWidget);
    });

    testWidgets("optional: Niet delen first, selected while off", (
      tester,
    ) async {
      await _open(
        tester,
        plan([
          one(
            slot(email, [
              card(email, mail1, hash: "e-1"),
              card(email, mail2, hash: "e-2"),
            ]),
            opt: true,
          ),
        ]),
        "change_optional_link_0",
      );
      expect(find.byKey(const Key("which_card_nothing")), findsOneWidget);
      expect(
        find.text("Webshop vraagt hierom, maar het hoeft niet."),
        findsOneWidget,
      );
      await _tap(tester, _row("e-2"));
      await _tap(tester, _choose);
      expect(find.text("s.devries@werk.example"), findsOneWidget);
      expect(find.byKey(const Key("change_optional_off_0")), findsOneWidget);
    });

    testWidgets("several: ticks, Klaar, one stays", (tester) async {
      await _open(tester, meerdere(), "change_pick_0");
      expect(find.text("Welke kaartjes deel je?"), findsWidgets);
      await _tap(tester, _row("d-2"));
      await _tap(tester, find.byKey(const Key("which_card_done")));
      expect(find.text("Master Zorgmanagement"), findsNothing);
      expect(find.text("HBO Verpleegkunde"), findsOneWidget);
    });

    testWidgets("a card in two sets says so", (tester) async {
      await _open(tester, tweesets(), "change_pick_0");
      expect(find.byKey(const Key("which_card_linked")), findsOneWidget);
    });
  });

  group("Welke combinatie deel je?", () {
    testWidgets("complete first, the incomplete one to add", (tester) async {
      await _open(tester, opties(), "change_combination_0");
      expect(find.text("Welke combinatie deel je?"), findsWidgets);
      final ys = [
        for (final o in [0, 1, 2])
          tester.getTopLeft(find.byKey(Key("combination_option_$o"))).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(find.text("Nog toevoegen: Rijbewijs"), findsOneWidget);
      expect(find.byKey(const Key("combination_add_2")), findsOneWidget);
      await _tap(tester, find.byKey(const Key("combination_option_1")));
      await _tap(tester, find.byKey(const Key("combination_choose")));
      expect(find.byKey(const Key("which_combination_sheet")), findsNothing);
      expect(find.byKey(const Key("change_slot_0_personal")), findsOneWidget);
    });

    testWidgets("optional: Niet delen", (tester) async {
      await _open(tester, stressopt(), "change_optional_link_1");
      expect(find.byKey(const Key("combination_nothing")), findsOneWidget);
      await _tap(tester, find.byKey(const Key("combination_option_0")));
      await _tap(tester, find.byKey(const Key("combination_choose")));
      expect(find.byKey(const Key("change_optional_off_1")), findsOneWidget);
    });
  });
}
