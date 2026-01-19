import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../models/session.dart";
import "./provider_helpers.dart" as helpers;

final smsIssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier("https://sms-issuer.staging.yivi.app"),
);

final smsIssuerApiProvider = Provider<SmsIssuerApi>(
  (ref) => DefaultSmsIssuerApi(host: ref.watch(smsIssuerUrlProvider)),
);

final smsIssuanceProvider = NotifierProvider.autoDispose(SmsIssuer.new);

abstract class SmsIssuerApi {
  /// Starts session at sms issuer
  Future<void> sendSms({required String phoneNumber, required String language});

  /// Verifies the verification code and receives back a session pointer that
  /// can be used to start the issuance session
  Future<SessionPointer> verifyCode({
    required String phoneNumber,
    required String verificationCode,
  });
}

class DefaultSmsIssuerApi implements SmsIssuerApi {
  final String host;

  DefaultSmsIssuerApi({required this.host});

  @override
  Future<void> sendSms({
    required String phoneNumber,
    required String language,
  }) async {
    debugPrint("Sending sms for: $phoneNumber");
    final payload = jsonEncode({"phone": phoneNumber, "language": language});
    final url = "$host/api/embedded/send";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );
    if (response.statusCode != 200) {
      throw switch (response.body) {
        "error:ratelimit" => SmsIssuanceRateLimitError(),
        _ => SmsIssuanceInternalServerError(message: response.body),
      };
    }
  }

  @override
  Future<SessionPointer> verifyCode({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    final payload = jsonEncode({
      "phone": phoneNumber,
      "token": verificationCode,
    });
    final url = "$host/api/embedded/verify";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );

    if (response.statusCode != 200) {
      throw switch (response.body) {
        "error:ratelimit" => SmsIssuanceRateLimitError(),
        "error:cannot-validate-token" => SmsIssuanceInvalidCodeError(),
        _ => SmsIssuanceInternalServerError(message: response.body),
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

enum SmsIssuanceStage { enteringPhoneNumber, enteringVerificationCode, waiting }

class SmsIssuanceState {
  final SmsIssuanceStage stage;
  final String enteredCode;
  final String phoneNumber;
  final SmsIssuanceError error;

  SmsIssuanceState({
    required this.stage,
    required this.enteredCode,
    required this.phoneNumber,
    required this.error,
  });

  SmsIssuanceState copyWith({
    SmsIssuanceStage? stage,
    String? enteredCode,
    String? phoneNumber,
    SmsIssuanceError? error,
  }) {
    return SmsIssuanceState(
      stage: stage ?? this.stage,
      enteredCode: enteredCode ?? this.enteredCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error ?? this.error,
    );
  }
}

class SmsIssuer extends Notifier<SmsIssuanceState> {
  SmsIssuer();

  @override
  SmsIssuanceState build() {
    return SmsIssuanceState(
      stage: .enteringPhoneNumber,
      enteredCode: "",
      phoneNumber: "",
      error: SmsIssuanceNoError(),
    );
  }

  Future<void> sendSms({
    required String phoneNumber,
    required String language,
  }) async {
    try {
      state = SmsIssuanceState(
        stage: .waiting,
        enteredCode: "",
        phoneNumber: phoneNumber,
        error: SmsIssuanceNoError(),
      );
      await ref
          .read(smsIssuerApiProvider)
          .sendSms(phoneNumber: phoneNumber, language: language);
      state = state.copyWith(stage: .enteringVerificationCode);
    } catch (e) {
      final err = switch (e) {
        SmsIssuanceError() => e,
        _ => SmsIssuanceGeneralError(message: e.toString()),
      };
      state = state.copyWith(stage: .enteringPhoneNumber, error: err);
    }
  }

  Future<SessionPointer?> verifyCode({required String code}) async {
    try {
      state = state.copyWith(enteredCode: code);
      return await ref
          .read(smsIssuerApiProvider)
          .verifyCode(phoneNumber: state.phoneNumber, verificationCode: code);
    } catch (e) {
      final err = switch (e) {
        SmsIssuanceError() => e,
        _ => SmsIssuanceGeneralError(message: e.toString()),
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
    state = state.copyWith(error: SmsIssuanceNoError());
  }

  void reset() {
    state = SmsIssuanceState(
      stage: .enteringPhoneNumber,
      enteredCode: "",
      phoneNumber: state.phoneNumber,
      error: SmsIssuanceNoError(),
    );
  }

  void goBackToEnterPhone() {
    state = SmsIssuanceState(
      stage: .enteringPhoneNumber,
      enteredCode: "",
      phoneNumber: state.phoneNumber,
      error: SmsIssuanceNoError(),
    );
  }
}

// --------------------------------------------------

abstract class SmsIssuanceError implements Exception {}

class SmsIssuanceNoError extends SmsIssuanceError {}

class SmsIssuanceRateLimitError extends SmsIssuanceError {
  @override
  String toString() {
    return "Too many requests";
  }
}

class SmsIssuanceInvalidCodeError extends SmsIssuanceError {
  @override
  String toString() {
    return "Invalid code";
  }
}

class SmsIssuanceGeneralError extends SmsIssuanceError {
  final String message;

  SmsIssuanceGeneralError({required this.message});

  @override
  String toString() {
    return "General error: $message";
  }
}

class SmsIssuanceInternalServerError extends SmsIssuanceError {
  final String message;

  SmsIssuanceInternalServerError({required this.message});

  @override
  String toString() {
    return "Internal server error: $message";
  }
}
