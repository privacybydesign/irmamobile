import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rxdart/rxdart.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/clear_all_data_event.dart";
import "package:yivi_core/src/models/credential_events.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";

final _issuer = TrustedParty(
  id: "issuer",
  name: "Issuer",
  url: null,
  parent: null,
  verified: true,
);

/// A card named [name], issued at [issued] (seconds).
Credential _card(String name, {int issued = 0}) => Credential(
  credentialId: "type.$name",
  hash: name,
  name: name,
  issuer: _issuer,
  credentialInstanceIds: {CredentialFormat.sdjwtvc: "stored-$name"},
  batchInstanceCountsRemaining: const {},
  attributes: const [],
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
  issuanceDate: issued,
);

class _MemoryOrderRepo implements OrderRepo {
  List<String> saved;

  _MemoryOrderRepo(this.saved);

  @override
  Future<List<String>> loadOrder() async => saved;

  @override
  Future<List<String>> loadLegacyTypeOrder() async => const [];

  @override
  Future<void> saveOrder(List<String> hashes) async => saved = hashes;
}

class _FakeRepository extends Fake implements IrmaRepository {
  final cards = BehaviorSubject<SchemalessCredentials>();
  final events = PublishSubject<Event>();

  void emit(List<Credential> cards) =>
      this.cards.add((credentials: cards, problematic: const []));

  @override
  Stream<SchemalessCredentials> getSchemalessCredentials() => cards.stream;

  @override
  Stream<Event> getEvents() => events.stream;
}

List<String> _names(List<Credential> cards) => [for (final c in cards) c.name];

void main() {
  group("reconcileCardOrder", () {
    test("keeps the stored order", () {
      final r = reconcileCardOrder(
        [_card("a"), _card("b"), _card("c")],
        ["c", "a", "b"],
      );
      expect(_names(r.visible), ["c", "a", "b"]);
      expect(r.order, ["c", "a", "b"]);
    });

    test("new cards go on top, newest first, whatever order they come in", () {
      final cards = [
        _card("old", issued: 1),
        _card("x"),
        _card("newest", issued: 3),
        _card("mid", issued: 2),
      ];
      final r = reconcileCardOrder(cards, ["x"]);
      expect(_names(r.visible), ["newest", "mid", "old", "x"]);
      expect(
        _names(reconcileCardOrder(cards.reversed.toList(), ["x"]).visible),
        ["newest", "mid", "old", "x"],
      );
    });

    test("a missing card keeps its place in the order to save", () {
      final r = reconcileCardOrder([_card("a"), _card("c")], ["c", "b", "a"]);
      expect(_names(r.visible), ["c", "a"]);
      expect(r.order, ["c", "b", "a"]);

      // Back again: in its old place, not on top.
      final back = reconcileCardOrder([
        _card("a"),
        _card("b"),
        _card("c"),
      ], r.order);
      expect(_names(back.visible), ["c", "b", "a"]);
    });
  });

  group("the order controller", () {
    late _FakeRepository repo;
    late _MemoryOrderRepo orders;
    late ProviderContainer container;

    Future<List<String>> shown() async {
      await pumpEventQueue();
      return _names(
        await container.read(
          schemalessCredentialOrderControllerProvider.future,
        ),
      );
    }

    Future<void> start(List<Credential> cards, List<String> saved) async {
      repo = _FakeRepository()..emit(cards);
      orders = _MemoryOrderRepo(saved);
      container = ProviderContainer(
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          credentialOrderRepoProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      container.listen(schemalessCredentialOrderControllerProvider, (_, _) {});
      await shown();
    }

    /// Lets the debounced save run.
    Future<void> settle() => Future.delayed(const Duration(milliseconds: 450));

    test("a start with some cards missing does not lose their place", () async {
      // irmago's first list lacks "b" (say its read failed), the next has it.
      await start([_card("a"), _card("c")], ["c", "b", "a"]);
      expect(orders.saved, ["c", "b", "a"]);

      repo.emit([_card("a"), _card("b"), _card("c")]);
      expect(await shown(), ["c", "b", "a"]);
    });

    test("a deleted card is forgotten: got again, it goes on top", () async {
      await start([_card("a"), _card("b"), _card("c")], ["a", "b", "c"]);

      repo.events.add(
        DeleteCredentialEvent(
          hashByFormat: {CredentialFormat.sdjwtvc: "stored-b"},
        ),
      );
      repo.emit([_card("a"), _card("c")]);
      await settle();
      expect(orders.saved, ["a", "c"]);

      repo.emit([_card("a"), _card("b"), _card("c")]);
      expect(await shown(), ["b", "a", "c"]);
    });

    test("clearing all data forgets the order", () async {
      await start([_card("a"), _card("b")], ["b", "a"]);
      repo.events.add(ClearAllDataEvent());
      repo.emit(const []);
      await settle();
      expect(orders.saved, isEmpty);
    });

    test("dragging keeps the place of a missing card", () async {
      await start([_card("a"), _card("c")], ["a", "b", "c"]);
      container
          .read(schemalessCredentialOrderControllerProvider.notifier)
          .reorder(1, 0);
      expect(await shown(), ["c", "a"]);
      await settle();
      expect(orders.saved, ["c", "b", "a"]);
    });
  });
}
