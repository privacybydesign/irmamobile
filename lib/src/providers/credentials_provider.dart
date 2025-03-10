import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:string_similarity/string_similarity.dart';

import '../models/credentials.dart';
import '../models/irma_configuration.dart';
import 'irma_repository_provider.dart';

final credentialsProvider = StreamProvider<Credentials>((ref) async* {
  final repo = ref.watch(irmaRepositoryProvider);
  final credentialsStream = repo.getCredentials();

  await for (final credentials in credentialsStream) {
    yield credentials;
  }
});

final credentialsSearchQueryProvider = StateProvider((ref) => '');

final credentialsSearchResultsProvider = StreamProvider.family<List<Credential>, Locale>(
  (ref, locale) async* {
    final query = ref.watch(credentialsSearchQueryProvider).toLowerCase();
    final credentials = ref.watch(credentialsProvider);
    final repo = ref.watch(irmaRepositoryProvider);

    if (credentials case AsyncData(:final value)) {
      final searchEntries = _credentialsToSearchEntries(value, locale, repo.irmaConfiguration);
      final searchResults = _search(searchEntries, query);
      final credentials = _searchEntriesToCredentials(value, searchResults);
      yield credentials;
    }
  },
);

// We create a separate class because the Credential class doesn't have the correct
// translation for the credential type and only contains the ID for the issuer
class _SearchEntry {
  final String hash;
  final String credentialType;
  final String issuerName;

  _SearchEntry({required this.hash, required this.credentialType, required this.issuerName});
}

// Searches the list of provided search candidates for the given query and returns an ordered
// list of search results. The best matches come first in the list.
List<_SearchEntry> _search(List<_SearchEntry> candidates, String query) {
  final strippedQuery = query.toLowerCase().trim().replaceAll('-', '');

  final fuzzyResults = candidates
      .map((credential) => MapEntry(credential, _scoreForSearchEntry(credential, strippedQuery)))
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

List<_SearchEntry> _credentialsToSearchEntries(Credentials credentials, Locale locale, IrmaConfiguration config) {
  return credentials.values.map((credential) {
    final credentialName =
        credential.credentialType.name.translate(locale.languageCode).toLowerCase().replaceAll('-', '');

    final issuer = config.issuers[credential.credentialType.fullIssuerId]?.name
            .translate(locale.languageCode)
            .toLowerCase()
            .replaceAll('-', '') ??
        '';

    final hash = credential.hash;
    return _SearchEntry(hash: hash, credentialType: credentialName, issuerName: issuer);
  }).toList(growable: false);
}

List<Credential> _searchEntriesToCredentials(Credentials credentials, List<_SearchEntry> entries) {
  return entries.map((entry) => credentials[entry.hash]!).toList(growable: false);
}
