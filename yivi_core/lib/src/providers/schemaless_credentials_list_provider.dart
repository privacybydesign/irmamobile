import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_preferences.dart";
import "../models/schemaless/schemaless_events.dart" as schemaless;
import "irma_repository_provider.dart";
import "preferences_provider.dart";

abstract class OrderRepo {
  Future<List<String>> loadOrder();
  Future<void> saveOrder(List<String> ids);
}

class IrmaPreferencesOrderRepo implements OrderRepo {
  final IrmaPreferences _prefs;

  IrmaPreferencesOrderRepo(this._prefs);

  @override
  Future<List<String>> loadOrder() async {
    return _prefs.getCredentialOrder();
  }

  @override
  Future<void> saveOrder(List<String> ids) {
    return _prefs.setCredentialOrder(ids);
  }
}

final credentialOrderRepoProvider = Provider(
  (ref) => IrmaPreferencesOrderRepo(ref.watch(preferencesProvider)),
);

enum NewItemPolicy { append, prepend }

/// ----- Controller: reconciles external items with stored order
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
  StreamSubscription<List<schemaless.Credential>>? _subscription;
  List<String> _order = const []; // persisted order of IDs
  final NewItemPolicy _policy = .prepend;

  @override
  Future<List<schemaless.Credential>> build() async {
    ref.keepAlive();

    _order = await ref.read(credentialOrderRepoProvider).loadOrder();

    final repo = ref.read(irmaRepositoryProvider);

    // Cancel any previous subscription (in case build() is called again).
    _subscription?.cancel();

    // Seed from the current stream value.
    final initial = await repo.getSchemalessCredentials().first;
    final initialTypes = _deduplicateByType(initial);
    final merged = _reconcile(initialTypes, _order, _policy);
    _order = merged.map((e) => e.credentialId).toList();
    await ref.read(credentialOrderRepoProvider).saveOrder(_order);

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

  void _onCredentialsChanged(List<schemaless.Credential> allCredentials) {
    final types = _deduplicateByType(allCredentials);
    final merged = _reconcile(types, _order, _policy);
    _order = merged.map((e) => e.credentialId).toList();

    if (ref.mounted) {
      state = AsyncData(merged);
    }
    _debouncedSave(merged);
  }

  /// User reorders visible items
  void reorder(int oldIndex, int newIndex) {
    final current = state.requireValue.toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    state = AsyncData(current);
    _order = current.map((e) => e.credentialId).toList();
    _debouncedSave(current);
  }

  /// Deduplicate credentials by type ID, keeping first occurrence.
  List<schemaless.Credential> _deduplicateByType(
    List<schemaless.Credential> credentials,
  ) {
    final Set<String> seenIds = {};
    final List<schemaless.Credential> result = [];
    for (final info in credentials) {
      if (!seenIds.contains(info.credentialId)) {
        result.add(info);
        seenIds.add(info.credentialId);
      }
    }
    return result;
  }

  /// Merge logic:
  /// - keep IDs in stored order if they still exist
  /// - add any new external IDs at end/start (policy)
  List<schemaless.Credential> _reconcile(
    List<schemaless.Credential> external,
    List<String> storedOrder,
    NewItemPolicy newItemPolicy,
  ) {
    final byId = {for (final it in external) it.credentialId: it};
    final visible = <schemaless.Credential>[];

    // 1) Keep items that still exist in the stored order
    for (final id in storedOrder) {
      final it = byId.remove(id);
      if (it != null) visible.add(it);
    }

    // 2) Any remaining are new from external
    final newOnes = byId.values.toList();
    if (newOnes.isEmpty) return visible;

    if (newItemPolicy == .append) {
      visible.addAll(newOnes);
    } else {
      visible.insertAll(0, newOnes);
    }
    return visible;
  }

  void _debouncedSave(List<schemaless.Credential> items) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!ref.mounted) return;
      await ref
          .read(credentialOrderRepoProvider)
          .saveOrder(items.map((e) => e.credentialId).toList());
    });
  }
}
