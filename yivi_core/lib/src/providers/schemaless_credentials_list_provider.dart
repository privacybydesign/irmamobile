import "dart:async";

import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/feature_flags.dart";
import "../data/irma_preferences.dart";
import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../widgets/credential_card/models/credential_card_status.dart";
import "favourite_credentials_provider.dart";
import "feature_flag_provider.dart";
import "irma_repository_provider.dart";
import "preferences_provider.dart";
import "schemaless_credential_store_provider.dart";
import "schemaless_credentials_provider.dart";

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
    final initialTypes = _deduplicateByType(initial.credentials);
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

  void _onCredentialsChanged(schemaless.SchemalessCredentials data) {
    final types = _deduplicateByType(data.credentials);
    final merged = _reconcile(types, _order, _policy);
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
    _applyOrder(current);
  }

  /// Like [reorder], for a list that shows only some of the credentials, such
  /// as one section of the data tab. [section] is that list in display order
  /// and the indices refer to it. The moved credential ends up next to the same
  /// neighbour in the full order, so the credentials outside the section keep
  /// their place.
  void reorderWithin(
    List<schemaless.Credential> section,
    int oldIndex,
    int newIndex,
  ) {
    final moved = section[oldIndex];
    final others = [...section]..removeAt(oldIndex);
    if (others.isEmpty) return;

    final current = state.requireValue
        .where((c) => c.credentialId != moved.credentialId)
        .toList();
    final at = newIndex < others.length
        ? current.indexWhere(
            (c) => c.credentialId == others[newIndex].credentialId,
          )
        : current.indexWhere(
                (c) => c.credentialId == others.last.credentialId,
              ) +
              1;
    if (at < 0) return;

    current.insert(at, moved);
    _applyOrder(current);
  }

  void _applyOrder(List<schemaless.Credential> current) {
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

// ----- Data tab sections (flags `dataTabV2` and `dataTabCategories`)

enum DataTabLayout {
  /// One reorderable list, as before the redesign.
  classic,

  /// The user's own order, with staging and demo credentials in sections of
  /// their own at the bottom.
  sourcesApart,

  /// Favourites, then a section per category in the order of the add data
  /// screen, then staging and demo.
  categories,
}

final dataTabLayoutProvider = Provider<DataTabLayout>((ref) {
  final categories = ref.watch(
    featureFlagProvider(FeatureFlag.dataTabCategories),
  );
  if (categories.value ?? false) return .categories;

  final v2 = ref.watch(featureFlagProvider(FeatureFlag.dataTabV2));
  return (v2.value ?? false) ? .sourcesApart : .classic;
});

enum DataTabSectionKind {
  favourites,

  /// The credentials of a [DataTabLayout.sourcesApart] data tab that are not
  /// staging or demo. Has no header.
  ungrouped,

  /// A category; an empty [DataTabSection.category] holds the credentials
  /// without one.
  category,
  staging,
  demo,
}

class DataTabSection {
  final DataTabSectionKind kind;
  final String category;

  /// In the user's own order.
  final List<schemaless.Credential> credentials;

  const DataTabSection(this.kind, this.credentials, {this.category = ""});

  /// Identifies the section while the user collapses and expands it.
  String get key => switch (kind) {
    .category => "category:$category",
    _ => kind.name,
  };
}

final dataTabSectionsProvider = Provider<AsyncValue<List<DataTabSection>>>((
  ref,
) {
  final layout = ref.watch(dataTabLayoutProvider);
  if (layout == DataTabLayout.classic) return const AsyncData([]);

  final ordered = ref.watch(schemalessCredentialOrderControllerProvider);
  final credentials = ordered.value;
  if (credentials == null) return ordered.whenData((_) => const []);

  if (layout == DataTabLayout.sourcesApart) {
    return AsyncData(_withoutEmpty(_sourcesApart(credentials)));
  }

  // The grouped store is already in the order of the add data screen. Wait for
  // it and the favourites, so the tab does not show everything uncategorised
  // first.
  final store = ref.watch(groupedCredentialStoreProvider);
  final favourites = ref.watch(favouriteCredentialsProvider);
  if (store is AsyncLoading || favourites is AsyncLoading) {
    return const AsyncLoading();
  }

  return AsyncData(
    _withoutEmpty(
      _byCategory(
        credentials,
        store.value ?? const [],
        (favourites.value ?? const []).toSet(),
      ),
    ),
  );
});

List<DataTabSection> _withoutEmpty(List<DataTabSection> sections) => [
  for (final section in sections)
    if (section.credentials.isNotEmpty) section,
];

List<DataTabSection> _sourcesApart(List<schemaless.Credential> credentials) => [
  DataTabSection(.ungrouped, _fromSource(credentials, .production)),
  ..._separateSources(credentials),
];

List<DataTabSection> _byCategory(
  List<schemaless.Credential> credentials,
  List<CredentialStoreCategory> store,
  Set<String> favourites,
) {
  final favourite = credentials.where(
    (c) => favourites.contains(c.credentialId),
  );
  final rest = credentials
      .where((c) => !favourites.contains(c.credentialId))
      .toList();

  final categoryOf = {
    for (final section in store)
      if (section.source == CredentialStoreSource.production)
        for (final item in section.items)
          item.credential.credentialId: section.category,
  };
  final categories = {
    for (final section in store)
      if (section.source == CredentialStoreSource.production) section.category,
    // Held credentials the store does not know have no category either.
    "",
  };
  final production = _fromSource(rest, .production);

  return [
    if (favourite.isNotEmpty) DataTabSection(.favourites, favourite.toList()),
    for (final category in categories)
      DataTabSection(.category, [
        for (final c in production)
          if ((categoryOf[c.credentialId] ?? "") == category) c,
      ], category: category),
    ..._separateSources(rest),
  ];
}

List<DataTabSection> _separateSources(
  List<schemaless.Credential> credentials,
) => [
  DataTabSection(.staging, _fromSource(credentials, .staging)),
  DataTabSection(.demo, _fromSource(credentials, .demo)),
];

List<schemaless.Credential> _fromSource(
  List<schemaless.Credential> credentials,
  CredentialStoreSource source,
) => [
  for (final c in credentials)
    if (credentialSourceOf(c.credentialId) == source) c,
];

/// The sections the user collapsed, by [DataTabSection.key]. Lives for the
/// session only.
final collapsedDataTabSectionsProvider =
    NotifierProvider<CollapsedDataTabSections, Set<String>>(
      CollapsedDataTabSections.new,
    );

class CollapsedDataTabSections extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String sectionKey) {
    state = state.contains(sectionKey)
        ? ({...state}..remove(sectionKey))
        : {...state, sectionKey};
  }
}

/// The credential types that show as expired in the data tab. Empty while
/// `dataTabV2` is off. A type counts as expired when every credential of it is,
/// so a valid one next to an expired one does not make the type look unusable.
final expiredCredentialTypesProvider = Provider<Set<String>>((ref) {
  if (!(ref.watch(featureFlagProvider(FeatureFlag.dataTabV2)).value ?? false)) {
    return const {};
  }

  final credentials =
      ref.watch(schemalessCredentialsProvider).value?.credentials ?? const [];
  return {
    for (final MapEntry(:key, :value)
        in credentials.groupListsBy((c) => c.credentialId).entries)
      if (value.every(_isExpired)) key,
  };
});

bool _isExpired(schemaless.Credential credential) => CredentialCardStatus(
  expiryDateUnix: credential.expiryDate,
  revoked: credential.revoked,
  batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
).isExpired;
