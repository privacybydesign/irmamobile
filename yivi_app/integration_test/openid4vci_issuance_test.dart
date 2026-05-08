import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_issuance.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_removal.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/error/tx_code_lockout_screen.dart";
import "package:yivi_core/src/screens/notifications/notifications_tab.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_bell.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/oid4vci_preauth_txcode_screen.dart";
import "package:yivi_core/src/widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

const _issuerBaseUrl =
    "https://veramo-issuer.openid4vc.staging.yivi.app/test-issuer";
const _adminToken = "veramo-issuer-admin-token";

const _emailCredentialTileKey =
    "https://veramo-issuer.openid4vc.staging.yivi.app/test-issuer/vct/email";

final List<AttrRow> _organizationExpectedAttributes = [
  ("University Name", "TU Delft"),
  ("Founded", "1842"),
  ("Faculties", <Block>[
    [
      ("Faculty Name", "EEMCS"),
      ("Departments", <Block>[
        [
          ("Department Name", "Software Technology"),
          ("Courses", [
            "Compiler Construction",
            "Distributed Systems",
            "Intro to CS",
          ]),
        ],
        [
          ("Department Name", "Data Science"),
          ("Courses", ["Machine Learning"]),
        ],
      ]),
    ],
    [
      ("Faculty Name", "Architecture"),
      ("Departments", <Block>[
        [
          ("Department Name", "Urbanism"),
          ("Courses", ["City Planning"]),
        ],
      ]),
    ],
  ]),
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
      (tester) => testIssueEmailOpenId4Vci(tester, irmaBinding),
    );

    testWidgets(
      "issue-email-openid4vci-with-tx-code",
      (tester) => testIssueEmailOpenId4VciWithTxCode(tester, irmaBinding),
    );

    testWidgets(
      "issue-organization-openid4vci",
      (tester) => testIssueOrganizationOpenId4Vci(tester, irmaBinding),
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
      (tester) =>
          testRemoveDedupedAndUniqueCredentials(tester, irmaBinding),
    );

    // =========================================================================
    // Notification tests
    // =========================================================================

    testWidgets(
      "expired-credential-shows-expiration-notification",
      (tester) => testExpiredCredentialShowsExpirationNotification(
        tester,
        irmaBinding,
      ),
    );
  });
}

// =============================================================================
// Happy path test implementations
// =============================================================================

Future<void> testIssueEmailOpenId4Vci(
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
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    isExpired: false,
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  // Success screen
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Verify activity log
  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    isExpired: false,
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );
}

Future<void> testIssueEmailOpenId4VciWithTxCode(
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
  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  // Pinput auto-submits on completion.
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    isExpired: false,
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  // Success screen
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Verify activity log
  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    isExpired: false,
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );
}

Future<void> testIssueOrganizationOpenId4Vci(
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
  expect(find.byType(YiviCredentialCard), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
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
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await tester.pumpAndSettle();

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
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
  expect(
    find.byKey(Key("${_emailCredentialTileKey}_tile")),
    findsNothing,
  );

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
  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  // Still on tx_code screen — no navigation to ErrorScreen.
  expect(find.byType(OpenId4VciPreAuthTxCodeScreen), findsOneWidget);
  expect(find.byType(ErrorScreen), findsNothing);

  // Cancel out and verify clean state. We wait for the tx_code screen to
  // unmount before any tap-and-settle: while it's animating out, its cursor
  // still ticks and any subsequent tap may be absorbed by the off-stage
  // route.
  await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
  // After the tx_code screen unmounts the cursor stops, so pumpAndSettle is
  // safe again — and we need it because the home's bottom nav transition
  // continues briefly after the pop completes.
  await tester.pumpUntilGone(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(
    find.byKey(Key("${_emailCredentialTileKey}_tile")),
    findsNothing,
  );
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

  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));

  // First attempt: wrong code.
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  // Second attempt: correct code.
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
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

  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "111111",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 1 attempt remaining."),
  );

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
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

  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "111111",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 1 attempt remaining."),
  );
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "222222",
  );
  await tester.pumpUntilFound(find.byType(TxCodeLockoutScreen));
  expect(find.byType(ErrorScreen), findsNothing);

  await tester.tapAndSettle(find.text("OK"));
  await tester.waitFor(find.byType(DataTab));

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(
    find.byKey(Key("${_emailCredentialTileKey}_tile")),
    findsNothing,
  );

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

  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpUntilFound(
    find.text("Incorrect code. 2 attempts remaining."),
  );

  await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
  // After the tx_code screen unmounts the cursor stops, so pumpAndSettle is
  // safe again — and we need it because the home's bottom nav transition
  // continues briefly after the pop completes.
  await tester.pumpUntilGone(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(
    find.byKey(Key("${_emailCredentialTileKey}_tile")),
    findsNothing,
  );

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
  await tester.pumpUntilFound(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.tap(find.byKey(const Key("bottom_bar_secondary")));

  // Should be back at home (no confirmation dialog). Wait for the tx_code
  // screen to actually unmount — until then, its blinking cursor blocks
  // pumpAndSettle and the route still absorbs taps.
  await tester.pumpUntilGone(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.pumpAndSettle();

  // Verify no credential stored
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(
    find.byKey(Key("${_emailCredentialTileKey}_tile")),
    findsNothing,
  );

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

  // Open the email category details screen. We tap the only credential type
  // card on the data tab rather than a key built from a guessed credential ID.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.waitFor(find.byType(SchemalessYiviCredentialTypeCard));
  final emailTypeCard = find.byType(SchemalessYiviCredentialTypeCard);
  expect(emailTypeCard, findsOneWidget);
  await tester.tapAndSettle(emailTypeCard);
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);

  // Two cards: one merged (test@) representing both identical instances,
  // one unique (other@).
  expect(find.byType(YiviCredentialCard), findsExactly(2));

  // Delete the merged card first
  final mergedCard = find.ancestor(
    of: find.text("test@example.com"),
    matching: find.byType(YiviCredentialCard),
  );
  expect(mergedCard, findsOneWidget);
  await tester.tapAndSettle(
    find.descendant(
      of: mergedCard,
      matching: find.byIcon(Icons.more_horiz_sharp),
    ),
  );
  await tester.tapAndSettle(find.text("Delete data"));
  expect(find.byType(DeleteCredentialConfirmationDialog), findsOneWidget);
  await tester.tapAndSettle(find.text("Delete"));

  // Only the unique card remains
  expect(find.byType(YiviCredentialCard), findsOneWidget);
  expect(find.text("other@example.com"), findsOneWidget);

  // Delete the remaining (unique) card
  await tester.tapAndSettle(find.byIcon(Icons.more_horiz_sharp));
  await tester.tapAndSettle(find.text("Delete data"));
  expect(find.byType(DeleteCredentialConfirmationDialog), findsOneWidget);
  await tester.tapAndSettle(find.text("Delete"));

  // After deleting the last credential of this type, the details screen pops
  // back to the data tab and no credential type card should remain.
  await tester.waitFor(find.byType(DataTab));
  expect(find.byType(SchemalessYiviCredentialTypeCard), findsNothing);

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
  expect(find.byType(ActivityDetailRemoval), findsOneWidget);
  expect(find.byType(YiviCredentialCard), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [
      ("Email", "other@example.com"),
      ("Domain", "example.com"),
    ],
  );

  // Back to activity list, then drill into the older removal
  await tester.tapAndSettle(find.byType(YiviBackButton));

  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(1),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  expect(find.byType(ActivityDetailRemoval), findsOneWidget);
  expect(find.byType(YiviCredentialCard), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );
}

/// Issues a single EmailCredentialSdJwt via the pre-authorized code flow with
/// the wallet at home. Returns to home after success.
Future<void> _issueEmailCredViaPreAuth(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required String email,
}) async {
  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": email, "domain": "example.com"},
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: auto-grants and lands directly on IssuancePermission.
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

// =============================================================================
// Notification test implementations
// =============================================================================

/// Issues an SD-JWT email credential with a short TTL via OpenID4VCI, waits
/// for it to expire, then verifies that the notifications tab surfaces a
/// "Data expired" notification for it and that tapping the notification opens
/// the credential detail screen.
///
/// `LoadNotifications` is dispatched only on app lifecycle resume, on bloc
/// initialization, and on pull-to-refresh in the notifications tab. The
/// issuance flow does not dispatch it, so the notification is only surfaced
/// after the explicit refresh below.
Future<void> testExpiredCredentialShowsExpirationNotification(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final notificationBellFinder = find.byType(NotificationBell);
  final notificationsScreenFinder = find.byType(NotificationsTab);

  // Confirm a clean starting state so any card observed later is one we
  // caused.
  await tester.tapAndSettle(notificationBellFinder);
  expect(notificationsScreenFinder, findsOneWidget);
  expect(find.byType(NotificationCard), findsNothing);
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  // Issue with a short positive TTL — the Veramo agent computes `exp = now +
  // ttl`. Issuance verifies the JWT's `exp`, so it must still be in the future
  // when the credential is fetched; we then wait for it to expire before
  // refreshing notifications. An already-expired credential cannot be issued.
  const ttlSeconds = 10;
  final issuedAt = DateTime.now();
  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    ttlSeconds: ttlSeconds,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Wait until the credential's exp has passed (with a small safety margin).
  final expiresAt = issuedAt.add(const Duration(seconds: ttlSeconds));
  final remaining =
      expiresAt.difference(DateTime.now()) + const Duration(seconds: 2);
  if (!remaining.isNegative) {
    await Future.delayed(remaining);
  }

  // Open the notifications tab and pull-to-refresh to drive the handler.
  await tester.tapAndSettle(notificationBellFinder);
  expect(notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);

  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: "Data expired",
    content: "This data has expired: Email Credential (SD-JWT)",
    read: false,
  );

  // Tapping the notification opens the credential detail screen.
  await tester.tapAndSettle(notificationCardFinder);
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
}

// =============================================================================
// Helper functions
// =============================================================================

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

/// Response from the Veramo issuer's create-offer endpoint.
class OpenID4VCIOfferResponse {
  final String uri;
  final String id;
  final String? txCode;

  OpenID4VCIOfferResponse({
    required this.uri,
    required this.id,
    this.txCode,
  });
}

/// Creates a credential offer via the Veramo issuer API using the
/// pre-authorized code flow.
///
/// [ttlSeconds] controls the credential's `exp` claim. Defaults to one year.
/// A negative value produces an already-expired credential at issuance time
/// (the Veramo agent computes `exp = now + ttl`).
Future<OpenID4VCIOfferResponse> startOpenID4VCISession({
  required String credentialConfigId,
  required Map<String, dynamic> credentialData,
  String? txCodeInputMode,
  int? txCodeLength,
  int ttlSeconds = 31536000,
}) async {
  final grants = <String, dynamic>{
    "urn:ietf:params:oauth:grant-type:pre-authorized_code": {
      "pre-authorized_code": "generate",
      if (txCodeInputMode != null)
        "tx_code": {
          "input_mode": txCodeInputMode,
          if (txCodeLength != null) "length": txCodeLength,
        },
    },
  };

  // The _ttl field is consumed by the Veramo agent and not included in the
  // credential.
  final dataWithTtl = Map<String, dynamic>.from(credentialData);
  dataWithTtl["_ttl"] = ttlSeconds.toString();

  final body = {
    "credentials": [credentialConfigId],
    "grants": grants,
    "credentialDataSupplierInput": dataWithTtl,
  };

  final uri = Uri.parse("$_issuerBaseUrl/api/create-offer");
  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.headers.set("Authorization", "Bearer $_adminToken");
  request.write(jsonEncode(body));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to create OID4VCI offer: status ${response.statusCode}, $responseBody",
    );
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  return OpenID4VCIOfferResponse(
    uri: responseObject["uri"] as String,
    id: responseObject["id"] as String,
    txCode: responseObject["txCode"] as String?,
  );
}
