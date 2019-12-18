// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticationResultSuccess _$AuthenticationResultSuccessFromJson(
    Map<String, dynamic> json) {
  return AuthenticationResultSuccess();
}

Map<String, dynamic> _$AuthenticationResultSuccessToJson(
        AuthenticationResultSuccess instance) =>
    <String, dynamic>{};

AuthenticationResultFailed _$AuthenticationResultFailedFromJson(
    Map<String, dynamic> json) {
  return AuthenticationResultFailed(
    remainingAttempts: json['RemainingAttempts'] as int,
    blockedDuration: json['BlockedDuration'] as int,
  );
}

Map<String, dynamic> _$AuthenticationResultFailedToJson(
        AuthenticationResultFailed instance) =>
    <String, dynamic>{
      'RemainingAttempts': instance.remainingAttempts,
      'BlockedDuration': instance.blockedDuration,
    };

AuthenticationResultError _$AuthenticationResultErrorFromJson(
    Map<String, dynamic> json) {
  return AuthenticationResultError(
    error: json['Error'] as String,
  );
}

Map<String, dynamic> _$AuthenticationResultErrorToJson(
        AuthenticationResultError instance) =>
    <String, dynamic>{
      'Error': instance.error,
    };
