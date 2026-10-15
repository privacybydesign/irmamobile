import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../eudi_choice_helpers.dart";

/// DCQL `values` filter accepting a list of acceptable values. Issues three
/// emails (`one@`, `two@`, `three@`); verifier asks for email in
/// {one@example.com, three@example.com} plus domain. Two creds match.
Future<void> valueOptionsTwoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "one@example.com");
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "two@example.com");
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "three@example.com",
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
            "id": "em",
            "path": ["email"],
            "values": ["one@example.com", "three@example.com"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "one@example.com"), ("Domain", "example.com")],
  );

  await tapChangeChoicesButton(tester);
  expect(find.byKey(const Key("disclosure_choice_sheet")), findsOneWidget);

  final choiceCardsFinder = find.descendant(
    of: find.byKey(const Key("disclosure_choice_sheet")),
    matching: findCredentialCards(),
    skipOffstage: false,
  );

  // Two matching owned creds; no obtainable template card for OID4VCI
  // (backend leaves `obtainable_options == null` because the cred type has
  // no IssueURL).
  expect(choiceCardsFinder, findsNWidgets(2));
  expect(
    find.descendant(
      of: choiceCardsFinder.at(0),
      matching: find.text("one@example.com"),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: choiceCardsFinder.at(1),
      matching: find.text("three@example.com"),
    ),
    findsOneWidget,
  );
  expect(find.text("Obtain new data"), findsNothing);

  // Confirm choice / go back.
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Email", "one@example.com"), ("Domain", "example.com")],
      ),
    ],
  );
}
