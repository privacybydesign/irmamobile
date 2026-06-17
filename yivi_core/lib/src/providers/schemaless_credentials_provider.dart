import "dart:ui";

import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:string_similarity/string_similarity.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "./provider_helpers.dart" as helpers;
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
      // Floor raised from 0.2 to 0.3 alongside tokenisation. Bigram similarity
      // between unrelated words like "overheid" ↔ "verified" lands around 0.29
      // (shared "ve"/"er"); 0.3 cuts those off while keeping realistic typos
      // (e.g. "paspot" ↔ "paspoort" ≈ 0.67).
      .where((entry) => entry.value >= 0.3)
      .sorted((a, b) => b.value.compareTo(a.value))
      .map((entry) => entry.key)
      .toList(growable: false);

  return fuzzyResults;
}

double _scoreForSearchEntry(_SearchEntry credential, String query) {
  final credentialScore = _maxTokenScore(query, credential.credentialType);
  final issuerScore = _maxTokenScore(query, credential.issuerName);

  // Credential type weighted higher than issuer name in the final score.
  return credentialScore * 0.7 + issuerScore * 0.3;
}

// Score the query against each whitespace-separated token of [target] and
// return the best match. Tokenisation matters because Dice's-coefficient
// similarity over a whole string accumulates incidental shared bigrams across
// word boundaries — e.g. "overheid" against "verified email" picks up "ve"
// and "er" from "verified" plus nothing from "email", yet the longer combined
// string makes the overall similarity look meaningful when it isn't.
double _maxTokenScore(String query, String target) {
  double best = 0;
  for (final token in target.split(" ")) {
    if (token.isEmpty) continue;
    // Prefix and contains hits short-circuit fuzzy: a literal substring match
    // is always more relevant than a coincidental bigram overlap.
    if (token.startsWith(query)) return 1;
    if (token.contains(query)) {
      if (0.9 > best) best = 0.9;
      continue;
    }
    final fuzzy = query.similarityTo(token);
    if (fuzzy > best) best = fuzzy;
  }
  return best;
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
