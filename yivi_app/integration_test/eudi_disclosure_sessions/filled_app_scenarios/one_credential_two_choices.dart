import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../eudi_choice_helpers.dart";

/// Issue two emails, then disclose. The change-choice screen lists exactly
/// the two owned creds — no "Obtain new data" template card is shown
/// (irmago leaves `obtainable_options == null` for OID4VCI cred types
/// because they have no `IssueURL`). The user picks one of the two owned
/// creds and proceeds.
Future<void> oneCredentialTwoChoicesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "two@template.com",
    domain: "template.com",
  );

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);

  await tapChangeChoicesButton(tester);
  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  final cardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );

  // Two owned; no obtainable template card for OID4VCI.
  expect(cardsFinder, findsNWidgets(2));

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(0),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "one@example.com")],
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "two@template.com")],
  );
  expect(find.text("Obtain new data"), findsNothing);

  // Pick the second owned cred and go back.
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await tester.tapAndSettle(cardsFinder.at(1));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Email", "two@template.com")],
      ),
    ],
  );
}
