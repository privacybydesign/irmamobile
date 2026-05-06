import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";

/// Verifier asks only for an optional credential; wallet empty. Because
/// nothing is *required*, the user can submit an empty disclosure.
///
/// Open question per the plan: confirm during a real run that the wallet
/// renders `DisclosureChoicesOverview` (not the issuance wizard) when only
/// optional creds are missing. If the backend instead promotes the optional
/// to a wizard step, this test should fall back to asserting the same
/// "Close" UX as the other empty-app tests; document and adapt.
Future<void> completelyOptionalCanSubmitEmptyTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {"path": ["email"]},
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
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  // No required cred is missing, so the wallet stays on the choices
  // overview rather than entering the issuance wizard.
  expect(find.byType(IssueDuringDisclosureScreen), findsNothing);
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);

  // Empty-state copy is rendered when no data is selected.
  expect(find.text("No data selected"), findsOneWidget);

  // Share button is enabled; submit empty disclosure and complete.
  await shareAndFinishEudiDisclosure(tester);
}
