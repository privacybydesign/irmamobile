import "dart:convert";
import "dart:io";

import "eudi_issuance_helpers.dart"
    show veramoVerifierAdminToken, veramoVerifierBaseUrl;

/// The status the verifier (v1.6.4+) reports while it still validates a
/// vp_token. It answers the wallet first, so the result only appears after.
const _processingStatus = "RESPONSE_PROCESSING";

/// Message codes with which the verifier rejects a vc+sd-jwt presentation.
/// Its other messages are informational. `VCDM2` is left out on purpose: the
/// verifier uses it both for the "formatted according to VCDM2" notice and for
/// a credential without credentialSubject (which then leaves no claims).
const veramoRejectionCodes = {
  "INVALID_PRESENTATION",
  "INVALID_JWT",
  "VC_ERROR",
  "NBF_ERROR",
  "IAT_ERROR",
  "EXP_ERROR",
  "NO_CREDENTIALS_FOUND",
  "INVALID_RESPONSE",
  "INVALID_STATE",
};

class VeramoVerifierSession {
  final String state;
  final String requestUri;

  VeramoVerifierSession({required this.state, required this.requestUri});
}

class VeramoVerifierResult {
  final String status;

  /// Claims per DCQL credential query id. For vc+sd-jwt these are the contents
  /// of `credentialSubject`.
  final Map<String, List<Map<String, dynamic>>> credentials;
  final List<({String code, String message})> messages;

  VeramoVerifierResult({
    required this.status,
    required this.credentials,
    required this.messages,
  });

  factory VeramoVerifierResult.fromJson(Map<String, dynamic> json) {
    final result = json["result"] as Map<String, dynamic>?;
    final creds = (result?["credentials"] as Map<String, dynamic>?) ?? {};
    final messages = (result?["messages"] as List?) ?? [];
    return VeramoVerifierResult(
      status: json["status"] as String,
      credentials: {
        for (final MapEntry(:key, :value) in creds.entries)
          key: [
            for (final c in value as List)
              (c as Map<String, dynamic>)["claims"] as Map<String, dynamic>,
          ],
      },
      messages: [
        for (final m in messages.cast<Map<String, dynamic>>())
          (code: m["code"] as String, message: m["message"] as String),
      ],
    );
  }

  List<({String code, String message})> get rejections =>
      messages.where((m) => veramoRejectionCodes.contains(m.code)).toList();
}

Future<Map<String, dynamic>> _call(
  String method,
  String path, [
  Object? body,
]) async {
  final request = await HttpClient().openUrl(
    method,
    Uri.parse("$veramoVerifierBaseUrl$path"),
  );
  request.headers.set("Authorization", "Bearer $veramoVerifierAdminToken");
  if (body != null) {
    request.headers.set("Content-Type", "application/json");
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw Exception(
      "Veramo verifier $method $path: status ${response.statusCode}, $responseBody",
    );
  }
  return jsonDecode(responseBody) as Map<String, dynamic>;
}

/// Starts an OpenID4VP session at the Veramo test-verifier for [dcqlQuery].
/// The returned [VeramoVerifierSession.requestUri] can be handed to the app.
/// Unlike `startVeramoVPSession` it also returns the session's state, with
/// which [awaitVeramoVerifierResult] reads what the verifier received.
Future<VeramoVerifierSession> startVeramoVerifierSession(
  Map<String, dynamic> dcqlQuery,
) async {
  final json = await _call("POST", "/api/create-dcql-offer", {
    "dcql": dcqlQuery,
  });
  return VeramoVerifierSession(
    state: json["state"] as String,
    requestUri: json["requestUri"] as String,
  );
}

/// The verifier's view of the session, waiting (up to [timeout]) while it is
/// still processing a response it received.
Future<VeramoVerifierResult> awaitVeramoVerifierResult(
  String state, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final result = VeramoVerifierResult.fromJson(
      await _call("GET", "/api/check-offer/$state"),
    );
    if (result.status != _processingStatus) return result;
    if (DateTime.now().isAfter(deadline)) {
      throw Exception("Veramo verifier still processing after $timeout");
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
