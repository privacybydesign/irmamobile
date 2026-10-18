import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_parts.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/error/tx_code_lockout_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/openid4vci_preauth_txcode_screen.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "helpers/helpers.dart";
import "helpers/openid4vci_helpers.dart";
import "irma_binding.dart";
import "util.dart";

const _emailCredentialTileKey =
    "https://veramo-issuer.openid4vc.staging.yivi.app/test-issuer/vct/email";

final List<AttrRow> _organizationExpectedAttributes = [
  ("University Name", "TU Delft"),
  ("Founded", "1842"),
  (
    "Faculties",
    <Block>[
      [
        ("Faculty Name", "EEMCS"),
        (
          "Departments",
          <Block>[
            [
              ("Department Name", "Software Technology"),
              (
                "Courses",
                ["Compiler Construction", "Distributed Systems", "Intro to CS"],
              ),
            ],
            [
              ("Department Name", "Data Science"),
              ("Courses", ["Machine Learning"]),
            ],
          ],
        ),
      ],
      [
        ("Faculty Name", "Architecture"),
        (
          "Departments",
          <Block>[
            [
              ("Department Name", "Urbanism"),
              ("Courses", ["City Planning"]),
            ],
          ],
        ),
      ],
    ],
  ),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Required for enterText to work on iOS integration tests (Pinput included).
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("openid4vci-issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    // =========================================================================
    // Happy path tests
    // =========================================================================

    testWidgets(
      "issue-email-openid4vci",
      (tester) => testIssueEmailOpenID4VCI(tester, irmaBinding),
    );

    testWidgets(
      "issue-email-openid4vci-with-tx-code",
      (tester) => testIssueEmailOpenID4VCIWithTxCode(tester, irmaBinding),
    );

    testWidgets(
      "issue-organization-openid4vci",
      (tester) => testIssueOrganizationOpenID4VCI(tester, irmaBinding),
    );

    // =========================================================================
    // Error / dismissal tests
    // =========================================================================

    testWidgets(
      "dismiss-on-issuance-permission-screen",
      (tester) => testDismissOnIssuancePermissionScreen(tester, irmaBinding),
    );

    testWidgets(
      "wrong-tx-code-shows-inline-error",
      (tester) => testWrongTxCodeShowsInlineError(tester, irmaBinding),
    );

    testWidgets(
      "wrong-then-correct-tx-code",
      (tester) => testWrongThenCorrectTxCode(tester, irmaBinding),
    );

    testWidgets(
      "two-wrong-attempts-then-correct-tx-code",
      (tester) => testTwoWrongAttemptsThenCorrect(tester, irmaBinding),
    );

    testWidgets(
      "three-wrong-tx-code-attempts-shows-lockout",
      (tester) => testThreeWrongAttemptsLockout(tester, irmaBinding),
    );

    testWidgets(
      "cancel-after-wrong-tx-code-attempt",
      (tester) => testCancelAfterWrongAttempt(tester, irmaBinding),
    );

    testWidgets(
      "cancel-tx-code-screen-dismisses-session",
      (tester) => testCancelTxCodeScreenDismissesSession(tester, irmaBinding),
    );

    // =========================================================================
    // Credential management tests
    // =========================================================================

    testWidgets(
      "remove-deduped-and-unique-credentials",
      (tester) => testRemoveDedupedAndUniqueCredentials(tester, irmaBinding),
    );

    // =========================================================================
    // Credential card tests
    // =========================================================================

    testWidgets(
      "issue-nonexpiring-credential-shows-unlimited-validity",
      (tester) => testIssueNonExpiringCredentialShowsUnlimitedValidity(
        tester,
        irmaBinding,
      ),
    );
  });
}

// =============================================================================
// Happy path test implementations
// =============================================================================

Future<void> testIssueEmailOpenID4VCI(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: the wallet auto-grants and lands directly on IssuancePermission
  // with filled values.
  await tester.waitFor(find.byType(IssuancePermission));
  await evaluateCredentialCard(
    tester,
    findIssuanceCards().first,
    credentialName: "Email Credential (SD-JWT)",
    isExpired: false,
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  // Success screen
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Verify activity log
  await navigateToLatestActivity(tester);
  expect(find.text("YOU RECEIVED"), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(ActivityCredentialTile).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    isExpired: false,
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
}

Future<void> testIssueEmailOpenID4VCIWithTxCode(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // Tx code screen appears directly (no preview screen anymore). Use
  // pumpUntilFound rather than waitFor here: waitFor pumps-and-settles, but
  // Pinput's blinking-cursor animation never settles once the screen mounts.
  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  // Pinput auto-submits on completion.
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await evaluateCredentialCard(
    tester,
    findIssuanceCards().first,
    credentialName: "Email Credential (SD-JWT)",
    isExpired: false,
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  // Success screen
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Verify activity log
  await navigateToLatestActivity(tester);
  expect(find.text("YOU RECEIVED"), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(ActivityCredentialTile).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    isExpired: false,
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
}

Future<void> testIssueOrganizationOpenID4VCI(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "OrganizationCredentialSdJwt",
    credentialData: {
      "name": "TU Delft",
      "faculties": [
        {
          "faculty_name": "EEMCS",
          "departments": [
            {
              "dept_name": "Software Technology",
              "courses": [
                "Compiler Construction",
                "Distributed Systems",
                "Intro to CS",
              ],
            },
            {
              "dept_name": "Data Science",
              "courses": ["Machine Learning"],
            },
          ],
        },
        {
          "faculty_name": "Architecture",
          "departments": [
            {
              "dept_name": "Urbanism",
              "courses": ["City Planning"],
            },
          ],
        },
      ],
      "founded": 1842,
    },
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: lands directly on IssuancePermission with filled values.
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.pumpAndSettle();
  expect(findIssuanceCards(), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    findIssuanceCards().first,
    credentialName: "Organization Credential (SD-JWT)",
    isExpired: false,
    attributes: _organizationExpectedAttributes,
  );

  // Scroll back to the top to tap "Add"
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    find.byKey(const Key("bottom_bar_primary")),
    -100,
    scrollable: scrollable,
    maxScrolls: 50,
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  // Success screen
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Verify activity log — same nested-claim assertion.
  await navigateToLatestActivity(tester);
  expect(find.text("YOU RECEIVED"), findsOneWidget);
  await tester.pumpAndSettle();

  await evaluateCredentialCard(
    tester,
    find.byType(ActivityCredentialTile).first,
    credentialName: "Organization Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: _organizationExpectedAttributes,
  );
}

// =============================================================================
// Error / dismissal test implementations
// =============================================================================

Future<void> testDismissOnIssuancePermissionScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: lands directly on IssuancePermission. Tap "Cancel".
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));

  // Should be back at home
  await tester.waitFor(find.byType(DataTab));

  // Verify no credential stored
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(Key("${_emailCredentialTileKey}_tile")), findsNothing);

  // Verify no activity logged
  await tester.tap(find.byKey(const Key("nav_button_activity")));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text("There are no logged activities yet"), findsOneWidget);
}

/// A wrong tx_code keeps the user on the tx_code screen with an inline
/// error and a cleared input — no navigation to the generic error screen.
Future<void> testWrongTxCodeShowsInlineError(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // Pinput's blinking-cursor animation never settles, so we cannot use
  // waitFor / pumpAndSettle while the tx_code screen is on top.
  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  // Still on tx_code screen — no navigation to ErrorScreen.
  expect(find.byType(OpenID4VCIPreAuthTxCodeScreen), findsOneWidget);
  expect(find.byType(ErrorScreen), findsNothing);

  // Cancel out and verify clean state. We wait for the tx_code screen to
  // unmount before any tap-and-settle: while it's animating out, its cursor
  // still ticks and any subsequent tap may be absorbed by the off-stage
  // route.
  await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
  // After the tx_code screen unmounts the cursor stops, so pumpAndSettle is
  // safe again — and we need it because the home's bottom nav transition
  // continues briefly after the pop completes.
  await tester.pumpUntilGone(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(Key("${_emailCredentialTileKey}_tile")), findsNothing);
}

/// Wrong code, then the correct code: success path still works after retry.
Future<void> testWrongThenCorrectTxCode(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));

  // First attempt: wrong code.
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  // Second attempt: correct code.
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

/// Two wrong codes, then correct: verifies the singular wording on the
/// last-chance attempt ("1 attempt remaining").
Future<void> testTwoWrongAttemptsThenCorrect(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "111111",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 1 attempt remaining."),
  );

  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

/// Three wrong codes in a row → dedicated lockout screen, not the generic
/// error screen.
Future<void> testThreeWrongAttemptsLockout(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "111111",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 1 attempt remaining."),
  );
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "222222",
  );
  await tester.pumpUntilFound(find.byType(TxCodeLockoutScreen));
  expect(find.byType(ErrorScreen), findsNothing);

  await tester.tapAndSettle(find.text("OK"));
  await tester.waitFor(find.byType(DataTab));

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(Key("${_emailCredentialTileKey}_tile")), findsNothing);

  await tester.tap(find.byKey(const Key("nav_button_activity")));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text("There are no logged activities yet"), findsOneWidget);
}

/// User can cancel cleanly after a wrong attempt — no leaked retry state,
/// no credential issued.
Future<void> testCancelAfterWrongAttempt(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
  // After the tx_code screen unmounts the cursor stops, so pumpAndSettle is
  // safe again — and we need it because the home's bottom nav transition
  // continues briefly after the pop completes.
  await tester.pumpUntilGone(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(Key("${_emailCredentialTileKey}_tile")), findsNothing);

  await tester.tap(find.byKey(const Key("nav_button_activity")));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text("There are no logged activities yet"), findsOneWidget);
}

Future<void> testCancelTxCodeScreenDismissesSession(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    txCodeInputMode: "numeric",
    txCodeLength: 6,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // Tx code screen — tap "Cancel" in the bottom bar to dismiss the session.
  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.tap(find.byKey(const Key("bottom_bar_secondary")));

  // Should be back at home (no confirmation dialog). Wait for the tx_code
  // screen to actually unmount — until then, its blinking cursor blocks
  // pumpAndSettle and the route still absorbs taps.
  await tester.pumpUntilGone(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.pumpAndSettle();

  // Verify no credential stored
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(Key("${_emailCredentialTileKey}_tile")), findsNothing);

  // Verify no activity logged
  await tester.tap(find.byKey(const Key("nav_button_activity")));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text("There are no logged activities yet"), findsOneWidget);
}

// =============================================================================
// Credential management test implementations
// =============================================================================

Future<void> testRemoveDedupedAndUniqueCredentials(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Issue 3 EmailCredentialSdJwt credentials. The first two share attribute
  // values; the third differs only in the email address. The wallet groups
  // credentials with identical attribute values into a single card on the
  // details screen, so we expect 2 cards rather than 3.
  await _issueEmailCredViaPreAuth(
    tester,
    irmaBinding,
    email: "test@example.com",
  );
  await _issueEmailCredViaPreAuth(
    tester,
    irmaBinding,
    email: "test@example.com",
  );
  await _issueEmailCredViaPreAuth(
    tester,
    irmaBinding,
    email: "other@example.com",
  );

  // The data tab shows one card per credential instance: one merged card
  // (test@) for both identical instances, one unique card (other@).
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.waitFor(findWalletCards(_emailCredentialTileKey));
  expect(
    findWalletCards(_emailCredentialTileKey, skipOffstage: false),
    findsExactly(2),
  );

  // Delete the merged card first
  await navigateToCredentialDetailsPage(
    tester,
    _emailCredentialTileKey,
    index: _walletCardIndexWithEmail(tester, "test@example.com"),
  );
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
  await deleteCredentialFromDetail(tester);

  // Only the unique card remains
  expect(
    findWalletCards(_emailCredentialTileKey, skipOffstage: false),
    findsOneWidget,
  );

  // Delete the remaining (unique) card
  await navigateToCredentialDetailsPage(tester, _emailCredentialTileKey);
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "other@example.com"), ("Domain", "example.com")],
  );
  await deleteCredentialFromDetail(tester);

  // No card of this type should remain on the data tab.
  await tester.waitFor(find.byType(DataTab));
  expect(
    findWalletCards(_emailCredentialTileKey, skipOffstage: false),
    findsNothing,
  );

  // Activity tab: two removal entries, drilled into in turn.
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));

  expect(find.text("Data deleted"), findsExactly(2));

  // Most-recent activity entry → unique-card removal (deleted second)
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  expect(find.text("YOU DELETED"), findsOneWidget);
  expect(find.byType(ActivityCredentialTile), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(ActivityCredentialTile).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [("Email", "other@example.com"), ("Domain", "example.com")],
  );

  // Back to activity list, then drill into the older removal
  await tester.tapAndSettle(find.byType(YiviBackButton));

  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(1),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  expect(find.text("YOU DELETED"), findsOneWidget);
  expect(find.byType(ActivityCredentialTile), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(ActivityCredentialTile).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
}

// =============================================================================
// Credential card test implementations
// =============================================================================

Future<void> testIssueNonExpiringCredentialShowsUnlimitedValidity(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await _issueEmailCredViaPreAuth(
    tester,
    irmaBinding,
    email: "test@example.com",
    ttlSeconds: null,
  );

  // Open the card's detail view.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.waitFor(findWalletCards(_emailCredentialTileKey));
  expect(
    findWalletCards(_emailCredentialTileKey, skipOffstage: false),
    findsOneWidget,
  );
  await navigateToCredentialDetailsPage(tester, _emailCredentialTileKey);
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
    isExpired: false,
    isExpiringSoon: false,
  );

  // The validity chip says "Valid indefinitely", not a date.
  expect(
    find.descendant(
      of: findCredentialDetail(),
      matching: find.text("Valid indefinitely"),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: findCredentialDetail(),
      matching: find.textContaining("Valid until"),
    ),
    findsNothing,
  );
}

// =============================================================================
// Helper functions
// =============================================================================

/// Issues a single EmailCredentialSdJwt via the pre-authorized code flow with
/// the wallet at home. Returns to home after success.
Future<void> _issueEmailCredViaPreAuth(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required String email,
  int? ttlSeconds = 31536000,
}) async {
  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": email, "domain": "example.com"},
    ttlSeconds: ttlSeconds,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: auto-grants and lands directly on IssuancePermission.
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

/// The index, among the data tab's cards of the email type, of the card whose
/// email address is [email].
int _walletCardIndexWithEmail(WidgetTester tester, String email) {
  final cards = walletCards(
    tester,
  ).where((c) => c.credentialId == _emailCredentialTileKey).toList();
  final index = cards.indexWhere(
    (c) => c.attributes.any((a) => a.value?.string == email),
  );
  expect(index, isNot(-1), reason: "No email card with $email");
  return index;
}

/// Navigates to the Activity tab and opens the most recent activity entry.
Future<void> navigateToLatestActivity(WidgetTester tester) async {
  expect(find.byKey(const Key("nav_button_activity")), findsOneWidget);

  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));

  // Tap the top activity card
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
}
