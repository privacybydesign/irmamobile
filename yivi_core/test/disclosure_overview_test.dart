import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/providers/last_shared_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/providers/session_user_choices_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_keys.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_overview_page.dart";
import "package:yivi_core/src/screens/session/models/disclosure_plan_view.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_photo.dart";

import "disclosure_fixtures.dart";
import "support/test_app.dart";

const _id = 3;

SessionState _session(
  DisclosurePlan plan, {
  SessionType type = SessionType.disclosure,
  bool verified = true,
  String? message,
  List<Credential>? offered,
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
    verified: verified,
  ),
  disclosurePlan: plan,
  messageToSign: message,
  offeredCredentials: offered,
);

class _Spy {
  final shares =
      <(List<ChoiceSelection>, List<SelectableCredentialInstance>)>[];
  final changes = <int?>[];
}

/// The overview of [state] in Dutch, on a phone.
Future<_Spy> _pump(
  WidgetTester tester,
  SessionState state, {
  DisclosureSelection? selection,
}) async {
  final spy = _Spy();
  await pumpTestApp(
    tester,
    DisclosureOverviewPage(
      session: state,
      onDismiss: () {},
      onClose: () {},
      onShare: (c, s) => spy.shares.add((c, s)),
      onChange: spy.changes.add,
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
  if (selection != null) {
    final n = ProviderScope.containerOf(
      tester.element(find.byType(DisclosureOverviewPage)),
    ).read(disclosureSelectionProvider(_id).notifier);
    for (final MapEntry(:key, :value) in selection.option.entries) {
      n.chooseOption(key, value);
    }
    for (final MapEntry(:key, :value) in selection.cards.entries) {
      n.chooseCards(key, value);
    }
    for (final i in selection.optionalOn) {
      n.share(i, on: true);
    }
  }
  await tester.pumpAndSettle();
  return spy;
}

Finder _inValues(String text) => find.descendant(
  of: find.byKey(DisclosureKeys.values),
  matching: find.text(text),
);

void main() {
  testWidgets("one list of names and values, no card names", (tester) async {
    await _pump(tester, _session(drie()));

    expect(find.text("Je deelt gegevens met"), findsOneWidget);
    expect(find.text("DIT DEEL JE"), findsOneWidget);
    expect(_inValues("Documentnummer"), findsOneWidget);
    expect(_inValues("NX4R7K2P9"), findsOneWidget);
    expect(_inValues("E-mailadres"), findsOneWidget);
    expect(_inValues("Paspoort"), findsNothing);
    expect(find.text("Uit twee kaartjes in je app"), findsOneWidget);
    expect(find.text("Wijzig"), findsOneWidget);
  });

  testWidgets("the pile opens the change page", (tester) async {
    final spy = await _pump(tester, _session(drie()));
    await tester.tap(find.byKey(DisclosureKeys.pile));
    expect(spy.changes, [null]);
  });

  testWidgets("nothing to change: Bekijk", (tester) async {
    await _pump(tester, _session(ontvangen()));
    expect(find.text("Uit 1 kaartje in je app"), findsOneWidget);
    expect(find.text("Bekijk"), findsOneWidget);
  });

  testWidgets("a multiple slot is a block per card", (tester) async {
    await _pump(tester, _session(meerdere()));
    expect(find.text("HBO Verpleegkunde"), findsOneWidget);
    expect(find.text("Master Zorgmanagement"), findsOneWidget);
    expect(find.text("MBO Verzorgende IG"), findsOneWidget);
    expect(find.text("Uit vier kaartjes in je app"), findsOneWidget);
  });

  testWidgets("one query in two sets: its values once", (tester) async {
    await _pump(tester, _session(tweesets()));
    expect(find.text("sanne@example.nl"), findsOneWidget);
    expect(find.text("Uit twee kaartjes in je app"), findsOneWidget);
  });

  testWidgets("a card without values: one row", (tester) async {
    await _pump(tester, _session(alleenkaartje()));
    expect(_inValues("Studiegegevens"), findsOneWidget);
    expect(find.text("Alleen dat je dit kaartje hebt"), findsOneWidget);
  });

  group("optional data", () {
    testWidgets("not shared: the hint, which opens the change page", (
      tester,
    ) async {
      final spy = await _pump(tester, _session(hotel()));
      expect(find.text("06 12345678"), findsNothing);
      expect(
        find.text("Je kunt nog één ding delen als je wil"),
        findsOneWidget,
      );
      await tester.tap(find.byKey(DisclosureKeys.optionalHint));
      expect(spy.changes, [2]);
    });

    testWidgets("shared: its own card with the chip, counted in the pile", (
      tester,
    ) async {
      await _pump(
        tester,
        _session(rijbewijs()),
        selection: const DisclosureSelection(optionalOn: {1}),
      );
      expect(find.byKey(DisclosureKeys.optionalCard(1)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(DisclosureKeys.optionalCard(1)),
          matching: find.text("Niet verplicht"),
        ),
        findsOneWidget,
      );
      expect(find.text("Uit twee kaartjes in je app"), findsOneWidget);
      expect(find.byKey(DisclosureKeys.optionalHint), findsNothing);
    });

    testWidgets("two not shared: nog twee dingen", (tester) async {
      await _pump(tester, _session(nietsnodig()));
      expect(
        find.text("Je kunt nog twee dingen delen als je wil"),
        findsOneWidget,
      );
    });
  });

  group("nothing required", () {
    testWidgets("its title and lead, no list, no pile", (tester) async {
      final spy = await _pump(tester, _session(nietsnodig()));
      expect(find.text("Wil je gegevens delen met"), findsOneWidget);
      expect(find.text("Niets is verplicht."), findsOneWidget);
      expect(find.byKey(DisclosureKeys.values), findsNothing);
      expect(find.byKey(DisclosureKeys.pile), findsNothing);
      expect(find.text("Doorgaan zonder te delen"), findsOneWidget);
      await tester.tap(find.text("Doorgaan zonder te delen"));
      expect(spy.shares.single.$1.map((c) => c.option), [-1, -1]);
    });

    testWidgets("once something is chosen: Delen", (tester) async {
      await _pump(
        tester,
        _session(nietsnodig()),
        selection: const DisclosureSelection(optionalOn: {0}),
      );
      expect(find.text("sanne@example.nl"), findsOneWidget);
      expect(find.byKey(DisclosureKeys.pile), findsOneWidget);
      expect(find.text("Delen"), findsOneWidget);
    });
  });

  testWidgets("Delen sends the answer and the cards", (tester) async {
    final spy = await _pump(tester, _session(eenvoudig()));
    await tester.tap(find.text("Delen"));
    final (choices, cards) = spy.shares.single;
    expect(
      choices.single.slots.single.credentials.single.credentialHash,
      "e-1",
    );
    expect(cards.map((c) => c.hash), ["e-1"]);
  });

  testWidgets("signing: the message and Ondertekenen", (tester) async {
    await _pump(
      tester,
      _session(eenvoudig(), type: SessionType.signature, message: "Akkoord"),
    );
    expect(find.text("Je ondertekent een bericht voor"), findsOneWidget);
    expect(find.text("HET BERICHT"), findsOneWidget);
    expect(find.text("DIT ZET JE ERONDER"), findsOneWidget);
    expect(find.text("Ondertekenen"), findsWidgets);
  });

  testWidgets("share and receive", (tester) async {
    await _pump(
      tester,
      _session(
        ontvangen(),
        offered: [
          walletCard(study, [("Opleiding", "Bachelor")]),
        ],
      ),
    );
    await tester.scrollUntilVisible(
      find.text("DIT KRIJG JE TERUG"),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("DIT KRIJG JE TERUG"), findsOneWidget);
    expect(find.text("Delen en ontvangen"), findsOneWidget);
  });

  group("kept values", () {
    testWidgets("a marker on each, and the card naming them", (tester) async {
      await _pump(tester, _session(bewaren()));
      expect(find.byKey(const Key("value_kept")), findsNWidgets(2));
      expect(find.byKey(DisclosureKeys.keepCard), findsOneWidget);
      expect(find.text("Webshop bewaart"), findsOneWidget);
      expect(find.text("Achternaam en Documentnummer"), findsOneWidget);
    });

    testWidgets("optional values only while shared", (tester) async {
      await _pump(
        tester,
        _session(bewaren()),
        selection: const DisclosureSelection(optionalOn: {1}),
      );
      expect(
        find.text("Achternaam, Documentnummer en Mobiel telefoonnummer"),
        findsOneWidget,
      );
    });

    testWidgets("none kept: no card", (tester) async {
      await _pump(tester, _session(eenvoudig()));
      expect(find.byKey(DisclosureKeys.keepCard), findsNothing);
    });
  });

  group("an unknown requestor", () {
    testWidgets("the reason, Toch delen, and the dialog first", (tester) async {
      final spy = await _pump(tester, _session(eenvoudig(), verified: false));
      expect(find.byKey(DisclosureKeys.trustWash), findsOneWidget);
      expect(find.text("Deel alleen als je Webshop vertrouwt"), findsOneWidget);
      await tester.tap(find.text("Toch delen"));
      await tester.pumpAndSettle();
      expect(spy.shares, isEmpty);
      expect(
        find.text("Delen met een partij die Yivi niet kent?"),
        findsOneWidget,
      );
      await tester.tap(find.byKey(DisclosureKeys.anywayCancel));
      await tester.pumpAndSettle();
      expect(spy.shares, isEmpty);

      await tester.tap(find.text("Toch delen"));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DisclosureKeys.anywayConfirm));
      await tester.pumpAndSettle();
      expect(spy.shares, hasLength(1));
    });
  });

  group("the value list", () {
    testWidgets("nested values fold on the overview", (tester) async {
      await _pump(tester, _session(genest()));
      expect(find.text("Lindelaan 12"), findsOneWidget);
      await tester.tap(find.text("Adres"));
      await tester.pumpAndSettle();
      expect(find.text("Lindelaan 12"), findsNothing);
      expect(find.text("Lindelaan 12, NL"), findsOneWidget);
    });

    testWidgets("a list of two items: their places", (tester) async {
      await _pump(tester, _session(diepgenest()));
      // Two distinct cards of one slot: the first is shared; its one
      // faculty has no header.
      expect(find.text("1 van 1"), findsNothing);
      expect(find.text("Techniek"), findsOneWidget);
    });

    testWidgets("an image: the small picture", (tester) async {
      const png =
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";
      await _pump(
        tester,
        _session(
          plan([
            one(
              slot(passport, [
                card(
                  passport,
                  const [],
                  hash: "pp-1",
                  raw: [
                    Attribute(
                      claimPath: const ["photo"],
                      displayName: "Pasfoto",
                      value: AttributeValue(
                        type: AttributeType.base64Image,
                        base64Image: png,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ]),
        ),
      );
      expect(find.text("Pasfoto"), findsOneWidget);
      expect(find.byType(AttributePhoto), findsOneWidget);
    });

    testWidgets("driving licence categories: the table", (tester) async {
      await _pump(
        tester,
        _session(
          plan([
            one(
              slot(driving, [
                card(
                  driving,
                  const [],
                  hash: "dr-1",
                  credentialId: "pbdf-staging.pbdf.drivinglicence",
                  raw: [
                    Attribute(
                      claimPath: const ["categoryB"],
                      displayName: "Categorie B",
                      value: AttributeValue(
                        type: AttributeType.boolean,
                        boolValue: true,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ]),
        ),
      );
      expect(find.text("B"), findsOneWidget);
      expect(
        find.byKey(const Key("driving_licence_categories_divider")),
        findsNothing,
      );
    });
  });
}
