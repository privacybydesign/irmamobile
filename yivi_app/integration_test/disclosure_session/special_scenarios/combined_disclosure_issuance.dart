import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> combinedDisclosureIssuanceSessionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding);

  // Email address
  // And receiving the  irma-demo.sidn-pbdf.uniqueid credential
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/issuance/v2",
          "credentials": [{
              "credential" : "irma-demo.sidn-pbdf.uniqueid",
              "attributes": {
                "uniqueid": "1234",
                "organization": "E-mail guild"
              }
            }],
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);

  // Combined issuance+disclosure sessions skip the introduction screen
  // and go straight to the disclosure choices overview.
  // For issuance sessions, the button says "Next" instead of "Share data".
  await tester.waitFor(find.text("Next"));
  await tester.tapAndSettle(find.text("Next"));

  // Expect add data screen
  expect(find.byType(IssuancePermission), findsOneWidget);

  final cardsFinder = find.byType(YiviCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Login data",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: {"Login code": "1234", "Organization": "E-mail guild"},
    style: IrmaCardStyle.normal,
  );

  // Tap add data button
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  final successScreenFinder = find.byType(IssuanceSuccessScreen);
  expect(successScreenFinder, findsOneWidget);

  await tester.tapAndSettle(find.text("OK"));

  expect(find.byType(SessionScreen), findsNothing);
}
