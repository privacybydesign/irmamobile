import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/providers/favourite_credentials_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

import "helpers/data_tab_fixtures.dart";

void main() {
  test("toggle pins a credential, then unpins it", () async {
    final prefs = await freshPrefs();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final controller = container.read(favouriteCredentialsControllerProvider);

    await controller.toggle("pbdf.pbdf.passport");
    await controller.toggle("pbdf.sidn-pbdf.email");
    expect(await prefs.getFavouriteCredentials().first, [
      "pbdf.pbdf.passport",
      "pbdf.sidn-pbdf.email",
    ]);

    await controller.toggle("pbdf.pbdf.passport");
    expect(await prefs.getFavouriteCredentials().first, [
      "pbdf.sidn-pbdf.email",
    ]);
  });

  test("clearAll forgets the pins", () async {
    final prefs = await freshPrefs();
    await prefs.setFavouriteCredentials(["pbdf.pbdf.passport"]);

    await prefs.clearAll();

    expect(await prefs.getFavouriteCredentials().first, isEmpty);
  });
}
