import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../models/session.dart";
import "./provider_helpers.dart" as helpers;

final emailIssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier("https://email-issuer.staging.yivi.app"),
);

final emailIssuerApiProvider = Provider<EmailIssuerApi>(
  (ref) => DefaultEmailIssuerApi(host: ref.watch(emailIssuerUrlProvider)),
);

final emailIssuanceProvider = NotifierProvider.autoDispose(EmailIssuer.new);

abstract class EmailIssuerApi {
  /// Starts session at sms issuer
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  });

  /// Verifies the verification code and receives back a session pointer that
  /// can be used to start the issuance session
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  });
}

class DefaultEmailIssuerApi implements EmailIssuerApi {
  final String host;

  DefaultEmailIssuerApi({required this.host});

  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {
    debugPrint("Sending email for: $emailAddress");
    final payload = jsonEncode({"email": emailAddress, "language": language});
    final url = "$host/api/embedded/send";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw switch (json["error"]) {
        "error_invalid_token" => EmailIssuanceInvalidCodeError(),
        "error_ratelimit" => EmailIssuanceRateLimitError(),
        _ => EmailIssuanceInternalServerError(message: response.body),
      };
    }
  }

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    final payload = jsonEncode({"email": email, "token": verificationCode});
    final url = "$host/api/embedded/verify";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw switch (json["error"]) {
        "error_invalid_token" => EmailIssuanceInvalidCodeError(),
        "error_ratelimit" => EmailIssuanceRateLimitError(),
        _ => EmailIssuanceInternalServerError(message: response.body),
      };
    }

    final responseBody = jsonDecode(response.body);

    final irmaServerUrlParam = responseBody["irma_server_url"];
    final jwtUrlParam = responseBody["jwt"];

    final ptr = SessionPointer.fromJson(
      await _startIrmaSession(jwtUrlParam, irmaServerUrlParam),
    );
    ptr.continueOnSecondDevice = true;
    return ptr;
  }

  Future<dynamic> _startIrmaSession(String jwt, String irmaServerUrl) async {
    final response = await http.post(
      Uri.parse("$irmaServerUrl/session"),
      body: jwt,
    );
    if (response.statusCode != 200) {
      throw Exception("Store failed: ${response.statusCode} ${response.body}");
    }

    return json.decode(response.body)["sessionPtr"];
  }
}

enum EmailIssuanceStage { enteringEmail, enteringVerificationCode, waiting }

class EmailIssuanceState {
  final EmailIssuanceStage stage;
  final String enteredCode;
  final String email;
  final EmailIssuanceError error;

  EmailIssuanceState({
    required this.stage,
    required this.enteredCode,
    required this.email,
    required this.error,
  });

  EmailIssuanceState copyWith({
    EmailIssuanceStage? stage,
    String? enteredCode,
    String? email,
    EmailIssuanceError? error,
  }) {
    return EmailIssuanceState(
      stage: stage ?? this.stage,
      enteredCode: enteredCode ?? this.enteredCode,
      email: email ?? this.email,
      error: error ?? this.error,
    );
  }
}

class EmailIssuer extends Notifier<EmailIssuanceState> {
  @override
  EmailIssuanceState build() {
    return EmailIssuanceState(
      stage: .enteringEmail,
      enteredCode: "",
      email: "",
      error: EmailIssuanceNoError(),
    );
  }

  Future<void> sendEmail({
    required String email,
    required String language,
  }) async {
    try {
      state = EmailIssuanceState(
        stage: .waiting,
        enteredCode: "",
        email: email,
        error: EmailIssuanceNoError(),
      );
      await ref
          .read(emailIssuerApiProvider)
          .sendEmail(emailAddress: email, language: language);
      state = state.copyWith(stage: .enteringVerificationCode);
    } catch (e) {
      final err = switch (e) {
        EmailIssuanceError() => e,
        _ => EmailIssuanceGeneralError(message: e.toString()),
      };
      state = state.copyWith(stage: .enteringEmail, error: err);
    }
  }

  Future<SessionPointer?> verifyCode({required String code}) async {
    try {
      state = state.copyWith(enteredCode: code);
      return await ref
          .read(emailIssuerApiProvider)
          .verifyCode(email: state.email, verificationCode: code);
    } catch (e) {
      final err = switch (e) {
        EmailIssuanceError() => e,
        _ => EmailIssuanceGeneralError(message: e.toString()),
      };
      state = state.copyWith(
        enteredCode: "",
        stage: .enteringVerificationCode,
        error: err,
      );
    }
    return null;
  }

  void resetError() {
    state = state.copyWith(error: EmailIssuanceNoError());
  }

  void reset() {
    state = EmailIssuanceState(
      email: "",
      enteredCode: "",
      stage: .enteringEmail,
      error: EmailIssuanceNoError(),
    );
  }

  void goBackToEnteringEmail() {
    state = EmailIssuanceState(
      email: state.email,
      enteredCode: "",
      stage: .enteringEmail,
      error: EmailIssuanceNoError(),
    );
  }
}

// --------------------------------------------------------

abstract class EmailIssuanceError implements Exception {}

class EmailIssuanceNoError extends EmailIssuanceError {}

class EmailIssuanceRateLimitError extends EmailIssuanceError {
  @override
  String toString() {
    return "Too many requests";
  }
}

class EmailIssuanceInvalidCodeError extends EmailIssuanceError {
  @override
  String toString() {
    return "Invalid code";
  }
}

class EmailIssuanceGeneralError extends EmailIssuanceError {
  final String message;

  EmailIssuanceGeneralError({required this.message});

  @override
  String toString() {
    return "General error: $message";
  }
}

class EmailIssuanceInternalServerError extends EmailIssuanceError {
  final String message;

  EmailIssuanceInternalServerError({required this.message});

  @override
  String toString() {
    return "Internal server error: $message";
  }
}
