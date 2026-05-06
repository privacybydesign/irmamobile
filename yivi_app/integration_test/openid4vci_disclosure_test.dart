import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "disclosure_session/disclosure_helpers.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

const _issuerBaseUrl =
    "https://veramo-issuer.openid4vc.staging.yivi.app/test-issuer";
const _verifierBaseUrl =
    "https://veramo-verifier.openid4vc.staging.yivi.app/test-verifier";
const _issuerAdminToken = "veramo-issuer-admin-token";
const _verifierAdminToken = "veramo-verifier-admin-token";

const _emailCredentialVct =
    "https://veramo-issuer.openid4vc.staging.yivi.app/vct/email";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("openid4vci-disclosure", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "disclose-email-only-from-oid4vci-cred",
      (tester) => testDiscloseEmailOnly(tester, irmaBinding),
    );

    testWidgets(
      "disclose-email-and-domain-from-oid4vci-cred",
      (tester) => testDiscloseEmailAndDomain(tester, irmaBinding),
    );

    testWidgets(
      "disclose-without-credential-shows-no-options",
      (tester) => testDiscloseWithoutCredential(tester, irmaBinding),
      skip: true,
    );
  });
}

// =============================================================================
// Test implementations
// =============================================================================

Future<void> testDiscloseEmailOnly(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueEmailCredential(
    tester,
    irmaBinding,
    email: "test@example.com",
    domain: "example.com",
  );

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [_emailCredentialVct],
        },
        "claims": [
          {"id": "em", "path": ["email"]},
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  // The wallet has the credential, so we should land on the choices overview.
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [("Email", "test@example.com")],
  );

  // Selective disclosure: domain value must not be revealed in the
  // disclosure card.
  expect(find.text("example.com"), findsNothing);

  await _shareAndFinishDisclosureSession(tester);
}

Future<void> testDiscloseEmailAndDomain(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueEmailCredential(
    tester,
    irmaBinding,
    email: "test@example.com",
    domain: "example.com",
  );

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [_emailCredentialVct],
        },
        "claims": [
          {"id": "em", "path": ["email"]},
          {"id": "do", "path": ["domain"]},
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );

  await _shareAndFinishDisclosureSession(tester);
}

Future<void> testDiscloseWithoutCredential(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // No issuance — the wallet has no credential to satisfy the request.

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [_emailCredentialVct],
        },
        "claims": [
          {"id": "em", "path": ["email"]},
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  // The wallet still renders the disclosure overview, but with no card to
  // disclose because the credential isn't owned and isn't obtainable
  // (OID4VCI-issued credentials don't carry an issue URL in their metadata).
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(find.byType(YiviCredentialCard), findsNothing);
}

// =============================================================================
// Issuance helpers
// =============================================================================

/// Issues a single EmailCredentialSdJwt via the pre-authorized code flow with
/// the wallet at home. Returns to home after success.
Future<void> _issueEmailCredential(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required String email,
  required String domain,
}) async {
  final offer = await _startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": email, "domain": domain},
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: auto-grants and lands directly on IssuancePermission.
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

/// Response from the Veramo issuer's create-offer endpoint.
class _OpenID4VCIOfferResponse {
  final String uri;
  final String id;

  _OpenID4VCIOfferResponse({required this.uri, required this.id});
}

/// Creates a credential offer via the Veramo issuer using the pre-authorized
/// code flow. Mirrors the helper in `openid4vci_issuance_test.dart`.
Future<_OpenID4VCIOfferResponse> _startOpenID4VCISession({
  required String credentialConfigId,
  required Map<String, dynamic> credentialData,
}) async {
  final dataWithTtl = Map<String, dynamic>.from(credentialData);
  dataWithTtl["_ttl"] = "31536000";

  final body = {
    "credentials": [credentialConfigId],
    "grants": {
      "urn:ietf:params:oauth:grant-type:pre-authorized_code": {
        "pre-authorized_code": "generate",
      },
    },
    "credentialDataSupplierInput": dataWithTtl,
  };

  final uri = Uri.parse("$_issuerBaseUrl/api/create-offer");
  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.headers.set("Authorization", "Bearer $_issuerAdminToken");
  request.write(jsonEncode(body));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to create OID4VCI offer: status ${response.statusCode}, $responseBody",
    );
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  return _OpenID4VCIOfferResponse(
    uri: responseObject["uri"] as String,
    id: responseObject["id"] as String,
  );
}

// =============================================================================
// Disclosure helpers
// =============================================================================

/// Posts a DCQL query to the veramo-verifier and returns the wallet-facing
/// `openid4vp://...` request URL.
Future<String> startVeramoVPSession(Map<String, dynamic> dcql) async {
  final uri = Uri.parse("$_verifierBaseUrl/api/create-dcql-offer");
  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.headers.set("Authorization", "Bearer $_verifierAdminToken");
  request.write(jsonEncode({"dcql": dcql}));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to create veramo-verifier DCQL offer: status ${response.statusCode}, $responseBody",
    );
  }

  final json = jsonDecode(responseBody) as Map<String, dynamic>;
  final requestUri = json["requestUri"] as String?;
  if (requestUri == null || requestUri.isEmpty) {
    throw Exception("veramo-verifier returned no requestUri: $responseBody");
  }
  return requestUri;
}

/// Walks through the share confirm dialog and the success feedback screen,
/// dismissing both. Mirrors the helper used by the IRMA-SD-JWT disclosure
/// tests, kept local because that file's helper is private.
Future<void> _shareAndFinishDisclosureSession(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
