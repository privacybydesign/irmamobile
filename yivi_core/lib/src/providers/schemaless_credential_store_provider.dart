import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/credential_store.dart";

import "../models/translated_value.dart";
import "irma_repository_provider.dart";

final credentialStoreProvider = StreamProvider<List<CredentialStoreItem>>((
  ref,
) async* {
  final repo = ref.watch(irmaRepositoryProvider);

  await for (final credentials in repo.getCredentialStoreItems()) {
    yield credentials;
  }
});

class CredentialStoreCategory {
  final TranslatedValue category;
  final List<CredentialStoreItem> items;

  CredentialStoreCategory({required this.category, required this.items});
}

final groupedCredentialStoreProvider =
    StreamProvider<List<CredentialStoreCategory>>((ref) async* {
      final all = await ref.watch(credentialStoreProvider.future);

      final categorized = <TranslatedValue, List<CredentialStoreItem>>{};
      for (final item in all) {
        final category = item.credential.category!;
        categorized.putIfAbsent(category, () => []).add(item);
      }

      final result = categorized.entries
          .map((e) => CredentialStoreCategory(category: e.key, items: e.value))
          .toList();

      // Put the personal section as the first
      result.sort((a, b) {
        final aIsPersonal = a.category.translate("en") == "Personal";
        final bIsPersonal = b.category.translate("en") == "Personal";

        if (aIsPersonal && !bIsPersonal) return -1;
        if (!aIsPersonal && bIsPersonal) return 1;
        return 0; // keep relative order otherwise
      });

      yield result;
    });
