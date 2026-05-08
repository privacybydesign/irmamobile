import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Verifier asks for an OID4VCI email credential the wallet has never seen.
///
/// Backend (`irmago/internal/sessiontest/openid4vp_veramo_disclosure_test.go:
/// testVeramoVerifierRequestingMissingCredentialSurfacesIt`) populates
/// `IssueDuringDislosure.Steps[0].Options[0]` with `IssueURL == nil` and
/// the descriptor's `Name`/`Issuer.Name` from VCT type metadata, while
/// leaving `DisclosureChoicesOverview` nil.
///
/// Wallet routing (`session_screen.dart:253-262`) therefore renders the
/// `IssueDuringDisclosureScreen`. Because the descriptor has no IssueURL,
/// `currentIsObtainable` is false and the bottom-bar primary becomes
/// "Close" (`issue_during_disclosure_screen.dart:119-122`). Tapping Close
/// dismisses the session.
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
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  // Wallet must NOT render the choices overview — the backend hides it
  // when issuance steps exist.
  expect(find.byType(DisclosureChoicesOverview), findsNothing);
  expect(find.byType(IssueDuringDisclosureScreen), findsOneWidget);

  // The missing-cred descriptor card displays the credential name from VCT
  // type metadata. We use a direct text-finder rather than
  // `evaluateCredentialCard(credentialName: ...)` because the unobtainable
  // descriptor's metadata carries no logo, so `IrmaAvatar` falls back to
  // rendering `credentialName[0]` as initials — making the *first* text in
  // the header "E", not the full credential name. The bridge payload also
  // returns `issuer.name == null` for missing-cred descriptors, so no
  // issuer assertion is meaningful here.
  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  expect(
    find.descendant(
      of: cardFinder,
      matching: find.text("Email Credential (SD-JWT)"),
    ),
    findsOneWidget,
  );

  // No "Obtain data" CTA — the cred type has no IssueURL.
  expect(find.text("Obtain data"), findsNothing);
  expect(find.text("Close"), findsOneWidget);

  await tester.tapAndSettle(find.text("Close"));

  // The dismiss flow is async (dispatch → backend → state update → pop);
  // wait for the SessionScreen to fully unmount before ending the test so
  // the next test's setUp doesn't race against this widget tree's dispose.
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
