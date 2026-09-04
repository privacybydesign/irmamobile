/// Helpers for the staging EUDI stack from `openid4vc-poc-ops`: the EU
/// reference Python credential issuer, which issues `mso_mdoc` credentials
/// over OpenID4VCI, and the EU reference Kotlin verifier, which requests them
/// over OpenID4VP with DCQL. See `docs/mdoc-integration-plan.md`.
///
/// Every test in `mdoc_issuance_test.dart` and `mdoc_disclosure_sessions/`
/// goes through this file, so a staging change (hostname, display name,
/// certificate) is one edit here.
library;

import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/openid4vci_preauth_txcode_screen.dart";

import "../irma_binding.dart";
import "../util.dart";

// ---------------------------------------------------------------------------
// Hosts
// ---------------------------------------------------------------------------

/// The EU reference Python issuer (`eudi-issuer.tf`). Its offer endpoint is
/// unauthenticated and returns the offer JSON itself rather than a URI.
const eudiIssuerBaseUrl = "https://eudi-issuer.openid4vc.staging.yivi.app";

/// The EU reference Kotlin verifier v0.11.0 (`eudi-verifier.tf`), configured
/// for `x509_san_dns` client ids and plain `direct_post`.
const eudiVerifierBaseUrl = "https://verifierapi.openid4vc.staging.yivi.app";

/// v0.11.0 refuses a transaction that names neither an intended use nor a
/// registration certificate. No `VERIFIER_INTENDEDUSES*` is configured on the
/// deployment, so the image's shipped intended use `1` is the only one.
const eudiVerifierIntendedUseId = "1";

/// What the wallet shows as the verifier's name. With `x509_san_dns` and no
/// `client_name` in the request, irmago names the verifier after the
/// relying-party certificate: the `organization.legalName` from its scheme
/// extension when present, otherwise the leaf's common name. The pending
/// certificate reissue may change this; every test reads it from here.
const eudiVerifierDisplayName = "verifierapi.openid4vc.staging.yivi.app";

// ---------------------------------------------------------------------------
// Display names, from the issuer's published metadata (English only)
// ---------------------------------------------------------------------------

const eudiIssuerDisplayName = "Digital Credentials Issuer";
const avCredentialName = "Proof of Age";
const pidMdocCredentialName = "PID (MSO Mdoc)";
const mdlCredentialName = "mDL (MSO Mdoc)";

// ---------------------------------------------------------------------------
// Configuration ids, document types, namespaces
// ---------------------------------------------------------------------------

/// EU age-verification profile: configuration id and docType. Note the two
/// differ; the wallet keys the credential by docType.
const avConfigId = "eu.europa.ec.eudi.age_verification_mdoc";
const avDocType = "eu.europa.ec.av.1";

/// PID as mdoc: namespace equals docType.
const pidMdocConfigId = "eu.europa.ec.eudi.pid_mdoc";
const pidMdocDocType = "eu.europa.ec.eudi.pid.1";

/// ISO 18013-5 mDL: namespace differs from docType.
const mdlConfigId = "eu.europa.ec.eudi.mdl_mdoc";
const mdlDocType = "org.iso.18013.5.1.mDL";

/// Copies the wallet stores per issuance. The issuer advertises a batch of
/// 100; irmago caps a batch at 30 (`maxBatchInstances`, following the AV
/// Blueprint's "thirty (30) attestations").
const mdocBatchSize = 30;

// ---------------------------------------------------------------------------
// Preset identity: Jane Doe, born 1990-05-19 (the irmago suite's fixture)
// ---------------------------------------------------------------------------

const presetFamilyName = "Doe";
const presetGivenName = "Jane";
const presetBirthDate = "1990-05-19";
const presetBirthCountry = "NL";
const presetBirthLocality = "Amsterdam";
const presetNationality = "NL";

/// ISO/IEC 5218 sex code, an integer element.
const presetSex = 2;
const presetResidentCity = "Amsterdam";
const mdlLicenceNumber = "X1234";
const mdlVehicleCategory = "B";

/// A one-pixel PNG. The issuer runs image elements through
/// `base64.urlsafe_b64decode`, so the value must contain no `+` or `/`.
const mdlPortraitBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";

/// The thresholds the issuer's own age-verification preset carries for Jane
/// Doe: true through 28, false from 40. `age_over_18` is the one mandatory
/// element; every other `age_over_NN` is optional and only present when the
/// offer supplies it.
const Map<int, bool> avDefaultThresholds = {
  13: true,
  15: true,
  16: true,
  18: true,
  21: true,
  23: true,
  25: true,
  27: true,
  28: true,
  40: false,
  60: false,
  65: false,
  67: false,
};

/// Offer `data` for the age-verification mdoc. Keys are `age_over_NN`; values
/// must be JSON booleans, or the issuer mints CBOR text strings.
Map<String, dynamic> avData([
  Map<int, bool> thresholds = avDefaultThresholds,
]) => {for (final e in thresholds.entries) "age_over_${e.key}": e.value};

/// Offer `data` for the PID mdoc. The issuer adds issuance and expiry dates,
/// issuing authority and country itself.
Map<String, dynamic> pidMdocData({
  String familyName = presetFamilyName,
  String givenName = presetGivenName,
  String birthDate = presetBirthDate,
  String residentCity = presetResidentCity,
}) => {
  "family_name": familyName,
  "given_name": givenName,
  "birth_date": birthDate,
  "place_of_birth": {
    "country": presetBirthCountry,
    "locality": presetBirthLocality,
  },
  "nationality": [presetNationality],
  "sex": presetSex,
  "resident_city": residentCity,
};

/// Offer `data` for the mDL. Every element the mDL metadata marks mandatory
/// and does not fill itself has to be here, or the wallet refuses the
/// credential at issuance.
Map<String, dynamic> mdlData({
  String familyName = presetFamilyName,
  String givenName = presetGivenName,
  String licenceNumber = mdlLicenceNumber,
}) => {
  "family_name": familyName,
  "given_name": givenName,
  "birth_date": presetBirthDate,
  "document_number": licenceNumber,
  "portrait": mdlPortraitBase64,
  "driving_privileges": [
    {"vehicle_category_code": mdlVehicleCategory},
  ],
};

/// "Age Over NN", the label the issuer publishes for every threshold.
String avLabel(int threshold) => "Age Over $threshold";

// ---------------------------------------------------------------------------
// Issuance: the Python issuer's offer endpoint
// ---------------------------------------------------------------------------

/// A minted credential offer, as the wallet and the tx_code screen need it.
class EudiIssuerOffer {
  /// `openid-credential-offer://?credential_offer=<url-encoded offer JSON>`.
  final String uri;

  /// The transaction code the pre-authorized grant carries, as the string the
  /// user types. Null when the grant carries none.
  final String? txCode;

  /// The `tx_code.length` the grant advertises; drives whether the wallet's
  /// screen auto-submits (a fixed-length pin field) or needs the button.
  final int? txCodeLength;

  final Map<String, dynamic> offer;

  const EudiIssuerOffer({
    required this.uri,
    required this.offer,
    this.txCode,
    this.txCodeLength,
  });
}

const _preAuthorizedGrant =
    "urn:ietf:params:oauth:grant-type:pre-authorized_code";

/// Mints a pre-authorized-code offer for one credential configuration with
/// the given element values.
///
/// `POST /credentialOfferReq2` is form-encoded, unauthenticated, and takes
/// `request=<b64url({})>.<b64url(payload)>.`; only the payload segment is
/// read. It returns the offer JSON itself and embeds the transaction code,
/// non-standardly, at `grants[pre-authorized_code].tx_code.value` as a JSON
/// number. Only `credentials[0]` is honoured, so this mints one credential
/// per offer.
Future<EudiIssuerOffer> startEudiIssuerOffer({
  required String configId,
  required Map<String, dynamic> data,
}) async {
  String b64url(String s) =>
      base64Url.encode(utf8.encode(s)).replaceAll("=", "");
  final payload = jsonEncode({
    "credentials": [
      {"credential_configuration_id": configId, "data": data},
    ],
  });
  final request = "${b64url("{}")}.${b64url(payload)}.";

  final httpRequest = await HttpClient().postUrl(
    Uri.parse("$eudiIssuerBaseUrl/credentialOfferReq2"),
  );
  httpRequest.headers.contentType = ContentType(
    "application",
    "x-www-form-urlencoded",
  );
  httpRequest.write("request=${Uri.encodeQueryComponent(request)}");
  final response = await httpRequest.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw "EUDI issuer offer failed: ${response.statusCode}: $body";
  }

  final offer = jsonDecode(body) as Map<String, dynamic>;
  final grant =
      (offer["grants"] as Map<String, dynamic>?)?[_preAuthorizedGrant]
          as Map<String, dynamic>?;
  final txCodeObject = grant?["tx_code"] as Map<String, dynamic>?;
  final rawTxCode = txCodeObject?["value"];

  return EudiIssuerOffer(
    uri:
        "openid-credential-offer://?credential_offer=${Uri.encodeComponent(jsonEncode(offer))}",
    offer: offer,
    txCode: rawTxCode?.toString(),
    txCodeLength: txCodeObject?["length"] as int?,
  );
}

/// Enters a transaction code on the wallet's tx_code screen.
///
/// With an advertised `length` the screen is a fixed-length pin field that
/// submits on completion; without one it is a text field with a submit
/// button. Uses `pumpUntilFound` throughout: the pin field's cursor animation
/// never settles, so `pumpAndSettle` would hang while the screen is up.
Future<void> enterTxCode(
  WidgetTester tester,
  EudiIssuerOffer offer, {
  String? code,
}) async {
  final txCode = code ?? offer.txCode;
  if (txCode == null) {
    throw "the offer carries no transaction code";
  }
  await tester.pumpUntilFound(find.byType(OpenID4VCIPreAuthTxCodeScreen));
  await tester.enterText(
    find.byKey(const Key("openid4vci_tx_code_input_field")),
    txCode,
  );
  if (offer.txCodeLength == null) {
    await tester.pump();
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pump();
  }
}

/// Drives one mdoc issuance from a minted offer to the home screen: tx_code
/// screen, permission screen (accept), success screen. The wallet must be on
/// the home / data tab when called.
Future<void> issueMdoc(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required String configId,
  required Map<String, dynamic> data,
}) async {
  final offer = await startEudiIssuerOffer(configId: configId, data: data);
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  if (offer.txCode != null) {
    await enterTxCode(tester, offer);
  }
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

/// Issues an age-verification mdoc with the given thresholds (defaults to the
/// issuer's Jane Doe preset).
Future<void> issueAvMdoc(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Map<int, bool> thresholds = avDefaultThresholds,
}) => issueMdoc(
  tester,
  irmaBinding,
  configId: avConfigId,
  data: avData(thresholds),
);

/// Issues a PID mdoc for Jane Doe.
Future<void> issuePidMdoc(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Map<String, dynamic>? data,
}) => issueMdoc(
  tester,
  irmaBinding,
  configId: pidMdocConfigId,
  data: data ?? pidMdocData(),
);

/// Issues an mDL for Jane Doe.
Future<void> issueMdlMdoc(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Map<String, dynamic>? data,
}) => issueMdoc(
  tester,
  irmaBinding,
  configId: mdlConfigId,
  data: data ?? mdlData(),
);

// ---------------------------------------------------------------------------
// Disclosure: the Kotlin verifier's presentations endpoint
// ---------------------------------------------------------------------------

/// A started verifier transaction.
class EudiVerifierSession {
  /// The `openid4vp://` link the wallet opens.
  final String uri;

  /// The verifier's transaction id, for reading the wallet response back.
  final String transactionId;

  const EudiVerifierSession({required this.uri, required this.transactionId});
}

/// Starts an OpenID4VP transaction for the raw DCQL query [dcql] and returns
/// the wallet link plus the transaction id.
///
/// `jar_mode: by_reference` makes the wallet fetch the request object by
/// `request_uri`; no `request_uri_method` is sent because v0.11.0 enforces
/// the method the transaction was started with and the wallet GETs (the
/// deployment defaults to `PostOrGet`). `issuer_chain` is mandatory: without
/// a trust-validator service the verifier has no standing anchor for the
/// issuer, and refuses the presentation after the user has consented.
Future<EudiVerifierSession> startEudiVerifierSession(
  String dcql, {
  String nonce = "nonce",
}) async {
  final body = jsonEncode({
    "dcql_query": jsonDecode(dcql),
    "nonce": nonce,
    "jar_mode": "by_reference",
    "intended_use_id": eudiVerifierIntendedUseId,
    "issuer_chain": yiviStagingAttestationProvidersCA,
  });

  final request = await HttpClient().postUrl(
    Uri.parse("$eudiVerifierBaseUrl/ui/presentations"),
  );
  request.headers.contentType = ContentType.json;
  request.write(body);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw "EUDI verifier transaction failed: ${response.statusCode}: $responseBody";
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  final transactionId =
      (responseObject["transaction_id"] ?? responseObject["presentation_id"])
          as String;

  // The response carries the authorization request parameters (client_id,
  // request_uri, ...). Pass every string-valued one through, as the SD-JWT
  // suite does; the wallet requires client_id and request_uri.
  final params = <String, String>{
    for (final e in responseObject.entries)
      if (e.value is String) e.key: e.value as String,
  };
  final uri = Uri(scheme: "openid4vp", host: "", queryParameters: params);
  return EudiVerifierSession(uri: uri.toString(), transactionId: transactionId);
}

/// Reads the wallet response the verifier holds for [transactionId], or null
/// when the wallet has not (yet) posted one. Used to prove a presentation
/// reached the verifier, and to prove a declined session left nothing.
Future<Map<String, dynamic>?> readEudiVerifierResponse(
  String transactionId,
) async {
  final request = await HttpClient().getUrl(
    Uri.parse("$eudiVerifierBaseUrl/ui/presentations/$transactionId"),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    return null;
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

/// The Yivi Staging Attestation Providers CA, which issued the EUDI Python
/// issuer's certificate. Both the verifier (`issuer_chain`) and the wallet
/// anchor the issuer here.
const yiviStagingAttestationProvidersCA = """
-----BEGIN CERTIFICATE-----
MIICbTCCAhSgAwIBAgIUX8STjkv3TRF5UBstXlp4ILHy2h0wCgYIKoZIzj0EAwQw
RjELMAkGA1UEBhMCTkwxDTALBgNVBAoMBFlpdmkxKDAmBgNVBAMMH1lpdmkgU3Rh
Z2luZyBSZXF1ZXN0b3JzIFJvb3QgQ0EwHhcNMjUwODEyMTUwODA1WhcNNDAwODA4
MTUwODA0WjBMMQswCQYDVQQGEwJOTDENMAsGA1UECgwEWWl2aTEuMCwGA1UEAwwl
WWl2aSBTdGFnaW5nIEF0dGVzdGF0aW9uIFByb3ZpZGVycyBDQTBZMBMGByqGSM49
AgEGCCqGSM49AwEHA0IABMDTwj6APykJnBdr0sCO8LpkULpbXFOBWV47hKKsJHsa
CVMarjLCYU3CV57UdklHSlMrtm7vfoDpYn4BvUv00UqjgdkwgdYwEgYDVR0TAQH/
BAgwBgEB/wIBADAfBgNVHSMEGDAWgBRjtHvVs5rhDnC0L2AUi+7ncyXe1jBwBgNV
HR8EaTBnMGWgY6Bhhl9odHRwczovL2NhLnN0YWdpbmcueWl2aS5hcHAvZWpiY2Ev
cHVibGljd2ViL2NybHMvc2VhcmNoLmNnaT9pSGFzaD1rRkNPdDhOTGhKOGcwV3FN
QW5sJTJCdm9OMlJ1WTAdBgNVHQ4EFgQUEjcBLRMmQGBJO0h04IL5Jwha1rEwDgYD
VR0PAQH/BAQDAgGGMAoGCCqGSM49BAMEA0cAMEQCIDEaWIs4uSm8KVQe+fy0EndE
Taj1ayt6dUgKQY/xZBO3AiAPYGwRlZMzbeCTFQ2ORLJiSowRtXzbmXpNDSyvtn7e
Dw==
-----END CERTIFICATE-----
""";
