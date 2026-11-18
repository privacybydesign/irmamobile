import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../data/altcha_solver.dart";
import "../models/session.dart";
import "../util/provider_helpers.dart" as helpers;
import "local_backends_provider.dart";

/// Which contact detail is added: an e-mail address or a phone number.
enum ContactKind { email, phone }

/// What went wrong talking to the e-mail or SMS issuer.
sealed class ContactError implements Exception {
  const ContactError();
}

/// The code is not the one sent.
final class ContactWrongCode extends ContactError {
  const ContactWrongCode();
  @override
  String toString() => "Invalid code";
}

/// Too many codes asked for.
final class ContactRateLimited extends ContactError {
  const ContactRateLimited();
  @override
  String toString() => "Too many requests";
}

/// The SMS issuer did not accept the proof of work.
final class ContactCaptchaFailed extends ContactError {
  const ContactCaptchaFailed();
  @override
  String toString() => "Captcha validation failed";
}

/// The SMS issuer does not send to this number.
final class ContactNotAllowed extends ContactError {
  const ContactNotAllowed();
  @override
  String toString() => "Destination not allowed";
}

/// The issuer said something else.
final class ContactServerError extends ContactError {
  const ContactServerError(this.body);
  final String body;
  @override
  String toString() => "Internal server error: $body";
}

/// No connection, a bad answer, no issuer: anything that is not the
/// issuer's word.
final class ContactFailed extends ContactError {
  const ContactFailed(this.cause);
  final Object cause;
  @override
  String toString() => "General error: $cause";
}

/// An e-mail or SMS issuer: it sends a code to an address or number, and
/// gives the issuance session for the right code.
abstract interface class ContactIssuerApi {
  Future<void> send({required String target, required String language});

  /// The session that issues the address or number, to be continued on
  /// this device.
  Future<SessionPointer> verify({required String target, required String code});
}

/// Posts the issuer's signed request to its IRMA server: the session's
/// pointer, to be continued on this device.
Future<SessionPointer> startIssuerSession(
  http.Client client, {
  required String jwt,
  required String irmaServerUrl,
}) async {
  final response = await client.post(
    Uri.parse("$irmaServerUrl/session"),
    body: jwt,
  );
  if (response.statusCode != 200) {
    throw Exception("Store failed: ${response.statusCode} ${response.body}");
  }
  return SessionPointer.fromJson(
    json.decode(response.body)["sessionPtr"],
  ).copyWith(continueOnSecondDevice: true);
}

/// The issuer's answer to a right code: its signed request and its IRMA
/// server.
Future<SessionPointer> _sessionFrom(
  http.Client client,
  http.Response verified,
) {
  final body = jsonDecode(verified.body);
  return startIssuerSession(
    client,
    jwt: body["jwt"],
    irmaServerUrl: body["irma_server_url"],
  );
}

/// The e-mail issuer: errors as JSON (`{"error": "error_ratelimit"}`).
final class EmailIssuerApi implements ContactIssuerApi {
  EmailIssuerApi({required this.host, http.Client? client}) : _client = client;

  final String host;
  final http.Client? _client;

  /// [body] with the client given, or a new one (the zone's, see
  /// `http.runWithClient`), closed afterwards as `http.post` does.
  Future<T> _withClient<T>(Future<T> Function(http.Client) body) async {
    if (_client case final client?) return body(client);
    final client = http.Client();
    try {
      return await body(client);
    } finally {
      client.close();
    }
  }

  static ContactError _error(http.Response response) =>
      switch (jsonDecode(response.body)["error"]) {
        "error_invalid_token" => const ContactWrongCode(),
        "error_ratelimit" => const ContactRateLimited(),
        _ => ContactServerError(response.body),
      };

  @override
  Future<void> send({required String target, required String language}) =>
      _withClient((client) async {
        debugPrint("Sending email for: $target");
        final response = await client.post(
          Uri.parse("$host/api/embedded/send"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": target, "language": language}),
        );
        if (response.statusCode != 200) throw _error(response);
      });

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) => _withClient((client) async {
    final response = await client.post(
      Uri.parse("$host/api/embedded/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": target, "token": code}),
    );
    if (response.statusCode != 200) throw _error(response);
    return _sessionFrom(client, response);
  });
}

/// The SMS issuer: an ALTCHA proof of work before sending, errors as the
/// raw body (`error:ratelimit`).
final class SmsIssuerApi implements ContactIssuerApi {
  SmsIssuerApi({required this.host, http.Client? client})
    : _client = client ?? http.Client();

  final String host;
  final http.Client _client;

  @override
  Future<void> send({required String target, required String language}) async {
    debugPrint("Sending sms for: $target");

    // Solve an ALTCHA proof-of-work challenge before asking the issuer to send
    // an SMS. This taxes automated bulk requests with CPU. Issuers that do not
    // hand out a challenge (ALTCHA disabled, or an older issuer) return null
    // here, in which case we send without a solution.
    final altcha = await _solveChallenge();

    final response = await _client.post(
      Uri.parse("$host/api/embedded/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone": target,
        "language": language,
        "altcha": ?altcha,
      }),
    );
    if (response.statusCode != 200) {
      throw switch (response.body) {
        "error:ratelimit" => const ContactRateLimited(),
        "error:invalid-captcha" => const ContactCaptchaFailed(),
        "error:destination-not-allowed" => const ContactNotAllowed(),
        _ => ContactServerError(response.body),
      };
    }
  }

  /// Fetches an ALTCHA challenge from the issuer and solves it, returning the
  /// base64 solution payload to attach as the `altcha` field.
  ///
  /// Returns null when the issuer does not hand out a challenge (for example an
  /// older issuer, or one with ALTCHA disabled), so the caller can send without
  /// one. Solving runs on background isolates so it never blocks the UI thread.
  Future<String?> _solveChallenge() async {
    final http.Response response;
    try {
      response = await _client.get(
        Uri.parse("$host/api/embedded/altcha-challenge"),
      );
    } catch (_) {
      return null;
    }
    if (response.statusCode != 200) return null;

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      // Not a JSON challenge (for example an issuer that serves its SPA shell
      // for unknown paths): treat as "no proof of work required".
      return null;
    }

    final challenge = tryParseAltchaChallenge(decoded);
    if (challenge == null) return null;

    return solveAltchaChallenge(challenge);
  }

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse("$host/api/embedded/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": target, "token": code}),
    );
    if (response.statusCode != 200) {
      throw switch (response.body) {
        "error:ratelimit" => const ContactRateLimited(),
        "error:cannot-validate-token" => const ContactWrongCode(),
        _ => ContactServerError(response.body),
      };
    }
    return _sessionFrom(_client, response);
  }
}

/// The e-mail issuer's base URL, set from the credential's issue URL when
/// adding or linking an address starts; null until then.
final emailIssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier<String?>(null),
);

/// The SMS issuer's base URL, set like [emailIssuerUrlProvider].
final smsIssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier<String?>(null),
);

/// The e-mail issuer: a debug local backend's, else the one set from the
/// credential's issue URL. Without either, nothing can be sent.
final emailIssuerApiProvider = Provider<ContactIssuerApi>((ref) {
  final host =
      ref.watch(localBackendsProvider)?.emailIssuer ??
      ref.watch(emailIssuerUrlProvider);
  return host == null ? const _NoIssuer() : EmailIssuerApi(host: host);
});

final smsIssuerApiProvider = Provider<ContactIssuerApi>((ref) {
  final host = ref.watch(smsIssuerUrlProvider);
  return host == null ? const _NoIssuer() : SmsIssuerApi(host: host);
});

/// No issuer set: every call fails, so the step says it could not send.
final class _NoIssuer implements ContactIssuerApi {
  const _NoIssuer();

  static Never _fail() => throw ContactFailed(StateError("no issuer set"));

  @override
  Future<void> send({required String target, required String language}) async =>
      _fail();

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) async => _fail();
}
