import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> filledChoiceMixedTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Should go straight to overview screen,
  // because the address has already been obtained
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  await tester.waitFor(find.text('Share my data with is.demo.staging.yivi.app'));

  // Expect the already obtained municipality address
  final cardsFinder = find.byType(YiviCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.normal,
  );

  // Change choice should be visible
  final changeChoiceFinder = find.text('Change choice');
  await tester.scrollUntilVisible(changeChoiceFinder.hitTestable(), 50);
  expect(changeChoiceFinder, findsOneWidget);

  // Press the change choice
  await tester.tapAndSettle(changeChoiceFinder);

  // Expect make choice screen
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  //This screen to have two options
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
    },
    isSelected: true,
  );

  final secondCardFinder = cardsFinder.at(1);
  await evaluateCredentialCard(
    tester,
    secondCardFinder,
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {},
    isSelected: false,
  );

  // Press iDin option
  await tester.scrollUntilVisible(
    secondCardFinder.hitTestable(),
    50,
  );
  await tester.tapAndSettle(secondCardFinder);

  // The styling of the cards should represent this choice
  await evaluateCredentialCard(tester, cardsFinder.first, isSelected: false);
  await evaluateCredentialCard(tester, cardsFinder.at(1), isSelected: true);

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // Issue iDin
  await issueIdin(tester, irmaBinding);

  // Now two filled cards should be present
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
    },
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {
      'Address': 'Meander 501',
      'City': 'Arnhem',
    },
  );

  await tester.tapAndSettle(find.text('Done'));

  // Expect choices overview
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('Share my data with is.demo.staging.yivi.app'), findsOneWidget);

  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {
      'Address': 'Meander 501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
