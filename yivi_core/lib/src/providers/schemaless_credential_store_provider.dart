import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/credential_store.dart";

import "../models/translated_value.dart";
import "../util/nfc_credentials.dart";
import "irma_repository_provider.dart";
import "nfc_availability_provider.dart";

final credentialStoreProvider = StreamProvider<List<CredentialStoreItem>>((
  ref,
) async* {
  final repo = ref.watch(irmaRepositoryProvider);
  // Hide credentials that require onboard NFC issuance (passport, ID card,
  // driving licence) on devices without NFC hardware, so users aren't led into
  // a scanning flow they cannot complete (e.g. iPads).
  //
  // Default to NFC-available when the check can't be resolved: filtering only
  // ever *removes* credentials, so a failed NFC check must never blank the
  // whole credential store — better to show an NFC credential the user can't
  // complete than to hide every credential on the device.
  bool nfcAvailable;
  try {
    nfcAvailable = await ref.watch(nfcAvailableProvider.future);
  } catch (_) {
    nfcAvailable = true;
  }

  await for (final credentials in repo.getCredentialStoreItems()) {
    yield filterNfcRequiringCredentials(
      credentials,
      nfcAvailable: nfcAvailable,
    );
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
