import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/irma_empty_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../disclosure_session/disclosure_helpers.dart";
import "../irma_binding.dart";
import "../util.dart";
import "helpers.dart";

const veramoIssuerBaseUrl =
    "https://veramo-issuer.openid4vc.staging.yivi.app/test-issuer";
const veramoBatch2IssuerBaseUrl =
    "https://veramo-issuer.openid4vc.staging.yivi.app/batch2-issuer";
const veramoVerifierBaseUrl =
    "https://veramo-verifier.openid4vc.staging.yivi.app/test-verifier";
const veramoVerifierDisplayName = "test-verifier";
const veramoIssuerAdminToken = "piMmprGSinTFrEJkxNo5jfuU5QbDRbqP";
const veramoVerifierAdminToken = "yxMPqponlkzYRnJ8OiT1POF99VXs221I";

/// VCT URLs for the credential types issued by the veramo-issuer test-issuer.
const veramoEmailCredentialVct =
    "https://veramo-issuer.openid4vc.staging.yivi.app/vct/email";
const veramoPhoneCredentialVct =
    "https://veramo-issuer.openid4vc.staging.yivi.app/vct/phone";
const veramoOrganizationCredentialVct =
    "https://veramo-issuer.openid4vc.staging.yivi.app/vct/organization";

/// Response from the Veramo issuer's create-offer endpoint.
class OpenID4VCIOfferResponse {
  final String uri;
  final String id;

  OpenID4VCIOfferResponse({required this.uri, required this.id});
}

/// Issues a single OID4VCI credential via the pre-authorized code flow with
/// the wallet at home. Returns to home after success.
///
/// The wallet must be on the home/data tab when called.
Future<void> _issueOpenID4VCICredential(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required String credentialConfigId,
  required Map<String, dynamic> credentialData,
  String issuerBaseUrl = veramoIssuerBaseUrl,
}) async {
  final offer = await startOpenID4VCISession(
    credentialConfigId: credentialConfigId,
    credentialData: credentialData,
    issuerBaseUrl: issuerBaseUrl,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // No tx code: auto-grants and lands directly on IssuancePermission.
  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

/// Issues an `EmailCredentialSdJwt` via OID4VCI pre-authorized code flow.
Future<void> issueEmailViaOpenID4VCI(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  String email = "test@example.com",
  String domain = "example.com",
}) => _issueOpenID4VCICredential(
  tester,
  irmaBinding,
  credentialConfigId: "EmailCredentialSdJwt",
  credentialData: {"email": email, "domain": domain},
);

/// Issues an `EmailCredentialSdJwt` via the staging `batch2-issuer`, which
/// advertises `batch_credential_issuance.batch_size = 2`. Use this to drive
/// the disclosure-time low- and zero-instance-count code paths.
Future<void> issueEmailViaOpenID4VCIBatch2(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  String email = "test@example.com",
  String domain = "example.com",
}) => _issueOpenID4VCICredential(
  tester,
  irmaBinding,
  credentialConfigId: "EmailCredentialSdJwt",
  credentialData: {"email": email, "domain": domain},
  issuerBaseUrl: veramoBatch2IssuerBaseUrl,
);

/// Issues a `PhoneCredentialSdJwt` via OID4VCI pre-authorized code flow.
Future<void> issuePhoneViaOpenID4VCI(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  String phoneNumber = "0612345678",
}) => _issueOpenID4VCICredential(
  tester,
  irmaBinding,
  credentialConfigId: "PhoneCredentialSdJwt",
  credentialData: {"phone_number": phoneNumber},
);

/// Issues an `OrganizationCredentialSdJwt` via OID4VCI pre-authorized code
/// flow. Defaults to a TU Delft fixture mirroring `openid4vci_issuance_test`.
Future<void> issueOrganizationViaOpenID4VCI(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Map<String, dynamic>? orgData,
}) => _issueOpenID4VCICredential(
  tester,
  irmaBinding,
  credentialConfigId: "OrganizationCredentialSdJwt",
  credentialData: orgData ?? _defaultOrganizationData,
);

const Map<String, dynamic> _defaultOrganizationData = {
  "name": "TU Delft",
  "founded": 1842,
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
};

/// Creates a credential offer via the Veramo issuer using the pre-authorized
/// code flow.
Future<OpenID4VCIOfferResponse> startOpenID4VCISession({
  required String credentialConfigId,
  required Map<String, dynamic> credentialData,
  String issuerBaseUrl = veramoIssuerBaseUrl,
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

  final uri = Uri.parse("$issuerBaseUrl/api/create-offer");
  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.headers.set("Authorization", "Bearer $veramoIssuerAdminToken");
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
  );
}

/// Taps the share button on the disclosure overview, walks through the
/// share-confirm dialog, and dismisses the success feedback screen.
Future<void> shareAndFinishEudiDisclosure(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

/// Opens the activity tab, taps the most recent [ActivityCard], and runs
/// [evaluateCredentialCard] against each credential card on the resulting
/// [ActivityDetailsScreen].
///
/// `expectedCredentials` lists one spec per card in the order they're
/// rendered. Pass an empty list for empty disclosures (just verifies a log
/// entry exists and is openable).
Future<void> verifyMostRecentActivityLog(
  WidgetTester tester, {
  required List<
    ({String credentialName, String issuerName, List<AttrRow> attributes})
  >
  expectedCredentials,
}) async {
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).first,
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);

  if (expectedCredentials.isEmpty) {
    return;
  }

  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsNWidgets(expectedCredentials.length));

  for (var i = 0; i < expectedCredentials.length; i++) {
    final spec = expectedCredentials[i];
    await evaluateCredentialCard(
      tester,
      cardsFinder.at(i),
      credentialName: spec.credentialName,
      issuerName: spec.issuerName,
      attributes: spec.attributes,
    );
  }
}

/// Opens the most recent activity entry and asserts it represents an empty
/// disclosure: an [IrmaEmptyCredentialCard] is shown, and the [RequestorHeader]
/// contains [expectedRequestorName] (i.e. the log records *who* the
/// transaction was with, even though no data was shared).
Future<void> verifyEmptyDisclosureActivityLog(
  WidgetTester tester, {
  required String expectedRequestorName,
}) async {
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).first,
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  expect(find.byType(IrmaEmptyCredentialCard), findsOneWidget);

  final requestorHeaderFinder = find.byType(RequestorHeader);
  expect(requestorHeaderFinder, findsOneWidget);
  expect(
    find.descendant(
      of: requestorHeaderFinder,
      matching: find.text(expectedRequestorName),
    ),
    findsOneWidget,
  );
}

/// Taps the activity tab and asserts no log entries exist (the empty-state
/// placeholder is shown).
Future<void> verifyEmptyActivityLog(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(find.text("There are no logged activities yet"), findsOneWidget);
  expect(find.byType(ActivityCard), findsNothing);
}

/// Taps the activity tab and asserts that exactly [expected] log entries
/// exist (`ActivityCard`s on the activity tab).
Future<void> verifyActivityLogCount(WidgetTester tester, int expected) async {
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(
    find.byType(ActivityCard, skipOffstage: false),
    findsNWidgets(expected),
  );
}

/// Posts a DCQL query to the veramo-verifier and returns the wallet-facing
/// `openid4vp://...` request URL.
Future<String> startVeramoVPSession(Map<String, dynamic> dcql) async {
  final uri = Uri.parse("$veramoVerifierBaseUrl/api/create-dcql-offer");
  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.headers.set("Authorization", "Bearer $veramoVerifierAdminToken");
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
