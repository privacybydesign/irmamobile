import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_preferences.dart";
import "../models/clear_all_data_event.dart";
import "../models/credential_events.dart";
import "../models/event.dart";
import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../util/instance_hint.dart";
import "irma_repository_provider.dart";
import "preferences_provider.dart";

abstract class OrderRepo {
  /// The saved card order, as instance hashes.
  Future<List<String>> loadOrder();

  /// The per-type order the data tab used before it listed instances, as
  /// credential type ids. Only read once, to seed the card order.
  Future<List<String>> loadLegacyTypeOrder();

  Future<void> saveOrder(List<String> hashes);
}

class IrmaPreferencesOrderRepo implements OrderRepo {
  final IrmaPreferences _prefs;

  IrmaPreferencesOrderRepo(this._prefs);

  @override
  Future<List<String>> loadOrder() async => _prefs.getCardOrder();

  @override
  Future<List<String>> loadLegacyTypeOrder() async =>
      _prefs.getCredentialOrder();

  @override
  Future<void> saveOrder(List<String> hashes) => _prefs.setCardOrder(hashes);
}

final credentialOrderRepoProvider = Provider<OrderRepo>(
  (ref) => IrmaPreferencesOrderRepo(ref.watch(preferencesProvider)),
);

/// ----- Controller: the user's cards (credential instances) in their order
///
/// Subscribes directly to the repository's credential stream instead of using
/// ref.watch/ref.listen on another Riverpod provider. This is necessary because
/// in Riverpod 3.x both ref.watch and ref.listen inside build() create
/// dependencies that cause build() to re-run, and keepAlive providers only
/// rebuild lazily (when next read). During issuance sessions no widget watches
/// this controller, so Riverpod would never trigger the rebuild and the order
/// would be stale. A direct stream subscription fires eagerly on every emission.
final schemalessCredentialOrderControllerProvider =
    AsyncNotifierProvider<
      SchemalessCredentialOrderController,
      List<schemaless.Credential>
    >(SchemalessCredentialOrderController.new);

class SchemalessCredentialOrderController
    extends AsyncNotifier<List<schemaless.Credential>> {
  Timer? _debounce;
  StreamSubscription<schemaless.SchemalessCredentials>? _subscription;
  StreamSubscription<Event>? _deletes;

  /// The persisted order of instance hashes. Also holds the cards missing
  /// from the latest list, so a card that drops out for a moment (its type
  /// not loaded yet, a failed read) comes back in its place. Only deleting
  /// a card forgets it.
  List<String> _order = const [];

  @override
  Future<List<schemaless.Credential>> build() async {
    ref.keepAlive();

    final orderRepo = ref.read(credentialOrderRepoProvider);
    final repo = ref.read(irmaRepositoryProvider);

    // Cancel any previous subscription (in case build() is called again).
    _subscription?.cancel();
    _deletes?.cancel();

    // Seed from the current stream value.
    final initial = await repo.getSchemalessCredentials().first;
    _order = await orderRepo.loadOrder();
    if (_order.isEmpty) {
      _order = migrateTypeOrder(
        initial.credentials,
        await orderRepo.loadLegacyTypeOrder(),
      );
    }
    final (:visible, :order) = reconcileCardOrder(initial.credentials, _order);
    _order = order;
    await orderRepo.saveOrder(_order);

    // Subscribe for subsequent changes. skip(1) skips the BehaviorSubject
    // replay so we don't double-process the value we just seeded above.
    _subscription = repo
        .getSchemalessCredentials()
        .skip(1)
        .listen(_onCredentialsChanged);
    _deletes = repo.getEvents().listen(_onEvent);

    ref.onDispose(() {
      _subscription?.cancel();
      _deletes?.cancel();
      _debounce?.cancel();
    });

    return visible;
  }

  void _onCredentialsChanged(schemaless.SchemalessCredentials data) {
    final (:visible, :order) = reconcileCardOrder(data.credentials, _order);
    _order = order;

    if (ref.mounted) {
      state = AsyncData(visible);
    }
    _debouncedSave();
  }

  /// A deleted card leaves the order: got again, it is new and goes on top.
  void _onEvent(Event event) {
    if (event is ClearAllDataEvent) {
      _order = const [];
    } else if (event is DeleteCredentialEvent) {
      final deleted = event.hashByFormat.values.toSet();
      final cards = {
        for (final c in state.value ?? const <schemaless.Credential>[])
          if (c.credentialInstanceIds.values.any(deleted.contains)) c.hash,
      };
      _order = [
        for (final hash in _order)
          if (!cards.contains(hash) && !deleted.contains(hash)) hash,
      ];
    } else {
      return;
    }
    _debouncedSave();
  }

  /// User reorders visible items. [newIndex] is the destination *after* the item
  /// at [oldIndex] has been taken out, which is what `onReorderItem` reports —
  /// so no downward-move adjustment here.
  void reorder(int oldIndex, int newIndex) {
    final current = state.requireValue.toList();
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    _applyOrder(current);
  }

  /// Like [reorder], for a list that shows only some of the credentials, such
  /// as one section of the data tab. [section] is that list in display order
  /// and the indices refer to it. The credentials outside it keep their place.
  void reorderWithin(
    List<schemaless.Credential> section,
    int oldIndex,
    int newIndex,
  ) {
    final reordered = [...section];
    reordered.insert(newIndex, reordered.removeAt(oldIndex));

    // The section's credentials take over the slots it already had.
    final ids = {for (final c in section) c.credentialId};
    var next = 0;
    _applyOrder([
      for (final c in state.requireValue)
        ids.contains(c.credentialId) ? reordered[next++] : c,
    ]);
  }

  void _applyOrder(List<schemaless.Credential> current) {
    state = AsyncData(current);
    // The shown cards take over the slots they had; missing ones keep theirs.
    final shown = {for (final c in current) c.hash};
    var next = 0;
    _order = [
      for (final hash in _order)
        shown.contains(hash) ? current[next++].hash : hash,
    ];
    _debouncedSave();
  }

  void _debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!ref.mounted) return;
      await ref.read(credentialOrderRepoProvider).saveOrder(_order);
    });
  }
}

/// Builds a card order from the old per-type order, so people keep the order
/// they had: each card takes its type's old position, cards of the same type
/// go oldest first, and types that were not in the old order go last.
List<String> migrateTypeOrder(
  List<schemaless.Credential> credentials,
  List<String> typeOrder,
) {
  if (typeOrder.isEmpty) return const [];
  final rank = {for (var i = 0; i < typeOrder.length; i++) typeOrder[i]: i};
  final sorted = [...credentials]
    ..sort((a, b) {
      final ra = rank[a.credentialId] ?? typeOrder.length;
      final rb = rank[b.credentialId] ?? typeOrder.length;
      if (ra != rb) return ra - rb;
      return (a.issuanceDate ?? 0).compareTo(b.issuanceDate ?? 0);
    });
  return sorted.map((c) => c.hash).toList();
}

/// The cards of [external] in [storedOrder], and the order to save.
///
/// Cards in the stored order keep their place. Cards it does not have yet go
/// on top, newest first. Hashes of cards missing from [external] stay in the
/// order to save, so a card that is missing for a moment comes back in its
/// place.
({List<schemaless.Credential> visible, List<String> order}) reconcileCardOrder(
  List<schemaless.Credential> external,
  List<String> storedOrder,
) {
  final byHash = {for (final it in external) it.hash: it};
  final stored = storedOrder.toSet();
  final newOnes =
      [
        for (final it in external)
          if (!stored.contains(it.hash)) it,
      ]..sort((a, b) {
        final byDate = (b.issuanceDate ?? 0).compareTo(a.issuanceDate ?? 0);
        return byDate != 0 ? byDate : a.hash.compareTo(b.hash);
      });
  final order = [
    for (final it in newOnes) it.hash,
    // Without duplicates, should the stored order hold any.
    ...stored,
  ];
  return (
    visible: [
      for (final hash in order)
        ?byHash[hash],
    ],
    order: order,
  );
}

/// The instance hint of every card, by hash, worked out over all the cards
/// the user holds (see [instanceHintFor]).
final instanceHintsProvider = Provider<Map<String, InstanceHint>>((ref) {
  final cards =
      ref.watch(schemalessCredentialOrderControllerProvider).value ?? const [];
  return {for (final c in cards) c.hash: instanceHintFor(c, cards)};
});

/// How the data tab shows the cards.
enum WalletView { stack, list, grid }

final walletViewProvider = NotifierProvider<WalletViewController, WalletView?>(
  WalletViewController.new,
);

/// The view the user picked, or null for the default of the screen size.
class WalletViewController extends Notifier<WalletView?> {
  @override
  WalletView? build() {
    final saved = ref.read(preferencesProvider).getWalletViewNow();
    return WalletView.values.where((v) => v.name == saved).firstOrNull;
  }

  void set(WalletView view) {
    state = view;
    ref.read(preferencesProvider).setWalletView(view.name);
  }
}
