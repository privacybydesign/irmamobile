import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../models/session.dart";

final smsIssuerUrlProvider = StateProvider(
  (ref) => "https://sms-issuer.staging.yivi.app",
);

final smsIssuanceProvider = StateNotifierProvider.autoDispose(
  (ref) => SmsIssuer(
    api: DefaultSmsIssuerApi(host: ref.watch(smsIssuerUrlProvider)),
  ),
);

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
      throw Exception("Call to $url failed: ${response.body}");
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

enum SmsIssuanceStage { enteringPhoneNumber, enteringVerificationCode, waiting }

class SmsIssuanceState {
  final SmsIssuanceStage stage;
  final String enteredCode;
  final String phoneNumber;
  final String error;

  SmsIssuanceState({
    required this.stage,
    required this.enteredCode,
    required this.phoneNumber,
    this.error = "",
  });

  SmsIssuanceState copyWith({
    SmsIssuanceStage? stage,
    String? enteredCode,
    String? phoneNumber,
    String? error,
  }) {
    return SmsIssuanceState(
      stage: stage ?? this.stage,
      enteredCode: enteredCode ?? this.enteredCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error ?? this.error,
    );
  }
}

class SmsIssuer extends StateNotifier<SmsIssuanceState> {
  final SmsIssuerApi api;

  SmsIssuer({required this.api})
    : super(
        SmsIssuanceState(
          stage: .enteringPhoneNumber,
          enteredCode: "",
          phoneNumber: "",
        ),
      );

  Future<void> sendSms({
    required String phoneNumber,
    required String language,
  }) async {
    try {
      state = SmsIssuanceState(
        stage: .waiting,
        enteredCode: "",
        phoneNumber: phoneNumber,
      );
      await api.sendSms(phoneNumber: phoneNumber, language: language);
      state = state.copyWith(stage: .enteringVerificationCode);
    } catch (e) {
      state = state.copyWith(stage: .enteringPhoneNumber, error: e.toString());
    }
  }

  Future<SessionPointer?> verifyCode({required String code}) async {
    try {
      state = state.copyWith(enteredCode: code);
      return await api.verifyCode(
        phoneNumber: state.phoneNumber,
        verificationCode: code,
      );
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

  void reset() {
    state = SmsIssuanceState(
      stage: .enteringPhoneNumber,
      enteredCode: "",
      phoneNumber: state.phoneNumber,
      error: "",
    );
  }

  void goBackToEnterPhone() {
    state = SmsIssuanceState(
      stage: .enteringPhoneNumber,
      enteredCode: "",
      phoneNumber: state.phoneNumber,
      error: "",
    );
  }
}
