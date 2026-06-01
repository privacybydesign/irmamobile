import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
// ignore: depend_on_referenced_packages
import "package:plugin_platform_interface/plugin_platform_interface.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/link.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/url_launcher_platform_interface.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_issuance.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/openid4vci_authcode_pending_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

const _issuerBaseUrl =
    "https://veramo-issuer.openid4vc.staging.yivi.app/authcode-issuer";
const _mockAsBaseUrl = "https://veramo-mock-as.openid4vc.staging.yivi.app";
const _adminToken = "veramo-issuer-admin-token";

const _emailCredentialTileKey =
    "https://veramo-issuer.openid4vc.staging.yivi.app/authcode-issuer/vct/email";

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

  // Replace the real url_launcher / in-app-browser plumbing with no-ops so the
  // wallet's url-launching calls do not throw on the simulator.
  UrlLauncherPlatform.instance = _NoOpUrlLauncherPlatform();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel("irma.app/iiab"),
        (call) async => null,
      );

  // Capture the auth-code flow's ASWebAuthenticationSession call so the test
  // can deliver the issuer's redirect URL on demand via [dispatchAuthCallback].
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel("flutter_web_auth_2"),
        (call) async {
          final completer = Completer<String>();
          _pendingAuthCompleter = completer;
          return completer.future;
        },
      );

  group("openid4vci-authcode-issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    // =========================================================================
    // Happy path tests
    // =========================================================================

    testWidgets(
      "issue-email-openid4vci-authcode",
      (tester) => testIssueEmailOpenID4VCIAuthCode(tester, irmaBinding),
    );

    testWidgets(
      "issue-organization-openid4vci-authcode",
      (tester) => testIssueOrganizationOpenID4VCIAuthCode(tester, irmaBinding),
    );

    // =========================================================================
    // Dismissal tests
    // =========================================================================

    testWidgets(
      "dismiss-on-pending-screen",
      (tester) => testDismissOnPendingScreen(tester, irmaBinding),
    );

    testWidgets(
      "dismiss-on-issuance-permission-screen",
      (tester) => testDismissOnIssuancePermissionScreen(tester, irmaBinding),
    );
  });
}

// =============================================================================
// Happy path test implementations
// =============================================================================

Future<void> testIssueEmailOpenID4VCIAuthCode(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startAuthCodeOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
  );

  final newSessionFuture = irmaBinding.repository.getNewSessionIds().first;
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);
  final sessionId = await newSessionFuture;

  // The wallet auto-launches the browser when the session enters
  // requestAuthorizationCode. Wait for openID4VCIState to be populated, then
  // dispatch the synthetic deep-link that mimics the browser redirect.
  final session = await irmaBinding.repository
      .getSessionState(sessionId)
      .firstWhere((s) => s.openID4VCIState != null);
  final walletState = session.openID4VCIState!;
  final code = await getAuthCodeFromMockAS(
    issuerState: offer.issuerState,
    walletState: walletState,
  );
  await dispatchAuthCallback(
    irmaBinding.repository,
    walletState: walletState,
    code: code,
  );

  // Permission screen: IssuancePermission with filled values
  await tester.waitFor(find.byType(IssuancePermission));
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
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
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "AuthCode Issuer",
    isExpired: false,
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
}

Future<void> testIssueOrganizationOpenID4VCIAuthCode(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startAuthCodeOpenID4VCISession(
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

  final newSessionFuture = irmaBinding.repository.getNewSessionIds().first;
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);
  final sessionId = await newSessionFuture;

  final session = await irmaBinding.repository
      .getSessionState(sessionId)
      .firstWhere((s) => s.openID4VCIState != null);
  final walletState = session.openID4VCIState!;
  final code = await getAuthCodeFromMockAS(
    issuerState: offer.issuerState,
    walletState: walletState,
  );

  // Wallet auto-launched the browser; dispatch the synthetic redirect.
  await dispatchAuthCallback(
    irmaBinding.repository,
    walletState: walletState,
    code: code,
  );

  // Permission screen — spot-check all key values by scrolling to each
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

  await tester.scrollUntilVisible(
    find.byKey(const Key("bottom_bar_primary")),
    -100,
    scrollable: scrollable,
    maxScrolls: 50,
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

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
// Dismissal test implementations
// =============================================================================

Future<void> testDismissOnPendingScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startAuthCodeOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // The wallet auto-launches the browser. Without a synthetic redirect, the
  // session stays in requestAuthorizationCode and the pending screen renders.
  await tester.waitFor(find.byType(OpenID4VCIAuthCodePendingScreen));

  // Tap "Cancel" to dismiss the session directly.
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

Future<void> testDismissOnIssuancePermissionScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startAuthCodeOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
  );

  final newSessionFuture = irmaBinding.repository.getNewSessionIds().first;
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);
  final sessionId = await newSessionFuture;

  final session = await irmaBinding.repository
      .getSessionState(sessionId)
      .firstWhere((s) => s.openID4VCIState != null);
  final walletState = session.openID4VCIState!;
  final code = await getAuthCodeFromMockAS(
    issuerState: offer.issuerState,
    walletState: walletState,
  );

  // Browser auto-launched; dispatch the synthetic redirect to advance state.
  await dispatchAuthCallback(
    irmaBinding.repository,
    walletState: walletState,
    code: code,
  );

  // Permission screen — tap "Cancel" to dismiss
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

  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
}

/// Response from creating an authorization-code OpenID4VCI offer.
class OpenID4VCIAuthCodeOfferResponse {
  final String uri;
  final String id;
  final String issuerState;

  OpenID4VCIAuthCodeOfferResponse({
    required this.uri,
    required this.id,
    required this.issuerState,
  });
}

/// Creates a credential offer via the Veramo issuer API using the
/// authorization-code flow, then fetches the offer body to extract the
/// `issuer_state` that the mock authorization server needs.
Future<OpenID4VCIAuthCodeOfferResponse> startAuthCodeOpenID4VCISession({
  required String credentialConfigId,
  required Map<String, dynamic> credentialData,
}) async {
  // Add a 1-year TTL so the issued credential has a valid exp claim.
  // The _ttl field is consumed by the Veramo agent and not included in the credential.
  final dataWithTtl = Map<String, dynamic>.from(credentialData);
  dataWithTtl["_ttl"] = "31536000";

  final body = {
    "credentials": [credentialConfigId],
    "grants": {"authorization_code": <String, dynamic>{}},
    "credentialDataSupplierInput": dataWithTtl,
  };

  final createUri = Uri.parse("$_issuerBaseUrl/api/create-offer");
  final createRequest = await HttpClient().postUrl(createUri);
  createRequest.headers.set("Content-Type", "application/json");
  createRequest.headers.set("Authorization", "Bearer $_adminToken");
  createRequest.write(jsonEncode(body));

  final createResponse = await createRequest.close();
  final createBody = await createResponse.transform(utf8.decoder).first;

  if (createResponse.statusCode != 200) {
    throw Exception(
      "Failed to create OID4VCI authcode offer: status ${createResponse.statusCode}, $createBody",
    );
  }

  final created = jsonDecode(createBody) as Map<String, dynamic>;
  final uri = created["uri"] as String;
  final id = created["id"] as String;

  // Fetch the offer body to extract issuer_state from the authorization_code grant.
  final fetchUri = Uri.parse("$_issuerBaseUrl/get-credential-offer/$id");
  final fetchRequest = await HttpClient().getUrl(fetchUri);
  final fetchResponse = await fetchRequest.close();
  final fetchBody = await fetchResponse.transform(utf8.decoder).first;

  if (fetchResponse.statusCode != 200) {
    throw Exception(
      "Failed to fetch OID4VCI offer $id: status ${fetchResponse.statusCode}, $fetchBody",
    );
  }

  final offer = jsonDecode(fetchBody) as Map<String, dynamic>;
  final grants = offer["grants"] as Map<String, dynamic>?;
  final authCodeGrant = grants?["authorization_code"] as Map<String, dynamic>?;
  final issuerState = authCodeGrant?["issuer_state"] as String?;
  if (issuerState == null) {
    throw Exception(
      "Offer $id has no authorization_code.issuer_state: $fetchBody",
    );
  }

  return OpenID4VCIAuthCodeOfferResponse(
    uri: uri,
    id: id,
    issuerState: issuerState,
  );
}

/// Calls the mock authorization server's `/authorize` endpoint to obtain an
/// authorization code, mimicking what a real browser would receive after the
/// user authenticates.
Future<String> getAuthCodeFromMockAS({
  required String issuerState,
  required String walletState,
}) async {
  final uri = Uri.parse("$_mockAsBaseUrl/authorize").replace(
    queryParameters: {"issuer_state": issuerState, "state": walletState},
  );
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  final body = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw Exception(
      "Mock AS /authorize failed: status ${response.statusCode}, $body",
    );
  }

  final json = jsonDecode(body) as Map<String, dynamic>;
  final code = json["code"] as String?;
  if (code == null) {
    throw Exception("Mock AS /authorize returned no code: $body");
  }
  return code;
}

/// Most-recently captured auth-session completer, set by the
/// `flutter_web_auth_2` method-channel mock and resolved by
/// [dispatchAuthCallback].
Completer<String>? _pendingAuthCompleter;

/// Mimics the issuer's authorization endpoint redirecting to the bounce page
/// at `https://open.yivi.app/-/auth-callback?...`, which JS-redirects to
/// `app.yivi.open://auth-callback?...` and is captured by
/// `ASWebAuthenticationSession`. The wallet's `authenticateOpenID4VCI` call
/// then runs its `handleOpenID4VCIAuthCallback` path, which looks up the
/// in-flight session by `walletState` and dispatches a
/// [SessionUserInteractionEvent.authCallback].
Future<void> dispatchAuthCallback(
  IrmaRepository repo, {
  required String walletState,
  required String code,
}) async {
  while (_pendingAuthCompleter == null) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  final completer = _pendingAuthCompleter!;
  _pendingAuthCompleter = null;
  completer.complete(
    "app.yivi.open://auth-callback?state=$walletState&code=$code",
  );
}

/// Replacement for [UrlLauncherPlatform] that pretends every launch succeeded
/// without touching the platform. Used so the wallet's `openURLinAppBrowser`
/// call during the auth-code flow does not actually open SFSafariViewController
/// (or fail on simulators where it cannot).
class _NoOpUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => true;
}
