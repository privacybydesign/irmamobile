import "package:flutter_riverpod/flutter_riverpod.dart";

import "preferences_provider.dart";

/// The ids of the credential types the user pinned to the top of the data tab.
final favouriteCredentialsProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(preferencesProvider).getFavouriteCredentials(),
);

final favouriteCredentialsControllerProvider = Provider(
  FavouriteCredentialsController.new,
);

class FavouriteCredentialsController {
  final Ref _ref;

  FavouriteCredentialsController(this._ref);

  Future<void> toggle(String credentialId) async {
    final prefs = _ref.read(preferencesProvider);
    final current = await prefs.getFavouriteCredentials().first;
    final updated = current.contains(credentialId)
        ? [
            for (final id in current)
              if (id != credentialId) id,
          ]
        : [...current, credentialId];

    await prefs.setFavouriteCredentials(updated);
  }
}
