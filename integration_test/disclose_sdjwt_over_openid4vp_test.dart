import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';

import 'disclosure_session/disclosure_helpers.dart';
import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('disclose sdjwt over openid4vp', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

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
            'path': ['email']
          },
          {
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

  // TODO: evaluate credential count has been decreased for both credentials
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

  // pick the phone
  await tester.tapAndSettle(cardsFinder.at(1));
  // go back
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // share
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
  // confirm
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  // TODO: evaluate phone cred count has decreased and email not
}

Future<String> startOpenID4VPSession(Map<String, dynamic> dcqlQuery) async {
  final authReqReq = {
    'type': 'vp_token',
    'dcql_query': dcqlQuery,
    'nonce': 'nonce',
    'jar_mode': 'by_reference',
    'request_uri_method': 'post',
    'issuer_chain': demoIssuerSdJwtCertChain,
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

const demoIssuerSdJwtCertChain = '''
-----BEGIN CERTIFICATE-----
MIICITCCAcigAwIBAgIUJmW4EIKWApJzMrgBjkLi8AnO3f8wCgYIKoZIzj0EAwIw
QTELMAkGA1UEBhMCTkwxDTALBgNVBAoMBFlpdmkxIzAhBgNVBAMMGm9wZW5pZDR2
Yy5zdGFnaW5nLnlpdmkuYXBwMB4XDTI1MDYwMzA4MzQxNloXDTM1MDYwMTA4MzQx
NlowQTELMAkGA1UEBhMCTkwxDTALBgNVBAoMBFlpdmkxIzAhBgNVBAMMGm9wZW5p
ZDR2Yy5zdGFnaW5nLnlpdmkuYXBwMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE
Sr7bMrDTDe+R/HI1wywYtEYr+DJa5HdTnI8dsjZer6grPyZ4vxTeOmdjU9wp0Wkz
fONmyk8xsPePon4AhwCK+aOBnTCBmjAMBgNVHRMBAf8EAjAAMAsGA1UdDwQEAwIF
oDATBgNVHSUEDDAKBggrgQICAAABBzBJBgNVHREEQjBAhiJodHRwczovL29wZW5p
ZDR2Yy5zdGFnaW5nLnlpdmkuYXBwghpvcGVuaWQ0dmMuc3RhZ2luZy55aXZpLmFw
cDAdBgNVHQ4EFgQUNFp/ITlrNmraTYMsN3jijYUmLXswCgYIKoZIzj0EAwIDRwAw
RAIgYDuyJIVAY/2XEoxU1802ztuawBc618Ygyz39PinWrk0CIH2kc3A3LsnYDWun
6PY2x495dIntuwQAXq9ThYjvtOCE
-----END CERTIFICATE-----
''';
