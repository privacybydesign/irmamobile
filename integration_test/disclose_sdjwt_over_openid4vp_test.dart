import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import 'disclosure_session/disclosure_helpers.dart';
import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('openid4vp', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      'select-one-of-two-possible-emails-and-two-possible-phones',
      (tester) => testSelectOneOfTwoPossibleEmailsAndTwoPossiblePhones(tester, irmaBinding),
    );

    testWidgets(
      'two-credentials-two-choices-each',
      (tester) => testTwoCredentialsTwoChoicesEach(tester, irmaBinding),
    );

    testWidgets(
      'one-credential-two-choices',
      (tester) => testOneCredentialTwoChoices(tester, irmaBinding),
    );

    testWidgets(
      'one-missing-one-present',
      (tester) => testOneMissingOnePresent(tester, irmaBinding),
    );

    testWidgets(
      'missing',
      (tester) => testDiscloseSdJwtThatsNotThere(tester, irmaBinding),
    );

    testWidgets(
      'zero-credential-instance-count-shows-reobtain-button-and-red-card',
      (tester) => testZeroInstanceCountShowsReobtainButton(tester, irmaBinding),
    );

    testWidgets(
      'low-credential-instance-count-shows-reobtain-button',
      (tester) => testLowCredentialInstanceCountShowsReobtainButton(tester, irmaBinding),
    );

    testWidgets(
      'filled-app-disclose-with-choice',
      (tester) => testDiscloseSdJwtWithChoices(tester, irmaBinding),
    );

    testWidgets(
      'filled-app-disclose-email-openid4vp',
      (tester) => testDiscloseSdJwtOverOpenID4VP(tester, irmaBinding),
    );

    // optional disclose one attribute
    // optional disclose whole credential
    // disclosure with predetermined value, one matching, one not
    // disclosure with multiple predetermined values
    // check logs for disclosed credentials
    // disclosure session with a credential that is present but with an instance count of 0
  });
}

Future<void> testSelectOneOfTwoPossibleEmailsAndTwoPossiblePhones(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com', domain: 'example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@template.com', domain: 'template.com');
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10, phone: '0612345678');
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10, phone: '0687654321');

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': 'mail',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'id': 'em',
            'path': ['email']
          },
          {
            'id': 'do',
            'path': ['domain']
          },
        ]
      },
      {
        'id': 'phone',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.mobilenumber']
        },
        'claims': [
          {
            'id': 'mn',
            'path': ['mobilenumber']
          },
        ]
      },
    ],
    'credential_sets': [
      {
        'options': [
          ['mail'],
          ['phone']
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  final choiceButtonFinder = find.text('Change choice');
  expect(choiceButtonFinder, findsOneWidget);

  await tester.tapAndSettle(choiceButtonFinder);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsNWidgets(4));

  expect(find.descendant(of: cardsFinder, matching: find.text('one@example.com')), findsOneWidget);
  expect(find.descendant(of: cardsFinder, matching: find.text('two@template.com')), findsOneWidget);
  expect(find.descendant(of: cardsFinder, matching: find.text('0612345678')), findsOneWidget);

  final lastMobileFinder = find.descendant(of: cardsFinder, matching: find.text('0687654321'));
  expect(lastMobileFinder, findsOneWidget);

  await tester.scrollUntilVisible(lastMobileFinder, 100);
  await tester.tapAndSettle(lastMobileFinder);

  // back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // share
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // confirm
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

/// Issues phone and email both twice, then asks for one of each, should present two choice buttons
Future<void> testTwoCredentialsTwoChoicesEach(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com', domain: 'example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@template.com', domain: 'template.com');
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10, phone: '0612345678');
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10, phone: '0687654321');

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': 'mail',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'id': 'em',
            'path': ['email']
          },
          {
            'id': 'do',
            'path': ['domain']
          },
        ]
      },
      {
        'id': 'phone',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.mobilenumber']
        },
        'claims': [
          {
            'id': 'mn',
            'path': ['mobilenumber']
          },
        ]
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  final choiceButtonFinder = find.text('Change choice');
  expect(choiceButtonFinder, findsNWidgets(2));

  // change the email
  await tester.tapAndSettle(choiceButtonFinder.at(0));
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsNWidgets(2));
  expect(
    find.descendant(of: cardsFinder, matching: find.text('one@example.com', skipOffstage: false)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: cardsFinder, matching: find.text('two@template.com', skipOffstage: false)),
    findsOneWidget,
  );

  await tester.tapAndSettle(find.byType(YiviBackButton));

  // change mobilenumber
  await tester.scrollUntilVisible(choiceButtonFinder.at(1), 100);
  await tester.tapAndSettle(choiceButtonFinder.at(1));

  expect(cardsFinder, findsNWidgets(2));
  expect(
    find.descendant(of: cardsFinder, matching: find.text('0612345678', skipOffstage: false)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: cardsFinder, matching: find.text('0687654321', skipOffstage: false)),
    findsOneWidget,
  );

  await tester.tapAndSettle(find.byType(YiviBackButton));

  // share
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // confirm
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

/// Issue two email addresses and allow the user to pick between them
Future<void> testOneCredentialTwoChoices(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com', domain: 'example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@template.com', domain: 'template.com');

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': 'mail',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'path': ['email']
          },
        ]
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  await tester.tapAndSettle(find.text('Change choice'));

  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // expect two credentials: email and phone...
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  // TODO: Should this be three? (one for issuing a new one)
  expect(cardsFinder, findsNWidgets(2));

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(0),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'one@example.com',
    },
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'two@template.com',
    },
  );

  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await tester.tapAndSettle(cardsFinder.at(1));
  // go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // share
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // confirm
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

/// Disclose email and phone, but only email is already present -> should start issuance session for phone
Future<void> testOneMissingOnePresent(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10);

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': 'mail',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'path': ['email']
          },
        ]
      },
      {
        'id': 'phone',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.mobilenumber']
        },
        'claims': [
          {
            'path': ['mobilenumber']
          },
        ]
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
  final cardFinder = find.byType(YiviCredentialCard);

  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
  );

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));

  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // we can't actually open the browser in the integration test, so we'll just start an issuance session
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10);

  expect(find.text('All required data has been added'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));
  expect(find.text('This data has already been added to your app. Verify that the data is still correct.'),
      findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false).at(0),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
    },
  );
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false).at(1),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
    attributes: {
      'Mobile phone number': '0612345678',
    },
  );

  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

/// Starts the issuance flow during disclosure
Future<void> testDiscloseSdJwtThatsNotThere(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  final dcql = {
    'credentials': [
      {
        'id': '32f54163-7166-48f1-93d8-ff217bdb0653',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'path': ['email']
          },
        ]
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
  );

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));

  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // we can't actually open the browser in the integration test, so we'll just start an issuance session
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10);

  expect(find.text('All required data has been added'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

Future<void> testZeroInstanceCountShowsReobtainButton(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  const credentialCount = 1;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': '32f54163-7166-48f1-93d8-ff217bdb0653',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'path': ['email']
          },
        ]
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  // share button
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.email');
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    instancesRemaining: 0,
    style: IrmaCardStyle.danger,
    isExpired: true,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
    },
  );
}

Future<void> testLowCredentialInstanceCountShowsReobtainButton(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // threshold is 5, so issue one more to reach it after a single disclosure
  const credentialCount = 6;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': '32f54163-7166-48f1-93d8-ff217bdb0653',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'path': ['email']
          },
        ]
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
    },
  );

  // share button
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  // evaluate email is about to expire
  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.email');
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    instancesRemaining: credentialCount - 1,
    isExpiringSoon: true,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
    },
  );
}

Future<void> testDiscloseSdJwtOverOpenID4VP(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const credentialCount = 10;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': '32f54163-7166-48f1-93d8-ff217bdb0653',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'id': 'em',
            'path': ['email']
          },
          {
            'id': 'do',
            'path': ['domain']
          }
        ]
      },
      {
        'id': '32f54163-7166-48f1-93d8-ff217bdb0654',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.mobilenumber']
        },
        'claims': [
          {
            'id': 'mn',
            'path': ['mobilenumber']
          }
        ]
      }
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false).at(0),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
    },
  );
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false).at(1),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
    attributes: {
      'Mobile phone number': '0612345678',
    },
  );

  // share button
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  // evaluate phone and email instance counts have both decreased
  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.email');
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
    },
    instancesRemaining: credentialCount - 1,
  );

  await navigateBack(tester);
  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.mobilenumber');
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
    attributes: {
      'Mobile phone number': '0612345678',
    },
    instancesRemaining: credentialCount - 1,
  );
}

Future<void> testDiscloseSdJwtWithChoices(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const credentialCount = 10;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
      {
        'id': 'email-query',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.email']
        },
        'claims': [
          {
            'path': ['email']
          }
        ]
      },
      {
        'id': 'phone-query',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['irma-demo.sidn-pbdf.mobilenumber']
        },
        'claims': [
          {
            'path': ['mobilenumber']
          }
        ]
      }
    ],
    'credential_sets': [
      {
        'options': [
          ['email-query'],
          ['phone-query']
        ],
      }
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  await evaluateIntroduction(tester);

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // expect one card, namely the email credential
  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
    },
  );

  // tap on change button
  await tester.tapAndSettle(find.text('Change choice'));

  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // expect two credentials: email and phone...
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(0),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
    },
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
    attributes: {
      'Mobile phone number': '0612345678',
    },
  );

  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  // pick the phone
  await tester.tapAndSettle(cardsFinder.at(1));
  // go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // share
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // confirm
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  // evaluate phone cred count has decreased and email not
  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.email');
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
    },
    instancesRemaining: credentialCount,
  );

  await navigateBack(tester);
  await navigateToCredentialDetailsPage(tester, 'irma-demo.sidn-pbdf.mobilenumber');
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
    attributes: {
      'Mobile phone number': '0612345678',
    },
    instancesRemaining: credentialCount - 1,
  );
}

Future<String> startOpenID4VPSession(Map<String, dynamic> dcqlQuery) async {
  final authReqReq = {
    'type': 'vp_token',
    'dcql_query': dcqlQuery,
    'nonce': 'nonce',
    'jar_mode': 'by_reference',
    'request_uri_method': 'post',
    'issuer_chain': yiviStagingAttestationProvidersCA,
  };

  final authReqReqJson = jsonEncode(authReqReq);

  final uri = Uri.parse('https://verifierapi.openid4vc.staging.yivi.app/ui/presentations');

  final request = await HttpClient().postUrl(uri);
  request.headers.set('Content-Type', 'application/json');
  request.write(authReqReqJson);

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw 'Status ${response.statusCode}: $responseBody';
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  final sessionUrl = Uri(scheme: 'eudi-openid4vp', queryParameters: responseObject, host: '');
  return sessionUrl.toString();
}

const yiviStagingAttestationProvidersCA = '''
-----BEGIN CERTIFICATE-----
MIICbTCCAhSgAwIBAgIUX8STjkv3TRF5UBstXlp4ILHy2h0wCgYIKoZIzj0EAwQw
RjELMAkGA1UEBhMCTkwxDTALBgNVBAoMBFlpdmkxKDAmBgNVBAMMH1lpdmkgU3Rh
Z2luZyBSZXF1ZXN0b3JzIFJvb3QgQ0EwHhcNMjUwODEyMTUwODA1WhcNNDAwODA4
MTUwODA0WjBMMQswCQYDVQQGEwJOTDENMAsGA1UECgwEWWl2aTEuMCwGA1UEAwwl
WWl2aSBTdGFnaW5nIEF0dGVzdGF0aW9uIFByb3ZpZGVycyBDQTBZMBMGByqGSM49
AgEGCCqGSM49AwEHA0IABMDTwj6APykJnBdr0sCO8LpkULpbXFOBWV47hKKsJHsa
CVMarjLCYU3CV57UdklHSlMrtm7vfoDpYn4BvUv00UqjgdkwgdYwEgYDVR0TAQH/
BAgwBgEB/wIBADAfBgNVHSMEGDAWgBRjtHvVs5rhDnC0L2AUi+7ncyXe1jBwBgNV
HR8EaTBnMGWgY6Bhhl9odHRwczovL2NhLnN0YWdpbmcueWl2aS5hcHAvZWpiY2Ev
cHVibGljd2ViL2NybHMvc2VhcmNoLmNnaT9pSGFzaD1rRkNPdDhOTGhKOGcwV3FN
QW5sJTJCdm9OMlJ1WTAdBgNVHQ4EFgQUEjcBLRMmQGBJO0h04IL5Jwha1rEwDgYD
VR0PAQH/BAQDAgGGMAoGCCqGSM49BAMEA0cAMEQCIDEaWIs4uSm8KVQe+fy0EndE
Taj1ayt6dUgKQY/xZBO3AiAPYGwRlZMzbeCTFQ2ORLJiSowRtXzbmXpNDSyvtn7e
Dw==
-----END CERTIFICATE-----
''';
