import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "irma_repository_provider.dart";

final schemalessCredentialsProvider =
    StreamProvider<List<schemaless.Credential>>((ref) {
      final repo = ref.watch(irmaRepositoryProvider);
      return repo.getSchemalessCredentials();
    });

final schemalessCredentialTypesProvider =
    StreamProvider<List<schemaless.CredentialType>>((ref) async* {
      final allCredentials = await ref.watch(
        schemalessCredentialsProvider.future,
      );

      final Set<String> seenIds = {};
      final List<schemaless.CredentialType> result = [];
      for (final info in allCredentials) {
        if (!seenIds.contains(info.credentialId)) {
          result.add(
            schemaless.CredentialType(
              credentialId: info.credentialId,
              name: info.name,
              issuerName: info.issuer.name,
              imagePath: info.imagePath,
            ),
          );
          seenIds.add(info.credentialId);
        }
      }
      yield result;
    });
