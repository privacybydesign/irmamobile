import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";

/// Verifier asks only for an optional credential; wallet empty. Because
/// nothing is *required*, the user can submit an empty disclosure. The
/// resulting activity log entry should still record the transaction with
/// the requestor, even though no data was shared — mirroring the IRMA
/// `completely_optional` scenario.
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
          {
            "path": ["email"],
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
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await tester.pumpAndSettle();

  // No required cred is missing, so the wallet stays on the choices
  // overview rather than entering the issuance wizard.
  expect(find.byType(AddMissingDataScreen), findsNothing);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Empty-state copy is rendered when no data is selected.
  expect(find.text("No data selected"), findsOneWidget);

  // Share button is enabled; submit empty disclosure and complete.
  await shareAndFinishEudiDisclosure(tester);

  await verifyEmptyDisclosureActivityLog(
    tester,
    expectedRequestorName: veramoVerifierDisplayName,
  );
}
