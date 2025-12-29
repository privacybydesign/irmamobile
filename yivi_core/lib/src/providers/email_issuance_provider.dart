import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../models/session.dart";

final emailIssuerUrlProvider = StateProvider(
  (ref) => "https://email-issuer.staging.yivi.app",
);

final emailIssuanceProvider = StateNotifierProvider.autoDispose(
  (ref) => EmailIssuer(
    api: DefaultEmailIssuerApi(host: ref.watch(emailIssuerUrlProvider)),
  ),
);

abstract class EmailIssuerApi {
  /// Starts session at sms issuer
  Future<void> sendEmail({required String emailAddress});

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
  Future<void> sendEmail({required String emailAddress}) async {
    debugPrint("Sending email for: $emailAddress");
    final payload = jsonEncode({"email": emailAddress, "language": "nl"});
    final url = "$host/api/embedded/send";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );
    if (response.statusCode != 200) {
      throw Exception("Call to $url failed: ${response.body}");
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
      throw Exception("Call to $url failed: ${response.body}");
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
  final String error;

  EmailIssuanceState({
    required this.stage,
    required this.enteredCode,
    required this.email,
    this.error = "",
  });

  EmailIssuanceState copyWith({
    EmailIssuanceStage? stage,
    String? enteredCode,
    String? email,
    String? error,
  }) {
    return EmailIssuanceState(
      stage: stage ?? this.stage,
      enteredCode: enteredCode ?? this.enteredCode,
      email: email ?? this.email,
      error: error ?? this.error,
    );
  }
}

class EmailIssuer extends StateNotifier<EmailIssuanceState> {
  final EmailIssuerApi api;

  EmailIssuer({required this.api})
    : super(
        EmailIssuanceState(stage: .enteringEmail, enteredCode: "", email: ""),
      );

  Future<void> sendEmail({required String email}) async {
    try {
      state = EmailIssuanceState(
        stage: .waiting,
        enteredCode: "",
        email: email,
      );
      await api.sendEmail(emailAddress: email);
      state = state.copyWith(stage: .enteringVerificationCode);
    } catch (e) {
      state = state.copyWith(stage: .enteringEmail, error: e.toString());
    }
  }

  Future<SessionPointer?> verifyCode({required String code}) async {
    try {
      state = state.copyWith(enteredCode: code);
      return await api.verifyCode(email: state.email, verificationCode: code);
    } catch (e) {
      state = state.copyWith(
        enteredCode: "",
        stage: .enteringVerificationCode,
        error: e.toString(),
      );
    }
    return null;
  }

  void resetError() {
    state = state.copyWith(error: "");
  }
}
