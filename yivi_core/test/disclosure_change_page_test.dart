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

const _id = 8;

SessionState _session(
  DisclosurePlan plan, {
  SessionType type = SessionType.disclosure,
}) => SessionState(
  id: _id,
  protocol: "irma",
  type: type,
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

/// The flow of [state] in Dutch, opened on "Kies wat je deelt" through
/// [via] (the pile, or the hint).
Future<void> _pump(
  WidgetTester tester,
  SessionState state, {
  Key via = DisclosureKeys.pile,
}) async {
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
  await tester.tap(find.byKey(via));
  await tester.pumpAndSettle();
}

Finder _page = find.byKey(const Key("change_page"));
Finder _link(String key) => find.byKey(Key(key));
String _text(WidgetTester tester, String key) => tester
    .widget<Semantics>(
      find.descendant(of: _link(key), matching: find.byType(Semantics)).first,
    )
    .properties
    .label!;

void main() {
  testWidgets("its title, lead and a card per choice with its head", (
    tester,
  ) async {
    await _pump(tester, _session(drie()));
    expect(_page, findsOneWidget);
    expect(find.text("Kies wat je deelt"), findsWidgets);
    expect(find.text("Uit deze kaartjes komen je gegevens."), findsOneWidget);
    expect(find.text("DIT DEEL JE"), findsOneWidget);
    expect(find.byKey(const Key("change_card_0")), findsOneWidget);
    expect(find.byKey(const Key("change_card_1")), findsOneWidget);
    expect(find.text("Paspoort"), findsWidgets);
    expect(find.text("NX4R7K2P9"), findsOneWidget);
  });

  testWidgets("the links of small choices", (tester) async {
    await _pump(tester, _session(drie()));
    expect(_text(tester, "change_pick_0"), "Ander kaartje kiezen");
    expect(_text(tester, "change_pick_1"), "Ander e-mailadres kiezen");
  });

  testWidgets("de/het: Andere toetsinschrijving", (tester) async {
    await _pump(tester, _session(toets()));
    expect(
      _text(tester, "change_pick_slot_0_exam"),
      "Andere toetsinschrijving kiezen",
    );
    expect(_link("change_pick_slot_0_personal"), findsNothing);
    expect(_link("change_combination_0"), findsNothing);
  });

  testWidgets("a slot of several cards: Kies welke je deelt", (tester) async {
    await _pump(tester, _session(meerdere()));
    expect(_text(tester, "change_pick_0"), "Kies welke je deelt");
  });

  testWidgets("a big choice of several options: another combination", (
    tester,
  ) async {
    await _pump(tester, _session(opties()));
    expect(_text(tester, "change_combination_0"), "Andere combinatie kiezen");
    expect(find.byKey(const Key("change_slot_0_passport")), findsOneWidget);
    expect(find.byKey(const Key("change_slot_0_adr")), findsOneWidget);
  });

  testWidgets("one card nothing can replace: no link", (tester) async {
    await _pump(tester, _session(ontvangen()));
    expect(_link("change_pick_0"), findsNothing);
  });

  testWidgets("a card without values", (tester) async {
    await _pump(tester, _session(alleenkaartje()));
    expect(
      find.descendant(
        of: _page,
        matching: find.text("Alleen dat je dit kaartje hebt"),
      ),
      findsOneWidget,
    );
  });

  group("optional data", () {
    testWidgets("Ook delen shares it at once; Niet delen stops it", (
      tester,
    ) async {
      await _pump(tester, _session(rijbewijs()));
      expect(find.text("OPTIONEEL"), findsOneWidget);
      expect(_text(tester, "change_optional_link_1"), "Ook delen");
      await tester.tap(_link("change_optional_link_1"));
      await tester.pumpAndSettle();
      expect(find.text("06 12345678"), findsOneWidget);
      expect(_link("change_optional_off_1"), findsOneWidget);
      await tester.tap(_link("change_optional_off_1"));
      await tester.pumpAndSettle();
      expect(find.text("06 12345678"), findsNothing);
      expect(_link("change_optional_link_1"), findsOneWidget);
    });

    testWidgets("not in the app: add it", (tester) async {
      await _pump(
        tester,
        _session(nietsnodig()),
        via: DisclosureKeys.optionalHint,
      );
      expect(
        _text(tester, "change_optional_link_1"),
        "Mobiel telefoonnummer toevoegen",
      );
      expect(find.text("Nog niet in je app"), findsOneWidget);
    });

    testWidgets("several combinations", (tester) async {
      await _pump(tester, _session(stressopt()));
      expect(find.text("Twee mogelijkheden"), findsOneWidget);
      expect(_text(tester, "change_optional_link_1"), "Combinatie kiezen");
    });
  });

  testWidgets("Klaar returns to the overview", (tester) async {
    await _pump(tester, _session(drie()));
    await tester.tap(find.byKey(const Key("change_done")));
    await tester.pumpAndSettle();
    expect(_page, findsNothing);
    expect(find.byKey(DisclosureKeys.overview), findsOneWidget);
  });

  testWidgets("signing", (tester) async {
    await _pump(tester, _session(drie(), type: SessionType.signature));
    expect(find.text("Kies waarmee je ondertekent"), findsWidgets);
    expect(
      find.text("Met deze kaartjes onderteken je het bericht."),
      findsOneWidget,
    );
  });
}
