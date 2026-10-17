import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
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
  await waitForRequest(tester);

  // No required cred is missing, so the share screen has no empty spot.
  expect(findEmptySpot(0), findsNothing);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Nothing is included: the button shares without data.
  expect(
    find.descendant(
      of: find.byKey(const Key("share_button")),
      matching: find.text("Share without data"),
    ),
    findsOneWidget,
  );

  // Share button is enabled; submit empty disclosure and complete.
  await shareAndFinishEudiDisclosure(tester);

  await verifyEmptyDisclosureActivityLog(
    tester,
    expectedRequestorName: veramoVerifierDisplayName,
  );
}
