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
const _personalCategoryNames = {"Personal", "Persoonlijk", "Persönlich"};

final groupedCredentialStoreProvider =
    StreamProvider<List<CredentialStoreCategory>>((ref) async* {
      final all = await ref.watch(credentialStoreProvider.future);

      final categorized = <String, List<CredentialStoreItem>>{};
      for (final item in all) {
        final category = item.credential.category ?? "";
        categorized.putIfAbsent(category, () => []).add(item);
      }

      final result = categorized.entries
          .map((e) => CredentialStoreCategory(category: e.key, items: e.value))
          .toList();

      // Put the personal section as the first
      result.sort((a, b) {
        final aIsPersonal = _personalCategoryNames.contains(a.category);
        final bIsPersonal = _personalCategoryNames.contains(b.category);

        if (aIsPersonal && !bIsPersonal) return -1;
        if (!aIsPersonal && bIsPersonal) return 1;
        return 0; // keep relative order otherwise
      });

      yield result;
    });
