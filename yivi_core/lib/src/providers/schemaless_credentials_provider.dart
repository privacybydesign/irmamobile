import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "irma_repository_provider.dart";

final schemalessCredentialsProvider =
    StreamProvider<schemaless.SchemalessCredentials>((ref) async* {
      final repo = ref.watch(irmaRepositoryProvider);

      await for (final data in repo.getSchemalessCredentials()) {
        yield data;
      }
    });

/// Whether the data tab has anything to show: a credential, or one that cannot
/// be rendered. The keyshare credential is never in the list, so this is false
/// right after enrollment.
final hasCredentialsProvider = Provider<bool>((ref) {
  final credentials = ref.watch(schemalessCredentialsProvider).value;
  return credentials != null &&
      (credentials.credentials.isNotEmpty ||
          credentials.problematic.isNotEmpty);
});

// A list of all credentials of the given credential type id
final schemalessCredentialsWithIdProvider =
    FutureProvider.family<List<schemaless.Credential>, String>((
      ref,
      credentialTypeId,
    ) async {
      final credentials = (await ref.watch(
        schemalessCredentialsProvider.future,
      )).credentials;

      final filteredCredentials = credentials
          .where((cred) => cred.credentialId == credentialTypeId)
          .toList();

      return filteredCredentials;
    });
