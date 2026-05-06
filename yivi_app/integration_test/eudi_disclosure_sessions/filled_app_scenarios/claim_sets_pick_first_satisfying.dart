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

/// DCQL claim_sets — verifier offers two satisfying claim sets:
///   1. email-cond: email == "one@example.com"
///   2. domain-cond: domain == "template.com" + email-general (any email)
/// Wallet has three emails, two of which satisfy a claim set. Asserts the
/// first satisfying credential is preselected and that the change-choice
/// screen lists exactly the two matching owned credentials.
///
/// Unlike the IRMA-issued SD-JWT spine, no "Obtain new data" template card
/// is rendered: the irmago backend leaves `obtainable_options == null` for
/// OID4VCI credential types because they carry no `IssueURL`, so
/// `DisclosureMakeChoiceScreen` simply doesn't render the obtainable
/// section.
Future<void> claimSetsPickFirstSatisfyingTest(
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
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "three@not.com",
    domain: "not.com",
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
            "id": "email-cond",
            "path": ["email"],
            "values": ["one@example.com"],
          },
          {
            "id": "domain-cond",
            "path": ["domain"],
            "values": ["template.com"],
          },
          {
            "id": "email-general",
            "path": ["email"],
          },
        ],
        "claim_sets": [
          ["email-cond"],
          ["domain-cond", "email-general"],
        ],
      },
    ],
  };
  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(find.byType(YiviCredentialCard, skipOffstage: false), findsOneWidget);

  await tapChangeChoicesButton(tester);

  final choiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );

  // Two owned (matching emails) and no obtainable template card.
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
      matching: find.text("two@template.com"),
    ),
    findsOneWidget,
  );
  expect(find.text("Obtain new data"), findsNothing);

  // Confirm choice / go back.
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await shareAndFinishEudiDisclosure(tester);
}
