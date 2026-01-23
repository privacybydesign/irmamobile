import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/credential_store.dart";

import "irma_repository_provider.dart";

final credentialStoreProvider = StreamProvider<List<CredentialStoreItem>>((
  ref,
) async* {
  final repo = ref.watch(irmaRepositoryProvider);

  await for (final credentials in repo.getCredentialStoreItems()) {
    yield credentials;
  }
});
