import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/data/passport_issuer.dart';
import 'package:irmamobile/src/data/passport_reader.dart';
import 'package:irmamobile/src/models/passport_data_result.dart';
import 'package:irmamobile/src/providers/passport_repository_provider.dart';
import 'package:irmamobile/src/screens/activity/activity_detail_screen.dart';
import 'package:irmamobile/src/screens/activity/widgets/activity_card.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/passport/mrz_reader_screen.dart';
import 'package:irmamobile/src/screens/passport/nfc_reading_screen.dart';
import 'package:irmamobile/src/screens/passport/widgets/mzr_scanner.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';
import 'package:irmamobile/src/widgets/requestor_header.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import 'disclosure_session/disclosure_helpers.dart';
import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'helpers/passport_helpers.dart';
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
      'disclosing-passport-opens-passport-scanning-flow',
      (tester) => testDisclosePassportOpensPassportScanner(tester, irmaBinding),
    );

    testWidgets(
      'empty-sdjwt-still-option',
      (tester) => testEmptySdJwtStillShowsInOptions(tester, irmaBinding),
    );

    testWidgets(
      'claim-sets-pick-first-satisfying-option',
      (tester) => testClaimSetsPickFirstSatisfyingOption(tester, irmaBinding),
    );

    testWidgets(
      'claim-with-multiple-value-options-two-match',
      (tester) => testClaimWithMultipleValueOptionsTwoMatch(tester, irmaBinding),
    );
    testWidgets(
      'claim-value-one-present-one-not',
      (tester) => testClaimValueOnePresentOneNot(tester, irmaBinding),
    );

    testWidgets(
      'optionally-disclose-extra-credential',
      (tester) => testOptionallyDiscloseExtraCredential(tester, irmaBinding),
    );

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
  });
}

Future<void> testDisclosePassportOpensPassportScanner(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  final fakeReader = FakePassportReader(
    statesDuringRead: [
      PassportReaderConnecting(),
      PassportReaderReadingCardAccess(),
      PassportReaderReadingCardSecurity(),
      PassportReaderReadingPassportData(dataGroup: 'DG1', progress: 0.0),
      PassportReaderSecurityVerification(),
      PassportReaderSuccess(result: PassportDataResult(dataGroups: {}, efSod: '')),
    ],
  );
  final fakeIssuer = FakePassportIssuer();

  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    Locale('en'),
    [
      passportReaderProvider.overrideWith((ref) => fakeReader),
      passportIssuerProvider.overrideWithValue(fakeIssuer),
    ],
  );

  final dcql = {
    'credentials': [
      {
        'id': 'country',
        'format': 'dc+sd-jwt',
        'meta': {
          'vct_values': ['pbdf-staging.pbdf.passport']
        },
        'claims': [
          {
            'id': 'c',
            'path': ['country'],
          },
        ],
      },
    ],
  };

  // first session to get to instance count of 0
  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();
  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);

  await tester.tapAndSettle(find.text('Obtain data'));

  expect(find.byType(AddDataDetailsScreen), findsOneWidget);
  await tester.tapAndSettle(find.text('Add'));

  await tester.waitFor(find.byType(MzrReaderScreen));

  final fakeMrz = FakeMrzResult(
    documentNumber: 'XR0000001',
    birthDate: DateTime(1990, 1, 1),
    expiryDate: DateTime(2030, 12, 31),
    countryCode: 'NLD',
  );

  final scannerState = tester.state<MRZScannerState>(find.byType(MRZScanner));
  scannerState.widget.onSuccess(
      fakeMrz, const ['P<NLDTEST<<EXAMPLE<<<<<<<<<<<<<<<<<<<<', 'XR0000001NLD9001011M3012317<<<<<<<<<<<<<<00']);

  await tester.pumpAndSettle();

  // Wait for NFC screen and press "Start scanning" button
  await tester.waitFor(find.byType(NfcReadingScreen));
  final startScanningButton = find.byKey(const Key('bottom_bar_primary'));
  await tester.tapAndSettle(startScanningButton);

  expect(fakeReader.readCallCount, greaterThanOrEqualTo(1));
  expect(fakeReader.lastDocumentNumber, fakeMrz.documentNumber);
  expect(fakeReader.lastBirthDate, fakeMrz.birthDate);
  expect(fakeReader.lastExpiryDate, fakeMrz.expiryDate);
  expect(fakeReader.lastCountryCode, fakeMrz.countryCode);

  // after reading passport an issuance session will start
  await tester.waitFor(find.byType(SessionScreen));

  // press the continue button
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  // should be back at the issue wizard screen
  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
}

Future<void> navigateToLatestActivity(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  expect(find.byKey(const Key('nav_button_activity')), findsOneWidget);

  await tester.tap(find.byKey(const Key('nav_button_activity'), skipOffstage: false));
  // for some reason pump and settle fails here in landscape mode, so we'll just do this instead...
  await tester.pump(const Duration(seconds: 1));

  // pick top card
  await tester.tapAndSettle(find.byType(ActivityCard, skipOffstage: false).at(0));
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
}

Future<void> testEmptySdJwtStillShowsInOptions(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 1, email: 'one@example.com', domain: 'example.com');

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
            'path': ['email'],
          },
        ],
      },
    ],
  };

  // first session to get to instance count of 0
  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(tester, cardsFinder);

  await shareAndFinishDisclosureSession(tester);

  // second session to make sure it still shows up in the list of options
  final session2Url = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(session2Url);

  await tester.pumpAndSettle();
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(tester, cardsFinder, isExpired: true);

  // make sure the share button is disabled, so it can't be pressed...
  final shareButton = tester.widget<YiviThemedButton>(find.widgetWithText(YiviThemedButton, 'Share data'));
  expect(shareButton.onPressed, isNull);

  // issue it again...
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 1, email: 'one@example.com', domain: 'example.com');

  // make sure the session can now be finished
  await shareAndFinishDisclosureSession(tester);

  // check a correct activity is showing up for the openid4vp session
  await navigateToLatestActivity(tester, irmaBinding);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'one@example.com',
    },
  );
  await evaluateRequestor(tester, find.byType(RequestorHeader), 'Yivi B.V.');
}

Future<void> testClaimSetsPickFirstSatisfyingOption(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com', domain: 'example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@template.com', domain: 'template.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'thee@not.com', domain: 'not.com');

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  // either email of exactly 'one@example.com' or any email with 'template.com' as domain
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
            'id': 'email-cond',
            'path': ['email'],
            'values': ['one@example.com']
          },
          {
            'id': 'domain-cond',
            'path': ['domain'],
            'values': ['template.com']
          },
          {
            'id': 'email-general',
            'path': ['email'],
          },
        ],
        'claim_sets': [
          ['email-cond'],
          ['domain-cond', 'email-general']
        ],
      },
    ],
  };
  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await tester.pumpAndSettle();
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await tapChangeChoicesButton(tester);

  // make sure there are three choices available (two existing + option to issue new one)
  expect(cardsFinder, findsNWidgets(3));
  expect(find.descendant(of: cardsFinder.at(0), matching: find.text('one@example.com')), findsOneWidget);
  expect(find.descendant(of: cardsFinder.at(1), matching: find.text('two@template.com')), findsOneWidget);

  // expect obtain new data with one card with a predefined value from the claim
  expect(find.text('Obtain new data', skipOffstage: false), findsOneWidget);
  expect(find.descendant(of: cardsFinder.at(2), matching: find.text('one@example.com')), findsOneWidget);

  // go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  await shareAndFinishDisclosureSession(tester);
}

Future<void> testClaimWithMultipleValueOptionsTwoMatch(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'three@example.com');

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
            'path': ['email'],
            'values': ['one@example.com', 'three@example.com']
          },
          {
            'id': 'do',
            'path': ['domain']
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
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'one@example.com',
      'Email domain name': 'example.com',
    },
  );

  await tapChangeChoicesButton(tester);
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // make sure there are two existing choices available + one obtain data
  expect(cardsFinder, findsNWidgets(3));
  expect(find.descendant(of: cardsFinder.at(0), matching: find.text('one@example.com')), findsOneWidget);
  expect(find.descendant(of: cardsFinder.at(1), matching: find.text('three@example.com')), findsOneWidget);

  expect(find.text('Obtain new data', skipOffstage: false), findsOneWidget);
  expect(find.descendant(of: cardsFinder.at(2), matching: find.text('one@example.com')), findsOneWidget);

  // go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  await shareAndFinishDisclosureSession(tester);
}

Future<void> testClaimValueOnePresentOneNot(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@example.com');

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
            'path': ['email'],
            'values': ['two@example.com']
          },
          {
            'id': 'do',
            'path': ['domain']
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
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'two@example.com',
      'Email domain name': 'example.com',
    },
  );

  await tapChangeChoicesButton(tester);
  expect(cardsFinder, findsNWidgets(2));

  expect(find.text('Obtain new data'), findsOneWidget);

  // confirm choice/go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  await shareAndFinishDisclosureSession(tester);
}

Future<void> testOptionallyDiscloseExtraCredential(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'one@example.com');
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10, email: 'two@example.com');
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10, phone: '0612345678');

  await tester.tapAndSettle(find.text('OK'));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

  final dcql = {
    'credentials': [
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
    ],
    'credential_sets': [
      {
        'required': false,
        'options': [
          ['mail']
        ],
      },
      {
        'options': [
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
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);

  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Mobile phone number',
    attributes: {
      'Mobile phone number': '0612345678',
    },
  );

  final addOptionalDataButton = find.text('Add optional data');
  await tester.scrollUntilVisible(addOptionalDataButton, 100);
  expect(addOptionalDataButton, findsOneWidget);

  await tester.tapAndSettle(addOptionalDataButton);

  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  expect(cardsFinder, findsNWidgets(3));
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(0),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'one@example.com',
      'Email domain name': 'example.com',
    },
  );
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'two@example.com',
      'Email domain name': 'example.com',
    },
  );

  await tester.scrollUntilVisible(cardsFinder.at(2), 100);
  expect(find.text('Obtain new data', skipOffstage: false), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(2),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
  );

  // confirm choice/go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  expect(cardsFinder, findsNWidgets(2));

  // now shows chosen credential card
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    credentialName: 'Demo Email address',
    attributes: {
      'Email address': 'one@example.com',
      'Email domain name': 'example.com',
    },
  );

  // remove the optional credential card
  await tester.tapAndSettle(find.byKey(const Key('remove_optional_data_button')));
  expect(addOptionalDataButton, findsOneWidget);

  await shareAndFinishDisclosureSession(tester);
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

  await tapChangeChoicesButton(tester);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);

  // expect 4 existing credentials + 2 buttons to obtain new ones
  expect(cardsFinder, findsNWidgets(6));

  expect(find.descendant(of: cardsFinder, matching: find.text('one@example.com')), findsOneWidget);
  expect(find.descendant(of: cardsFinder, matching: find.text('two@template.com')), findsOneWidget);
  expect(find.descendant(of: cardsFinder, matching: find.text('0612345678')), findsOneWidget);

  final lastExistingMobileFinder = find.descendant(of: cardsFinder, matching: find.text('0687654321'));
  expect(lastExistingMobileFinder, findsOneWidget);

  await tester.scrollUntilVisible(lastExistingMobileFinder, 100);
  await tester.tapAndSettle(lastExistingMobileFinder);

  expect(find.text('Obtain new data'), findsOneWidget);

  // confirm choice/go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  await shareAndFinishDisclosureSession(tester);
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
  final choiceButtonFinder = find.text('Change choice', skipOffstage: false);
  expect(choiceButtonFinder, findsNWidgets(2));

  // change the email
  await tester.scrollUntilVisible(choiceButtonFinder.at(0), 100);
  await tester.tapAndSettle(choiceButtonFinder.at(0));
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);

  // expect two existing + an obtain data card
  expect(cardsFinder, findsNWidgets(3));
  expect(
    find.descendant(of: cardsFinder, matching: find.text('one@example.com', skipOffstage: false)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: cardsFinder, matching: find.text('two@template.com', skipOffstage: false)),
    findsOneWidget,
  );
  expect(find.text('Obtain new data'), findsOneWidget);

  await tester.tapAndSettle(find.byType(YiviBackButton));

  // change mobilenumber
  await tester.scrollUntilVisible(choiceButtonFinder.at(1), 100);
  await tester.tapAndSettle(choiceButtonFinder.at(1));

  // expect two existing + an obtain data card
  expect(cardsFinder, findsExactly(3));
  expect(
    find.descendant(of: cardsFinder, matching: find.text('0612345678', skipOffstage: false)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: cardsFinder, matching: find.text('0687654321', skipOffstage: false)),
    findsOneWidget,
  );
  expect(find.text('Obtain new data'), findsOneWidget);

  await tester.tapAndSettle(find.byType(YiviBackButton));
  await shareAndFinishDisclosureSession(tester);

  await navigateToLatestActivity(tester, irmaBinding);

  const expectedNumCards = 2;

  expect(cardsFinder, findsExactly(expectedNumCards));

  // email and mobilenumber should both be there, but the order is not predefined fixed

  var emailFound = false;
  var mobilenumberFound = false;

  for (int i = 0; i < expectedNumCards; ++i) {
    final f = cardsFinder.at(i);

    if (find.descendant(of: f, matching: find.textContaining('Email')).evaluate().isNotEmpty) {
      await evaluateCredentialCard(
        tester,
        f,
        issuerName: 'Demo Privacy by Design Foundation via SIDN',
        credentialName: 'Demo Email address',
        attributes: {
          'Email address': 'one@example.com',
          'Email domain name': 'example.com',
        },
      );
      emailFound = true;
    } else {
      await evaluateCredentialCard(
        tester,
        cardsFinder.at(1),
        issuerName: 'Demo Privacy by Design Foundation via SIDN',
        credentialName: 'Demo Mobile phone number',
        attributes: {
          'Mobile phone number': '0687654321',
        },
      );
      mobilenumberFound = true;
    }
  }

  expect(emailFound && mobilenumberFound, isTrue);

  await evaluateRequestor(tester, find.byType(RequestorHeader), 'Yivi B.V.');
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

  await tapChangeChoicesButton(tester);

  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // expect two credentials: email and phone...
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);

  expect(cardsFinder, findsNWidgets(3));

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

  expect(find.text('Obtain new data'), findsOneWidget);

  // select the last credential card to start obtaining it
  await tester.scrollUntilVisible(cardsFinder.at(2), 100);
  await tester.tapAndSettle(cardsFinder.at(2));

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));

  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // we can't actually open the browser in the integration test, so we'll just start an issuance session
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10);

  // now expect to see 4 cards, of which 3 are existing
  expect(cardsFinder, findsNWidgets(4));

  // select one of them
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await tester.tapAndSettle(cardsFinder.at(1));

  // go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  await shareAndFinishDisclosureSession(tester);
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

  await shareAndFinishDisclosureSession(tester);
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
  await shareAndFinishDisclosureSession(tester);
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

  await shareAndFinishDisclosureSession(tester);

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

  await shareAndFinishDisclosureSession(tester);

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

  await shareAndFinishDisclosureSession(tester);

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

  await tapChangeChoicesButton(tester);

  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // expect two credentials: email and phone...
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  // 2 existing + 2 obtainable
  expect(cardsFinder, findsNWidgets(4));
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
  await shareAndFinishDisclosureSession(tester);

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
  final sessionUrl = Uri(scheme: 'openid4vp', queryParameters: responseObject, host: '');
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

Future<void> shareAndFinishDisclosureSession(WidgetTester tester) async {
  // share
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // confirm
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

Future<void> tapChangeChoicesButton(WidgetTester tester) async {
  final changeChoiceFinder = find.text('Change choice', skipOffstage: false);
  await tester.scrollUntilVisible(changeChoiceFinder, 100);
  await tester.tapAndSettle(changeChoiceFinder);
}
