import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/providers/last_shared_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/providers/session_user_choices_provider.dart";

import "disclosure_fixtures.dart";

const _id = 7;

SessionState _session(DisclosurePlan plan) => SessionState(
  id: _id,
  protocol: "irma",
  type: SessionType.disclosure,
  status: SessionStatus.requestPermission,
  requestor: party("Verifier"),
  disclosurePlan: plan,
);

/// [ontbreekt] after the email card was issued.
DisclosurePlan _withEmail() => plan([
  one(slot(personal, [card(personal, id3.sublist(0, 2), hash: "pg-1")])),
  one(slot(email, [card(email, mail1, hash: "e-new")])),
]);

void main() {
  late StreamController<SessionState> sessions;
  late ProviderContainer container;

  setUp(() {
    sessions = StreamController<SessionState>();
    container = ProviderContainer(
      overrides: [
        sessionStateProvider(_id).overrideWith((ref) => sessions.stream),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    sessions.close();
  });

  Future<void> emit(DisclosurePlan p) async {
    sessions.add(_session(p));
    await Future<void>.delayed(Duration.zero);
  }

  test("the add step's rows are fixed from the first plan", () async {
    container.listen(fixedChoicesProvider(_id), (_, _) {});
    expect(container.read(fixedChoicesProvider(_id)), isNull);
    await emit(ontbreekt());
    expect(container.read(fixedChoicesProvider(_id)), [1]);
    await emit(_withEmail());
    expect(container.read(fixedChoicesProvider(_id)), [1]);
  });

  test("a card issued while the request waits is picked", () async {
    container.listen(disclosureSelectionProvider(_id), (_, _) {});
    await emit(ontbreekt());
    expect(container.read(disclosureSelectionProvider(_id)).cards, isEmpty);
    await emit(_withEmail());
    expect(container.read(disclosureSelectionProvider(_id)).cards, {
      "email": ["e-new"],
    });
  });

  test("an issued optional card is switched on, with its option", () async {
    container.listen(disclosureSelectionProvider(_id), (_, _) {});
    await emit(nietsnodig());
    await emit(
      plan([
        one(slot(email, [card(email, mail1, hash: "e-1")]), opt: true),
        one(slot(phone, [card(phone, tel, hash: "t-new")]), opt: true),
      ]),
    );
    final s = container.read(disclosureSelectionProvider(_id));
    expect(s.optionalOn, {1});
    expect(s.option, {1: 0});
  });

  test("the chosen cards follow the plan and the selection", () async {
    container.listen(chosenProvider(_id), (_, _) {});
    expect(container.read(chosenProvider(_id)), isNull);
    await emit(keuze());
    container
        .read(disclosureSelectionProvider(_id).notifier)
        .chooseOption(0, 1);
    expect(container.read(chosenProvider(_id))!.option, [1, 0]);
  });

  group("last shared", () {
    final verifier = party("Verifier");

    test("newest first: with this requestor, and with anyone", () {
      final last = lastSharedOf([
        share("Other", DateTime(2026, 6, 1)),
        share("Verifier", DateTime(2026, 3, 1)),
        share("Verifier", DateTime(2026, 1, 1)),
      ], verifier);
      expect(last.withRequestor, DateTime(2026, 3, 1));
      expect(last.withAnyone, DateTime(2026, 6, 1));
    });

    test("never shared", () {
      final last = lastSharedOf(const [], verifier);
      expect(last.withRequestor, isNull);
      expect(last.withAnyone, isNull);
    });
  });
}
