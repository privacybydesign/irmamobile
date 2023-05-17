import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/add_data/add_data_screen.dart';
import 'package:irmamobile/src/screens/data/widgets/credential_category_list.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('credential-store', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('credential-store-order', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      final actionCardFetchFinder = find.byKey(const Key('home_action_fetch'));
      expect(actionCardFetchFinder, findsOneWidget);

      // Expect AddDataScreen to be shown
      await tester.tapAndSettle(actionCardFetchFinder);
      expect(find.byType(AddDataScreen), findsOneWidget);

      // Find all the credential store
      final credentialCategoryListFinder = find.byType(CredentialCategoryList);

      // First category list should be 'Personal data'
      final firstCategoryListFinder = credentialCategoryListFinder.first;
      expect(
        find.descendant(
          of: firstCategoryListFinder,
          matching: find.text('Personal data'),
        ),
        findsOneWidget,
      );

      // Note: the current test scheme does not have any credentials in the "Other" category
      // If this changes expect the "Other" category to be the last one
    });
  });
}
