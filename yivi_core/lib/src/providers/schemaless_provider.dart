import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "irma_repository_provider.dart";

final schemalessCredentialsProvider =
    StreamProvider<List<schemaless.Credential>>((ref) async* {
      final repo = ref.watch(irmaRepositoryProvider);
      await for (final creds in repo.getSchemalessCredentials()) {
        yield creds;
      }
    });
