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
    // we don't want to show the app id credential
    final keyshareAttrs = repo.irmaConfiguration.schemeManagers.values
        .map((sm) => sm.keyshareAttributes)
        .flattened
        .toList(growable: false);
    yield credentials.rebuiltRemoveWhere((hash, credential) {
      return keyshareAttrs.any((id) => id.startsWith(credential.fullId));
    });
  }
});

// A list of all credential types for which at least one instance exists in the app
final credentialInfoListProvider = StreamProvider<List<CredentialInfo>>((ref) async* {
  final allCredentials = await ref.watch(credentialsProvider.future);
  final infos = allCredentials.values.map((c) => c as CredentialInfo);

  final Set<String> seenIds = {};
  final List<CredentialInfo> result = [];
  for (final info in infos) {
    if (!seenIds.contains(info.fullId)) {
      result.add(info);
      seenIds.add(info.fullId);
    }
  }
  yield result;
});

// A list of all credentials of the given credential type id
final credentialsForTypeProvider = FutureProviderFamily<List<Credential>, String>((ref, credentialTypeId) async {
  final credentials = await ref.watch(credentialsProvider.future);

  final filteredCredentials =
      credentials.values.where((cred) => cred.info.credentialType.fullId == credentialTypeId).toList();

  return filteredCredentials;
});

final credentialsSearchQueryProvider = StateProvider((ref) => '');

// A list of credentials filtered by the query in the `credentialsSearchQueryProvider`
final credentialsSearchResultsProvider = FutureProvider.family<List<Credential>, Locale>(
  (ref, locale) async {
    final query = ref.watch(credentialsSearchQueryProvider);
    final credentials = await ref.watch(credentialsProvider.future);
    final repo = ref.watch(irmaRepositoryProvider);

    final searchEntries = _credentialsToSearchEntries(credentials, locale, repo.irmaConfiguration);
    final searchResults = _search(searchEntries, query);
    final filteredCredentials = _searchEntriesToCredentials(credentials, searchResults);
    return filteredCredentials;
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
