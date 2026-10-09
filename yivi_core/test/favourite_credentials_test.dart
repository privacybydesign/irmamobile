import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/providers/favourite_credentials_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

import "helpers/data_tab_fixtures.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("toggling pins and unpins a credential type", () async {
    final prefs = await freshPrefs();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final controller = container.read(favouriteCredentialsControllerProvider);

    await controller.toggle("pbdf.a");
    await controller.toggle("pbdf.b");
    expect(await prefs.getFavouriteCredentials().first, ["pbdf.a", "pbdf.b"]);

    await controller.toggle("pbdf.a");
    expect(await prefs.getFavouriteCredentials().first, ["pbdf.b"]);
  });

  test("a new wallet has no favourites", () async {
    final prefs = await freshPrefs();

    expect(await prefs.getFavouriteCredentials().first, isEmpty);
  });
}
