import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "credentials_list_provider.dart";
import "schemaless_credentials_provider.dart";

/// ----- Controller: reconciles external items with stored order
final schemalessCredentialOrderControllerProvider =
    AsyncNotifierProvider<
      SchemalessCredentialOrderController,
      List<schemaless.Credential>
    >(SchemalessCredentialOrderController.new);

class SchemalessCredentialOrderController
    extends AsyncNotifier<List<schemaless.Credential>> {
  Timer? _debounce;
  List<String> _order = const []; // persisted order of IDs
  final NewItemPolicy _policy = .prepend;

  @override
  Future<List<schemaless.Credential>> build() async {
    // Load persisted order once
    _order = await ref.read(credentialOrderRepoProvider).loadOrder();

    // Set up a listener for subsequent updates (sync listener!)
    ref.listen<AsyncValue<List<schemaless.Credential>>>(
      schemalessCredentialTypesProvider,
      (prev, next) {
        final items = next.value;
        if (items == null) return;

        final merged = _reconcile(items, _order, _policy);

        // Defer the state write so it can't happen during widget build.
        Future.microtask(() {
          // Provider might have been disposed in the meantime
          if (!ref.mounted) return;

          state = AsyncData(merged);
        });

        _debouncedSave(merged);
        _order = merged.map((c) => c.credentialId).toList();
      },
    );

    // Seed initial value
    final ext = await ref.read(schemalessCredentialTypesProvider.future);
    final merged = _reconcile(ext, _order, _policy);
    _order = merged.map((e) => e.credentialId).toList();
    return merged;
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
      await ref
          .read(credentialOrderRepoProvider)
          .saveOrder(items.map((e) => e.credentialId).toList());
    });
  }

  void dispose() {
    _debounce?.cancel();
  }
}
