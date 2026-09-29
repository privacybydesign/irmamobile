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
    final initialUnique = _deduplicateByHash(initial.credentials);
    final merged = _reconcile(initialUnique, _order, _policy);
    _order = merged.map((e) => e.hash).toList();
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
    final unique = _deduplicateByHash(data.credentials);
    final merged = _reconcile(unique, _order, _policy);
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

  /// See [deduplicateCredentialsByHash].
  ///
  /// By hash and NOT by credentialId. For an mdoc, credentialId is the docType,
  /// so every eu.europa.ec.av.1 attestation shares one -- and keying on it made
  /// a wallet holding two of them render one card. The hidden one could not be
  /// seen or deleted, yet the disclosure screen (which does not deduplicate)
  /// still offered it, so it was disclosed on the user's behalf. Deleting the
  /// visible card removed one batch and left the other, which is what made
  /// deletion look broken.
  ///
  /// irmago already collapses genuinely identical issuances into one credential
  /// by content hash before they reach here, so two entries sharing a
  /// credentialId are two different credentials and both belong on screen. This
  /// stays only as a guard against the same credential arriving twice.
  List<schemaless.Credential> _deduplicateByHash(
    List<schemaless.Credential> credentials,
  ) => deduplicateCredentialsByHash(credentials);

  /// Merge logic:
  /// - keep credentials in stored order if they still exist
  /// - add any new ones at end/start (policy)
  ///
  /// Keyed on hash, like _deduplicateByHash and for the same reason: a map keyed
  /// on credentialId silently collapsed two credentials of one docType into one
  /// entry, so fixing the deduplication alone would have changed nothing.
  ///
  /// The stored order holds hashes. Entries written by an older build hold
  /// credentialIds, which match no hash, so those credentials are treated as new
  /// and placed by the policy. That is a one-time reordering that corrects
  /// itself on the next save, and is preferable to a migration that would have
  /// to guess which of two same-docType credentials an old id referred to.
  List<schemaless.Credential> _reconcile(
    List<schemaless.Credential> external,
    List<String> storedOrder,
    NewItemPolicy newItemPolicy,
  ) => reconcileCredentialOrder(external, storedOrder, newItemPolicy);

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

/// Deduplicate credentials by hash, keeping first occurrence.
///
/// By hash and NOT by credentialId. For an mdoc, credentialId is the docType, so
/// every eu.europa.ec.av.1 attestation shares one -- and keying on it made a
/// wallet holding two of them render a single card. The hidden one could not be
/// seen or deleted, yet the disclosure screen (which does not deduplicate) still
/// offered it, so it was disclosed on the user's behalf. Deleting the visible
/// card removed one batch and left the other, which is what made deletion look
/// broken.
///
/// irmago already collapses genuinely identical issuances into one credential by
/// content hash before they reach here, so two entries sharing a credentialId are
/// two different credentials and both belong on screen. This remains only as a
/// guard against the same credential arriving twice in one event.
@visibleForTesting
List<schemaless.Credential> deduplicateCredentialsByHash(
  List<schemaless.Credential> credentials,
) {
  final Set<String> seenHashes = {};
  final List<schemaless.Credential> result = [];
  for (final info in credentials) {
    if (!seenHashes.contains(info.hash)) {
      result.add(info);
      seenHashes.add(info.hash);
    }
  }
  return result;
}

/// Merge the credentials the wallet reports with the user's stored order:
/// keep known ones in that order, place the rest by [newItemPolicy].
///
/// Keyed on hash, for the same reason as [deduplicateCredentialsByHash]: a map
/// keyed on credentialId silently collapsed two credentials of one docType into
/// one entry, so fixing the deduplication alone would have changed nothing.
///
/// The stored order holds hashes. Entries written by an older build hold
/// credentialIds, which match no hash, so those credentials are treated as new
/// and placed by the policy. That is a one-time reordering which corrects itself
/// on the next save, and is preferable to a migration that would have to guess
/// which of two same-docType credentials an old id referred to.
@visibleForTesting
List<schemaless.Credential> reconcileCredentialOrder(
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

  if (newItemPolicy == NewItemPolicy.append) {
    visible.addAll(newOnes);
  } else {
    visible.insertAll(0, newOnes);
  }
  return visible;
}
