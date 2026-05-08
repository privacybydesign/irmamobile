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

/// OR disjunction across two cred types, each with two issued instances.
/// The change-choice screen exposes the four owned creds (no obtainable
/// templates — irmago leaves `obtainable_options == null` for OID4VCI cred
/// types). User selects one of the four owned options and proceeds.
Future<void> selectOneOfTwoEmailsAndTwoPhonesTest(
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
  await issuePhoneViaOpenID4VCI(tester, irmaBinding, phoneNumber: "0612345678");
  await issuePhoneViaOpenID4VCI(tester, irmaBinding, phoneNumber: "0687654321");

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
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
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
    ],
    "credential_sets": [
      {
        "options": [
          ["mail"],
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

  await tapChangeChoicesButton(tester);

  final cardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );

  // 4 owned options; no obtainable templates for OID4VCI.
  expect(cardsFinder, findsNWidgets(4));

  expect(
    find.descendant(of: cardsFinder, matching: find.text("one@example.com")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: cardsFinder, matching: find.text("two@template.com")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: cardsFinder, matching: find.text("0612345678")),
    findsOneWidget,
  );

  final lastPhoneFinder = find.descendant(
    of: cardsFinder,
    matching: find.text("0687654321"),
  );
  expect(lastPhoneFinder, findsOneWidget);

  await tester.scrollUntilVisible(lastPhoneFinder, 100);
  await tester.tapAndSettle(lastPhoneFinder);

  expect(find.text("Obtain new data"), findsNothing);

  // Confirm choice / go back.
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Phone Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Phone Number", "0687654321")],
      ),
    ],
  );
}
