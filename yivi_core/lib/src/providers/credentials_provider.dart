import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/credential.dart";
import "irma_repository_provider.dart";

final credentialsProvider = StreamProvider<WalletCredentials>(
  (ref) => ref.watch(irmaRepositoryProvider).getCredentials(),
);

/// Whether the data tab has anything to show: a credential, or one that cannot
/// be rendered. The keyshare credential is never in the list, so this is false
/// right after enrollment.
final hasCredentialsProvider = Provider<bool>((ref) {
  final credentials = ref.watch(credentialsProvider).value;
  return credentials != null &&
      (credentials.credentials.isNotEmpty ||
          credentials.problematic.isNotEmpty);
});

// A list of all credentials of the given credential type id
final credentialsWithIdProvider =
    FutureProvider.family<List<Credential>, String>((
      ref,
      credentialTypeId,
    ) async {
      final credentials = (await ref.watch(
        credentialsProvider.future,
      )).credentials;

      final filteredCredentials = credentials
          .where((cred) => cred.credentialId == credentialTypeId)
          .toList();

      return filteredCredentials;
    });
