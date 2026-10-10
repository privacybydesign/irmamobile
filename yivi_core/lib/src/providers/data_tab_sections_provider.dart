import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/feature_flags.dart";
import "../models/schemaless/schemaless_events.dart" as schemaless;
import "favourite_credentials_provider.dart";
import "feature_flag_provider.dart";
import "schemaless_credential_store_provider.dart";
import "schemaless_credentials_list_provider.dart";

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

  final sourcesApart = ref.watch(featureFlagProvider(FeatureFlag.dataTabV2));
  return (sourcesApart.value ?? false) ? .sourcesApart : .classic;
});

enum DataTabSectionKind {
  favourites,

  /// The credentials that are not staging or demo, when they are not split by
  /// category. Has no header.
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

/// The data tab as sections, without the empty ones. Which sections there are
/// follows [dataTabLayoutProvider].
final dataTabSectionsProvider = Provider<AsyncValue<List<DataTabSection>>>((
  ref,
) {
  final layout = ref.watch(dataTabLayoutProvider);
  final ordered = ref.watch(schemalessCredentialOrderControllerProvider);
  final credentials = ordered.value;
  if (credentials == null) return ordered.whenData((_) => const []);

  if (layout == DataTabLayout.classic) {
    return AsyncData([DataTabSection(.ungrouped, credentials)]);
  }
  if (layout == DataTabLayout.sourcesApart) {
    return AsyncData(
      _withoutEmpty([
        DataTabSection(.ungrouped, _fromSource(credentials, .production)),
        ..._separateSources(credentials),
      ]),
    );
  }

  // The grouped store is already in the order of the add data screen. Wait for
  // it and the favourites, so the tab does not show everything uncategorised
  // first.
  final store = ref.watch(groupedCredentialStoreProvider);
  final favourites = ref.watch(favouriteCredentialsProvider);
  if (_pending(store) || _pending(favourites)) return const AsyncLoading();

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

bool _pending(AsyncValue<Object?> value) =>
    value is AsyncLoading && !value.hasValue;

List<DataTabSection> _withoutEmpty(List<DataTabSection> sections) => [
  for (final section in sections)
    if (section.credentials.isNotEmpty) section,
];

List<DataTabSection> _byCategory(
  List<schemaless.Credential> credentials,
  List<CredentialStoreCategory> store,
  Set<String> favourites,
) {
  final favourite = [
    for (final c in credentials)
      if (favourites.contains(c.credentialId)) c,
  ];
  final rest = [
    for (final c in credentials)
      if (!favourites.contains(c.credentialId)) c,
  ];

  final production = [
    for (final section in store)
      if (section.source == CredentialStoreSource.production) section,
  ];
  final categoryOf = {
    for (final section in production)
      for (final item in section.items)
        item.credential.credentialId: section.category,
  };
  final categories = {
    for (final section in production) section.category,
    // Held credentials the store does not know have no category either.
    "",
  };
  final unpinned = _fromSource(rest, .production);

  return [
    DataTabSection(.favourites, favourite),
    for (final category in categories)
      DataTabSection(.category, [
        for (final c in unpinned)
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
