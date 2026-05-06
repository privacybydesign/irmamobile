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

/// Required: phone. Optional: email. Wallet has both. Tests the "Add
/// optional data" flow on the choices overview. The change-choice screen
/// shows only the two owned email cards (no obtainable template — irmago
/// leaves `obtainable_options == null` for OID4VCI cred types).
Future<void> optionalExtraCredentialTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "one@example.com",
  );
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "two@example.com",
  );
  await issuePhoneViaOpenID4VCI(
    tester,
    irmaBinding,
    phoneNumber: "0612345678",
  );

  final dcql = {
    "credentials": [
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["phone_number"],
          },
        ],
      },
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "required": false,
        "options": [
          ["mail"],
        ],
      },
      {
        "options": [
          ["phone"],
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  // Default selection is the required cred (phone).
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Test Issuer",
    credentialName: "Phone Credential (SD-JWT)",
    attributes: [("Phone Number", "0612345678")],
  );

  final addOptionalDataButton = find.text("Add optional data");
  await tester.scrollUntilVisible(addOptionalDataButton, 100);
  expect(addOptionalDataButton, findsOneWidget);
  await tester.tapAndSettle(addOptionalDataButton);

  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  final choiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );

  // Two owned email cards; no obtainable template card for OID4VCI.
  expect(choiceCardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder.at(0),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [
      ("Email", "one@example.com"),
      ("Domain", "example.com"),
    ],
  );
  await tester.scrollUntilVisible(choiceCardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder.at(1),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [
      ("Email", "two@example.com"),
      ("Domain", "example.com"),
    ],
  );
  expect(find.text("Obtain new data"), findsNothing);

  // Confirm choice / go back to overview.
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  // Overview now shows two cards: phone + chosen email.
  expect(cardsFinder, findsNWidgets(2));
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [
      ("Email", "one@example.com"),
      ("Domain", "example.com"),
    ],
  );

  // Remove the optional card.
  await tester.tapAndSettle(
    find.byKey(const Key("remove_optional_data_button")),
  );
  expect(addOptionalDataButton, findsOneWidget);

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
