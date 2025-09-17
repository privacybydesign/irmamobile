import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/passport_data_result.dart';
import '../models/session.dart';
import '../providers/passport_repository_provider.dart';

class NonceAndSessionId {
  final String nonce;
  final String sessionId;

  NonceAndSessionId({required this.nonce, required this.sessionId});
}

/// Interface for passport issuance http requests so they can be mocked/spied in the integration tests
abstract class PassportIssuer {
  /// Starts a session at the passport issuer server, which will return a nonce and
  /// session id to be used during passport reading to prove the readout is not a replay.
  Future<NonceAndSessionId> startSessionAtPassportIssuer();

  /// Initiates the issuance session at the irma server and returns a session pointer,
  /// which the app will use to start the normal issuance session flow.
  Future<SessionPointer> startIrmaIssuanceSession(PassportDataResult passportDataResult);
}

/// Default passport issuer implementation that is used in production and talks to actual
/// passport issuer & irma servers
class DefaultPassportIssuer implements PassportIssuer {
  final String hostName;

  DefaultPassportIssuer({required this.hostName});

  // Start a passport issuer session (so not irma session yet)
  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    final storeResp =
        await http.post(Uri.parse('$hostName/api/start-validation'), headers: {'Content-Type': 'application/json'});
    if (storeResp.statusCode != 200) {
      throw Exception('Store failed: ${storeResp.statusCode} ${storeResp.body}');
    }

    final response = json.decode(storeResp.body);
    return NonceAndSessionId(sessionId: response['session_id'].toString(), nonce: response['nonce'].toString());
  }

  // Starts the issuance session with the irma server with passport scan result
  @override
  Future<SessionPointer> startIrmaIssuanceSession(PassportDataResult passportDataResult) async {
    // Create secure data payload
    final payload = passportDataResult.toJson();
    // Get the signed IRMA JWT from the passport issuer
    final responseBody = await _getIrmaSessionJwt(hostName, payload);
    final irmaServerUrlParam = responseBody['irma_server_url'];
    final jwtUrlParam = responseBody['jwt'];

    // Start the session
    final sessionResponseBody = await _startIrmaSession(jwtUrlParam, irmaServerUrlParam);
    final sessionPtr = sessionResponseBody['sessionPtr'];

    final pointer = Pointer.fromString(json.encode(sessionPtr)) as SessionPointer;

    // This should be true so that the app doesn't want to go back to the browser
    pointer.continueOnSecondDevice = true;
    return pointer;
  }

  Future<dynamic> _getIrmaSessionJwt(String hostName, Map<String, dynamic> payload) async {
    final String jsonPayload = json.encode(payload);
    final storeResp = await http.post(
      Uri.parse('$hostName/api/verify-and-issue'),
      headers: {'Content-Type': 'application/json'},
      body: jsonPayload,
    );
    if (storeResp.statusCode != 200) {
      throw Exception('Store failed: ${storeResp.statusCode} ${storeResp.body}');
    }

    return json.decode(storeResp.body);
  }

  Future<dynamic> _startIrmaSession(String jwt, String irmaServerUrl) async {
    // Start the IRMA session
    final response = await http.post(
      Uri.parse('$irmaServerUrl/session'),
      body: jwt,
    );
    if (response.statusCode != 200) {
      throw Exception('Store failed: ${response.statusCode} ${response.body}');
    }

    return json.decode(response.body);
  }
}

final passportIssuerProvider = Provider<PassportIssuer>((ref) {
  final url = ref.watch(passportUrlProvider);
  return DefaultPassportIssuer(hostName: url);
});

// ----------------------------------------------------------------------------
