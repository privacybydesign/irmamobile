import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/credential_store.dart";

import "irma_repository_provider.dart";

final credentialStoreProvider = StreamProvider<List<CredentialStoreItem>>((
  ref,
) async* {
  final repo = ref.watch(irmaRepositoryProvider);

  // Credentials that require onboard NFC issuance (passport, ID card, driving
  // licence) stay in the store on devices without NFC hardware (e.g. iPads).
  // The add-data screen greys them out and explains, on tap, that the device
  // cannot load them without NFC — see `SchemalessAddDataScreen` and
  // `nfcAvailableProvider`.
  yield* repo.getCredentialStoreItems();
});

class CredentialStoreCategory {
  final String category;
  final List<CredentialStoreItem> items;

  CredentialStoreCategory({required this.category, required this.items});
}

// The category text irmago resolves for the personal section, across the
// supported languages. Category strings now arrive resolved to the effective
// app language (no translation map), so the personal section is recognised by
// its resolved name rather than a fixed "en" lookup.
//
// This matches on display text because the resolved DTO carries no stable
// category key: if a scheme rewords one of these, or adds a category
// translation in a language not listed here, the personal section silently
// sorts alphabetically instead of first. Pinned by
// test/credential_store_category_order_test.dart so that change fails loudly;
// the durable fix is a category identifier on irmago's side.
const _personalCategoryNames = {"Personal", "Persoonlijk", "Persönlich"};

final groupedCredentialStoreProvider =
    StreamProvider<List<CredentialStoreCategory>>((ref) async* {
      final all = await ref.watch(credentialStoreProvider.future);

      final categorized = <String, List<CredentialStoreItem>>{};
      for (final item in all) {
        final category = item.credential.category ?? "";
        categorized.putIfAbsent(category, () => []).add(item);
      }

      // irmago builds the store by iterating a Go map, so it arrives in a
      // different order on every start. Sort it here: the personal section
      // first, then the other categories alphabetically, credentials without a
      // category last; within a section by name.
      final result =
          categorized.entries
              .map(
                (e) => CredentialStoreCategory(
                  category: e.key,
                  items: e.value..sort(_byName),
                ),
              )
              .toList()
            ..sort(_bySection);

      yield result;
    });

int _sectionRank(CredentialStoreCategory section) {
  if (_personalCategoryNames.contains(section.category)) return 0;
  return section.category.isEmpty ? 2 : 1;
}

int _bySection(CredentialStoreCategory a, CredentialStoreCategory b) {
  final byRank = _sectionRank(a).compareTo(_sectionRank(b));
  return byRank != 0 ? byRank : _compareText(a.category, b.category);
}

int _byName(CredentialStoreItem a, CredentialStoreItem b) {
  final byName = _compareText(a.credential.name, b.credential.name);
  // Two credentials can share a name; the id keeps their order fixed too.
  return byName != 0
      ? byName
      : a.credential.credentialId.compareTo(b.credential.credentialId);
}

/// Case-insensitive, so "e-mail" and "E-mail" do not sort apart.
int _compareText(String a, String b) {
  final folded = a.toLowerCase().compareTo(b.toLowerCase());
  return folded != 0 ? folded : a.compareTo(b);
}
