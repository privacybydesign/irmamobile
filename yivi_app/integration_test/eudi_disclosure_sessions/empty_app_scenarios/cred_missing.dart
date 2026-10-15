import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Verifier asks for an OID4VCI email credential the wallet has never seen.
///
/// Backend (`irmago/internal/sessiontest/openid4vp_veramo_disclosure_test.go:
/// testVeramoVerifierRequestingMissingCredentialSurfacesIt`) populates
/// `IssueDuringDisclosure.Steps[0].Options[0]` with `IssueURL == nil` and
/// the descriptor's `Name`/`Issuer.Name` from VCT type metadata, while
/// leaving `DisclosureShareScreen` nil.
///
/// Wallet routing therefore renders the `AddMissingDataScreen`. Because the
/// descriptor has no IssueURL, nothing in the step can be added from Yivi
/// (`addActionFor` gives `CloseCannotAdd`): the one button is "Close", with
/// why above it. Tapping Close dismisses the session.
Future<void> credMissingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // No issuance — wallet has nothing.

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  // Wallet must NOT render the choices overview — the backend hides it
  // when issuance steps exist.
  expect(find.byType(DisclosureShareScreen), findsNothing);
  expect(find.byType(AddMissingDataScreen), findsOneWidget);

  // One step with one option: the credential name from VCT type metadata.
  // The bridge payload returns `issuer.name == null` for missing-cred
  // descriptors, so no issuer assertion is meaningful here.
  final step = findAddStep(0);
  expect(step, findsOneWidget);
  expect(findAddStep(1), findsNothing);
  final option = findAddOption(0, 0);
  expect(
    find.descendant(
      of: option,
      matching: find.text("Email Credential (SD-JWT)"),
    ),
    findsWidgets,
  );
  expect(
    find.descendant(
      of: option,
      matching: find.text("Can't be added from Yivi"),
    ),
    findsOneWidget,
  );

  // No add button — the cred type has no IssueURL; "Close", and why.
  expect(addButtonTexts(tester), ["Close"]);
  expect(find.byKey(const Key("add_reason")), findsOneWidget);

  await tester.tapAndSettle(
    find.descendant(
      of: find.byKey(const Key("add_button")),
      matching: find.text("Close"),
    ),
  );

  // The dismiss flow is async (dispatch → backend → state update → pop);
  // wait for the SessionScreen to fully unmount before ending the test so
  // the next test's setUp doesn't race against this widget tree's dispose.
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
