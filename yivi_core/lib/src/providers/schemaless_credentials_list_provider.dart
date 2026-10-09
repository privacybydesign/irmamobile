import "dart:async";

import "package:flutter/foundation.dart";
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
  StreamSubscription<schemaless.SchemalessCredentials>? _subscription;
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
    final initialTypes = deduplicateCredentialsByType(initial.credentials);
    final merged = reconcileCredentialOrder(initialTypes, _order, _policy);
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

  void _onCredentialsChanged(schemaless.SchemalessCredentials data) {
    final types = deduplicateCredentialsByType(data.credentials);
    final merged = reconcileCredentialOrder(types, _order, _policy);
    _order = merged.map((e) => e.credentialId).toList();

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
    _order = current.map((e) => e.credentialId).toList();
    _debouncedSave(current);
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

/// Deduplicate credentials by type, keeping first occurrence.
///
/// By credentialId and NOT by hash, because this list is a list of credential
/// TYPES: each card opens SchemalessCredentialsDetailsScreen by credentialTypeId,
/// which lists every credential of that type and offers each one its own delete.
/// Keying on the hash put one card per credential here, so a wallet holding two
/// eu.europa.ec.av.1 attestations showed two identical "Proof of Age" cards that
/// both opened the same screen listing both of them.
///
/// Duplicates are therefore not hidden by this, only folded: the second
/// attestation is reachable, and deletable, one tap deeper. That is the whole
/// arrangement -- one card per type out here, per-credential management inside.
@visibleForTesting
List<schemaless.Credential> deduplicateCredentialsByType(
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

/// Merge the credential types the wallet reports with the user's stored order:
/// keep known ones in that order, place the rest by [newItemPolicy].
///
/// Keyed on credentialId, matching [deduplicateCredentialsByType] and the
/// ValueKey the list widget gives each row. All three have to agree: a map keyed
/// on anything finer than the deduplication would carry entries the list never
/// renders, and a row key finer than the deduplication would be fine while a
/// coarser one would collide and crash ReorderableListView.
@visibleForTesting
List<schemaless.Credential> reconcileCredentialOrder(
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

  if (newItemPolicy == NewItemPolicy.append) {
    visible.addAll(newOnes);
  } else {
    visible.insertAll(0, newOnes);
  }
  return visible;
}
