import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../eudi_disclosure_sessions/eudi_choice_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 20: a requested value with several acceptable values on a non-boolean
/// element. Three PID mdocs are issued (Amsterdam, Utrecht, Rotterdam); the
/// verifier accepts Amsterdam or Utrecht. Two match, so the change-choice
/// screen lists exactly those two, and the user can pick either.
Future<void> pidRequestedValueTwoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  for (final city in ["Amsterdam", "Utrecht", "Rotterdam"]) {
    await issuePidMdoc(
      tester,
      irmaBinding,
      data: pidMdocData(residentCity: city),
    );
  }

  const dcql = """
{
  "credentials": [
    {
      "id": "pid",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.eudi.pid.1" },
      "claims": [
        { "path": ["eu.europa.ec.eudi.pid.1", "family_name"] },
        {
          "path": ["eu.europa.ec.eudi.pid.1", "resident_city"],
          "values": ["Amsterdam", "Utrecht"]
        }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(find.byType(YiviCredentialCard, skipOffstage: false), findsOneWidget);

  await tapChangeChoicesButton(tester);
  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  final choiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  // The two matching PIDs; the Rotterdam one is filtered out by irmago and
  // there is no obtainable template for an mdoc.
  expect(choiceCardsFinder, findsNWidgets(2));
  expect(
    find.descendant(
      of: choiceCardsFinder,
      matching: find.text("Amsterdam", skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: choiceCardsFinder,
      matching: find.text("Utrecht", skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(find.text("Rotterdam", skipOffstage: false), findsNothing);
  expect(find.text("Obtain new data"), findsNothing);

  // Pick the Amsterdam PID explicitly, confirm, share.
  final amsterdamCard = find.ancestor(
    of: find.text("Amsterdam", skipOffstage: false),
    matching: find.byType(YiviCredentialCard),
  );
  await tester.scrollUntilVisible(amsterdamCard, 100);
  await tester.tapAndSettle(amsterdamCard);
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: pidMdocCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: [("Family Name(s)", "Doe"), ("Resident City", "Amsterdam")],
      ),
    ],
  );
}
