import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/providers/last_shared_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/session/disclosure/add_picker_page.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_keys.dart";
import "package:yivi_core/src/screens/session/models/disclosure_plan_view.dart";

import "disclosure_fixtures.dart";
import "support/test_app.dart";

const _id = 5;

SessionState _session(
  DisclosurePlan plan, {
  SessionType type = SessionType.disclosure,
  Credential? wrong,
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
  disclosurePlan: DisclosurePlan(
    choices: plan.choices,
    wrongCredentialIssued: wrong,
  ),
);

class _Run {
  final StreamController<SessionState> states;
  final closes = <void>[];
  _Run(this.states);

  void emit(SessionState s) => states.add(s);
}

/// The flow of [first] in Dutch, its later states sent with [_Run.emit].
Future<_Run> _pump(
  WidgetTester tester,
  SessionState first, {
  List<Credential> wallet = const [],
  Size size = const Size(390, 844),
}) async {
  final states = StreamController<SessionState>.broadcast();
  addTearDown(states.close);
  final run = _Run(states);
  var latest = first;
  await pumpTestApp(
    tester,
    StreamBuilder<SessionState>(
      stream: states.stream,
      initialData: first,
      builder: (context, snap) => DisclosureFlow(
        session: snap.data!,
        onDismiss: () {},
        onClose: () => run.closes.add(null),
        onShare: (_, _) {},
      ),
    ),
    size: size,
    locale: const Locale("nl", "NL"),
    overrides: [
      sessionStateProvider(_id).overrideWith((ref) async* {
        yield latest;
        await for (final s in states.stream) {
          latest = s;
          yield s;
        }
      }),
      walletCardsProvider.overrideWithValue(wallet),
      sharesOfProvider(_id).overrideWith(
        (ref) =>
            (_) => LastShared.never,
      ),
    ],
  );
  await tester.pumpAndSettle();
  return run;
}

Finder _row(int i) => find.byKey(Key("add_step_row_$i"));
Finder _inRow(int i, String text) =>
    find.descendant(of: _row(i), matching: find.text(text));

void main() {
  group("the add step", () {
    testWidgets("one card missing: its row and the button", (tester) async {
      await _pump(tester, _session(ontbreekt()));
      expect(find.byKey(DisclosureKeys.addStep), findsOneWidget);
      expect(find.text("Voeg eerst een kaartje toe"), findsOneWidget);
      expect(_inRow(1, "E-mailadres"), findsWidgets);
      expect(_inRow(1, "Yivi"), findsOneWidget);
      expect(
        find.text("Nog één kaartje, dan zie je wat je deelt"),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel("E-mailadres toevoegen"), findsOneWidget);
      // The row of a choice that was fine is not there.
      expect(_row(0), findsNothing);
    });

    testWidgets("one of several cards", (tester) async {
      await _pump(tester, _session(hotel()));
      expect(
        _inRow(0, "Paspoort, Identiteitskaart of Rijbewijs"),
        findsOneWidget,
      );
      expect(_inRow(0, "Eén is genoeg. Kies er één."), findsOneWidget);
      expect(find.text("Kies wat je toevoegt"), findsOneWidget);
    });

    testWidgets("two rows: the count as a word", (tester) async {
      await _pump(tester, _session(gemeente()));
      expect(find.text("Voeg eerst twee kaartjes toe"), findsOneWidget);
      expect(
        find.text("Nog twee kaartjes, dan zie je wat je deelt"),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel("Persoonsgegevens toevoegen"),
        findsOneWidget,
      );
    });

    testWidgets("a set with part in the app", (tester) async {
      await _pump(tester, _session(set()));
      expect(find.text("Voeg eerst toe wat nog ontbreekt"), findsOneWidget);
      expect(_inRow(0, "Persoonsgegevens + Adres"), findsOneWidget);
      expect(_inRow(0, "Horen bij elkaar · 1 van 2 in je app"), findsOneWidget);
      expect(find.text("Adres toevoegen"), findsOneWidget);
      expect(
        find.text("Nog één ding, dan zie je wat je deelt"),
        findsOneWidget,
      );
    });

    testWidgets("ways of several cards: the choice of three", (tester) async {
      await _pump(tester, _session(optiesleeg()));
      expect(_inRow(0, "Kies uit drie mogelijkheden"), findsOneWidget);
      expect(
        _inRow(0, "Persoonsgegevens · Paspoort + Adres · Rijbewijs + Adres"),
        findsOneWidget,
      );
    });

    testWidgets("an expired card: say so, add again", (tester) async {
      await _pump(
        tester,
        _session(
          plan([
            one(
              slot(passport, [
                card(passport, doc, reason: UnusableReason.expired),
              ]),
            ),
          ]),
        ),
      );
      expect(_inRow(0, "Verlopen. Voeg het opnieuw toe."), findsOneWidget);
      expect(
        find.bySemanticsLabel("Paspoort opnieuw toevoegen"),
        findsOneWidget,
      );
    });

    testWidgets("revoked, one of several ways", (tester) async {
      await _pump(tester, _session(verlopen()));
      expect(
        _inRow(0, "Paspoort is verlopen. Kies er één om toe te voegen."),
        findsOneWidget,
      );
    });

    testWidgets("a revoked card one can add again", (tester) async {
      await _pump(tester, _session(ingetrokken()));
      expect(_inRow(0, "Ingetrokken. Voeg het opnieuw toe."), findsOneWidget);
      expect(
        find.bySemanticsLabel("Persoonsgegevens opnieuw toevoegen"),
        findsOneWidget,
      );
    });

    testWidgets("a value is asked: the blue tag", (tester) async {
      await _pump(tester, _session(speelhal()));
      expect(find.text("Gevraagd: Ouder dan 18 Ja"), findsOneWidget);
    });

    testWidgets("several allowed values", (tester) async {
      await _pump(tester, _session(waarden()));
      expect(find.text("Gevraagd: Land NL, BE of LU"), findsOneWidget);
    });

    testWidgets("more than three allowed values", (tester) async {
      await _pump(tester, _session(waardenveel()));
      expect(
        find.text(
          "Gevraagd: Provincie Gelderland, Overijssel, Flevoland of nog vier "
          "andere",
        ),
        findsOneWidget,
      );
    });

    testWidgets("another value in the app: two facts, fetch again", (
      tester,
    ) async {
      await _pump(tester, _session(parkeren()), wallet: parkerenWallet());
      expect(find.text("In je app staat iets anders"), findsOneWidget);
      expect(_inRow(0, "In je app: Woonplaats Utrecht"), findsOneWidget);
      expect(_inRow(0, "Gevraagd: Woonplaats Rijnstad"), findsOneWidget);
      expect(find.byKey(DisclosureKeys.addStepHelp), findsOneWidget);
      expect(find.bySemanticsLabel("Adres opnieuw ophalen"), findsOneWidget);
      expect(find.textContaining("telt niet mee"), findsNothing);
    });

    testWidgets("a card of another kind was added: one line", (tester) async {
      await _pump(tester, _session(ontbreekt(), wrong: walletCard(phone, tel)));
      expect(
        find.text(
          "Mobiel telefoonnummer staat nu in je app, maar is niet wat "
          "Webshop vraagt.",
        ),
        findsOneWidget,
      );
    });
  });

  group("a card Yivi cannot add", () {
    testWidgets("only what stops it, and Sluiten closes", (tester) async {
      // An e-mail address could be added, but nobody adds cards for a
      // request that cannot be finished.
      final run = await _pump(
        tester,
        _session(
          plan([one(slot(email, [], asks: mail1)), kanniet().choices[1]]),
        ),
      );
      expect(find.text("Dit kun je nu niet delen"), findsOneWidget);
      expect(_row(0), findsNothing);
      expect(_row(1), findsOneWidget);
      expect(
        find.text(
          "Kan niet in Yivi worden toegevoegd. Haal het eerst bij "
          "Hogeschool Rijnstad.",
        ),
        findsOneWidget,
      );
      expect(find.text("Je deelt niets"), findsOneWidget);
      await tester.tap(find.text("Sluiten"));
      expect(run.closes, hasLength(1));
    });

    testWidgets("revoked and cannot be renewed", (tester) async {
      await _pump(tester, _session(nietvernieuwen()));
      expect(
        find.text(
          "Ingetrokken. Yivi kan dit kaartje niet vernieuwen. Vraag "
          "Hogeschool Rijnstad om een nieuw kaartje.",
        ),
        findsOneWidget,
      );
    });

    testWidgets("signing", (tester) async {
      await _pump(tester, _session(kanniet(), type: SessionType.signature));
      expect(find.text("Dit kun je nu niet ondertekenen"), findsOneWidget);
      expect(find.text("Je ondertekent niets"), findsOneWidget);
    });
  });

  group("after adding", () {
    testWidgets("the row stays, done; the step waits for the button", (
      tester,
    ) async {
      final run = await _pump(tester, _session(ontbreekt()));
      run.emit(
        _session(
          plan([
            one(slot(personal, [card(personal, id3.sublist(0, 2))])),
            one(slot(email, [card(email, mail1, hash: "e-new")])),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("add_step_done_1")), findsOneWidget);
      expect(find.text("Staat nu in je app"), findsOneWidget);
      expect(find.text("Alles is toegevoegd"), findsOneWidget);
      expect(find.text("Alles staat in je app"), findsOneWidget);
      expect(find.byKey(DisclosureKeys.addStep), findsOneWidget);

      await tester.tap(find.text("Bekijk wat je deelt"));
      await tester.pumpAndSettle();
      expect(find.byKey(DisclosureKeys.addStep), findsNothing);
      expect(find.byKey(DisclosureKeys.overview), findsOneWidget);
      expect(find.text("sanne@example.nl"), findsOneWidget);
    });

    testWidgets("nothing missing: straight to the overview", (tester) async {
      await _pump(tester, _session(eenvoudig()));
      expect(find.byKey(DisclosureKeys.addStep), findsNothing);
      expect(find.byKey(DisclosureKeys.overview), findsOneWidget);
    });
  });

  group("Kies wat je toevoegt", () {
    testWidgets("one row per way, nearest first", (tester) async {
      await _pump(tester, _session(afmaken()));
      await tester.tap(find.text("Kies wat je toevoegt"));
      await tester.pumpAndSettle();
      expect(find.byKey(DisclosureKeys.addPicker), findsOneWidget);
      final rows = [
        for (final o in [0, 1])
          tester.getTopLeft(find.byKey(DisclosureKeys.addPickerRow(o))).dy,
      ];
      expect(rows[0], lessThan(rows[1]));
      expect(
        find.descendant(
          of: find.byKey(DisclosureKeys.addPickerRow(0)),
          matching: find.text("Samen met E-mailadres uit je app"),
        ),
        findsOneWidget,
      );
    });

    testWidgets("a way leads on to adding it, in the same sheet", (
      tester,
    ) async {
      await _pump(tester, _session(hotel()));
      await tester.tap(_row(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DisclosureKeys.addPickerRow(1)));
      await tester.pumpAndSettle();
      expect(find.text("Identiteitskaart toevoegen"), findsWidgets);
    });

    testWidgets("one way: the sheet opens on the card", (tester) async {
      await _pump(tester, _session(ontbreekt()));
      await tester.tap(find.bySemanticsLabel("E-mailadres toevoegen"));
      await tester.pumpAndSettle();
      expect(find.byKey(DisclosureKeys.addPicker), findsNothing);
      expect(find.byType(AddSheet), findsOneWidget);
    });
  });

  for (final (name, size) in [
    ("held sideways", const Size(874, 402)),
    ("on a tablet", const Size(1024, 1366)),
  ]) {
    testWidgets("$name: title and button in the panel, the rows beside", (
      tester,
    ) async {
      await _pump(tester, _session(gemeente()), size: size);
      final panel = find.byKey(DisclosureKeys.panel);
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.byKey(DisclosureKeys.next)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text("Voeg eerst twee kaartjes toe"),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(_row(0)).dx,
        greaterThan(tester.getTopRight(panel).dx),
      );
    });
  }
}
