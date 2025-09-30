import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_permission.dart';
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

  group('sdjwtvc-issuance-over-irma', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      'low-instance-count-no-reobtain-during-issuance',
      (tester) => testIssuanceLowInstanceCountNoReobtainButtonDuringIssuance(tester, irmaBinding),
    );

    testWidgets(
      'issue-email-en',
      (tester) => testIssueEmailWithSdJwt(tester, irmaBinding, const Locale('en', 'EN')),
    );

    testWidgets(
      'issue-email-nl',
      (tester) => testIssueEmailWithSdJwt(tester, irmaBinding, const Locale('nl', 'NL')),
    );
  });
}

/// make sure the reobtain button and expiry warning don't show if the credential count is low during issuance
Future<void> testIssuanceLowInstanceCountNoReobtainButtonDuringIssuance(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
  );

  const credentialCount = 1;

  final groupedAttributes = groupAttributes({
    'irma-demo.sidn-pbdf.email.email': 'test@example.com',
    'irma-demo.sidn-pbdf.email.domain': 'example.com',
  });
  await startIssuanceSession(irmaBinding, groupedAttributes, sdJwtBatchSize: 1);
  await tester.pumpAndSettle();

  var issuancePageFinder = find.byType(IssuancePermission);
  await tester.waitFor(issuancePageFinder);

  // Make sure it's not shown as nearly expired even though the instance count is low.
  // We don't want to show a re-obtain button during issuance...
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
    },
    isRevoked: false,
    isExpired: false,
    instancesRemaining: 1,
  );

  // continue with issuance request
  final buttonFinder = find.byKey(const Key('bottom_bar_primary'));
  expect(buttonFinder, findsOneWidget);

  await tester.tapAndSettle(buttonFinder);

  await tester.waitUntilDisappeared(issuancePageFinder);

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

  // finish flow
  await tester.tapAndSettle(find.text('OK'));

  // Go to data tab
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.email');

  // Expect to find a card
  final cardFinder = find.byType(YiviCredentialCard);
  final credentialCards = tester.widgetList<YiviCredentialCard>(cardFinder).toList();
  expect(credentialCards.length, equals(1));
  expect(credentialCards[0].instanceCount, equals(credentialCount));

  expect(find.text('$credentialCount times left', skipOffstage: false), findsOneWidget);
}

Future<void> testIssueEmailWithSdJwt(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
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

  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.email');

  // Expect to find a card
  final cardFinder = find.byType(YiviCredentialCard);
  final credentialCards = tester.widgetList<YiviCredentialCard>(cardFinder).toList();
  expect(credentialCards.length, equals(1));
  expect(credentialCards[0].instanceCount, equals(credentialCount));

  if (locale == Locale('nl', 'NL')) {
    expect(find.text('Nog $credentialCount keer', skipOffstage: false), findsOneWidget);
  } else {
    expect(find.text('$credentialCount times left', skipOffstage: false), findsOneWidget);
  }
}
