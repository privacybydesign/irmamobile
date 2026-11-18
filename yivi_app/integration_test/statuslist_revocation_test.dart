import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/refresh_credential_statuses_event.dart";
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

/// Does a Token Status List revocation reach the user? Covers the card, the
/// notification, the disclosure overview, and the way back after reinstatement.
///
/// Runs against staging. Note that a stale Go bridge drops the refresh event
/// silently, so run `bind_go.sh` after changing anything under irmagobridge.
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

/// Room for a live status list fetch from staging, round-tripped over the bridge.
const _refreshTimeout = Duration(seconds: 30);

Future<void> _testRevocationSurfacesOnCardAndNotification(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final marker = statusListRunMarker();
  await issueStatusListViaOpenID4VCI(tester, irmaBinding, email: marker);

  // Control: issuance succeeding at all already proves the holder-side status
  // check read VALID at the allocated index.
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
  // Confirms this is our run's credential. Labels aren't asserted: the staging
  // vct document declares no claim display names.
  expect(find.text(marker), findsOneWidget);
  await navigateBack(tester);

  await setStatusListRevocation(marker, revoke: true);
  _refreshStatuses(irmaBinding);

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
    // OID4VCI credentials carry no IssueURL, so there is nothing to reobtain.
    expectReobtainButton: false,
  );
  await navigateBack(tester);

  // The bell loads notifications when opened and on pull-to-refresh; nothing
  // pushes into it.
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
  // Pins the starting state, so the wait for the label to go away below cannot
  // pass on a card that never had it.
  expect(find.text(_revokedLabel), findsOneWidget);

  await setStatusListRevocation(marker, revoke: false);
  _refreshStatuses(irmaBinding);

  // Wait for the card back *and* unflagged: every refresh briefly swaps the card
  // for a spinner (FutureProvider over the credentials stream), which on its own
  // already makes the label vanish.
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

/// IRMA parity: a revoked credential is still offered, flagged, for the frontend
/// to decide on — the verifier's own check is the backstop.
Future<void> _testRevokedCredentialFlaggedInDisclosure(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final marker = statusListRunMarker();
  await issueStatusListViaOpenID4VCI(tester, irmaBinding, email: marker);
  await setStatusListRevocation(marker, revoke: true);

  // Required: the disclosure-time check reads only the cache, which issuance
  // warmed with the still-valid token.
  _refreshStatuses(irmaBinding);
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

/// Drives the sweep directly, so the test does not depend on the app's own
/// resume/periodic triggers.
void _refreshStatuses(IntegrationTestIrmaBinding irmaBinding) =>
    irmaBinding.repository.bridgedDispatch(RefreshCredentialStatusesEvent());

Future<void> _openStatusListCredential(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, veramoStatusListCredentialVct);
}

/// Waits until the refresh has landed, so the session starts against a wallet
/// that already knows about the revocation.
Future<void> _awaitRevokedInCredentialList(WidgetTester tester) async {
  await _openStatusListCredential(tester);
  await tester.pumpUntilFound(
    find.text(_revokedLabel),
    timeout: _refreshTimeout,
  );
  await navigateBack(tester);
}
