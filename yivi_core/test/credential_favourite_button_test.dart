import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";

import "helpers/data_tab_fixtures.dart";

const _passport = "pbdf.pbdf.passport";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  Future<void> pumpDetails(
    WidgetTester tester, {
    Set<FeatureFlag> flags = const {},
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);

    prefs = (await tester.runAsync(freshPrefs))!;

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        dataTabApp(
          overrides: dataTabOverrides(
            held: [heldCredential(_passport, name: "Passport")],
            prefs: prefs,
            flags: flags,
          ),
          home: const SchemalessCredentialsDetailsScreen(
            credentialTypeId: _passport,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await settle(tester);
  }

  final button = find.byKey(const Key("favourite_button"));

  testWidgets("without dataTabCategories there is no star", (tester) async {
    await pumpDetails(tester);

    expect(button, findsNothing);
  });

  testWidgets("the star pins the credential and unpins it again", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDetails(tester, flags: {FeatureFlag.dataTabCategories});

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.bySemanticsLabel("Add to favourites"), findsOneWidget);

    await tester.tap(button);
    await settle(tester);

    expect(await tester.runAsync(() => prefs.getFavouriteCredentials().first), [
      _passport,
    ]);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.bySemanticsLabel("Remove from favourites"), findsOneWidget);

    await tester.tap(button);
    await settle(tester);

    expect(
      await tester.runAsync(() => prefs.getFavouriteCredentials().first),
      isEmpty,
    );
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    semantics.dispose();
  });
}
