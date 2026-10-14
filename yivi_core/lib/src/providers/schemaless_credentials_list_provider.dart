import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_preferences.dart";
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

enum NewItemPolicy { append, prepend }

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
  List<String> _order = const []; // persisted order of instance hashes
  final NewItemPolicy _policy = .prepend;

  @override
  Future<List<schemaless.Credential>> build() async {
    ref.keepAlive();

    final orderRepo = ref.read(credentialOrderRepoProvider);
    final repo = ref.read(irmaRepositoryProvider);

    // Cancel any previous subscription (in case build() is called again).
    _subscription?.cancel();

    // Seed from the current stream value.
    final initial = await repo.getSchemalessCredentials().first;
    _order = await orderRepo.loadOrder();
    if (_order.isEmpty) {
      _order = migrateTypeOrder(
        initial.credentials,
        await orderRepo.loadLegacyTypeOrder(),
      );
    }
    final merged = reconcileCardOrder(initial.credentials, _order, _policy);
    _order = merged.map((e) => e.hash).toList();
    await orderRepo.saveOrder(_order);

    // Subscribe for subsequent changes. skip(1) skips the BehaviorSubject
    // replay so we don't double-process the value we just seeded above.
    _subscription = repo
        .getSchemalessCredentials()
        .skip(1)
        .listen(_onCredentialsChanged);

    ref.onDispose(() {
      _subscription?.cancel();
      _debounce?.cancel();
    });

    return merged;
  }

  void _onCredentialsChanged(schemaless.SchemalessCredentials data) {
    final merged = reconcileCardOrder(data.credentials, _order, _policy);
    _order = merged.map((e) => e.hash).toList();

    if (ref.mounted) {
      state = AsyncData(merged);
    }
    _debouncedSave(merged);
  }

  /// User reorders visible items. [newIndex] is the destination *after* the item
  /// at [oldIndex] has been taken out, which is what `onReorderItem` reports —
  /// so no downward-move adjustment here.
  void reorder(int oldIndex, int newIndex) {
    final current = state.requireValue.toList();
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    state = AsyncData(current);
    _order = current.map((e) => e.hash).toList();
    _debouncedSave(current);
  }

  void _debouncedSave(List<schemaless.Credential> items) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!ref.mounted) return;
      await ref
          .read(credentialOrderRepoProvider)
          .saveOrder(items.map((e) => e.hash).toList());
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

/// Merge logic:
/// - keep cards in stored order if they still exist
/// - add any new cards at end/start (policy)
List<schemaless.Credential> reconcileCardOrder(
  List<schemaless.Credential> external,
  List<String> storedOrder,
  NewItemPolicy newItemPolicy,
) {
  final byHash = {for (final it in external) it.hash: it};
  final visible = <schemaless.Credential>[];

  // 1) Keep items that still exist in the stored order
  for (final hash in storedOrder) {
    final it = byHash.remove(hash);
    if (it != null) visible.add(it);
  }

  // 2) Any remaining are new from external
  final newOnes = byHash.values.toList();
  if (newOnes.isEmpty) return visible;

  if (newItemPolicy == .append) {
    visible.addAll(newOnes);
  } else {
    visible.insertAll(0, newOnes);
  }
  return visible;
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
