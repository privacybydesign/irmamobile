import "dart:convert";
import "dart:io";

const _issuerBaseUrl =
    "https://veramo-issuer.openid4vc.staging.yivi.app/test-issuer";
const _adminToken = "veramo-issuer-admin-token";

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
