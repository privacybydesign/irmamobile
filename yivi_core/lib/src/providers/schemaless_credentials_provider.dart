import "dart:ui";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "./provider_helpers.dart" as helpers;
import "credentials_search.dart";
import "irma_repository_provider.dart";

final credentialsSearchQueryProvider = NotifierProvider(
  () => helpers.ValueNotifier(""),
);

final schemalessCredentialsProvider =
    StreamProvider<List<schemaless.Credential>>((ref) async* {
      final repo = ref.watch(irmaRepositoryProvider);

      await for (final credentials in repo.getSchemalessCredentials()) {
        yield credentials;
      }
    });

final schemalessCredentialTypesProvider =
    StreamProvider<List<schemaless.Credential>>((ref) async* {
      final allCredentials = await ref.watch(
        schemalessCredentialsProvider.future,
      );

      final Set<String> seenIds = {};
      final List<schemaless.Credential> result = [];
      for (final info in allCredentials) {
        if (!seenIds.contains(info.credentialId)) {
          result.add(info);
          seenIds.add(info.credentialId);
        }
      }
      yield result;
    });

// A list of all credentials of the given credential type id
final schemalessCredentialsWithIdProvider =
    FutureProvider.family<List<schemaless.Credential>, String>((
      ref,
      credentialTypeId,
    ) async {
      final credentials = await ref.watch(schemalessCredentialsProvider.future);

      final filteredCredentials = credentials
          .where((cred) => cred.credentialId == credentialTypeId)
          .toList();

      return filteredCredentials;
    });

// A list of credentials filtered by the query in the `credentialsSearchQueryProvider`
final schemalessCredentialsSearchResultsProvider =
    FutureProvider.family<List<schemaless.Credential>, Locale>((
      ref,
      locale,
    ) async {
      final query = ref.watch(credentialsSearchQueryProvider);
      final credentials = await ref.watch(
        schemalessCredentialTypesProvider.future,
      );

      final searchEntries = _credentialsToSearchEntries(credentials, locale);
      final searchResults = searchCredentials(searchEntries, query);
      return searchResults
          .map((entry) => credentials.firstWhere((c) => c.hash == entry.hash))
          .toList(growable: false);
    });

List<SearchEntry> _credentialsToSearchEntries(
  List<schemaless.Credential> credentials,
  Locale locale,
) {
  return credentials
      .map((credential) {
        final credentialName = credential.name
            .translate(locale.languageCode)
            .toLowerCase()
            .replaceAll("-", "");

        final issuer = credential.issuer.name
            .translate(locale.languageCode)
            .toLowerCase()
            .replaceAll("-", "");

        return SearchEntry(
          hash: credential.hash,
          credentialType: credentialName,
          issuerName: issuer,
        );
      })
      .toList(growable: false);
}
