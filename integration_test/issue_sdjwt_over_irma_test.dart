import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/data/credentials_details_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_success_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/success_graphic.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('sd-jwt vc issuance over irma', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    Future<void> testIssueMunicipalityWithSdJwt(
      WidgetTester tester,
      Locale locale,
    ) async {
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        locale,
      );

      const credentialCount = 50;

      await issueEmailAddress(
        tester,
        irmaBinding,
        sdJwtBatchSize: credentialCount,
        locale: locale,
      );
      await tester.pumpAndSettle();

      final successScreenFinder = find.byType(IssuanceSuccessScreen);
      expect(successScreenFinder, findsOneWidget);

      // Expect the SuccessGraphic in the IssuanceSuccessScreen
      final successGraphicFinder = find.byType(SuccessGraphic);
      expect(
        find.descendant(
          of: successScreenFinder,
          matching: successGraphicFinder,
        ),
        findsOneWidget,
      );

      await tester.tapAndSettle(find.text('OK'));

      // Go to data tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

      // Expect CredentialTypeTile and tap it
      var categoryTileFinder = find.byKey(const Key('irma-demo.sidn-pbdf.email_tile')).hitTestable();
      await tester.scrollUntilVisible(categoryTileFinder, 75);
      await tester.tapAndSettle(categoryTileFinder);

      // Expect detail page
      expect(find.byType(CredentialsDetailsScreen), findsOneWidget);

      // Expect to find a card
      final credentialCards = tester.widgetList<YiviCredentialCard>(find.byType(YiviCredentialCard)).toList();
      expect(credentialCards.length, equals(1));

      expect(credentialCards[0].instanceCount, equals(credentialCount));

      if (locale == Locale('nl', 'NL')) {
        expect(find.text('Nog $credentialCount keer', skipOffstage: false), findsOneWidget);
      } else {
        expect(find.text('$credentialCount times left', skipOffstage: false), findsOneWidget);
      }
    }

    testWidgets(
      'issue-municipality-en',
      (tester) => testIssueMunicipalityWithSdJwt(tester, const Locale('en', 'EN')),
    );

    testWidgets(
      'issue-municipality-nl',
      (tester) => testIssueMunicipalityWithSdJwt(tester, const Locale('nl', 'NL')),
    );
  });
}
