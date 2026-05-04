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

const _organizationExpectedValues = [
  "TU Delft",
  "EEMCS",
  "Software Technology",
  "Compiler Construction",
  "Distributed Systems",
  "Intro to CS",
  "Data Science",
  "Machine Learning",
  "Architecture",
  "Urbanism",
  "City Planning",
  "1842",
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
    attributes: {
      "Email": "test@example.com",
      "Domain": "example.com",
    },
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
    attributes: {
      "Email": "test@example.com",
      "Domain": "example.com",
    },
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

  // Tx code screen appears directly (no preview screen anymore).
  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  // Pinput auto-submits on completion.
  await tester.pumpAndSettle();

  // Permission screen with filled values
  await tester.waitFor(find.byType(IssuancePermission));
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    isExpired: false,
    attributes: {
      "Email": "test@example.com",
      "Domain": "example.com",
    },
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
    attributes: {
      "Email": "test@example.com",
      "Domain": "example.com",
    },
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
      "university": {
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
    },
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: lands directly on IssuancePermission with filled values.
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.pumpAndSettle();
  expect(find.byType(YiviCredentialCard), findsOneWidget);

  final scrollable = find.byType(Scrollable).first;
  for (final value in _organizationExpectedValues) {
    await tester.scrollUntilVisible(
      find.text(value),
      100,
      scrollable: scrollable,
      maxScrolls: 50,
    );
    expect(find.text(value), findsAtLeast(1));
  }

  // Scroll back to the top to tap "Add"
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

  // Verify activity log — same spot-checks
  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await tester.pumpAndSettle();

  final activityScrollable = find.byType(Scrollable).first;
  for (final value in _organizationExpectedValues) {
    await tester.scrollUntilVisible(
      find.text(value),
      100,
      scrollable: activityScrollable,
      maxScrolls: 50,
    );
    expect(find.text(value), findsAtLeast(1));
  }
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

  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpAndSettle();

  // Still on tx_code screen — no navigation to ErrorScreen.
  expect(find.byType(OpenId4VciPreAuthTxCodeScreen), findsOneWidget);
  expect(find.byType(ErrorScreen), findsNothing);
  // Inline error is visible with the remaining-attempts count.
  expect(find.text("Incorrect code. 2 attempts remaining."), findsOneWidget);

  // Cancel out and verify clean state.
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));
  await tester.waitFor(find.byType(DataTab));

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

  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));

  // First attempt: wrong code.
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpAndSettle();
  expect(find.text("Incorrect code. 2 attempts remaining."), findsOneWidget);

  // Second attempt: correct code.
  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  await tester.pumpAndSettle();

  await tester.waitFor(find.byType(IssuancePermission));
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

  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpAndSettle();
  expect(find.text("Incorrect code. 2 attempts remaining."), findsOneWidget);

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "111111",
  );
  await tester.pumpAndSettle();
  expect(find.text("Incorrect code. 1 attempt remaining."), findsOneWidget);

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    offer.txCode!,
  );
  await tester.pumpAndSettle();

  await tester.waitFor(find.byType(IssuancePermission));
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

  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));

  for (final wrong in const ["000000", "111111", "222222"]) {
    await tester.enterText(
      find.byKey(const Key("oid4vci_tx_code_input_field")),
      wrong,
    );
    await tester.pumpAndSettle();
  }

  await tester.waitFor(find.byType(TxCodeLockoutScreen));
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

  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));

  await tester.enterText(
    find.byKey(const Key("oid4vci_tx_code_input_field")),
    "000000",
  );
  await tester.pumpAndSettle();
  expect(find.text("Incorrect code. 2 attempts remaining."), findsOneWidget);

  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));
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
  await tester.waitFor(find.byType(OpenId4VciPreAuthTxCodeScreen));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));

  // Should be back at home (no confirmation dialog).
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
    attributes: {
      "Email": "other@example.com",
      "Domain": "example.com",
    },
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
    attributes: {
      "Email": "test@example.com",
      "Domain": "example.com",
    },
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
Future<OpenID4VCIOfferResponse> startOpenID4VCISession({
  required String credentialConfigId,
  required Map<String, dynamic> credentialData,
  String? txCodeInputMode,
  int? txCodeLength,
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

  // Add a 1-year TTL so the issued credential has a valid exp claim.
  // The _ttl field is consumed by the Veramo agent and not included in the credential.
  final dataWithTtl = Map<String, dynamic>.from(credentialData);
  dataWithTtl["_ttl"] = "31536000";

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
