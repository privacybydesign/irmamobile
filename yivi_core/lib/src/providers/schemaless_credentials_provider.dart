import "dart:ui";

import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:string_similarity/string_similarity.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "credentials_provider.dart";
import "irma_repository_provider.dart";

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
      final searchResults = _search(searchEntries, query);
      final filteredCredentials = _searchEntriesToCredentials(
        credentials,
        searchResults,
      );
      return filteredCredentials;
    });

// We create a separate class because the Credential class doesn't have the correct
// translation for the credential type and only contains the ID for the issuer
class _SearchEntry {
  final String hash;
  final String credentialType;
  final String issuerName;

  _SearchEntry({
    required this.hash,
    required this.credentialType,
    required this.issuerName,
  });
}

// Searches the list of provided search candidates for the given query and returns an ordered
// list of search results. The best matches come first in the list.
List<_SearchEntry> _search(List<_SearchEntry> candidates, String query) {
  final strippedQuery = query.toLowerCase().trim().replaceAll("-", "");

  final fuzzyResults = candidates
      .map(
        (credential) => MapEntry(
          credential,
          _scoreForSearchEntry(credential, strippedQuery),
        ),
      )
      .where((entry) => entry.value >= 0.2)
      .sorted((a, b) => b.value.compareTo(a.value))
      .map((entry) => entry.key)
      .toList(growable: false);

  return fuzzyResults;
}

double _scoreForSearchEntry(_SearchEntry credential, String query) {
  // sometimes a string may start with or contain the query but the threshold for similarity is not reached
  // we filter these cases out so they still show up in the search results with high priority
  if (credential.credentialType.startsWith(query)) {
    return 1;
  }
  if (credential.credentialType.contains(query)) {
    return 0.9;
  }
  final credentialSimilarity = query.similarityTo(credential.credentialType);
  final issuerSimilarity = query.similarityTo(credential.issuerName);

  // we weight the credential and issuer similarities so the credential is more important in the search results
  return credentialSimilarity * 0.7 + issuerSimilarity * 0.3;
}

List<_SearchEntry> _credentialsToSearchEntries(
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

        final hash = credential.hash;
        return _SearchEntry(
          hash: hash,
          credentialType: credentialName,
          issuerName: issuer,
        );
      })
      .toList(growable: false);
}

List<schemaless.Credential> _searchEntriesToCredentials(
  List<schemaless.Credential> credentials,
  List<_SearchEntry> entries,
) {
  return entries
      .map((entry) => credentials.firstWhere((c) => c.hash == entry.hash))
      .toList(growable: false);
}
