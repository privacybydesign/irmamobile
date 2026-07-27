import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_bell.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "disclosure_session/disclosure_helpers.dart";
import "helpers/eudi_issuance_helpers.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// End-to-end IETF Token Status List revocation for an SD-JWT credential issued
/// over OpenID4VCI, from the app's side: does a status list bit flip actually
/// reach the user?
///
/// irmago already covers the protocol level (unit tests over bit packing, token
/// verification and the refresh sweep; a docker e2e over the disclosure *plan*).
/// What only the app can prove is that the resulting status shows up on the
/// credential card, in the notification bell, and in the disclosure overview —
/// and that lifting the revocation clears it again.
///
/// Needs staging: the veramo test-issuer (which wires
/// `StatusListCredentialSdJwt` to the statuslist-agent and proxies revokes to
/// it) and the statuslist-agent itself, pinned to a build that packs the bit
/// array LSB-first. A pre-2026-07-09 agent packs it MSB-first, which makes a
/// compliant wallet read every revoked credential as valid *without any error* —
/// so read a failure of the revoked assertions as "check the agent version"
/// before suspecting the wallet.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("statuslist-revocation", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "revocation-surfaces-on-card-and-notification",
      (tester) =>
          _testRevocationSurfacesOnCardAndNotification(tester, irmaBinding),
    );

    testWidgets(
      "revoked-credential-flagged-in-disclosure",
      (tester) =>
          _testRevokedCredentialFlaggedInDisclosure(tester, irmaBinding),
    );
  });
}

const _credentialName = "Status List Credential (SD-JWT)";
const _issuerName = "Test Issuer";
const _revokedLabel = "Revoked";

/// The status sweep runs on the Go side and reports back over the bridge, so
/// give it room — this is a live fetch of the status list from staging.
const _refreshTimeout = Duration(seconds: 30);

/// Card, notification bell, and reinstatement.
Future<void> _testRevocationSurfacesOnCardAndNotification(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final marker = statusListRunMarker();
  await issueStatusListViaOpenID4VCI(tester, irmaBinding, email: marker);

  // Control. That issuance succeeded at all already proves the holder-side
  // status check passed: the wallet fetched the statuslist+jwt, verified it
  // against the agent's did:web, and read VALID at its freshly allocated index.
  await _openStatusListCredential(tester);
  expect(
    find.text(_revokedLabel),
    findsNothing,
    reason: "a freshly issued credential must not be flagged revoked",
  );
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    credentialName: _credentialName,
    issuerName: _issuerName,
    isRevoked: false,
    expectReobtainButton: false,
  );
  // The marker email is the credential's own attribute value, so this also
  // confirms we are looking at this run's credential. Attribute *labels* are
  // not asserted: the staging vct document declares no claim display names.
  expect(find.text(marker), findsOneWidget);
  await navigateBack(tester);

  // Revoke at the issuer, which proxies to the statuslist-agent and flips the
  // bit, then force the sweep the app would otherwise only run hourly.
  await setStatusListRevocation(marker, revoke: true);
  refreshCredentialStatuses(irmaBinding);

  await _openStatusListCredential(tester);
  await tester.pumpUntilFound(
    find.text(_revokedLabel),
    timeout: _refreshTimeout,
  );
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    credentialName: _credentialName,
    issuerName: _issuerName,
    isRevoked: true,
    style: IrmaCardStyle.danger,
    // OID4VCI credentials carry no IssueURL, so a revoked one still offers no
    // way to reobtain it.
    expectReobtainButton: false,
  );
  await navigateBack(tester);

  // The bell does not get pushed to; it loads its notifications when opened
  // and on pull-to-refresh.
  await tester.tapAndSettle(find.byType(NotificationBell));
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardsFinder = find.byType(NotificationCard);
  expect(notificationCardsFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardsFinder.first,
    title: "Data revoked",
    content: "$_issuerName has revoked this data: $_credentialName",
    read: false,
  );

  // Tapping the notification opens the credential it is about.
  await tester.tapAndSettle(notificationCardsFinder.first);
  expect(find.byType(YiviCredentialCard), findsOneWidget);

  // Lift the revocation: the sweep must move the credential back to valid, not
  // just one-way into revoked.
  await setStatusListRevocation(marker, revoke: false);
  refreshCredentialStatuses(irmaBinding);

  // Wait for the card to be back *and* unflagged, not merely for the label to
  // vanish: the details screen is driven by a FutureProvider over the
  // credentials stream, so every refresh puts it in AsyncLoading and swaps the
  // card for a spinner for a frame — which makes "Revoked" disappear too.
  final cardFinder = find.byType(YiviCredentialCard);
  await tester.pumpUntil(
    () => tester.any(cardFinder) && !tester.any(find.text(_revokedLabel)),
    timeout: _refreshTimeout,
  );
  await evaluateCredentialCard(
    tester,
    cardFinder,
    credentialName: _credentialName,
    issuerName: _issuerName,
    isRevoked: false,
    expectReobtainButton: false,
  );
}

/// A revoked credential is still *offered* for disclosure, flagged revoked —
/// IRMA parity: the wallet surfaces the flag and lets the frontend decide, with
/// the verifier's own status check as the backstop.
Future<void> _testRevokedCredentialFlaggedInDisclosure(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final marker = statusListRunMarker();
  await issueStatusListViaOpenID4VCI(tester, irmaBinding, email: marker);
  await setStatusListRevocation(marker, revoke: true);

  // Required, not decorative: issuance warmed the status list cache with the
  // still-valid token, and the disclosure-time check reads only that cache
  // (never fetches). Without forcing a refresh first, the plan would be built
  // from the stale valid token.
  refreshCredentialStatuses(irmaBinding);
  await _awaitRevokedInCredentialList(tester);

  final dcql = {
    "credentials": [
      {
        "id": "statuslist-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoStatusListCredentialVct],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpUntilFound(find.byType(DisclosureChoicesOverview));

  final cardsFinder = find.byType(YiviCredentialCard);
  expect(
    cardsFinder,
    findsOneWidget,
    reason: "the revoked instance must still be offered as an option",
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: _credentialName,
    issuerName: _issuerName,
    isRevoked: true,
    expectReobtainButton: false,
  );

  // Leave no session behind for the next test.
  await tester.tapAndSettle(find.byType(IrmaCloseButton));
  await tester.tapAndSettle(find.text("Yes"));
}

Future<void> _openStatusListCredential(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, veramoStatusListCredentialVct);
}

/// Waits until the refreshed (revoked) status has landed in the credential list,
/// so the disclosure session below is started against a wallet that already
/// knows about the revocation.
Future<void> _awaitRevokedInCredentialList(WidgetTester tester) async {
  await _openStatusListCredential(tester);
  await tester.pumpUntilFound(
    find.text(_revokedLabel),
    timeout: _refreshTimeout,
  );
  await navigateBack(tester);
}
