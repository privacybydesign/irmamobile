import "package:flutter_riverpod/flutter_riverpod.dart";

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
  /// Starts session at sms issuer and returns the corresponding session ID
  Future<String> startSession({required String phoneNumber});

  /// Verifies the verification code and receives back a session pointer that
  /// can be used to start the issuance session
  Future<SessionPointer> verifyCode({
    required String sessionId,
    required String phoneNumber,
    required String verificationCode,
  });
}

class DefaultSmsIssuerApi implements SmsIssuerApi {
  final String host;

  DefaultSmsIssuerApi({required this.host});

  @override
  Future<String> startSession({required String phoneNumber}) async {
    return "123456";
  }

  @override
  Future<SessionPointer> verifyCode({
    required String sessionId,
    required String phoneNumber,
    required String verificationCode,
  }) async {
    throw UnimplementedError();
  }
}

enum SmsIssuanceStage { enteringPhoneNumber, enteringVerificationCode, waiting }

class SmsIssuanceState {
  final SmsIssuanceStage stage;
  final String enteredCode;
  final String phoneNumber;
  final String sessionId;
  final String? error;

  SmsIssuanceState({
    required this.stage,
    required this.enteredCode,
    required this.phoneNumber,
    required this.sessionId,
    this.error,
  });

  SmsIssuanceState copyWith({
    SmsIssuanceStage? stage,
    String? enteredCode,
    String? phoneNumber,
    String? sessionId,
    String? error,
  }) {
    return SmsIssuanceState(
      stage: stage ?? this.stage,
      enteredCode: enteredCode ?? this.enteredCode,
      phoneNumber: phoneNumber ?? this.enteredCode,
      sessionId: sessionId ?? this.sessionId,
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
          sessionId: "",
          phoneNumber: "",
        ),
      );

  Future<void> sendSms({required String phoneNumber}) async {
    try {
      state = state.copyWith(phoneNumber: phoneNumber, stage: .waiting);
      final sessionId = await api.startSession(phoneNumber: phoneNumber);
      state = state.copyWith(
        stage: .enteringVerificationCode,
        sessionId: sessionId,
      );
    } catch (e) {
      state = state.copyWith(stage: .enteringPhoneNumber, error: e.toString());
    }
  }

  Future<SessionPointer?> verifyCode({required String code}) async {
    try {
      state = state.copyWith(stage: .waiting, enteredCode: code);
      return api.verifyCode(
        sessionId: state.sessionId,
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
}
