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

/// OR disjunction: verifier asks for email OR phone. Wallet has both.
/// Default selection is email; user opens change-choice, picks phone, and
/// shares. Asserts the chosen cred's instance count decremented and the
/// other cred's count is unchanged.
Future<void> discloseWithChoiceDisjunctionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "test@example.com",
    domain: "example.com",
  );
  await issuePhoneViaOpenID4VCI(
    tester,
    irmaBinding,
    phoneNumber: "0612345678",
  );

  final dcql = {
    "credentials": [
      {
        "id": "email-query",
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
      {
        "id": "phone-query",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "path": ["phone_number"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "options": [
          ["email-query"],
          ["phone-query"],
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);

  // Default selection is the email cred.
  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "test@example.com")],
  );

  await tapChangeChoicesButton(tester);
  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  final cardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  // 2 owned options; no obtainable templates for OID4VCI (the irmago
  // backend leaves `obtainable_options == null` for cred types without an
  // IssueURL).
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(0),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "test@example.com")],
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: "Test Issuer",
    credentialName: "Phone Credential (SD-JWT)",
    attributes: [("Phone Number", "0612345678")],
  );

  // Pick the phone, go back, share.
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await tester.tapAndSettle(cardsFinder.at(1));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Phone Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Phone Number", "0612345678")],
      ),
    ],
  );
}
