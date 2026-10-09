import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";

import "helpers/data_tab_fixtures.dart";

void main() {
  group("favourite button on the credential screen", () {
    late StreamController<List<String>> pinChanges;

    setUp(() => pinChanges = StreamController<List<String>>.broadcast());
    tearDown(() => pinChanges.close());

    Future<void> pumpDetails(
      WidgetTester tester, {
      required Set<FeatureFlag> flags,
    }) async {
      await tester.pumpWidget(
        dataTabApp(
          home: const SchemalessCredentialsDetailsScreen(
            credentialTypeId: "pbdf.sidn-pbdf.email",
          ),
          flags: flags,
          pinChanges: pinChanges,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("pins and unpins the credential", (tester) async {
      final pinned = <List<String>>[];
      pinChanges.stream.listen(pinned.add);
      await pumpDetails(tester, flags: {FeatureFlag.dataTabCategories});

      expect(find.byIcon(Icons.star_border), findsOneWidget);

      await tester.tap(find.byKey(const Key("favourite_button")));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(pinned.last, ["pbdf.sidn-pbdf.email"]);

      await tester.tap(find.byKey(const Key("favourite_button")));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(pinned.last, isEmpty);
    });

    testWidgets("is named for what a tap does", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDetails(tester, flags: {FeatureFlag.dataTabCategories});

      expect(find.bySemanticsLabel("Add to favourites"), findsOneWidget);

      await tester.tap(find.byKey(const Key("favourite_button")));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel("Remove from favourites"), findsOneWidget);

      handle.dispose();
    });

    testWidgets("is not there with the flag off", (tester) async {
      await pumpDetails(tester, flags: {FeatureFlag.dataTabV2});

      expect(find.byKey(const Key("favourite_button")), findsNothing);
    });
  });
}
